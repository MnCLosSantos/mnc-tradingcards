/* ═══════════════════════════════════════════════════════
   MNC TRADING CARDS — Frontend  v1.1
═══════════════════════════════════════════════════════ */
'use strict';

// ── State ──────────────────────────────────────────────
var state = {
    sets:           {},
    rarities:       {},
    storedCards:    [],
    inventoryCards: [],
    binderId:       null,
    pendingCards:   [],
    currentSetId:   null,
    shopCards:      [],
    shopSelected:   {},   // cardid → true
    shopMult:       0.8,
};

// ── Rarity fallbacks ───────────────────────────────────
var RARITY_DEF = {
    common:    { label: 'Common',     holo: false, value: 10   },
    uncommon:  { label: 'Uncommon',   holo: false, value: 50   },
    rare:      { label: 'Rare',       holo: true,  value: 250  },
    ultraRare: { label: 'Ultra Rare', holo: true,  value: 1000 },
    misprint:  { label: 'Misprint',   holo: true,  value: 2500 },
    damaged:   { label: 'Damaged',    holo: false, value: 0    },
};

function getRarity(id) {
    var r = state.rarities && state.rarities[id];
    if (r) return r;
    return RARITY_DEF[id] || RARITY_DEF.common;
}

function getCardValue(data) {
    if (data.value !== undefined && data.value !== null) return data.value;
    return getRarity(data.rarity).value || 0;
}

// ── Image resolution ───────────────────────────────────
function cardImg(data) {
    if (data.image) return data.image;
    return 'https://docs.fivem.net/vehicles/' + (data.model || '') + '.webp';
}
function cardBg(data) {
    return data.background || '';
}
function imgFallback(img, data) {
    img.onerror = null;
    if (data.image) { img.style.visibility = 'hidden'; return; }
    img.src = 'https://docs.fivem.net/vehicles/' + (data.model || '') + '.png';
    img.onerror = function() { img.onerror = null; img.style.visibility = 'hidden'; };
}

// ── NUI fetch ──────────────────────────────────────────
function nuiFetch(endpoint, body) {
    if (typeof GetParentResourceName !== 'function') return;
    fetch('https://' + GetParentResourceName() + '/' + endpoint, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body || {}),
    }).catch(function() {});
}

// ══════════════════════════════════════════════════════
//  SOUNDS
// ══════════════════════════════════════════════════════
var _audioCtx = null;
function getAudioCtx() {
    if (!_audioCtx) _audioCtx = new (window.AudioContext || window.webkitAudioContext)();
    return _audioCtx;
}

var _soundCache = {};
function playSound(name, vol) {
    vol = vol !== undefined ? vol : 0.6;
    var src = 'sounds/' + name;
    if (_soundCache[name]) {
        try {
            var clone = _soundCache[name].cloneNode();
            clone.volume = vol;
            clone.play().catch(function(){});
        } catch(e) {}
        return;
    }
    // Try .ogg first, fall back to .mp3
    var audio = new Audio(src + '.ogg');
    audio.volume = vol;
    audio.addEventListener('canplaythrough', function() {
        _soundCache[name] = audio;
        audio.play().catch(function(){});
    }, { once: true });
    audio.addEventListener('error', function() {
        var mp3 = new Audio(src + '.mp3');
        mp3.volume = vol;
        _soundCache[name] = mp3;
        mp3.play().catch(function(){});
    }, { once: true });
}

function playSoundForRarity(rarity) {
    if (rarity === 'misprint')  { playSound('misprint', 0.8); return; }
    if (rarity === 'damaged')   { playSound('damaged',  0.6); return; }
    if (rarity === 'ultraRare') { playSound('ultraRare', 0.75); return; }
    if (rarity === 'rare')      { playSound('rare',     0.65); return; }
    playSound('reveal', 0.5);
}

// ── Particles ──────────────────────────────────────────
var P_COLORS = ['#fbbf24', '#f43f5e', '#fb923c', '#e2e8f0'];
function spawnParticles(container, extra) {
    if (!container) return;
    var count = extra ? 20 : 10;
    for (var i = 0; i < count; i++) {
        var p = document.createElement('div');
        p.className = 'tc-particle';
        var sz    = (Math.random() * 3 + 1).toFixed(1);
        var left  = (Math.random() * 86 + 7).toFixed(1);
        var dur   = (Math.random() * 2 + 2.5).toFixed(1);
        var delay = (Math.random() * 4).toFixed(1);
        var col   = P_COLORS[Math.floor(Math.random() * P_COLORS.length)];
        p.style.cssText = 'width:' + sz + 'px;height:' + sz + 'px;left:' + left + '%;bottom:4%;background:' + col + ';box-shadow:0 0 ' + (sz * 2) + 'px ' + col + ';--dur:' + dur + 's;--delay:' + delay + 's;';
        container.appendChild(p);
    }
}

