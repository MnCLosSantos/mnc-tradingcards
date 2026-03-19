local QBCore = exports['qb-core']:GetCoreObject()
local isUIOpen  = false
local binderId  = nil
local shopMenuOpen = false

local function DebugPrint(msg)
    if Config.Debug then print('[mnc-tradingcards] ' .. msg) end
end

-- ============================================================
--  NUI HELPERS
-- ============================================================
local function OpenUI()
    isUIOpen = true
    SetNuiFocus(true, true)
end

local function CloseUI()
    isUIOpen = false
    binderId = nil
    SetNuiFocus(false, false)
    SendNUIMessage({ type = 'closeUI' })
end

-- ============================================================
--  OPEN PACK
-- ============================================================
RegisterNetEvent('mnc-tradingcards:client:startOpenPack', function(itemName, itemSlot)
    if isUIOpen then return end
    local packConfig = Config.Packs[itemName]
    if not packConfig then return end
    TriggerServerEvent('mnc-tradingcards:server:openPack', itemName, itemSlot)
end)

-- ============================================================
--  PACK OPENED
-- ============================================================
RegisterNetEvent('mnc-tradingcards:client:packOpened', function(cards, packLabel)
    DebugPrint('Pack opened, received ' .. #cards .. ' cards')
    OpenUI()
    SendNUIMessage({
        type      = 'showPackReveal',
        packLabel = packLabel or 'Card Pack',
        cards     = cards,
        sets      = Config.Sets,
        rarities  = Config.Rarities,
    })
end)

-- ============================================================
--  VIEW SINGLE CARD
-- ============================================================
RegisterNetEvent('mnc-tradingcards:client:startViewCard', function(slot, info)
    if isUIOpen then return end
    if not info then return end
    OpenUI()
    SendNUIMessage({ type = 'viewCard', card = info, rarities = Config.Rarities })
end)

RegisterNetEvent('mnc-tradingcards:client:viewCard', function(info)
    if not info then return end
    OpenUI()
    SendNUIMessage({ type = 'viewCard', card = info, rarities = Config.Rarities })
end)

-- ============================================================
--  BINDER
-- ============================================================
RegisterNetEvent('mnc-tradingcards:client:startBinder', function(slot)
    if isUIOpen then return end
    TriggerServerEvent('mnc-tradingcards:server:useBinder', slot)
end)

RegisterNetEvent('mnc-tradingcards:client:openBinder', function(binderData)
    binderId = binderData.binderId
    OpenUI()
    SendNUIMessage({
        type           = 'openBinder',
        binderId       = binderData.binderId,
        sets           = binderData.sets,
        rarities       = binderData.rarities,
        storedCards    = binderData.storedCards,
        inventoryCards = binderData.inventoryCards,
    })
end)

RegisterNetEvent('mnc-tradingcards:client:cardStoredInBinder', function(cardInfo)
    SendNUIMessage({ type = 'cardStoredInBinder', cardInfo = cardInfo })
end)

RegisterNetEvent('mnc-tradingcards:client:cardRemovedFromBinder', function(cardInfo)
    SendNUIMessage({ type = 'cardRemovedFromBinder', cardInfo = cardInfo })
end)

RegisterNetEvent('mnc-tradingcards:client:cardDiscarded', function(cardId)
    SendNUIMessage({ type = 'cardDiscarded', cardId = cardId })
end)

-- ============================================================
--  SELL COMPLETE — server confirmed the sale
-- ============================================================
RegisterNetEvent('mnc-tradingcards:client:sellComplete', function(data)
    SendNUIMessage({ type = 'sellComplete', sold = data.sold, total = data.total })
end)

-- ============================================================
--  NUI CALLBACKS
-- ============================================================
RegisterNUICallback('closeUI', function(_, cb)
    CloseUI(); cb({ status = 'ok' })
end)

RegisterNUICallback('notify', function(data, cb)
    lib.notify({ title = data.title or 'Trading Cards', description = data.description, type = data.type or 'info' })
    cb({ status = 'ok' })
end)

RegisterNUICallback('storeCardInBinder', function(data, cb)
    if not binderId then cb({ status = 'error', message = 'No active binder' }); return end
    TriggerServerEvent('mnc-tradingcards:server:storeCardInBinder', binderId, data.slot, data.cardid)
    cb({ status = 'ok' })
end)

RegisterNUICallback('removeCardFromBinder', function(data, cb)
    if not binderId then cb({ status = 'error', message = 'No active binder' }); return end
    TriggerServerEvent('mnc-tradingcards:server:removeCardFromBinder', data.binderId or binderId, data.cardid)
    cb({ status = 'ok' })
end)

RegisterNUICallback('discardDamaged', function(data, cb)
    TriggerServerEvent('mnc-tradingcards:server:discardDamaged', data.cardid)
    cb({ status = 'ok' })
end)

RegisterNUICallback('sellCards', function(data, cb)
    TriggerServerEvent('mnc-tradingcards:server:sellCards', data.cards)
    cb({ status = 'ok' })
end)

RegisterNUICallback('sellSet', function(data, cb)
    TriggerServerEvent('mnc-tradingcards:server:sellSet', data.setId)
    cb({ status = 'ok' })
end)

-- ============================================================
--  SHOP NPC
-- ============================================================
local shopPed   = nil
local shopBlip  = nil
local nearShop  = false

CreateThread(function()
    -- Blip
    shopBlip = AddBlipForCoord(Config.Shop.coords.x, Config.Shop.coords.y, Config.Shop.coords.z)
    SetBlipSprite(shopBlip, Config.Shop.blipSprite)
    SetBlipDisplay(shopBlip, 4)
    SetBlipScale(shopBlip, Config.Shop.blipScale)
    SetBlipColour(shopBlip, Config.Shop.blipColor)
    SetBlipAsShortRange(shopBlip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(Config.Shop.blipName)
    EndTextCommandSetBlipName(shopBlip)

    -- Ped (simple ambient dealer NPC)
    RequestModel(`s_m_m_movalien_01`)  -- fallback generic model
    local model = `s_m_y_dealer_01`
    RequestModel(model)
    local timer = 0
    while not HasModelLoaded(model) and timer < 5000 do
        Wait(100); timer = timer + 100
    end
    if not HasModelLoaded(model) then model = `a_m_m_skater_01` end

    local c = Config.Shop.coords
    shopPed = CreatePed(4, model, c.x, c.y, c.z - 1.0, Config.Shop.heading, false, true)
    SetEntityInvincible(shopPed, true)
    SetBlockingOfNonTemporaryEvents(shopPed, true)
    FreezeEntityPosition(shopPed, true)
    SetPedAsCop(shopPed, true)
    SetPedComponentVariation(shopPed, 0, 0, 0, 2)
end)

-- Proximity check + E prompt
CreateThread(function()
    while true do
        local sleep = 1000
        local pos   = GetEntityCoords(PlayerPedId())
        local dist  = #(pos - Config.Shop.coords)

        if dist < 2.0 then
            sleep = 0
            nearShop = true

            if not isUIOpen and not shopMenuOpen then
                -- Draw marker
                DrawMarker(20, Config.Shop.coords.x, Config.Shop.coords.y, Config.Shop.coords.z - 0.98,
                    0, 0, 0, 0, 0, 0, 0.6, 0.6, 0.3, 80, 200, 120, 150, false, true, 2, nil, nil, false)

                -- Draw help text
                BeginTextCommandDisplayHelp('STRING')
                AddTextComponentSubstringPlayerName('~INPUT_CONTEXT~ Card Dealer')
                EndTextCommandDisplayHelp(0, false, true, -1)

                if IsControlJustPressed(0, 38) then  -- E key
                    if not isUIOpen then
                        -- Gather inventory cards
                        TriggerServerEvent('mnc-tradingcards:server:requestShopOpen')
                    end
                end
            end
        else
            nearShop = false
        end

        Wait(sleep)
    end
end)

-- Server sends inventory for shop UI
RegisterNetEvent('mnc-tradingcards:client:openShop', function(inventoryCards)
    if isUIOpen then return end
    OpenUI()
    SendNUIMessage({
        type           = 'openShop',
        inventoryCards = inventoryCards,
        sets           = Config.Sets,
        rarities       = Config.Rarities,
        sellMultiplier = Config.Shop.sellMultiplier,
    })
end)

-- ============================================================
--  ESC to close
-- ============================================================
CreateThread(function()
    while true do
        Wait(0)
        if isUIOpen and IsControlJustPressed(0, 200) then
            CloseUI()
        end
    end
end)

-- ============================================================
--  Resource cleanup
-- ============================================================
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        if isUIOpen then SetNuiFocus(false, false); isUIOpen = false; binderId = nil end
        if shopPed  and DoesEntityExist(shopPed)  then DeleteEntity(shopPed)  end
        if shopBlip and DoesBlipExist(shopBlip)   then RemoveBlip(shopBlip)   end
    end
end)

DebugPrint('Client loaded')