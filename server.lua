local QBCore = exports['qb-core']:GetCoreObject()

local function DebugPrint(msg)
    if Config.Debug then print('[mnc-tradingcards] ' .. msg) end
end

-- Flatten _ref nested fields back to top level for NUI / client events
local function FlattenCardInfo(info)
    if not info then return nil end
    local ref = info._ref or {}
    return {
        cardid     = ref.cardid     or info.cardid,
        setId      = ref.setId      or info.setId,
        setLabel   = ref.setLabel   or info.setLabel,
        number     = info.number,
        name       = info.name,
        model      = ref.model      or info.model      or '',
        image      = ref.image      or info.image      or '',
        background = ref.background or info.background or '',
        rarity     = info.rarity,
        isMisprint = info.isMisprint or false,
        isDamaged  = info.isDamaged  or false,
        printNum   = info.printNum   or '',
        value      = info.value      or 0,
    }
end

-- ============================================================
--  AUTO-CREATE TABLES
-- ============================================================
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `mnc_trading_cards` (
            `id`              varchar(64)  NOT NULL,
            `owner_citizenid` varchar(50)  NOT NULL,
            `set_id`          varchar(50)  NOT NULL,
            `card_number`     int          NOT NULL,
            `rarity`          varchar(20)  NOT NULL,
            `is_misprint`     tinyint(1)   NOT NULL DEFAULT 0,
            `is_damaged`      tinyint(1)   NOT NULL DEFAULT 0,
            `print_num`       varchar(30)  NOT NULL DEFAULT '',
            `card_value`      int          NOT NULL DEFAULT 0,
            `acquired_at`     timestamp    DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            INDEX `idx_owner` (`owner_citizenid`),
            INDEX `idx_set`   (`set_id`)
        )
    ]], {}, function()
        -- Add new columns to existing installs
        MySQL.query('ALTER TABLE mnc_trading_cards ADD COLUMN IF NOT EXISTS `is_misprint` tinyint(1) NOT NULL DEFAULT 0', {})
        MySQL.query('ALTER TABLE mnc_trading_cards ADD COLUMN IF NOT EXISTS `is_damaged`  tinyint(1) NOT NULL DEFAULT 0', {})
        MySQL.query('ALTER TABLE mnc_trading_cards ADD COLUMN IF NOT EXISTS `print_num`   varchar(30) NOT NULL DEFAULT \'\'', {})
        MySQL.query('ALTER TABLE mnc_trading_cards ADD COLUMN IF NOT EXISTS `card_value`  int NOT NULL DEFAULT 0', {})
        print('^2[mnc-tradingcards]^7 Table `mnc_trading_cards` ready.')
    end)

    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `mnc_binders` (
            `id`              varchar(64) NOT NULL,
            `owner_citizenid` varchar(50) NOT NULL,
            PRIMARY KEY (`id`),
            INDEX `idx_owner` (`owner_citizenid`)
        )
    ]], {}, function()
        print('^2[mnc-tradingcards]^7 Table `mnc_binders` ready.')
    end)

    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `mnc_binder_cards` (
            `card_id`         varchar(64)  NOT NULL,
            `binder_id`       varchar(64)  NOT NULL,
            `owner_citizenid` varchar(50)  NOT NULL,
            `set_id`          varchar(50)  NOT NULL,
            `card_number`     int          NOT NULL,
            `rarity`          varchar(20)  NOT NULL,
            `name`            varchar(100) NOT NULL DEFAULT '',
            `model`           varchar(100) NOT NULL DEFAULT '',
            `image`           varchar(255) NOT NULL DEFAULT '',
            `background`      varchar(255) NOT NULL DEFAULT '',
            `set_label`       varchar(100) NOT NULL DEFAULT '',
            `is_misprint`     tinyint(1)   NOT NULL DEFAULT 0,
            `is_damaged`      tinyint(1)   NOT NULL DEFAULT 0,
            `print_num`       varchar(30)  NOT NULL DEFAULT '',
            `card_value`      int          NOT NULL DEFAULT 0,
            `stored_at`       timestamp    DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`card_id`),
            INDEX `idx_binder`  (`binder_id`),
            INDEX `idx_owner`   (`owner_citizenid`)
        )
    ]], {}, function()
        MySQL.query('ALTER TABLE mnc_binder_cards ADD COLUMN IF NOT EXISTS `image`      varchar(255) NOT NULL DEFAULT \'\'', {})
        MySQL.query('ALTER TABLE mnc_binder_cards ADD COLUMN IF NOT EXISTS `background` varchar(255) NOT NULL DEFAULT \'\'', {})
        MySQL.query('ALTER TABLE mnc_binder_cards ADD COLUMN IF NOT EXISTS `is_misprint` tinyint(1) NOT NULL DEFAULT 0', {})
        MySQL.query('ALTER TABLE mnc_binder_cards ADD COLUMN IF NOT EXISTS `is_damaged`  tinyint(1) NOT NULL DEFAULT 0', {})
        MySQL.query('ALTER TABLE mnc_binder_cards ADD COLUMN IF NOT EXISTS `print_num`   varchar(30) NOT NULL DEFAULT \'\'', {})
        MySQL.query('ALTER TABLE mnc_binder_cards ADD COLUMN IF NOT EXISTS `card_value`  int NOT NULL DEFAULT 0', {})
        print('^2[mnc-tradingcards]^7 Table `mnc_binder_cards` ready.')
    end)