// ══════════════════════════════════════════════════════
//  BUILD CARD
//  options: { faceDown, large, tilt, small }
// ══════════════════════════════════════════════════════
function buildCard(data, options) {
    options = options || {};

    var rarity    = data.rarity || 'common';
    var rDef      = getRarity(rarity);
    var setLbl    = data.setLabel || (state.sets[data.setId] && state.sets[data.setId].label) || '';
    var isHolo    = rDef.holo ? true : false;
    var isUltra   = rarity === 'ultraRare';
    var isMisprint = !!(data.isMisprint || data.rarity === 'misprint');
    var isDamaged  = !!(data.isDamaged  || data.rarity === 'damaged');

    // Print number label — custom printNum or sequential #NNN / TOTAL (per-set, starts at 1)
    // Misprints show their base card number but with "MISPRINT" replacing the count
    var setCardCount = state.sets[data.setId] ? state.sets[data.setId].cards.length : 0;
    var numStr = String(data.number || 0);
    while (numStr.length < 3) numStr = '0' + numStr;

    // The printNum from server is the global sequential print (e.g. "#00042 [Military Forces]")
    // We display only the global portion on the card face, and show both numbers on hover
    var globalPrint = data.printNum || '';
    var printLabel;
    if (isMisprint) {
        printLabel = '#' + numStr + ' / MISPRINT';
    } else {
        printLabel = '#' + numStr + (setCardCount > 0 ? ' / ' + setCardCount : '');
    }

    var bgUrl = cardBg(data);

    var wrap = document.createElement('div');
    wrap.className = 'tc-card-perspective' +
        (options.large ? ' large' : '') +
        (options.small ? ' small' : '');

    var card = document.createElement('div');
    card.className = 'tc-card';
    card.dataset.rarity = rarity;
    if (isMisprint) card.classList.add('is-misprint');
    if (isDamaged)  card.classList.add('is-damaged');

    var face = document.createElement('div');
    face.className = 'tc-face';

    // Background image layer
    if (bgUrl) {
        var bgLayer = document.createElement('div');
        bgLayer.className = 'tc-bg-layer';
        bgLayer.style.backgroundImage = 'url(' + bgUrl + ')';
        face.appendChild(bgLayer);
    }

    var header = document.createElement('div');
    header.className = 'tc-header';

    // Print number on left, badge on right
    var printEl = document.createElement('span');
    printEl.className = 'tc-num';
    printEl.textContent = printLabel;
    // Tooltip: show global print number (includes set name)
    if (isMisprint) {
        printEl.title = 'Card #' + (data.number || 0) + ' from the ' + (setLbl || 'set') + ' — this is a rare MISPRINT variant';
    } else if (globalPrint) {
        printEl.title = globalPrint;
    }

    var badge = document.createElement('span');
    badge.className = 'tc-badge';
    badge.textContent = rDef.label;

    header.appendChild(badge);

    // Special overlays for misprint / damaged
    if (isMisprint) {
        var mpStamp = document.createElement('div');
        mpStamp.className = 'tc-misprint-stamp';
        mpStamp.textContent = 'MISPRINT';
        face.appendChild(mpStamp);
    }
    if (isDamaged) {
        var dmgOverlay = document.createElement('div');
        dmgOverlay.className = 'tc-damaged-overlay';
        dmgOverlay.innerHTML = '<div class="tc-damaged-x">✕</div><div class="tc-damaged-label">DAMAGED</div>';
        face.appendChild(dmgOverlay);
    }

    var imgWrap = document.createElement('div');
    imgWrap.className = 'tc-img-wrap';

    var img = document.createElement('img');
    img.className = 'tc-img';
    img.src = cardImg(data);
    img.alt = data.name || '';
    img.loading = 'lazy';
    (function(d) { img.onerror = function() { imgFallback(img, d); }; })(data);
    imgWrap.appendChild(img);

    // Value label (hidden from face, kept for shop logic via data attribute)
    var cardVal = getCardValue(data);
    var footer = document.createElement('div');
    footer.className = 'tc-footer';
    footer.innerHTML =
        '<div class="tc-footer-line"></div>' +
        '<div class="tc-name">' + (data.name || '') + '</div>' +
        '<div class="tc-footer-row">' +
            '<div class="tc-set">' + setLbl + '</div>' +
            '<div class="tc-value' + (isDamaged ? ' tc-value-zero' : '') + '" data-value="' + cardVal + '">$' + cardVal.toLocaleString() + '</div>' +
        '</div>' +
        '<div class="tc-print-num" title="' + (printEl.title || '') + '">' + printLabel + '</div>';

    face.appendChild(header);
    face.appendChild(imgWrap);
    face.appendChild(footer);
    card.appendChild(face);

    if (isHolo || isMisprint) {
        var lines = document.createElement('div');
        lines.className = 'tc-holo tc-holo-lines' + (isMisprint ? ' misprint-holo' : '');
        card.appendChild(lines);

        var spot = document.createElement('div');
        spot.className = 'tc-holo tc-holo-spot';
        card.appendChild(spot);

        if (isUltra || isMisprint) {
            var scan = document.createElement('div');
            scan.className = 'tc-holo tc-holo-scan';
            card.appendChild(scan);
        }
    }

    if (isUltra || isMisprint) {
        var pc = document.createElement('div');
        pc.className = 'tc-particles';
        card.appendChild(pc);
        spawnParticles(pc, isMisprint);
    }

    if (options.faceDown) {
        var back = document.createElement('div');
        back.className = 'tc-back';
        back.innerHTML = '<div class="tc-back-circle">&#x1F0CF;</div>';
        card.appendChild(back);

        back.addEventListener('click', function() {
            back.classList.add('revealed');
            playSoundForRarity(rarity);
            if (options.tilt) enableTilt(wrap, card);
        }, { once: true });
    }

    wrap.appendChild(card);
    if (options.tilt && !options.faceDown) enableTilt(wrap, card);

    return wrap;
}

// ══════════════════════════════════════════════════════
//  TILT  — listeners on wrap only, never on document
// ══════════════════════════════════════════════════════
function enableTilt(wrap, card) {
    wrap.addEventListener('mousemove', function(e) {
        var r  = wrap.getBoundingClientRect();
        var dx = (e.clientX - (r.left + r.width  / 2)) / (r.width  / 2);
        var dy = (e.clientY - (r.top  + r.height / 2)) / (r.height / 2);
        card.style.transform =
            'rotateX(' + (-(dy * 14)).toFixed(2) + 'deg) rotateY(' + (dx * 14).toFixed(2) + 'deg) scale(1.04)';
        var sp = card.querySelector('.tc-holo-spot');
        if (sp) {
            sp.style.setProperty('--mx', ((e.clientX - r.left) / r.width  * 100).toFixed(1) + '%');
            sp.style.setProperty('--my', ((e.clientY - r.top)  / r.height * 100).toFixed(1) + '%');
        }
    });
    wrap.addEventListener('mouseleave', function() {
        card.style.transform = 'rotateX(0deg) rotateY(0deg) scale(1)';
    });
}

// ══════════════════════════════════════════════════════
//  SCREEN MANAGEMENT
// ══════════════════════════════════════════════════════
function hideAll() {
    document.querySelectorAll('.screen').forEach(function(s) { s.classList.add('hidden'); });
    document.body.style.display = 'none';
}
function showScreen(id) {
    document.querySelectorAll('.screen').forEach(function(s) { s.classList.add('hidden'); });
    document.body.style.display = 'block';
    document.getElementById(id).classList.remove('hidden');
}
function closeUI() {
    hideAll();
    nuiFetch('closeUI');
}
document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') closeUI();
});

// ══════════════════════════════════════════════════════
//  PACK OPENING — TEAR UI
// ══════════════════════════════════════════════════════
var packTearState = { dragging: false, startY: 0, currentY: 0, threshold: 90, opened: false };

function showPackOpen(packLabel, cards) {
    state.pendingCards     = cards;
    packTearState.opened   = false;
    packTearState.dragging = false;
    var flap = document.getElementById('packFlap');
    if (flap) flap.classList.remove('torn');

    var icons = { basic: '🃏', premium: '✨', legendary: '👑' };
    var icon  = '🃏';
    var ll    = (packLabel || '').toLowerCase();
    if (ll.indexOf('premium')   !== -1) icon = '✨';
    if (ll.indexOf('legendary') !== -1) icon = '👑';

    var el;
    el = document.getElementById('packLabelIcon'); if (el) el.textContent = icon;
    el = document.getElementById('packLabelName'); if (el) el.textContent = (packLabel || 'CARD PACK').toUpperCase();
    el = document.getElementById('packOpenTitle'); if (el) el.textContent = (packLabel || 'Card Pack').toUpperCase();

    drawProgress(0);
    showScreen('screen-pack-open');
    initPackDrag();
}

