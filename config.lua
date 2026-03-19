Config = {}

Config.Debug = false

-- ============================================================
--  LOOT BOX / PACK CONFIG
-- ============================================================
Config.Packs = {
    ['card_pack_basic'] = {             -- shop value should be around $50
        label     = 'Basic Card Pack',
        cardCount = 3,
        weights   = { common = 70, uncommon = 27, rare = 2, ultraRare = 1 },
        misprintChance = 0.5,
        damagedChance  = 5,
    },
    ['card_pack_premium'] = {             -- shop value should be around $150
        label         = 'Premium Card Pack',
        cardCount     = 5,
        weights       = { common = 60, uncommon = 34, rare = 3, ultraRare = 2 },
        misprintChance = 1,
        damagedChance  = 4,
    },
    ['card_pack_legendary'] = {             -- shop value should be around $200
        label         = 'Legendary Card Pack',
        cardCount     = 5,
        weights       = { common = 50, uncommon = 30, rare = 14, ultraRare = 6 },
        misprintChance = 2,
        damagedChance  = 2,
    },
}

-- ============================================================
--  RARITY DEFINITIONS
--  value = base $ value of a card of this rarity (sell price = value * shop.sellMultiplier)
-- ============================================================
Config.Rarities = {
    common    = { label = 'Common',     color = '#a0a0a0', holo = false, value = 10   },
    uncommon  = { label = 'Uncommon',   color = '#4ade80', holo = false, value = 50   },
    rare      = { label = 'Rare',       color = '#60a5fa', holo = true,  value = 100  },
    ultraRare = { label = 'Ultra Rare', color = '#f59e0b', holo = true,  value = 500 },
    misprint  = { label = 'Misprint',   color = '#e040fb', holo = true,  value = 1000 },
    damaged   = { label = 'Damaged',    color = '#ef5350', holo = false, value = 5    },
}

-- ============================================================
--  BINDER CONFIG
-- ============================================================
Config.Binders = {
    ['card_binder'] = {
        label           = 'Card Binder',
        maxSets         = 999,
        completionBonus = 1.5,
    },
}

-- ============================================================
--  SHOP LOCATION
-- ============================================================
Config.Shop = {
    coords         = vector3(-1288.06, -310.31, 36.65),
    heading        = 360.0,
    blipSprite     = 500,
    blipColor      = 5,
    blipScale      = 0.8,
    blipName       = 'Card Dealer',
    sellMultiplier      = 0.8,
    setCompletionBonus  = 1.25,
}