end)

-- ============================================================
--  UTILITY: weighted random rarity
-- ============================================================
local function RollRarity(weights)
    local total = 0
    for _, w in pairs(weights) do total = total + w end
    local roll = math.random(1, total)
    local cumulative = 0
    local order = { 'common', 'uncommon', 'rare', 'ultraRare' }
    for _, rarity in ipairs(order) do
        cumulative = cumulative + (weights[rarity] or 0)
        if roll <= cumulative then return rarity end
    end
    return 'common'
end

-- ============================================================
--  UTILITY: pick a random card of a given rarity from all sets
-- ============================================================
local function PickRandomCard(rarity)
    local pool = {}
    for setId, setData in pairs(Config.Sets) do
        for _, card in ipairs(setData.cards) do
            if card.rarity == rarity then
                table.insert(pool, {
                    setId      = setId,
                    setLabel   = setData.label,
                    number     = card.number,
                    name       = card.name,
                    model      = card.model      or '',
                    image      = card.image      or '',
                    background = card.background or (setData.background or ''),
                    rarity     = card.rarity,
                    printNum   = card.printNum   or '',
                    -- per-card value override, else fall back to rarity default
                    value      = card.value or (Config.Rarities[card.rarity] and Config.Rarities[card.rarity].value) or 0,
                })
            end
        end
    end
    if #pool == 0 then return PickRandomCard('common') end
    return pool[math.random(1, #pool)]
end

-- ============================================================
--  UTILITY: generate a unique ID
-- ============================================================
local function GenerateId(prefix)
    return prefix .. '_' .. math.random(1000000, 9999999) .. '_' .. (GetGameTimer() % 100000)
end

-- ============================================================
--  UTILITY: per-card global print counter (setId_cardNumber → count)
--  Loaded from DB on start, incremented each time a card is created.
--  Misprints share the same counter as their base card so their
--  rarity is obvious from the low print number, but are labelled
--  separately so they never occupy a normal set slot.
-- ============================================================
local _printCounters = {}   -- key: "setId_cardNumber"

local function _pcKey(setId, cardNumber)
    return tostring(setId) .. '_' .. tostring(cardNumber)
end

-- Initialise counters from existing DB rows so counts survive restarts
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    -- Small delay to let the CREATE TABLE queries finish first
    SetTimeout(2000, function()
        MySQL.query('SELECT set_id, card_number, COUNT(*) AS cnt FROM mnc_trading_cards GROUP BY set_id, card_number', {}, function(rows)
            if not rows then return end
            for _, row in ipairs(rows) do
                local key = _pcKey(row.set_id, row.card_number)
                _printCounters[key] = (row.cnt or 0)
            end
            -- Also count cards currently stored in binders
            MySQL.query('SELECT set_id, card_number, COUNT(*) AS cnt FROM mnc_binder_cards GROUP BY set_id, card_number', {}, function(brows)
                if not brows then return end
                for _, row in ipairs(brows) do
                    local key = _pcKey(row.set_id, row.card_number)
                    _printCounters[key] = (_printCounters[key] or 0) + (row.cnt or 0)
                end
                DebugPrint('Print counters loaded (' .. #rows .. ' inventory + ' .. #brows .. ' binder entries)')
            end)
        end)
    end)
end)

local function NextPrintNum(setId, cardNumber, setLabel)
    local key = _pcKey(setId, cardNumber)
    _printCounters[key] = (_printCounters[key] or 0) + 1
    local n = _printCounters[key]
    -- Format: #00042 [Set Name]  — set name appended so no two sets share the same print string
    local numStr = tostring(n)
    while #numStr < 5 do numStr = '0' .. numStr end
    local label = setLabel and ('[' .. setLabel .. ']') or ('[' .. tostring(setId) .. ']')
    return '#' .. numStr .. ' ' .. label
end

-- ============================================================
--  UTILITY: resolve card value (misprint / damaged overrides)
-- ============================================================
local function ResolveCardValue(baseValue, isMisprint, isDamaged)
    if isDamaged  then return 0 end
    if isMisprint then return Config.Rarities.misprint and Config.Rarities.misprint.value or baseValue * 2 end
    return baseValue
end

-- ============================================================
--  OPEN PACK
-- ============================================================
RegisterNetEvent('mnc-tradingcards:server:openPack', function(itemName, itemSlot)
    local src    = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local packConfig = Config.Packs[itemName]
    if not packConfig then
        DebugPrint('Unknown pack item: ' .. tostring(itemName))
        return
    end

    local removed = Player.Functions.RemoveItem(itemName, 1, itemSlot)
    if not removed then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Trading Cards', description = "Couldn't open pack.", type = 'error' })
        return
    end

    local droppedCards = {}
    local citizenid    = Player.PlayerData.citizenid

    for i = 1, packConfig.cardCount do
        local rarity     = RollRarity(packConfig.weights)
        local cardData   = PickRandomCard(rarity)
        local cardId     = GenerateId('card')

        -- Roll for misprint / damaged
        local mRoll = math.random(1, 100)
        local dRoll = math.random(1, 100)
        local isMisprint = (mRoll <= (packConfig.misprintChance or 0))
        local isDamaged  = (not isMisprint) and (dRoll <= (packConfig.damagedChance or 0))

        -- Effective rarity for display purposes
        local displayRarity = rarity
        if isMisprint then displayRarity = 'misprint' end
        if isDamaged  then displayRarity = 'damaged'  end

        local cardValue = ResolveCardValue(cardData.value, isMisprint, isDamaged)

        -- Sequential print number: every card ever created for this set+number gets the next count.
        -- This makes early prints rare and gives each physical card a unique identity.
        -- Set name is appended so print numbers are globally unique across all sets.
        local printLabel = NextPrintNum(cardData.setId, cardData.number, cardData.setLabel)
        if isMisprint then
            printLabel = printLabel .. ' MISPRINT'
        end
        if isDamaged then
            printLabel = printLabel .. ' (DMG)'
        end

        MySQL.insert(
            'INSERT INTO mnc_trading_cards (id, owner_citizenid, set_id, card_number, rarity, is_misprint, is_damaged, print_num, card_value) VALUES (?,?,?,?,?,?,?,?,?)',
            { cardId, citizenid, cardData.setId, cardData.number, displayRarity,
              isMisprint and 1 or 0, isDamaged and 1 or 0, printLabel, cardValue }
        )

        local cardInfo = {
            id          = cardId,
            cardid      = cardId,
            setId       = cardData.setId,
            setLabel    = cardData.setLabel,
            number      = cardData.number,
            name        = cardData.name,
            model       = cardData.model,
            image       = cardData.image,
            background  = cardData.background,
            rarity      = displayRarity,
            baseRarity  = rarity,
            isMisprint  = isMisprint,
            isDamaged   = isDamaged,
            printNum    = printLabel,
            value       = cardValue,
        }

        Player.Functions.AddItem('trading_card', 1, false, {
            -- visible in QB-Core inventory tooltip
            number     = cardInfo.number,
            name       = cardInfo.name,
            rarity     = displayRarity,
            isMisprint = isMisprint,
            isDamaged  = isDamaged,
            printNum   = printLabel,
            value      = cardValue,
            -- nested so QB-Core tooltip does not display these raw fields
            _ref = {
                cardid     = cardId,
                setId      = cardInfo.setId,
                setLabel   = cardInfo.setLabel,
                model      = cardInfo.model,
                image      = cardInfo.image,
                background = cardInfo.background,
            },
        })

        table.insert(droppedCards, cardInfo)

        DebugPrint('Player ' .. src .. ' received card: ' .. cardData.setId .. ' #' .. cardData.number ..
            ' (' .. displayRarity .. ') print=' .. printLabel .. (isMisprint and ' [MISPRINT]' or '') .. (isDamaged and ' [DAMAGED]' or ''))
    end

    TriggerClientEvent('mnc-tradingcards:client:packOpened', src, droppedCards, packConfig.label)
end)

-- ============================================================
--  USE CARD (view single card)
-- ============================================================
RegisterNetEvent('mnc-tradingcards:server:useCard', function(itemSlot)
    local src    = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local items    = Player.PlayerData.items
    local cardItem = nil

    for slot, item in pairs(items) do
        if item and item.name == 'trading_card' and tostring(slot) == tostring(itemSlot) then
            cardItem = item; break
        end
    end
    if not cardItem then
        for slot, item in pairs(items) do
            if item and item.name == 'trading_card' then cardItem = item; break end
        end
    end

    if not cardItem or not cardItem.info then return end
    TriggerClientEvent('mnc-tradingcards:client:viewCard', src, FlattenCardInfo(cardItem.info))
end)

-- ============================================================
--  DISCARD DAMAGED CARD
-- ============================================================
RegisterNetEvent('mnc-tradingcards:server:discardDamaged', function(cardId)
    local src    = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local items = Player.PlayerData.items
    local foundSlot = nil
    for slot, item in pairs(items) do
        if item and item.name == 'trading_card' and item.info then
            local ref = item.info._ref or item.info
            if ref.cardid == cardId then
                if item.info.isDamaged then
                    foundSlot = slot; break
                end
            end
        end
    end

    if not foundSlot then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Trading Cards', description = 'Card not found or not damaged.', type = 'error' })
        return
    end

    Player.Functions.RemoveItem('trading_card', 1, foundSlot)
    MySQL.query('DELETE FROM mnc_trading_cards WHERE id = ? AND owner_citizenid = ?', { cardId, Player.PlayerData.citizenid })

    TriggerClientEvent('ox_lib:notify', src, { title = 'Trading Cards', description = 'Damaged card discarded.', type = 'info' })
    TriggerClientEvent('mnc-tradingcards:client:cardDiscarded', src, cardId)
    DebugPrint('Player ' .. src .. ' discarded damaged card ' .. cardId)
end)

-- ============================================================
--  USE BINDER — loads binder data from SQL and sends to client
-- ============================================================
RegisterNetEvent('mnc-tradingcards:server:useBinder', function(itemSlot)
    local src    = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local items      = Player.PlayerData.items
    local binderItem = nil
    local binderSlot = itemSlot

    for slot, item in pairs(items) do
        if item and item.name == 'card_binder' then
            if tostring(slot) == tostring(itemSlot) or not binderItem then
                binderItem = item; binderSlot = slot
            end
        end
    end
    if not binderItem then return end

    local citizenid = Player.PlayerData.citizenid
    local binderId  = binderItem.info and binderItem.info.binderid

    if not binderId then
        binderId = GenerateId('binder')
        local info = binderItem.info or {}
        info.binderid = binderId
        MySQL.insert('INSERT INTO mnc_binders (id, owner_citizenid) VALUES (?, ?)', { binderId, citizenid })
        Player.Functions.RemoveItem('card_binder', 1, binderSlot)
        Player.Functions.AddItem('card_binder', 1, binderSlot, info)
        DebugPrint('Created new binder ID: ' .. binderId)
    end

    MySQL.query(
        'SELECT * FROM mnc_binder_cards WHERE binder_id = ? AND owner_citizenid = ?',
        { binderId, citizenid },
        function(binderCards)
            binderCards = binderCards or {}

            local inventoryCards = {}
            for slot, item in pairs(Player.PlayerData.items) do
                if item and item.name == 'trading_card' and item.info and (item.info.cardid or (item.info._ref and item.info._ref.cardid)) then
                    local ref = item.info._ref or item.info
                    table.insert(inventoryCards, {
                        slot        = slot,
                        cardid      = ref.cardid,
                        setId       = ref.setId,
                        setLabel    = ref.setLabel,
                        number      = item.info.number,
                        name        = item.info.name,
                        model       = ref.model      or '',
                        image       = ref.image      or '',
                        background  = ref.background or '',
                        rarity      = item.info.rarity,
                        isMisprint  = item.info.isMisprint  or false,
                        isDamaged   = item.info.isDamaged   or false,
                        printNum    = item.info.printNum    or '',
                        value       = item.info.value       or 0,
                    })
                end
            end

            local storedCards = {}
            for _, row in ipairs(binderCards) do
                table.insert(storedCards, {
                    cardid      = row.card_id,
                    setId       = row.set_id,
                    setLabel    = row.set_label,
                    number      = row.card_number,
                    name        = row.name,
                    model       = row.model       or '',
                    image       = row.image       or '',
                    background  = row.background  or '',
                    rarity      = row.rarity,
                    isMisprint  = row.is_misprint == 1,
                    isDamaged   = row.is_damaged  == 1,
                    printNum    = row.print_num   or '',
                    value       = row.card_value  or 0,
                })
            end

            TriggerClientEvent('mnc-tradingcards:client:openBinder', src, {
                binderId       = binderId,
                sets           = Config.Sets,
                rarities       = Config.Rarities,
                storedCards    = storedCards,
                inventoryCards = inventoryCards,
            })
        end
    )
end)

-- ============================================================
--  STORE CARD INTO BINDER
-- ============================================================
RegisterNetEvent('mnc-tradingcards:server:storeCardInBinder', function(binderId, cardSlot, cardId)
    local src    = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    if not binderId or not cardId then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Trading Cards', description = 'Invalid binder or card data.', type = 'error' })
        return
    end

    local citizenid = Player.PlayerData.citizenid

    MySQL.query('SELECT id FROM mnc_binders WHERE id = ? AND owner_citizenid = ?', { binderId, citizenid }, function(rows)
        if not rows or #rows == 0 then
            TriggerClientEvent('ox_lib:notify', src, { title = 'Trading Cards', description = 'Binder not found.', type = 'error' })
            return
        end

        local items     = Player.PlayerData.items
        local cardItem  = nil
        local foundSlot = nil

        for slot, item in pairs(items) do
            if item and item.name == 'trading_card' and item.info then
                local ref = item.info._ref or item.info
                if ref.cardid == cardId then
                    if tostring(slot) == tostring(cardSlot) then cardItem = item; foundSlot = slot; break end
                end
            end
        end
        if not cardItem then
            for slot, item in pairs(items) do
                if item and item.name == 'trading_card' and item.info then
                    local ref = item.info._ref or item.info
                    if ref.cardid == cardId then
                        cardItem = item; foundSlot = slot; break
                    end
                end
            end
        end

        if not cardItem or not cardItem.info then
            TriggerClientEvent('ox_lib:notify', src, { title = 'Trading Cards', description = 'Card not found in inventory.', type = 'error' })
            return
        end

        local info = cardItem.info
        local ref  = info._ref or info

        -- Block damaged cards from being stored in a binder
        if info.isDamaged then
            TriggerClientEvent('ox_lib:notify', src, { title = 'Trading Cards', description = 'Damaged cards cannot be stored in a binder.', type = 'error' })
            return
        end

        MySQL.query('SELECT card_id FROM mnc_binder_cards WHERE card_id = ?', { cardId }, function(existing)
            if existing and #existing > 0 then
                TriggerClientEvent('ox_lib:notify', src, { title = 'Trading Cards', description = 'Card is already stored in a binder.', type = 'error' })
                return
            end

            local removed = Player.Functions.RemoveItem('trading_card', 1, foundSlot)
            if not removed then
                TriggerClientEvent('ox_lib:notify', src, { title = 'Trading Cards', description = "Couldn't remove card from inventory.", type = 'error' })
                return
            end

            MySQL.insert(
                'INSERT INTO mnc_binder_cards (card_id, binder_id, owner_citizenid, set_id, card_number, rarity, name, model, image, background, set_label, is_misprint, is_damaged, print_num, card_value) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)',
                {
                    cardId, binderId, citizenid,
                    ref.setId      or '',
                    info.number    or 0,
                    info.rarity    or 'common',
                    info.name      or '',
                    ref.model      or '',
                    ref.image      or '',
                    ref.background or '',
                    ref.setLabel   or '',
                    info.isMisprint and 1 or 0,
                    info.isDamaged  and 1 or 0,
                    info.printNum  or '',
                    info.value     or 0,
                },
                function(insertId)
                    if not insertId then
                        Player.Functions.AddItem('trading_card', 1, false, info)
                        TriggerClientEvent('ox_lib:notify', src, { title = 'Trading Cards', description = 'Database error — card returned to inventory.', type = 'error' })
                        return
                    end

                    DebugPrint('Card ' .. cardId .. ' stored in binder ' .. binderId)

                    TriggerClientEvent('mnc-tradingcards:client:cardStoredInBinder', src, {
                        cardid      = ref.cardid,
                        setId       = ref.setId,
                        setLabel    = ref.setLabel,
                        number      = info.number,
                        name        = info.name,
                        model       = ref.model      or '',
                        image       = ref.image      or '',
                        background  = ref.background or '',
                        rarity      = info.rarity,
                        isMisprint  = info.isMisprint or false,
                        isDamaged   = info.isDamaged  or false,
                        printNum    = info.printNum   or '',
                        value       = info.value      or 0,
                    })

                    TriggerClientEvent('ox_lib:notify', src, { title = 'Trading Cards', description = (info.name or 'Card') .. ' stored in binder!', type = 'success' })
                end
            )
        end)
    end)
end)

-- ============================================================
--  REMOVE CARD FROM BINDER
-- ============================================================
RegisterNetEvent('mnc-tradingcards:server:removeCardFromBinder', function(binderId, cardId)
    local src    = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    if not binderId or not cardId then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Trading Cards', description = 'Invalid data.', type = 'error' })
        return
    end

    local citizenid = Player.PlayerData.citizenid

    MySQL.query(
        'SELECT * FROM mnc_binder_cards WHERE card_id = ? AND binder_id = ? AND owner_citizenid = ?',
        { cardId, binderId, citizenid },
        function(rows)
            if not rows or #rows == 0 then
                TriggerClientEvent('ox_lib:notify', src, { title = 'Trading Cards', description = 'Card not found in binder.', type = 'error' })
                return
            end

            local row = rows[1]

            MySQL.query('DELETE FROM mnc_binder_cards WHERE card_id = ? AND owner_citizenid = ?', { cardId, citizenid }, function(affected)
                if not affected or affected == 0 then
                    TriggerClientEvent('ox_lib:notify', src, { title = 'Trading Cards', description = 'Could not remove card.', type = 'error' })
                    return
                end

                local info = {
                    -- visible tooltip fields
                    number     = row.card_number,
                    name       = row.name,
                    rarity     = row.rarity,
                    isMisprint = row.is_misprint == 1,
                    isDamaged  = row.is_damaged  == 1,
                    printNum   = row.print_num   or '',
                    value      = row.card_value  or 0,
                    -- nested hidden fields
                    _ref = {
                        cardid     = cardId,
                        setId      = row.set_id,
                        setLabel   = row.set_label,
                        model      = row.model      or '',
                        image      = row.image      or '',
                        background = row.background or '',
                    },
                }

                -- flat copy for client event (NUI expects flat structure)
                local clientInfo = {
                    cardid     = cardId,
                    setId      = row.set_id,
                    setLabel   = row.set_label,
                    number     = row.card_number,
                    name       = row.name,
                    model      = row.model      or '',
                    image      = row.image      or '',
                    background = row.background or '',
                    rarity     = row.rarity,
                    isMisprint = row.is_misprint == 1,
                    isDamaged  = row.is_damaged  == 1,
                    printNum   = row.print_num   or '',
                    value      = row.card_value  or 0,
                }

                Player.Functions.AddItem('trading_card', 1, false, info)
                DebugPrint('Card ' .. cardId .. ' removed from binder and returned to inventory')

                TriggerClientEvent('mnc-tradingcards:client:cardRemovedFromBinder', src, clientInfo)
                TriggerClientEvent('ox_lib:notify', src, { title = 'Trading Cards', description = (row.name or 'Card') .. ' returned to inventory.', type = 'info' })
            end)
        end
    )
end)

-- ============================================================
--  SHOP — SELL CARDS
--  Accepts a list of { cardid, slot } from the client
-- ============================================================
RegisterNetEvent('mnc-tradingcards:server:sellCards', function(cardList)
    local src    = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    if not cardList or #cardList == 0 then return end

    local citizenid = Player.PlayerData.citizenid
    local multiplier = Config.Shop.sellMultiplier or 0.8
    local totalPay  = 0
    local sold      = 0

    for _, entry in ipairs(cardList) do
        local cardId = entry.cardid
        local items  = Player.PlayerData.items
        local foundSlot = nil
        local cardInfo  = nil

        for slot, item in pairs(items) do
            if item and item.name == 'trading_card' and item.info then
                local ref = item.info._ref or item.info
                if ref.cardid == cardId then
                    foundSlot = slot; cardInfo = item.info; break
                end
            end
        end

        if foundSlot and cardInfo then
            local baseVal = cardInfo.value or 0
            local pay = math.floor(baseVal * multiplier)
            Player.Functions.RemoveItem('trading_card', 1, foundSlot)
            MySQL.query('DELETE FROM mnc_trading_cards WHERE id = ? AND owner_citizenid = ?', { cardId, citizenid })
            totalPay = totalPay + pay
            sold = sold + 1
        end
    end

    if totalPay > 0 then
        Player.Functions.AddMoney('cash', totalPay, 'card-shop-sell')
    end

    TriggerClientEvent('ox_lib:notify', src, {
        title       = 'Card Dealer',
        description = 'Sold ' .. sold .. ' card(s) for $' .. totalPay,
        type        = 'success',
    })
    TriggerClientEvent('mnc-tradingcards:client:sellComplete', src, { sold = sold, total = totalPay })
    DebugPrint('Player ' .. src .. ' sold ' .. sold .. ' cards for $' .. totalPay)
end)

-- ============================================================
--  SHOP — SELL COMPLETE SET (all cards of a setId in inventory)
-- ============================================================
RegisterNetEvent('mnc-tradingcards:server:sellSet', function(setId)
    local src    = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local setData = Config.Sets[setId]
    if not setData then return end

    local citizenid  = Player.PlayerData.citizenid
    local multiplier = Config.Shop.sellMultiplier or 0.8
    local bonus      = Config.Shop.setCompletionBonus or 1.0
    local items      = Player.PlayerData.items

    local toSell = {}
    local valueSum = 0

    for slot, item in pairs(items) do
        if item and item.name == 'trading_card' and item.info then
            local ref = item.info._ref or item.info
            if ref.setId == setId then
                table.insert(toSell, { slot = slot, info = item.info })
                valueSum = valueSum + (item.info.value or 0)
            end
        end
    end

    if #toSell == 0 then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Card Dealer', description = 'No cards from that set in your inventory.', type = 'error' })
        return
    end

    -- Check if selling a complete set for the bonus
    local ownedNums = {}
    for _, entry in ipairs(toSell) do ownedNums[entry.info.number] = true end
    local isComplete = (#setData.cards == #toSell)  -- rough check; all cards present
    local mult = multiplier * (isComplete and bonus or 1.0)
    local totalPay = math.floor(valueSum * mult)

    for _, entry in ipairs(toSell) do
        Player.Functions.RemoveItem('trading_card', 1, entry.slot)
        local ref = entry.info._ref or entry.info
        MySQL.query('DELETE FROM mnc_trading_cards WHERE id = ? AND owner_citizenid = ?', { ref.cardid, citizenid })
    end

    if totalPay > 0 then
        Player.Functions.AddMoney('cash', totalPay, 'card-shop-sell-set')
    end

    local msg = 'Sold ' .. #toSell .. ' ' .. setData.label .. ' card(s) for $' .. totalPay
    if isComplete then msg = msg .. ' (Complete set bonus!)' end

    TriggerClientEvent('ox_lib:notify', src, { title = 'Card Dealer', description = msg, type = 'success' })
    TriggerClientEvent('mnc-tradingcards:client:sellComplete', src, { sold = #toSell, total = totalPay })
    DebugPrint('Player ' .. src .. ' sold set ' .. setId .. ' for $' .. totalPay)
end)

-- ============================================================
--  USEABLE ITEMS
-- ============================================================
for packName, _ in pairs(Config.Packs) do
    QBCore.Functions.CreateUseableItem(packName, function(source, item)
        local src    = source
        local Player = QBCore.Functions.GetPlayer(src)
        if not Player then return end
        TriggerClientEvent('mnc-tradingcards:client:startOpenPack', src, item.name, item.slot)
    end)
end

QBCore.Functions.CreateUseableItem('trading_card', function(source, item)
    local src = source
    TriggerClientEvent('mnc-tradingcards:client:startViewCard', src, item.slot, FlattenCardInfo(item.info))
end)

QBCore.Functions.CreateUseableItem('card_binder', function(source, item)
    local src = source
    TriggerClientEvent('mnc-tradingcards:client:startBinder', src, item.slot)
end)

-- ============================================================
--  SHOP — send player's inventory cards to client for shop UI
-- ============================================================
RegisterNetEvent('mnc-tradingcards:server:requestShopOpen', function()
    local src    = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local inventoryCards = {}
    for slot, item in pairs(Player.PlayerData.items) do
        if item and item.name == 'trading_card' and item.info and (item.info._ref or item.info.cardid) then
            local ref = item.info._ref or item.info
            table.insert(inventoryCards, {
                slot       = slot,
                cardid     = ref.cardid,
                setId      = ref.setId,
                setLabel   = ref.setLabel,
                number     = item.info.number,
                name       = item.info.name,
                model      = ref.model      or '',
                image      = ref.image      or '',
                background = ref.background or '',
                rarity     = item.info.rarity,
                isMisprint = item.info.isMisprint  or false,
                isDamaged  = item.info.isDamaged   or false,
                printNum   = item.info.printNum    or '',
                value      = item.info.value       or 0,
            })
        end
    end

    TriggerClientEvent('mnc-tradingcards:client:openShop', src, inventoryCards)
end)

-- ============================================================
--  ADMIN CARD PREVIEW  (/cardpreview)
-- ============================================================

RegisterNetEvent('mnc-tradingcards:server:requestCardPreview', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    -- Admin / god permission check
    if not QBCore.Functions.HasPermission(src, 'admin')
    and not QBCore.Functions.HasPermission(src, 'god') then
        TriggerClientEvent('ox_lib:notify', src, {
            description = 'You do not have permission to use /cardpreview.',
            type        = 'error',
        })
        return
    end

    -- Fire the preview event back to the requesting client only
    TriggerClientEvent('mnc-tradingcards:client:openCardPreview', src)
end)

print("^2[mnc-tradingcards]^7 Script loaded successfully!")