function initPackDrag() {
    var tearZone = document.getElementById('packTearZone');
    var wrapper  = document.getElementById('packWrapper');
    if (!tearZone || !wrapper) return;
    var newZone = tearZone.cloneNode(true);
    tearZone.parentNode.replaceChild(newZone, tearZone);

    function onDragStart(clientY) {
        if (packTearState.opened) return;
        packTearState.dragging = true;
        packTearState.startY   = clientY;
        packTearState.currentY = clientY;
        var prog = document.getElementById('packProgress');
        if (prog) prog.classList.add('visible');
    }
    function onDragMove(clientY) {
        if (!packTearState.dragging || packTearState.opened) return;
        packTearState.currentY = clientY;
        var delta = Math.max(0, packTearState.startY - clientY);
        var pct   = Math.min(1, delta / packTearState.threshold);
        drawProgress(pct);
        var body = document.querySelector('.pack-body');
        if (body) body.style.transform = 'translateY(' + (-delta * 0.08) + 'px)';
        if (pct >= 1) triggerPackOpen();
    }
    function onDragEnd() {
        if (!packTearState.dragging) return;
        packTearState.dragging = false;
        if (!packTearState.opened) {
            drawProgress(0);
            var body = document.querySelector('.pack-body');
            if (body) body.style.transform = '';
            var prog = document.getElementById('packProgress');
            if (prog) prog.classList.remove('visible');
        }
    }
    newZone.addEventListener('mousedown', function(e) { onDragStart(e.clientY); });
    document.addEventListener('mousemove', function(e) { onDragMove(e.clientY); });
    document.addEventListener('mouseup', onDragEnd);
    newZone.addEventListener('touchstart', function(e) { onDragStart(e.touches[0].clientY); }, { passive: true });
    document.addEventListener('touchmove', function(e) { onDragMove(e.touches[0].clientY); }, { passive: true });
    document.addEventListener('touchend', onDragEnd);
}

function drawProgress(pct) {
    var canvas = document.getElementById('packProgress');
    if (!canvas) return;
    var ctx = canvas.getContext('2d'), w = canvas.width, h = canvas.height, r = 18;
    ctx.clearRect(0, 0, w, h);
    ctx.beginPath(); ctx.arc(w/2, h/2, r, 0, Math.PI * 2);
    ctx.strokeStyle = 'rgba(255,255,255,0.15)'; ctx.lineWidth = 3; ctx.stroke();
    if (pct > 0) {
        ctx.beginPath();
        ctx.arc(w/2, h/2, r, -Math.PI/2, -Math.PI/2 + Math.PI * 2 * pct);
        var col = pct >= 1 ? '#fbbf24' : '#60a5fa';
        ctx.strokeStyle = col; ctx.lineWidth = 3; ctx.lineCap = 'round'; ctx.stroke();
        ctx.fillStyle = col; ctx.font = 'bold 13px sans-serif';
        ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
        ctx.fillText('↑', w/2, h/2);
    }
}

function triggerPackOpen() {
    if (packTearState.opened) return;
    packTearState.opened = true;
    playSound('tear', 0.75);

    var flap = document.getElementById('packFlap');
    if (flap) flap.classList.add('torn');
    var body = document.querySelector('.pack-body');
    if (body) {
        body.style.transition = 'transform 0.4s cubic-bezier(0.34,1.56,0.64,1)';
        body.style.transform  = 'translateY(6px) scale(1.02)';
    }
    setTimeout(function() { showPackReveal(state.pendingCards); }, 550);
}

// ══════════════════════════════════════════════════════
//  PACK REVEAL
// ══════════════════════════════════════════════════════
function showPackReveal(cards) {
    var container = document.getElementById('revealCards');
    container.innerHTML = '';
    cards.forEach(function(cardData, idx) {
        var wrap  = buildCard(cardData, { faceDown: true, tilt: true });
        var inner = wrap.querySelector('.tc-card');
        inner.style.animation = 'cardDeal 0.45s cubic-bezier(0.34,1.56,0.64,1) ' + (idx * 0.13) + 's both';
        container.appendChild(wrap);
    });
    showScreen('screen-reveal');
}
document.getElementById('btnRevealClose').addEventListener('click', function() { playSound('click', 0.5); closeUI(); });

// ══════════════════════════════════════════════════════
//  DISCARD CONFIRM MODAL  (window.confirm won't work in NUI/CEF)
// ══════════════════════════════════════════════════════
function showDiscardConfirm(message, onYes) {
    var existing = document.getElementById('discardConfirmModal');
    if (existing) existing.remove();

    var overlay = document.createElement('div');
    overlay.id = 'discardConfirmModal';
    overlay.style.cssText =
        'position:fixed;inset:0;z-index:9999;display:flex;align-items:center;justify-content:center;' +
        'background:rgba(0,0,0,0.7);';

    var box = document.createElement('div');
    box.style.cssText =
        'background:linear-gradient(160deg,#1a2035,#111827);border:1px solid rgba(239,83,80,0.35);' +
        'border-radius:12px;padding:28px 32px;max-width:340px;text-align:center;' +
        'box-shadow:0 20px 60px rgba(0,0,0,0.8);color:#f0f4ff;font-family:var(--font-ui);';

    var icon = document.createElement('div');
    icon.style.cssText = 'font-size:2rem;margin-bottom:12px;';
    icon.textContent = '🗑';

    var msg = document.createElement('div');
    msg.style.cssText = 'font-size:0.9rem;margin-bottom:22px;line-height:1.5;color:#cbd5e1;';
    msg.textContent = message;

    var btnRow = document.createElement('div');
    btnRow.style.cssText = 'display:flex;gap:10px;justify-content:center;';

    var cancelBtn = document.createElement('button');
    cancelBtn.style.cssText =
        'padding:8px 24px;border-radius:7px;border:1px solid rgba(255,255,255,0.15);' +
        'background:transparent;color:#7a8fb0;font-family:var(--font-ui);font-size:0.85rem;cursor:pointer;';
    cancelBtn.textContent = 'Keep';
    cancelBtn.addEventListener('click', function() { playSound('click', 0.5); overlay.remove(); });

    var yesBtn = document.createElement('button');
    yesBtn.style.cssText =
        'padding:8px 28px;border-radius:7px;border:none;' +
        'background:linear-gradient(135deg,#ef5350,#b71c1c);color:#fff;' +
        'font-family:var(--font-ui);font-size:0.85rem;font-weight:700;cursor:pointer;' +
        'box-shadow:0 3px 14px rgba(239,83,80,0.4);';
    yesBtn.textContent = 'Discard';
    yesBtn.addEventListener('click', function() { playSound('click', 0.5); overlay.remove(); onYes(); });

    btnRow.appendChild(cancelBtn);
    btnRow.appendChild(yesBtn);
    box.appendChild(icon);
    box.appendChild(msg);
    box.appendChild(btnRow);
    overlay.appendChild(box);
    document.body.appendChild(overlay);

    overlay.addEventListener('click', function(e) { if (e.target === overlay) overlay.remove(); });
}