-- ============================================================
--  COLLECTOR SETS
--
--  Card fields:
--    number     = sequential card number in set
--    name       = display name
--    model      = GTA V vehicle model for FiveM CDN image
--    image      = custom foreground image  e.g. 'images/mycard.png'
--    background = custom background PNG    e.g. 'images/bg_rhino.png'
--    rarity     = 'common'|'uncommon'|'rare'|'ultraRare'
--    printNum   = override print label shown on card e.g. '#042 / 500'
--    value      = override $ value for this specific card
-- ============================================================
Config.Sets = {

    ['military'] = {
        label  = 'Military Forces',
        icon   = '🎖️',
        cards  = {
            { number = 1,  name = 'Vetir Troop Transport',    model = 'vetir',       rarity = 'common'   },
            { number = 2,  name = 'Barracks Troop Transport', model = 'barracks',    rarity = 'common'   },
            { number = 3,  name = 'Mesa Crusader',            model = 'crusader',    rarity = 'common'   },
            { number = 4,  name = 'Halftrack',                model = 'halftrack',   rarity = 'uncommon' },
            { number = 5,  name = 'RCV',                      model = 'riot2',       rarity = 'uncommon' },
            { number = 6,  name = 'Menacer',                  model = 'menacer',     rarity = 'uncommon' },
            { number = 7,  name = 'Barracks Semi',            model = 'barracks2',   rarity = 'uncommon' },
            { number = 8,  name = 'Army Trailer',             model = 'armytrailer', rarity = 'uncommon' },
            { number = 9,  name = 'Army Tanker',              model = 'armytanker',  rarity = 'uncommon' },
            { number = 10, name = 'Insurgent',                model = 'insurgent',   rarity = 'rare'     },
            { number = 11, name = 'APC',                      model = 'apc',         rarity = 'rare'     },
            { number = 12, name = 'Barrage',                  model = 'barrage',     rarity = 'rare'     },
            { number = 13, name = 'Chernobog',                model = 'chernobog',   rarity = 'rare'     },
            { number = 14, name = 'Nightshark',               model = 'nightshark',  rarity = 'rare'     },
            { number = 15, name = 'Terrorbyte',               model = 'terbyte',     rarity = 'rare',     value = 600  },
            { number = 16, name = 'Khanjali',                 model = 'khanjali',    background = 'images/card2back.png', rarity = 'ultraRare', value = 1000 },
            { number = 17, name = 'Rhino Tank',               model = 'rhino',       background = 'images/card2back.png', rarity = 'ultraRare', value = 1200 },
            { number = 18, name = 'Thruster Jet Pack',        model = 'thruster',    background = 'images/card2back.png', rarity = 'ultraRare', value = 1300 },
            { number = 19, name = 'Kosatka Submarine',        model = 'kosatka',     background = 'images/card2back.png', rarity = 'ultraRare', value = 1400 },
            { number = 20, name = 'KURTZ 31 Patrol Boat',     model = 'patrolboat',  background = 'images/card2back.png', rarity = 'ultraRare', value = 1500 },
        },
    },

    ['police'] = {
        label  = 'Police Fleet',
        icon   = '🚔',
        cards  = {
        { number = 1,  name = 'Police Cruiser',              model = 'police',        rarity = 'common'   },
        { number = 2,  name = 'Police Cruiser 2',            model = 'police2',       rarity = 'common'   },
        { number = 3,  name = 'Police Cruiser 3',            model = 'police3',       rarity = 'common'   },
        { number = 4,  name = 'Sheriff Cruiser',             model = 'sheriff',       rarity = 'common'   },
        { number = 5,  name = 'Unmarked Cruiser',            model = 'police4',       rarity = 'common'   },
        { number = 6,  name = 'Police Rancher',              model = 'policeold1',    rarity = 'uncommon' },
        { number = 7,  name = 'Police Roadcruiser',          model = 'policeold2',    rarity = 'uncommon' },
        { number = 8,  name = 'Sheriff SUV',                 model = 'sheriff2',      rarity = 'uncommon' },
        { number = 9,  name = 'Police Transporter',          model = 'policet',       rarity = 'uncommon' },
        { number = 10, name = 'FIB SUV',                     model = 'fbi',           rarity = 'rare'     },
        { number = 11, name = 'FIB SUV 2',                   model = 'fbi2',          rarity = 'rare'     },
        { number = 12, name = 'Prison Bus',                  model = 'pbus',          rarity = 'rare'     },
        { number = 13, name = 'Brute Riot',                  model = 'riot',          rarity = 'rare'     },
        { number = 14, name = 'Dorado Police Package',       model = 'poldorado',     rarity = 'rare'     },
        { number = 15, name = 'Gauntlet Police Package',     model = 'polgauntlet',   background = 'images/card2back.png', rarity = 'ultraRare', value = 1400 },
        { number = 16, name = 'Dominator Police Package',    model = 'poldominator10',background = 'images/card2back.png', rarity = 'ultraRare', value = 1600 },
        { number = 17, name = 'Impaler Police Package',      model = 'polimpaler5',   background = 'images/card2back.png', rarity = 'ultraRare', value = 1800 },
        { number = 18, name = 'Predator Police Package',     model = 'predator',      background = 'images/card2back.png', rarity = 'ultraRare', value = 2000 },
        { number = 19, name = 'Greenwood Police Package',    model = 'polgreenwood',  background = 'images/card2back.png', rarity = 'ultraRare', value = 2200 },
        { number = 20, name = 'Impaler LX Police Package',   model = 'polimpaler6',   background = 'images/card2back.png', rarity = 'ultraRare', value = 2400 },
        },
    },

    ['planes'] = {
        label  = 'Aviation',
        icon   = '✈️',
        cards  = {
            { number = 1,  name = 'Duster',           model = 'duster',      rarity = 'common'    },
            { number = 2,  name = 'Mammatus',         model = 'mammatus',    rarity = 'common'    },
            { number = 3,  name = 'Dodo',             model = 'dodo',        rarity = 'common'    },
            { number = 4,  name = 'AirLiner',         model = 'jet',         rarity = 'common'    },
            { number = 5,  name = 'Cuban 800',        model = 'cuban800',    rarity = 'uncommon'  },
            { number = 6,  name = 'Mallard',          model = 'stunt',       rarity = 'uncommon'  },
            { number = 7,  name = 'Velum',            model = 'velum',       rarity = 'uncommon'  },
            { number = 8,  name = 'Luxor',            model = 'luxor',       rarity = 'uncommon'  },
            { number = 9,  name = 'Luxor Deluxe',     model = 'luxor2',      rarity = 'uncommon'  },
            { number = 10, name = 'Besra',            model = 'besra',       rarity = 'rare'      },
            { number = 11, name = 'Titan',            model = 'titan',       rarity = 'rare'      },
            { number = 12, name = 'Rogue',            model = 'rogue',       rarity = 'rare'      },
            { number = 13, name = 'Streamer 216',     model = 'streamer216', rarity = 'rare'      },
            { number = 14, name = 'V-65 Molotok',     model = 'molotok',     background = 'images/card2back.png', rarity = 'ultraRare', value = 200  },
            { number = 15, name = 'P-45 Nokota',      model = 'nokota',      background = 'images/card2back.png', rarity = 'ultraRare' },
            { number = 16, name = 'RM-10 Bombushka',  model = 'bombushka',   background = 'images/card2back.png', rarity = 'ultraRare' },
            { number = 17, name = 'RO-86 Alkonost',   model = 'alkonost',    background = 'images/card2back.png', rarity = 'ultraRare', value = 400  },
            { number = 18, name = 'B-11 Strikeforce', model = 'strikeforce', background = 'images/card2back.png', rarity = 'ultraRare', value = 600  },
            { number = 19, name = 'Lazer',            model = 'lazer',       background = 'images/card2back.png', rarity = 'ultraRare', value = 1000 },
            { number = 20, name = 'Hydra',            model = 'hydra',       background = 'images/card2back.png', rarity = 'ultraRare', value = 1500 },
        },
    },

    ['helis'] = {
        label  = 'Helicopters',
        icon   = '🚁',
        cards  = {
            { number = 1, name = 'Frogger',                  model = 'frogger',      rarity = 'common' },
            { number = 2, name = 'Maverick',                 model = 'maverick',     rarity = 'common' },
            { number = 3, name = 'Police Maverick',          model = 'polmav',       rarity = 'common' },      
            { number = 4, name = 'Buzzard',                  model = 'buzzard',      rarity = 'uncommon' },
            { number = 5, name = 'Buzzard Attack Chopper',   model = 'buzzard2',     rarity = 'uncommon' },
            { number = 6, name = 'Swift',                    model = 'swift',        rarity = 'uncommon' },
            { number = 7, name = 'SuperVolito',              model = 'supervolito',  rarity = 'uncommon' },
            { number = 8, name = 'Volatus',                  model = 'volatus',      rarity = 'uncommon' },
            { number = 9, name = 'Annihilator',              model = 'annihilator',  rarity = 'rare' },
            { number = 10, name = 'Cargobob',                model = 'cargobob',     rarity = 'rare' },
            { number = 11, name = 'Valkyrie',                model = 'valkyrie',     rarity = 'rare' },
            { number = 12, name = 'Skylift',                 model = 'skylift',      rarity = 'rare' },
            { number = 13, name = 'Cargobob Jetsam',         model = 'cargobob3',    rarity = 'rare' },
            { number = 14, name = 'Sea Sparrow',             model = 'seasparrow',   rarity = 'rare' },
            { number = 15, name = 'Sparrow',                 model = 'seasparrow2',      rarity = 'rare' },      
            { number = 16, name = 'Havok',                   model = 'havok',        rarity = 'rare' },              
            { number = 17, name = 'Savage',                  model = 'savage',       background = 'images/card2back.png', rarity = 'ultraRare', value = 1000 },
            { number = 18, name = 'Hunter',                  model = 'hunter',       background = 'images/card2back.png', rarity = 'ultraRare', value = 1000 },
            { number = 19, name = 'Akula',                   model = 'akula',        background = 'images/card2back.png', rarity = 'ultraRare', value = 1000 },
            { number = 20, name = 'Annihilator Stealth',     model = 'annihilator2', background = 'images/card2back.png', rarity = 'ultraRare', value = 1500 },
        },
    },

    ['motorbikes'] = {
        label  = 'Motorbikes',
        icon   = '🏍️',
        cards  = {
            { number = 1, name = 'PCJ-600',           model = 'pcj',          rarity = 'common' },
            { number = 2, name = 'Sanchez',           model = 'sanchez',      rarity = 'common' },
            { number = 3, name = 'Akuma',             model = 'akuma',        rarity = 'common' },
            { number = 4, name = 'Bati 801',          model = 'bati',         rarity = 'common' },
            { number = 5, name = 'Nagasaki Blazer',   model = 'blazer',       rarity = 'common' }, 
            { number = 6, name = 'Faggio',            model = 'faggio2',      rarity = 'common' },        
            { number = 7, name = 'Ruffian',           model = 'ruffian',      rarity = 'uncommon' },    
            { number = 8, name = 'Daemon',            model = 'daemon',       rarity = 'uncommon' },
            { number = 9, name = 'Carbon RS',         model = 'carbonrs',     rarity = 'uncommon' },
            { number = 10, name = 'Double-T Custom',  model = 'double',       rarity = 'rare' },
            { number = 11, name = 'Nemesis',          model = 'nemesis',      rarity = 'rare' },        
            { number = 12, name = 'Thrust',           model = 'thrust',       rarity = 'rare' },          
            { number = 13, name = 'Vader',            model = 'vader',        rarity = 'rare' },          
            { number = 14, name = 'Hexer',            model = 'hexer',        rarity = 'rare' },            
            { number = 15, name = 'Innovation',       model = 'innovation',   rarity = 'rare' }, 
            { number = 16, name = 'Hakuchou',         model = 'hakuchou',     rarity = 'rare' },
            { number = 17, name = 'Gargoyle',         model = 'gargoyle',     rarity = 'rare' },     
            { number = 18, name = 'Defiler',          model = 'defiler',      rarity = 'rare' },     
	    	{ number = 19, name = 'Sovereign',        model = 'sovereign',    background = 'images/card2back.png', rarity = 'ultraRare', value = 1000 },  
            { number = 20, name = 'Shotaro',          model = 'shotaro',      background = 'images/card2back.png', rarity = 'ultraRare', value = 1200 },  
        },
    },

    ['mfr_bravado'] = {
        label  = 'Bravado Collection',
        icon   = '🔶',
        cards  = {
            { number = 1,  name = 'Buffalo',              model = 'buffalo',    rarity = 'common'   },
            { number = 2,  name = 'FCV',                  model = 'riot2',      rarity = 'common'   },
            { number = 3,  name = 'Gauntlet',             model = 'gauntlet',   rarity = 'common'   },
            { number = 4,  name = 'Gresley',              model = 'gresley',    rarity = 'common'   },
            { number = 5,  name = 'Youga',                model = 'youga',      rarity = 'common'   },
            { number = 6,  name = 'Youga Classic',        model = 'youga2',     rarity = 'common'   },
            { number = 7,  name = 'Bison',                model = 'bison',      rarity = 'common'   },
            { number = 8,  name = 'Rat-Loader',           model = 'ratloader',  rarity = 'common'   },
            { number = 9,  name = 'Buffalo S',            model = 'buffalo2',   rarity = 'uncommon' },
            { number = 10, name = 'Dukes',                model = 'dukes',      rarity = 'uncommon' },
            { number = 11, name = 'Dukes O\'Death',       model = 'dukes2',     rarity = 'uncommon' },
            { number = 12, name = 'Gauntlet Classic',     model = 'gauntlet2',  rarity = 'uncommon' },
            { number = 13, name = 'Drift Gauntlet',       model = 'driftgauntlet4',   rarity = 'uncommon' },
            { number = 14, name = 'Banshee',              model = 'banshee',    rarity = 'rare'     },
            { number = 15, name = 'Buffalo STX',          model = 'buffalo4',   rarity = 'rare'     },
            { number = 16, name = 'Gauntlet Hellfire',    model = 'gauntlet3',  rarity = 'rare'     },
            { number = 17, name = 'Youga Classic \'69',   model = 'youga3',     rarity = 'rare'     },
            { number = 18, name = 'Banshee 900R',         model = 'banshee2',   background = 'images/card2back.png', rarity = 'ultraRare', value = 600 },
            { number = 19, name = 'Half-Track',           model = 'halftrack',  background = 'images/card2back.png', rarity = 'ultraRare', value = 800 },
            { number = 20, name = 'Buffalo STX',  model = 'buffalo5',   background = 'images/card2back.png', rarity = 'ultraRare', value = 1000 },
        },
    },

    ['mfr_pegassi'] = {
        label  = 'Pegassi Collection',
        icon   = '🐴',
        cards  = {
            { number = 1,  name = 'Monroe',           model = 'monroe',    rarity = 'common'   },
            { number = 2,  name = 'Torero XO',        model = 'torero2',  rarity = 'common'   },
            { number = 3,  name = 'Tezeract',         model = 'tezeract',  rarity = 'uncommon' },
            { number = 4,  name = 'Vacca',            model = 'vacca',     rarity = 'uncommon' },
            { number = 5,  name = 'Infernus',         model = 'infernus',  rarity = 'rare'     },
            { number = 6,  name = 'Reaper',           model = 'reaper',    rarity = 'rare'     },
            { number = 7,  name = 'Tempesta',         model = 'tempesta',  rarity = 'rare'     },
            { number = 8,  name = 'Zorrusso',         model = 'zorrusso',  rarity = 'rare'     },
            { number = 9,  name = 'Zentorno',         model = 'zentorno',  background = 'images/card2back.png', rarity = 'ultraRare', value = 1000 },
            { number = 10, name = 'Osiris',           model = 'osiris',    background = 'images/card2back.png', rarity = 'ultraRare', value = 1200 },
        },
    },

    ['mfr_dewbauchee'] = {
        label  = 'Dewbauchee Collection',
        icon   = '💎',
        cards  = {
            { number = 1,  name = 'Exemplar',         model = 'exemplar',  rarity = 'common'    },
            { number = 2,  name = 'Massacro',         model = 'massacro',  rarity = 'common'    },
            { number = 3,  name = 'Rapid GT',         model = 'rapidgt',   rarity = 'uncommon'  },
            { number = 4,  name = 'Massacro Racecar', model = 'massacro2', rarity = 'uncommon'  },
            { number = 5,  name = 'JB 700',           model = 'jb700',     rarity = 'rare'      },
            { number = 6,  name = 'Rapid GT Classic', model = 'rapidgt2',  rarity = 'rare'      },
            { number = 7,  name = 'Seven-70',         model = 'seven70',   rarity = 'rare'      },
            { number = 8,  name = 'Specter',          model = 'specter',   rarity = 'rare'      },
            { number = 9,  name = 'JB 700W',          model = 'jb7002',    background = 'images/card2back.png', rarity = 'ultraRare', value = 1000 },
            { number = 10, name = 'Specter Custom',   model = 'specter2',  background = 'images/card2back.png', rarity = 'ultraRare', value = 1000 },
        },
    },

    ['mfr_grotti'] = {
        label  = 'Grotti Collection',
        icon   = '🐎',
        cards  = {
            { number = 1,  name = 'Carbonizzare',     model = 'carbonizzare', rarity = 'common'                                                        },
            { number = 2,  name = 'Stinger',          model = 'stinger',      rarity = 'uncommon'                                                      },
            { number = 3,  name = 'Stinger GT',       model = 'stingergt',    rarity = 'uncommon'                                                      },
            { number = 4,  name = 'Cheetah',          model = 'cheetah',      rarity = 'rare'                                                          },
            { number = 5,  name = 'Itali GTO',        model = 'italigto',     rarity = 'rare'                                                          },
            { number = 6,  name = 'Itali GTB',        model = 'italigtb',     rarity = 'rare'                                                          },
            { number = 7,  name = 'Turismo R',        model = 'turismor',     rarity = 'rare'                                                          },
            { number = 8,  name = 'Cheetah Classic',  model = 'cheetah2',     background = 'images/card2back.png', rarity = 'ultraRare', value = 1000  },
            { number = 9,  name = 'Furia',            model = 'furia',        background = 'images/card2back.png', rarity = 'ultraRare', value = 1000  },
            { number = 10, name = 'Itali GTB Custom', model = 'italigtb2',    background = 'images/card2back.png', rarity = 'ultraRare', value = 1000  },
        },
    },

    ['mfr_truffade'] = {
        label  = 'Truffade Collection',
        icon   = '⚡',
        cards  = {
            { number = 1, name = 'Adder',       model = 'adder', background = 'images/card2back.png', rarity = 'ultraRare', value = 1000 },
            { number = 2, name = 'Thrax',       model = 'thrax', background = 'images/card2back.png', rarity = 'ultraRare', value = 2000 },
            { number = 3, name = 'Nero',        model = 'nero',  background = 'images/card2back.png', rarity = 'ultraRare', value = 3000 },
            { number = 4, name = 'Nero Custom', model = 'nero2', background = 'images/card2back.png', rarity = 'ultraRare', value = 4000 },
            { number = 5, name = 'Z-Type',      model = 'ztype', background = 'images/card2back.png', rarity = 'ultraRare', value = 18000 },
        },
    },

    ['fruit_collection'] = {
        label = 'Fruit Collection',
        icon  = '🌟',
        cards = {
        { number = 1, name = 'Blueberry',  image = 'images/blueberry.png', background = 'images/card1back.png',   rarity = 'ultraRare', value = 100 },
        { number = 2, name = 'Mint',       image = 'images/mint.png',      background = 'images/card1back.png',   rarity = 'ultraRare', value = 200 },
        { number = 3, name = 'Banana',     image = 'images/bananna.png',   background = 'images/card1back.png',   rarity = 'ultraRare', value = 300 },
        { number = 4, name = 'Peach',      image = 'images/peach.png',     background = 'images/card1back.png',   rarity = 'ultraRare', value = 400 },
        { number = 5, name = 'Mango',      image = 'images/mango.png',      background = 'images/card1back.png',   rarity = 'ultraRare', value = 500 },
        { number = 6, name = 'Pineapple',  image = 'images/pineapple.png',  background = 'images/card1back.png',   rarity = 'ultraRare', value = 600 },
        { number = 7, name = 'Watermelon', image = 'images/watermelon.png', background = 'images/card1back.png',   rarity = 'ultraRare', value = 700 },
        },
    },
}
