# 🃏 MNC Trading Cards System

[![FiveM](https://img.shields.io/badge/FiveM-Ready-green.svg)](https://fivem.net/)
[![QBCore](https://img.shields.io/badge/Framework-QBCore-blue.svg)](https://github.com/qbcore-framework)
[![Version](https://img.shields.io/badge/Version-1.1.0-brightgreen.svg)]()

---

## 🌟 Overview

A **fully-featured collectible trading card system** for QBCore-based FiveM servers. Players can open randomised card packs, collect cards across themed sets, store them in binders, and sell them to the in-world card dealer. Complete with a polished NUI, holographic rarity effects, misprint mechanics, a persistent database, and a set-completion bonus system.

---

## ✨ Key Features

### 📦 Pack Opening System
- **Three pack tiers** — Basic, Premium, and Legendary — each with configurable card counts and rarity weights
- **Interactive tear animation** with a drag-to-open mechanic and progress indicator
- **Sequential card reveal** — click each card individually to flip and reveal it
- **Misprint cards** — rare alternate variants with their own rarity tier and higher value
- **Damaged cards** — low-value cards that can be discarded for a small payout

### 🎴 Card Collection & Rarity
- **Six rarity tiers**: Common, Uncommon, Rare, Ultra Rare, Misprint, and Damaged, each with a unique colour and value
- **Holographic sheen** on Rare, Ultra Rare, and Misprint cards
- **Per-card print numbering** — a global counter tracks how many of each card have ever been created, so low print numbers carry real prestige
- **Custom image support** — cards can use GTA V vehicle CDN images or your own custom artwork
- **Custom backgrounds** per card or per set for full visual flexibility

### 📚 Card Binder
- **Physical binder UI** with a spine, rings, and a set contents panel
- **Drag cards in and out** of binder slots directly from the inventory
- **Set progress tracking** — shows how many cards of each set you've collected
- **Drag-to-remove zone** at the top of the binder page to return cards to your inventory
- **Persistent storage** — binder contents survive restarts via the database

### 🏪 Card Dealer Shop (NPC)
- **Ambient dealer NPC** spawned at a configurable world location with a map blip
- **E-key interaction prompt** when the player is within range
- **Sell individual cards** — select any combination from your inventory and see a live price total before confirming
- **Sell an entire set at once** for a configurable set-completion bonus multiplier
- **Configurable sell multiplier** applied to each card's base rarity value

### 🗄️ Persistent Database
- **Automatic table creation** on first resource start — no manual SQL import needed
- **Three tables**: `mnc_trading_cards` (inventory cards), `mnc_binders` (binder ownership), `mnc_binder_cards` (stored cards)
- **Auto-migration** adds new columns to existing installs safely
- **Print counter persistence** — global card print counts are loaded from the database on start so numbering is accurate across restarts

### 🖥️ Polished NUI
- Custom fonts (Bebas Neue, Barlow Condensed) for an authentic card-game aesthetic
- Fully mouse-driven with ESC-key or close button support
- Modular screen system — Pack Open, Pack Reveal, Single Card View, Binder, and Shop each have their own UI layer

---

## 📋 Requirements

| Dependency | Version | Required |
|------------|---------|----------|
| QBCore Framework | Latest | ✅ Yes |
| ox_lib | Latest | ✅ Yes |
| oxmysql | Latest | ✅ Yes |

---

## 🚀 Installation

### 1️⃣ Download & Extract

```bash
# Clone from GitHub
git clone https://github.com/MnCLosSantos/mnc-tradingcards.git

# OR download ZIP from Releases
```

Place into your resources folder:
```
[server-data]/resources/[custom]/mnc-tradingcards/
```

### 2️⃣ Database Setup

The script **automatically creates** all required tables on first start:

- `mnc_trading_cards` — tracks every card in player inventories
- `mnc_binders` — tracks binder ownership
- `mnc_binder_cards` — tracks cards stored inside binders

No manual SQL import needed!

### 3️⃣ Add to Server Config

```lua
# server.cfg
ensure oxmysql
ensure ox_lib
ensure mnc-tradingcards
```

### 4️⃣ Add Items to QBCore

Add all items to `qb-core/shared/items.lua`:

```lua
-- Card Packs
['card_pack_basic'] = {
    ['name'] = 'card_pack_basic',
    ['label'] = 'Basic Card Pack',
    ['weight'] = 100,
    ['type'] = 'item',
    ['image'] = 'card_pack_basic.png',
    ['unique'] = false,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['description'] = 'A basic pack of 3 trading cards',
},
['card_pack_premium'] = {
    ['name'] = 'card_pack_premium',
    ['label'] = 'Premium Card Pack',
    ['weight'] = 100,
    ['type'] = 'item',
    ['image'] = 'card_pack_premium.png',
    ['unique'] = false,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['description'] = 'A premium pack of 5 trading cards',
},
['card_pack_legendary'] = {
    ['name'] = 'card_pack_legendary',
    ['label'] = 'Legendary Card Pack',
    ['weight'] = 100,
    ['type'] = 'item',
    ['image'] = 'card_pack_legendary.png',
    ['unique'] = false,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['description'] = 'A legendary pack with boosted rare drop rates',
},

-- The card item itself (all cards share one item name; metadata differentiates them)
['trading_card'] = {
    ['name'] = 'trading_card',
    ['label'] = 'Trading Card',
    ['weight'] = 10,
    ['type'] = 'item',
    ['image'] = 'trading_card.png',
    ['unique'] = false,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['description'] = 'A collectible trading card',
},

-- Binder
['card_binder'] = {
    ['name'] = 'card_binder',
    ['label'] = 'Card Binder',
    ['weight'] = 500,
    ['type'] = 'item',
    ['image'] = 'card_binder.png',
    ['unique'] = false,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['description'] = 'Store and display your card collection',
},
```

### 5️⃣ Configure Settings

Edit `config.lua` to customise packs, rarities, the shop location, and your card sets.

---

## ⚙️ Configuration Guide

### 🎁 Pack Configuration

```lua
Config.Packs = {
    ['card_pack_basic'] = {
        label          = 'Basic Card Pack',
        cardCount      = 3,           -- cards per pack
        weights        = { common = 70, uncommon = 27, rare = 2, ultraRare = 1 },
        misprintChance = 0.5,         -- % chance any card is a misprint
        damagedChance  = 5,           -- % chance any card is damaged
    },
    -- Add more pack types as needed
}
```

### 💎 Rarity Configuration

```lua
Config.Rarities = {
    common    = { label = 'Common',     color = '#a0a0a0', holo = false, value = 10   },
    uncommon  = { label = 'Uncommon',   color = '#4ade80', holo = false, value = 50   },
    rare      = { label = 'Rare',       color = '#60a5fa', holo = true,  value = 100  },
    ultraRare = { label = 'Ultra Rare', color = '#f59e0b', holo = true,  value = 500  },
    misprint  = { label = 'Misprint',   color = '#e040fb', holo = true,  value = 1000 },
    damaged   = { label = 'Damaged',    color = '#ef5350', holo = false, value = 5    },
}
```

### 🏪 Shop Configuration

```lua
Config.Shop = {
    coords              = vector3(-1288.06, -310.31, 36.65),
    heading             = 360.0,
    blipSprite          = 500,
    blipColor           = 5,
    blipScale           = 0.8,
    blipName            = 'Card Dealer',
    sellMultiplier      = 0.8,    -- cards sell for 80% of their base value
    setCompletionBonus  = 1.25,   -- 25% bonus when selling a complete set
}
```

### 🗂️ Card Set Configuration

Sets are defined in `Config.Sets`. Each card supports:

| Field | Description |
|-------|-------------|
| `number` | Sequential card number within the set |
| `name` | Display name shown on the card |
| `model` | GTA V vehicle model name (used for automatic CDN image) |
| `image` | Custom foreground image path e.g. `'images/mycard.png'` |
| `background` | Custom background image path e.g. `'images/bg_rhino.png'` |
| `rarity` | `'common'`, `'uncommon'`, `'rare'`, or `'ultraRare'` |
| `printNum` | Override the print label shown on the card e.g. `'#042 / 500'` |
| `value` | Override the sell value for this specific card |

```lua
Config.Sets = {
    ['military'] = {
        label = 'Military Forces',
        icon  = '🎖️',
        cards = {
            { number = 1,  name = 'Vetir Troop Transport', model = 'vetir',    rarity = 'common'   },
            { number = 17, name = 'Rhino Tank',            model = 'rhino',    background = 'images/card2back.png', rarity = 'ultraRare', value = 1200 },
            -- ...
        },
    },
    -- Add as many sets as you like
}
```

---

## 🃏 Included Card Sets

| Set | Icon | Cards | Notes |
|-----|------|-------|-------|
| Military Forces | 🎖️ | 20 | Tanks, APCs, and military hardware |
| Police Fleet | 🚔 | 20 | Law enforcement vehicles |
| Motorcycles | 🏍️ | 20 | Street and off-road bikes |
| Bravado Collection | 🔶 | 20 | Manufacturer themed set |
| Pegassi Collection | 🐴 | 10 | Manufacturer themed set |
| Dewbauchee Collection | 💎 | 10 | Manufacturer themed set |
| Grotti Collection | 🐎 | 10 | Manufacturer themed set |
| Truffade Collection | ⚡ | 5 | All Ultra Rare — high value |
| Fruit Collection | 🌟 | 7 | Custom image cards |

---

## 🐛 Troubleshooting

**Pack won't open:**
- Confirm the item name in `Config.Packs` exactly matches the item name in `qb-core/shared/items.lua`
- Check the server console for errors on resource start

**Cards not saving between sessions:**
- Verify `oxmysql` is running and the connection string is correct
- Check the server console confirms `mnc_trading_cards` table is ready on startup

**Binder not opening:**
- Confirm `card_binder` is a registered useable item in QBCore
- Check that `binderId` is being passed correctly from the server event

**Shop NPC not appearing:**
- Verify `Config.Shop.coords` points to a valid pedestrian area
- Check the model `s_m_y_dealer_01` is not restricted on your server

**NUI not closing with ESC:**
- Ensure `ox_lib` is loaded before `mnc-tradingcards` in `server.cfg`

---

## 📝 Credits

**Author**: Stan Leigh  
**Version**: 1.1.0  
**Framework**: QBCore  

### Contributing
Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Submit a pull request with a detailed description

---

## 📞 Support & Community

For support, bug reports, or feature requests:
- Open an issue on GitHub
- Join our Discord community
- Check existing documentation

---

## 🔄 Changelog

### Version 1.1.0 (Current Release)
**New Features:**
- ✨ Added Misprint card variant with its own rarity tier and holo effect
- ✨ Added Damaged card variant with discard mechanic
- ✨ Implemented global per-card print counter with database persistence across restarts
- ✨ Added set-completion bonus when selling a full set at the dealer
- ✨ Added `sellSet` NUI callback for bulk set selling
- ✨ Implemented custom image and background support per card
- ✨ Added Fruit Collection set using fully custom artwork
- ✨ Added manufacturer-themed sets (Bravado, Pegassi, Dewbauchee, Grotti, Truffade)

**Improvements:**
- 🔧 Enhanced card data flattening (`FlattenCardInfo`) for consistent NUI payload structure
- 🔧 Added `ALTER TABLE … ADD COLUMN IF NOT EXISTS` migration for safe upgrades from v1.0.0
- 🔧 Improved binder UI with drag-to-remove zone and set progress display
- 🔧 Enhanced shop UI with select-all toggle and live price total
- 🔧 Refined pack tear animation with canvas-based progress indicator

**Bug Fixes:**
- 🐛 Fixed card data not persisting correctly when `_ref` nested structure was present
- 🐛 Resolved binder cards missing `image` and `background` columns on older installs
- 🐛 Fixed sell price calculating from `0` when card value was not flattened properly
- 🐛 Corrected print counter not initialising from existing database rows after restart
- 🐛 Fixed NUI remaining open if resource was stopped mid-session

---

### Version 1.0.0
**Features:**
- ✨ Initial release with core pack opening system
- ✨ Three pack tiers: Basic, Premium, Legendary
- ✨ Six rarity tiers with configurable weights and values
- ✨ Card Binder item with drag-and-drop storage
- ✨ Card Dealer NPC with world blip and E-key interaction
- ✨ Sell individual cards or entire sets at the dealer
- ✨ Automatic database table creation on resource start
- ✨ Military, Police Fleet, and Motorcycle card sets included
- ✨ Full NUI with pack tear animation, card flip reveal, binder book, and shop screens

---

## ⚠️ Important Notes

1. **Database**: Requires oxmysql — MariaDB 10.3+ recommended
2. **Compatibility**: QBCore only — not compatible with ESX
3. **Card Images**: Vehicle cards use the Cfx CDN automatically via the `model` field; custom cards require images placed in `web/images/`
4. **Performance**: NUI is only active while a screen is open — no background resource usage
5. **Legal**: For use on FiveM servers only, respect Rockstar's Terms of Service

---

**Enjoy collecting on your FiveM server! 🃏**