// ══════════════════════════════════════════════════════
//  SINGLE CARD VIEW
// ══════════════════════════════════════════════════════
function viewCard(cardData) {
    var container = document.getElementById('singleCardContainer');
    container.innerHTML = '';
    var wrap = buildCard(cardData, { tilt: true, large: true });
    container.appendChild(wrap);

    // Damaged — show discard button
    var discardArea = document.getElementById('cardViewDiscard');
    if (discardArea) discardArea.innerHTML = '';
    if (cardData.isDamaged && discardArea) {
        var btn = document.createElement('button');
        btn.className   = 'btn-danger';
        btn.textContent = '🗑 Discard Damaged Card';
        (function(cd) {
            btn.addEventListener('click', function() {
                playSound('click', 0.5);
                showDiscardConfirm('This card is worthless and cannot be sold or stored. Permanently discard it?', function() {
                    nuiFetch('discardDamaged', { cardid: cd.cardid || cd.id });
                    closeUI();
                });
            });
        })(cardData);
        discardArea.appendChild(btn);
    }

    showScreen('screen-card');
}
document.getElementById('btnCardClose').addEventListener('click', function() { playSound('click', 0.5); closeUI(); });

// ══════════════════════════════════════════════════════
//  BINDER
// ══════════════════════════════════════════════════════
function openBinder(data) {
    state.binderId       = data.binderId      || null;
    state.sets           = data.sets          || {};
    state.rarities       = data.rarities      || {};
    state.storedCards    = data.storedCards    || [];
    state.inventoryCards = data.inventoryCards || [];
    state.currentSetId   = null;

    buildBinderSidebar();
    var firstSetId = Object.keys(state.sets).sort(function(a, b) {
        return ((state.sets[a].label || '') < (state.sets[b].label || '') ? -1 : 1);
    })[0];
    if (firstSetId) renderBinderSet(firstSetId);
    showScreen('screen-binder');
}

function buildBinderSidebar() {
    var list = document.getElementById('binderSetList');
    list.innerHTML = '';

    // ── Pinned MISPRINTS category at the top ──────────────────
    function _isMp(c) { return !!(c.isMisprint || c.rarity === 'misprint'); }
    var allMisprints = state.storedCards.filter(function(c) { return _isMp(c); })
        .concat(state.inventoryCards.filter(function(c) { return _isMp(c); }));
    var mpCount = allMisprints.length;

    var mpPending = state.inventoryCards.filter(function(c) { return _isMp(c); }).length;

    var mpItem = document.createElement('div');
    mpItem.className = 'binder-set-item binder-misprint-category';
    mpItem.dataset.setId = '__misprints__';
    mpItem.innerHTML =
        '<span class="binder-set-icon">✦</span>' +
        '<div class="binder-set-info">' +
            '<div class="binder-set-name">Misprints</div>' +
            '<div class="binder-set-count">' + mpCount + ' card' + (mpCount === 1 ? '' : 's') + '</div>' +
        '</div>' +
        (mpPending > 0 ? '<span class="binder-pending-badge binder-pending-badge--misprint" title="' + mpPending + ' misprint' + (mpPending === 1 ? '' : 's') + ' in inventory — tap to store">＋' + mpPending + '</span>' : '') +
        '<span class="binder-set-tick ' + (mpCount > 0 ? 'tick-yes' : 'tick-no') + '">' + (mpCount > 0 ? mpCount : '') + '</span>';

    mpItem.addEventListener('click', function() {
        playSound('click', 0.5);
        document.querySelectorAll('.binder-set-item').forEach(function(i) { i.classList.remove('active'); });
        mpItem.classList.add('active');
        state.currentSetId = '__misprints__';
        renderMisprints();
    });
    list.appendChild(mpItem);

    // ── Divider ───────────────────────────────────────────────
    var div = document.createElement('div');
    div.className = 'binder-sidebar-divider';
    list.appendChild(div);

    // ── Sets sorted alphabetically ────────────────────────────
    var sortedEntries = Object.entries(state.sets).sort(function(a, b) {
        var la = (a[1].label || '').toLowerCase();
        var lb = (b[1].label || '').toLowerCase();
        return la < lb ? -1 : la > lb ? 1 : 0;
    });

    sortedEntries.forEach(function(entry) {
        var setId   = entry[0];
        var setData = entry[1];

        var ownedNums = new Set();
        state.storedCards.forEach(function(c)    { if (c.setId === setId && !_isMp(c)) ownedNums.add(c.number); });
        state.inventoryCards.forEach(function(c) { if (c.setId === setId && !_isMp(c)) ownedNums.add(c.number); });
        var owned = ownedNums.size;
        var total = setData.cards.length;
        var done  = owned >= total;

        // Count inventory cards for this set that are NOT yet stored (and not misprints/damaged)
        var storedNums = new Set();
        state.storedCards.forEach(function(c) { if (c.setId === setId && !_isMp(c)) storedNums.add(c.number); });
        var pendingCount = state.inventoryCards.filter(function(c) {
            return c.setId === setId && !_isMp(c) && !c.isDamaged && !storedNums.has(c.number);
        }).length;

        var item = document.createElement('div');
        item.className     = 'binder-set-item';
        item.dataset.setId = setId;

        item.innerHTML =
            '<span class="binder-set-icon">' + (setData.icon || '') + '</span>' +
            '<div class="binder-set-info">' +
                '<div class="binder-set-name">' + setData.label + '</div>' +
                '<div class="binder-set-count">' + owned + ' / ' + total + '</div>' +
            '</div>' +
            (pendingCount > 0 ? '<span class="binder-pending-badge" title="' + pendingCount + ' card' + (pendingCount === 1 ? '' : 's') + ' in inventory ready to store">\uFF0B' + pendingCount + '</span>' : '') +
            '<span class="binder-set-tick ' + (done ? 'tick-yes' : 'tick-no') + '">' + (done ? '\u2713' : '') + '</span>';

        item.addEventListener('click', function() {
            playSound('click', 0.5);
            document.querySelectorAll('.binder-set-item').forEach(function(i) { i.classList.remove('active'); });
            item.classList.add('active');
            renderBinderSet(setId);
        });
        list.appendChild(item);
    });
}

function renderBinderSet(setId) {
    var setData = state.sets[setId];
    if (!setData) return;
    state.currentSetId = setId;

    var grid    = document.getElementById('binderGrid');
    var titleEl = document.getElementById('binderSetTitle');
    var progEl  = document.getElementById('binderProgress');
    var tabEl   = document.getElementById('binderPageTab');

    var storedByNum    = {};
    var inventoryByNum = {};

    function _isMisprint(c) { return !!(c.isMisprint || c.rarity === 'misprint'); }

    state.storedCards.forEach(function(c) {
        if (c.setId === setId && !_isMisprint(c) && !c.isDamaged && !storedByNum[c.number]) {
            storedByNum[c.number] = c;
        }
    });
    state.inventoryCards.forEach(function(c) {
        if (c.setId === setId && !_isMisprint(c) && !inventoryByNum[c.number]) {
            inventoryByNum[c.number] = c;
        }
    });

    var ownedCount = Object.keys(storedByNum).length +
        Object.keys(inventoryByNum).filter(function(n) { return !storedByNum[n]; }).length;

    titleEl.textContent = setData.label;
    progEl.textContent  = ownedCount + ' / ' + setData.cards.length + ' collected';
    if (tabEl) tabEl.textContent = (setData.icon || '') + ' ' + setData.label.toUpperCase();
    grid.innerHTML = '';

    var sorted = setData.cards.slice().sort(function(a, b) { return a.number - b.number; });

    sorted.forEach(function(def) {
        var stored = storedByNum[def.number];
        var inInv  = inventoryByNum[def.number];

        if (stored) {
            var cardData = {
                setId: setId, setLabel: setData.label, number: def.number, name: def.name,
                model: def.model, image: def.image || null, background: stored.background || def.background || null,
                rarity: stored.rarity, isMisprint: stored.isMisprint, isDamaged: stored.isDamaged,
                printNum: stored.printNum, value: stored.value,
            };
            var wrap = buildCard(cardData, { tilt: true });

            var hint = document.createElement('div');
            hint.className = 'binder-remove-hint';
            hint.textContent = '↑ Drag up to remove';
            wrap.style.position = 'relative';
            wrap.appendChild(hint);

            wrap.dataset.cardid = stored.cardid;
            wrap.dataset.setId  = setId;
            wrap.dataset.number = def.number;
            wrap.dataset.stored = '1';

            addDragToRemove(wrap, stored);
            grid.appendChild(wrap);

        } else if (inInv) {
            var cardData2 = {
                setId: setId, setLabel: setData.label, number: def.number, name: def.name,
                model: def.model, image: def.image || null, background: inInv.background || def.background || null,
                rarity: inInv.rarity, isMisprint: inInv.isMisprint, isDamaged: inInv.isDamaged,
                printNum: inInv.printNum, value: inInv.value,
            };
            var wrap2 = buildCard(cardData2, { tilt: true });

            // Damaged cards get a warning overlay instead of a store button
            if (inInv.isDamaged) {
                var dmgOverlay2 = document.createElement('div');
                dmgOverlay2.className = 'binder-store-overlay binder-damaged-overlay';
                var dmgMsg = document.createElement('div');
                dmgMsg.className = 'binder-damaged-msg';
                dmgMsg.textContent = '⚠ Damaged — cannot store';
                dmgOverlay2.appendChild(dmgMsg);
                wrap2.style.position = 'relative';
                wrap2.appendChild(dmgOverlay2);
            } else {
                var overlay = document.createElement('div');
                overlay.className = 'binder-store-overlay';
                var btn = document.createElement('button');
                btn.className   = 'binder-store-btn';
                btn.textContent = '+ Store in Binder';
                btn.dataset.cardid = inInv.cardid;
                btn.dataset.slot   = inInv.slot || '';

                (function(cardRef, btnEl) {
                    btnEl.addEventListener('click', function(e) {
                        e.stopPropagation();
                        playSound('click', 0.5);
                        btnEl.disabled    = true;
                        btnEl.textContent = 'Storing…';
                        nuiFetch('storeCardInBinder', { cardid: cardRef.cardid, slot: cardRef.slot });
                        btnEl.textContent = 'Stored ✓';
                        overlay.style.display = 'none';

                        state.inventoryCards = state.inventoryCards.filter(function(c) { return c.cardid !== cardRef.cardid; });
                        state.storedCards.push(cardRef);

                        setTimeout(function() {
                            buildBinderSidebar();
                            renderBinderSet(cardRef.setId);
                            document.querySelectorAll('.binder-set-item').forEach(function(i) {
                                i.classList.toggle('active', i.dataset.setId === cardRef.setId);
                            });
                        }, 400);
                    });
                })(inInv, btn);

                overlay.appendChild(btn);
                wrap2.style.position = 'relative';
                wrap2.appendChild(overlay);
            }
            grid.appendChild(wrap2);

        } else {
            var numStr2 = String(def.number);
            while (numStr2.length < 3) numStr2 = '0' + numStr2;
            var slot = document.createElement('div');
            slot.className = 'slot-empty';
            slot.innerHTML = '<div class="slot-empty-num">#' + numStr2 + '</div><div class="slot-empty-name">' + def.name + '</div>';
            grid.appendChild(slot);
        }
    });

    document.querySelectorAll('.binder-set-item').forEach(function(i) {
        i.classList.toggle('active', i.dataset.setId === setId);
    });
}

// ══════════════════════════════════════════════════════
//  MISPRINTS PAGE — standalone category, no set slots
// ══════════════════════════════════════════════════════
function renderMisprints() {
    var grid    = document.getElementById('binderGrid');
    var titleEl = document.getElementById('binderSetTitle');
    var progEl  = document.getElementById('binderProgress');
    var tabEl   = document.getElementById('binderPageTab');

    var storedMisprints    = state.storedCards.filter(function(c)    { return !!(c.isMisprint || c.rarity === 'misprint'); });
    var inventoryMisprints = state.inventoryCards.filter(function(c) { return !!(c.isMisprint || c.rarity === 'misprint'); });
    var total = storedMisprints.length + inventoryMisprints.length;

    titleEl.textContent = 'Misprints';
    progEl.textContent  = total + ' misprint' + (total === 1 ? '' : 's') + ' collected';
    if (tabEl) tabEl.textContent = '✦ MISPRINTS';
    grid.innerHTML = '';

    if (total === 0) {
        var empty = document.createElement('div');
        empty.className = 'slot-empty';
        empty.style.cssText = 'grid-column:1/-1;text-align:center;padding:40px 20px;opacity:0.5;';
        empty.innerHTML = '<div style="font-size:2rem;margin-bottom:8px;">✦</div>' +
            '<div>No misprints found yet.</div>' +
            '<div style="font-size:0.8rem;margin-top:6px;">Misprints are rare errors that drop from packs — keep opening!</div>';
        grid.appendChild(empty);
        return;
    }

    // ── Stored misprints (drag to remove) ──────────────────
    storedMisprints.forEach(function(c) {
        var setData = state.sets[c.setId] || {};
        var mpWrap  = buildCard({
            setId: c.setId, setLabel: c.setLabel || setData.label || '',
            number: c.number, name: c.name,
            model: c.model, image: c.image || null, background: c.background || null,
            rarity: 'misprint', isMisprint: true, isDamaged: false,
            printNum: c.printNum, value: c.value,
        }, { tilt: true });

        var hint = document.createElement('div');
        hint.className  = 'binder-remove-hint';
        hint.textContent = '↑ Drag up to remove';
        mpWrap.style.position = 'relative';
        mpWrap.appendChild(hint);
        addDragToRemove(mpWrap, c);
        grid.appendChild(mpWrap);
    });

    // ── Inventory misprints (store button) ─────────────────
    inventoryMisprints.forEach(function(c) {
        var setData  = state.sets[c.setId] || {};
        var mpWrap2  = buildCard({
            setId: c.setId, setLabel: c.setLabel || setData.label || '',
            number: c.number, name: c.name,
            model: c.model, image: c.image || null, background: c.background || null,
            rarity: 'misprint', isMisprint: true, isDamaged: false,
            printNum: c.printNum, value: c.value,
        }, { tilt: true });

        var mpOverlay = document.createElement('div');
        mpOverlay.className = 'binder-store-overlay';
        var mpBtn = document.createElement('button');
        mpBtn.className   = 'binder-store-btn binder-store-btn-misprint';
        mpBtn.textContent = '+ Store Misprint';
        mpBtn.dataset.cardid = c.cardid;

        (function(cardRef, btnEl, ov) {
            btnEl.addEventListener('click', function(e) {
                e.stopPropagation();
                playSound('click', 0.5);
                btnEl.disabled    = true;
                btnEl.textContent = 'Storing…';
                nuiFetch('storeCardInBinder', { cardid: cardRef.cardid, slot: cardRef.slot });
                btnEl.textContent = 'Stored ✓';
                ov.style.display  = 'none';

                state.inventoryCards = state.inventoryCards.filter(function(c2) { return c2.cardid !== cardRef.cardid; });
                state.storedCards.push(cardRef);

                setTimeout(function() {
                    buildBinderSidebar();
                    renderMisprints();
                    document.querySelectorAll('.binder-set-item').forEach(function(i) {
                        i.classList.toggle('active', i.dataset.setId === '__misprints__');
                    });
                }, 400);
            });
        })(c, mpBtn, mpOverlay);

        mpOverlay.appendChild(mpBtn);
        mpWrap2.style.position = 'relative';
        mpWrap2.appendChild(mpOverlay);
        grid.appendChild(mpWrap2);
    });

    document.querySelectorAll('.binder-set-item').forEach(function(i) {
        i.classList.toggle('active', i.dataset.setId === '__misprints__');
    });
}

// ── DRAG-TO-REMOVE FROM BINDER ─────────────────────────
var dragState = { active: false, wrap: null, cardInfo: null, startX: 0, startY: 0, origRect: null, ghost: null };

function addDragToRemove(wrap, cardInfo) {
    var card = wrap.querySelector('.tc-card');
    if (!card) return;

    function onDragStart(clientX, clientY) {
        if (dragState.active) return;
        dragState.active   = true; dragState.wrap = wrap; dragState.cardInfo = cardInfo;
        dragState.startX   = clientX; dragState.startY = clientY;
        dragState.origRect = wrap.getBoundingClientRect();

        var ghost = wrap.cloneNode(true);
        ghost.style.cssText =
            'position:fixed;top:' + dragState.origRect.top + 'px;left:' + dragState.origRect.left + 'px;' +
            'width:' + dragState.origRect.width + 'px;height:' + dragState.origRect.height + 'px;' +
            'pointer-events:none;z-index:9999;transition:none;box-shadow:0 20px 60px rgba(0,0,0,0.7);filter:brightness(1.15);';
        document.body.appendChild(ghost);
        dragState.ghost = ghost;
        wrap.style.opacity = '0.3';
        var zone = document.getElementById('binderRemoveZone');
        if (zone) zone.classList.add('active');
    }
    function onDragMove(clientX, clientY) {
        if (!dragState.active || dragState.wrap !== wrap) return;
        var dx = clientX - dragState.startX, dy = clientY - dragState.startY;
        if (dragState.ghost) {
            dragState.ghost.style.left = (dragState.origRect.left + dx) + 'px';
            dragState.ghost.style.top  = (dragState.origRect.top  + dy) + 'px';
        }
        var zone = document.getElementById('binderRemoveZone');
        if (zone) {
            var zoneRect = zone.getBoundingClientRect();
            zone.classList.toggle('over', clientY < (zoneRect.top + zoneRect.height + 20));
        }
    }
    function onDragEnd(clientX, clientY) {
        if (!dragState.active || dragState.wrap !== wrap) return;
        var zone     = document.getElementById('binderRemoveZone');
        var zoneRect = zone ? zone.getBoundingClientRect() : null;
        var inZone   = zoneRect && clientY < (zoneRect.top + zoneRect.height + 20);

        if (dragState.ghost) { dragState.ghost.remove(); dragState.ghost = null; }
        wrap.style.opacity = '';
        if (zone) { zone.classList.remove('active'); zone.classList.remove('over'); }

        if (inZone) {
            playSound('click', 0.5);
            nuiFetch('removeCardFromBinder', { cardid: cardInfo.cardid, binderId: state.binderId });
            state.storedCards    = state.storedCards.filter(function(c) { return c.cardid !== cardInfo.cardid; });
            state.inventoryCards.push({
                cardid: cardInfo.cardid, setId: cardInfo.setId, setLabel: cardInfo.setLabel,
                number: cardInfo.number, name: cardInfo.name, model: cardInfo.model,
                image: cardInfo.image || null, background: cardInfo.background || null,
                rarity: cardInfo.rarity, isMisprint: cardInfo.isMisprint, isDamaged: cardInfo.isDamaged,
                printNum: cardInfo.printNum, value: cardInfo.value,
            });
            setTimeout(function() {
                buildBinderSidebar();
                if (state.currentSetId === '__misprints__') {
                    renderMisprints();
                    document.querySelectorAll('.binder-set-item').forEach(function(i) {
                        i.classList.toggle('active', i.dataset.setId === '__misprints__');
                    });
                } else if (state.currentSetId) {
                    renderBinderSet(state.currentSetId);
                    document.querySelectorAll('.binder-set-item').forEach(function(i) {
                        i.classList.toggle('active', i.dataset.setId === state.currentSetId);
                    });
                }
            }, 100);
        }

        dragState.active = false; dragState.wrap = null; dragState.ghost = null;
    }

    card.addEventListener('mousedown', function(e) { e.preventDefault(); onDragStart(e.clientX, e.clientY); });
    document.addEventListener('mousemove', function(e) { onDragMove(e.clientX, e.clientY); });
    document.addEventListener('mouseup',   function(e) { onDragEnd(e.clientX, e.clientY); });
    card.addEventListener('touchstart', function(e) { var t = e.touches[0]; onDragStart(t.clientX, t.clientY); }, { passive: true });
    document.addEventListener('touchmove', function(e) { var t = e.touches[0]; onDragMove(t.clientX, t.clientY); }, { passive: true });
    document.addEventListener('touchend',  function(e) { var t = e.changedTouches[0]; onDragEnd(t.clientX, t.clientY); });
}

document.getElementById('btnBinderClose').addEventListener('click', function() { playSound('click', 0.5); closeUI(); });

// ══════════════════════════════════════════════════════
//  SHOP
// ══════════════════════════════════════════════════════
function openShop(data) {
    state.shopCards    = data.inventoryCards || [];
    state.shopSelected = {};
    state.shopMult     = data.sellMultiplier || 0.8;
    state.sets         = data.sets     || state.sets;
    state.rarities     = data.rarities || state.rarities;
    renderShop();
    showScreen('screen-shop');
}

function renderShop() {
    var mult = state.shopMult;
    var grid = document.getElementById('shopGrid');
    grid.innerHTML = '';
    updateShopTotal();

    if (state.shopCards.length === 0) {
        var empty = document.createElement('div');
        empty.className = 'shop-empty';
        empty.textContent = 'No cards in your inventory.';
        grid.appendChild(empty);
        return;
    }

    // Group by set, sorted alphabetically
    var setGroups = {};
    state.shopCards.forEach(function(c) {
        var key = c.setId || '__unknown__';
        if (!setGroups[key]) setGroups[key] = [];
        setGroups[key].push(c);
    });

    Object.keys(setGroups).sort(function(a, b) {
        var la = ((state.sets[a] && state.sets[a].label) || a).toLowerCase();
        var lb = ((state.sets[b] && state.sets[b].label) || b).toLowerCase();
        return la < lb ? -1 : la > lb ? 1 : 0;
    }).forEach(function(setId) {
        var cards   = setGroups[setId];
        var setData = state.sets[setId] || {};
        var setVal  = cards.reduce(function(s, c) {
            return s + (c.isDamaged ? 0 : Math.floor((c.value || 0) * mult));
        }, 0);

        // Section header
        var hdr = document.createElement('div');
        hdr.className = 'shop-set-header';

        var iconSpan = document.createElement('span');
        iconSpan.className = 'shop-set-icon';
        iconSpan.textContent = setData.icon || '';

        var nameSpan = document.createElement('span');
        nameSpan.className = 'shop-set-name';
        nameSpan.textContent = setData.label || setId;

        var valSpan = document.createElement('span');
        valSpan.className = 'shop-set-val';
        valSpan.textContent = '$' + setVal.toLocaleString();

        var sellSetBtn = document.createElement('button');
        sellSetBtn.className = 'shop-sell-set-btn';
        sellSetBtn.textContent = 'Sell Set';

        hdr.appendChild(iconSpan);
        hdr.appendChild(nameSpan);
        hdr.appendChild(valSpan);
        hdr.appendChild(sellSetBtn);
        grid.appendChild(hdr);

        // Sell-set confirmation inline
        (function(sid, sLabel, sVal, sCards) {
            sellSetBtn.addEventListener('click', function(e) {
                e.stopPropagation();
                playSound('click', 0.5);
                showShopConfirm(
                    'Sell all ' + sLabel + ' cards for $' + sVal.toLocaleString() + '?',
                    function() {
                        nuiFetch('sellSet', { setId: sid });
                        state.shopCards = state.shopCards.filter(function(c) { return c.setId !== sid; });
                        sCards.forEach(function(c) { delete state.shopSelected[c.cardid]; });
                        renderShop();
                    }
                );
            });
        })(setId, setData.label || setId, setVal, cards);

        // Individual card rows
        cards.forEach(function(cardInfo) {
            var sellVal = cardInfo.isDamaged ? 0 : Math.floor((cardInfo.value || 0) * mult);
            var isSelected = !!state.shopSelected[cardInfo.cardid];

            var row = document.createElement('div');
            row.className = 'shop-card-row' + (isSelected ? ' selected' : '');
            row.dataset.cardid = cardInfo.cardid;

            // Rarity colour dot
            var dot = document.createElement('span');
            dot.className = 'shop-rarity-dot';
            dot.dataset.rarity = cardInfo.rarity;

            var nameEl = document.createElement('span');
            nameEl.className = 'shop-card-name';
            nameEl.textContent = cardInfo.name || '';

            var rarityEl = document.createElement('span');
            rarityEl.className = 'shop-card-rarity';
            rarityEl.textContent = getRarity(cardInfo.rarity).label || cardInfo.rarity;

            var priceEl = document.createElement('span');
            priceEl.className = 'shop-card-price' + (cardInfo.isDamaged ? ' price-zero' : '');
            priceEl.textContent = '$' + sellVal.toLocaleString();

            var selBtn = document.createElement('button');
            selBtn.className = 'shop-select-btn';
            selBtn.textContent = isSelected ? '✓' : 'Select';
            if (cardInfo.isDamaged) {
                selBtn.disabled = true;
                selBtn.title    = 'Damaged — no value';
            }

            row.appendChild(dot);
            row.appendChild(nameEl);
            row.appendChild(rarityEl);
            row.appendChild(priceEl);
            row.appendChild(selBtn);
            grid.appendChild(row);

            // Toggle selection — click anywhere on row or the button
            (function(ci, r, sb) {
                function toggle(e) {
                    e.stopPropagation();
                    if (ci.isDamaged) return;
                    playSound('click', 0.5);
                    if (state.shopSelected[ci.cardid]) {
                        delete state.shopSelected[ci.cardid];
                        r.classList.remove('selected');
                        sb.textContent = 'Select';
                    } else {
                        state.shopSelected[ci.cardid] = true;
                        r.classList.add('selected');
                        sb.textContent = '✓';
                    }
                    updateShopTotal();
                }
                r.addEventListener('click', toggle);
            })(cardInfo, row, selBtn);
        });
    });
}

// Simple inline confirm modal (window.confirm doesn't work in NUI)
function showShopConfirm(message, onYes) {
    var existing = document.getElementById('shopConfirmModal');
    if (existing) existing.remove();

    var overlay = document.createElement('div');
    overlay.id = 'shopConfirmModal';
    overlay.style.cssText =
        'position:fixed;inset:0;z-index:9999;display:flex;align-items:center;justify-content:center;' +
        'background:rgba(0,0,0,0.6);';

    var box = document.createElement('div');
    box.style.cssText =
        'background:linear-gradient(160deg,#1a2035,#111827);border:1px solid rgba(255,255,255,0.12);' +
        'border-radius:12px;padding:28px 32px;max-width:340px;text-align:center;' +
        'box-shadow:0 20px 60px rgba(0,0,0,0.8);color:#f0f4ff;font-family:var(--font-ui);';

    var msg = document.createElement('div');
    msg.style.cssText = 'font-size:0.9rem;margin-bottom:22px;line-height:1.5;';
    msg.textContent = message;

    var btnRow = document.createElement('div');
    btnRow.style.cssText = 'display:flex;gap:10px;justify-content:center;';

    var cancelBtn = document.createElement('button');
    cancelBtn.style.cssText =
        'padding:8px 24px;border-radius:7px;border:1px solid rgba(255,255,255,0.15);' +
        'background:transparent;color:#7a8fb0;font-family:var(--font-ui);font-size:0.85rem;cursor:pointer;';
    cancelBtn.textContent = 'Cancel';
    cancelBtn.addEventListener('click', function() { playSound('click', 0.5); overlay.remove(); });

    var yesBtn = document.createElement('button');
    yesBtn.style.cssText =
        'padding:8px 28px;border-radius:7px;border:none;' +
        'background:linear-gradient(135deg,#f43f5e,#dc2626);color:#fff;' +
        'font-family:var(--font-ui);font-size:0.85rem;font-weight:700;cursor:pointer;' +
        'box-shadow:0 3px 14px rgba(244,63,94,0.4);';
    yesBtn.textContent = 'Sell';
    yesBtn.addEventListener('click', function() { playSound('click', 0.5); overlay.remove(); onYes(); });

    btnRow.appendChild(cancelBtn);
    btnRow.appendChild(yesBtn);
    box.appendChild(msg);
    box.appendChild(btnRow);
    overlay.appendChild(box);
    document.body.appendChild(overlay);

    overlay.addEventListener('click', function(e) { if (e.target === overlay) overlay.remove(); });
}

function updateShopTotal() {
    var mult  = state.shopMult;
    var total = 0;
    state.shopCards.forEach(function(c) {
        if (state.shopSelected[c.cardid]) {
            total += c.isDamaged ? 0 : Math.floor((c.value || 0) * mult);
        }
    });
    var el = document.getElementById('shopTotal');
    if (el) el.textContent = '$' + total.toLocaleString();
    var sellBtn = document.getElementById('btnShopSell');
    if (sellBtn) sellBtn.disabled = (Object.keys(state.shopSelected).length === 0);
}

document.getElementById('btnShopClose').addEventListener('click', function() { playSound('click', 0.5); closeUI(); });

document.getElementById('btnShopSell').addEventListener('click', function() {
    var ids = Object.keys(state.shopSelected);
    if (ids.length === 0) return;
    playSound('click', 0.5);
    var total = 0;
    state.shopCards.forEach(function(c) {
        if (state.shopSelected[c.cardid]) {
            total += c.isDamaged ? 0 : Math.floor((c.value || 0) * state.shopMult);
        }
    });
    showShopConfirm(
        'Sell ' + ids.length + ' card' + (ids.length === 1 ? '' : 's') + ' for $' + total.toLocaleString() + '?',
        function() {
            var cards = ids.map(function(id) { return { cardid: id }; });
            nuiFetch('sellCards', { cards: cards });
            state.shopCards    = state.shopCards.filter(function(c) { return !state.shopSelected[c.cardid]; });
            state.shopSelected = {};
            renderShop();
        }
    );
});

document.getElementById('btnShopSelectAll').addEventListener('click', function() {
    playSound('click', 0.5);
    state.shopCards.forEach(function(c) {
        if (!c.isDamaged) state.shopSelected[c.cardid] = true;
    });
    // Update all rows visually without full re-render
    document.querySelectorAll('.shop-card-row').forEach(function(row) {
        var id = row.dataset.cardid;
        if (state.shopSelected[id]) {
            row.classList.add('selected');
            var sb = row.querySelector('.shop-select-btn');
            if (sb) sb.textContent = '✓';
        }
    });
    updateShopTotal();
});

// ══════════════════════════════════════════════════════
//  NUI MESSAGE HANDLER
// ══════════════════════════════════════════════════════
window.addEventListener('message', function(event) {
    var data = event.data;
    if (!data || !data.type) return;
    if (data.rarities) state.rarities = data.rarities;

    switch (data.type) {

        case 'showPackReveal':
            if (data.sets) state.sets = data.sets;
            if (data.packLabel) {
                showPackOpen(data.packLabel, data.cards || []);
            } else {
                showPackReveal(data.cards || []);
            }
            break;

        case 'viewCard':
            viewCard(data.card || {});
            break;

        case 'openBinder':
            openBinder({
                binderId:       data.binderId       || null,
                sets:           data.sets           || {},
                rarities:       data.rarities       || {},
                storedCards:    data.storedCards     || [],
                inventoryCards: data.inventoryCards  || [],
            });
            break;

        case 'openShop':
            openShop({
                inventoryCards: data.inventoryCards || [],
                sets:           data.sets           || {},
                rarities:       data.rarities       || {},
                sellMultiplier: data.sellMultiplier  || 0.8,
            });
            break;

        case 'cardStoredInBinder':
            if (data.cardInfo) {
                var ci = data.cardInfo;
                state.inventoryCards = state.inventoryCards.filter(function(c) { return c.cardid !== ci.cardid; });
                if (!state.storedCards.some(function(c) { return c.cardid === ci.cardid; })) state.storedCards.push(ci);
                buildBinderSidebar();
                var ciIsMp = !!(ci.isMisprint || ci.rarity === 'misprint');
                if (state.currentSetId === '__misprints__') renderMisprints();
                else if (ciIsMp) { /* stored a misprint while viewing a set — stay on set, sidebar count updated */ renderMisprints(); /* switch view */ state.currentSetId = '__misprints__'; document.querySelectorAll('.binder-set-item').forEach(function(i){ i.classList.toggle('active', i.dataset.setId === '__misprints__'); }); }
                else if (state.currentSetId) renderBinderSet(state.currentSetId);
            }
            break;

        case 'cardRemovedFromBinder':
            if (data.cardInfo) {
                var ri = data.cardInfo;
                state.storedCards    = state.storedCards.filter(function(c) { return c.cardid !== ri.cardid; });
                if (!state.inventoryCards.some(function(c) { return c.cardid === ri.cardid; })) state.inventoryCards.push(ri);
                buildBinderSidebar();
                if (state.currentSetId === '__misprints__') renderMisprints();
                else if (state.currentSetId) renderBinderSet(state.currentSetId);
            }
            break;

        case 'cardDiscarded':
            if (data.cardId) {
                state.inventoryCards = state.inventoryCards.filter(function(c) { return c.cardid !== data.cardId; });
            }
            break;

        case 'sellComplete':
            // Cards already removed optimistically; sidebar refresh if binder was open
            if (state.currentSetId) buildBinderSidebar();
            break;

        case 'closeUI':
            hideAll();
            break;
    }
});