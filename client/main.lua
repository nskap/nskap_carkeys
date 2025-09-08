local ESX = exports['es_extended']:getSharedObject()

local locale = (type(lib) ~= 'nil' and lib.locale and lib.locale()) or nil
local inventory = exports.ox_inventory
if inventory and inventory.displayMetadata then
    local label = (locale and locale('plate')) or 'plate'
    inventory:displayMetadata('plate', label)
end

local itemName <const> = (Config and Config.ItemName) or 'vehiclekey'
local ignitionKey <const> = (Config and Config.IgnitionKey) or 'Y'
local lockKey <const> = (Config and Config.LockKey) or 'L'

local keyInIgnition = {}

local function trimPlate(plate)
    if not plate then return nil end
    return (string.gsub(plate, '^%s*(.-)%s*$', '%1'))
end


local function getVehPlate(veh)
    return trimPlate(GetVehicleNumberPlateText(veh))
end

local function getClosestVehicle(maxDist)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local handle, veh = FindFirstVehicle()
    local success
    local closest, cDist
    repeat
        if DoesEntityExist(veh) then
            local dist = #(GetEntityCoords(veh) - coords)
            if dist <= (maxDist or 4.0) and (not cDist or dist < cDist) then
                closest, cDist = veh, dist
            end
        end
        success, veh = FindNextVehicle(handle)
    until not success
    EndFindVehicle(handle)
    return closest, cDist
end

local function meMessage(text)
    local coords = GetEntityCoords(PlayerPedId())
    TriggerServerEvent('nskap_keys:me', text, coords)
end

local function playLockEmote(duration)
    local dict, name = 'anim@mp_player_intmenu@key_fob@', 'fob_click'
    RequestAnimDict(dict)
    local timeout = GetGameTimer() + 2000
    while not HasAnimDictLoaded(dict) and GetGameTimer() < timeout do
        Wait(0)
    end
    local ped = PlayerPedId()
    TaskPlayAnim(ped, dict, name, 8.0, -8.0, duration or -1, 49, 0.0, false, false, false)
end

local function doLockProgress(willLock)
    local duration = (Config and Config.LockProgressDuration) or 2000
    local label = willLock and 'Zamykání...' or 'Odemykání...'
    if type(lib) ~= 'nil' and lib.progressBar then
        playLockEmote(duration)
        local ok = lib.progressBar({
            duration = duration,
            label = label,
            useWhileDead = false,
            canCancel = true,
            disable = { move = true, carMovement = true, combat = true }
        })
        ClearPedSecondaryTask(PlayerPedId())
        return ok
    end
    playLockEmote(duration)
    local endTime = GetGameTimer() + duration
    while GetGameTimer() < endTime do
        Wait(0)
        DisableControlAction(0, 21, true)
        DisableControlAction(0, 22, true)
        DisableControlAction(0, 24, true)
        DisableControlAction(0, 25, true)
        DisableControlAction(0, 75, true)
    end
    ClearPedSecondaryTask(PlayerPedId())
    return true
end

local function notify(msg, ntype)
    ntype = ntype or 'inform'
    if type(lib) ~= 'nil' and lib.notify and (not Config.NotifyProvider or Config.NotifyProvider == 'ox') then
        lib.notify({ title = 'Keys', description = msg, type = ntype, position = 'top-right' })
        return
    end
    if ESX and ESX.ShowNotification then
        ESX.ShowNotification(msg)
        return
    end
    TriggerEvent('chat:addMessage', { args = { '^3KEYS', msg } })
end

local function hasKey(plate, cb)
    ESX.TriggerServerCallback('nskap_keys:hasKey', function(result)
        cb(result)
    end, plate)
end

RegisterNetEvent('nskap_keys:clientUseKey', function(plate)
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    local targetVeh
    if veh ~= 0 then
        targetVeh = veh
    else
        targetVeh = getClosestVehicle(Config.NearbyVehicleDistance or 4.0)
    end
    if not targetVeh or targetVeh == 0 then
        notify('Žádné vozidlo poblíž.', 'error')
        return
    end
    local vPlate = getVehPlate(targetVeh)
    if vPlate ~= plate then
        notify(('Tento klíč nepasuje (SPZ %s).'):format(vPlate), 'error')
        return
    end
    local state = GetVehicleDoorLockStatus(targetVeh)
    local willLock = state == 1 or state == 0
    meMessage(willLock and '/me zamyká' or '/me odemyká')
    if not doLockProgress(willLock) then return end
    local netId = NetworkGetNetworkIdFromEntity(targetVeh)
    TriggerServerEvent('nskap_keys:toggleLock', plate, netId)
end)

RegisterNetEvent('nskap_keys:playLockFx', function(vehNet, locked)
    local veh = NetworkGetEntityFromNetworkId(vehNet)
    if not DoesEntityExist(veh) then return end
    SetVehicleLights(veh, 2)
    Wait(150)
    SetVehicleLights(veh, 0)
    if locked then
        StartVehicleHorn(veh, 100, `HELDDOWN`, false)
    end
end)

RegisterNetEvent('nskap_keys:lockNotify', function(plate, locked)
    if locked == nil then return end
    if locked then
        notify(('Vozidlo zamčeno (SPZ %s)'):format(plate), 'success')
    else
        notify(('Vozidlo odemčeno (SPZ %s)'):format(plate), 'inform')
    end
end)

RegisterNetEvent('nskap_keys:clientToggleLock', function(plate)
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    local targetVeh = veh ~= 0 and veh or getClosestVehicle(Config.NearbyVehicleDistance or 4.0)
    if not targetVeh or targetVeh == 0 then return end
    if getVehPlate(targetVeh) ~= plate then return end
    local state = GetVehicleDoorLockStatus(targetVeh)
    local nowLocked = state == 1 or state == 0
    SetVehicleDoorsLocked(targetVeh, nowLocked and 2 or 1)
    local netId = NetworkGetNetworkIdFromEntity(targetVeh)
    TriggerEvent('nskap_keys:playLockFx', netId, nowLocked)

    if nowLocked then
        notify(('Vozidlo zamčeno (SPZ %s)'):format(plate), 'success')
    else
        notify(('Vozidlo odemčeno (SPZ %s)'):format(plate), 'inform')
    end
end)

CreateThread(function()
   
    RegisterNetEvent('nskap_keys:useItem', function(item)
        if not item or not item.metadata or not item.metadata.plate then
            notify('Klíč nemá platnou SPZ.')
            return
        end
        local plate = trimPlate(item.metadata.plate)
        hasKey(plate, function(ok)
            if not ok then
                notify('Tento klíč nevlastníš.')
                return
            end
            TriggerEvent('nskap_keys:clientUseKey', plate)
        end)
    end)
end)

local function canToggleIgnitionFor(veh)
    if veh == 0 then return false end

    if GetPedInVehicleSeat(veh, -1) ~= PlayerPedId() then
        return false
    end
    return true
end

local function setEngine(veh, state)
    SetVehicleEngineOn(veh, state, true, true)
    SetVehicleUndriveable(veh, not state)
end

local function toggleIgnition()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if not canToggleIgnitionFor(veh) then
        notify('Musíš sedět na místě řidiče.', 'error')
        return
    end
    local plate = getVehPlate(veh)
    if not plate then return end
    TriggerServerEvent('nskap_keys:toggleIgnition', plate)
end

CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)
        if veh ~= 0 then
            local plate = getVehPlate(veh)
            if plate and not keyInIgnition[plate] then
                DisableControlAction(0, 71, true)
                DisableControlAction(0, 72, true)
                SetVehicleEngineOn(veh, false, true, true)
            end
        else
            local nearVeh = getClosestVehicle(6.0)
            if nearVeh and nearVeh ~= 0 then
                local plate = getVehPlate(nearVeh)
                if plate and keyInIgnition[plate] then
                    SetVehicleEngineOn(nearVeh, true, true, true)
                end
            end
        end
        Wait(0)
    end
end)

RegisterCommand('+nskap_ignition', toggleIgnition, false)
RegisterCommand('-nskap_ignition', function() end, false)
RegisterKeyMapping('+nskap_ignition', 'Vložit/Vytáhnout klíč zapalování', 'keyboard', string.lower(ignitionKey))

local function toggleLockKeybind()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    local targetVeh = veh ~= 0 and veh or getClosestVehicle(Config.NearbyVehicleDistance or 4.0)
    if not targetVeh or targetVeh == 0 then
        notify('Žádné vozidlo poblíž.', 'error')
        return
    end
    local plate = getVehPlate(targetVeh)
    hasKey(plate, function(ok)
        if not ok then
            notify('Nemáš správný klíč pro toto vozidlo.', 'error')
            return
        end
        local state = GetVehicleDoorLockStatus(targetVeh)
        local willLock = state == 1 or state == 0
        meMessage(willLock and '/me zamyká' or '/me odemyká')
        if not doLockProgress(willLock) then return end
        local netId = NetworkGetNetworkIdFromEntity(targetVeh)
        TriggerServerEvent('nskap_keys:toggleLock', plate, netId)
    end)
end

RegisterCommand('+nskap_lock', toggleLockKeybind, false)
RegisterCommand('-nskap_lock', function() end, false)
RegisterKeyMapping('+nskap_lock', 'Zamknout/Odemknout vozidlo s klíčem', 'keyboard', string.lower(lockKey))

CreateThread(function()
    TriggerEvent('chat:addSuggestion', '/addkey', 'Přidá klíč hráči pro vozidlo, ve kterém sedí', {
        { name = 'playerId', help = 'ID hráče' },
        { name = 'count', help = 'Počet (výchozí 1)' }
    })
end)

RegisterNetEvent('nskap_keys:ignitionResult', function(success, plate, inserted, errMsg)
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if not success then
        if errMsg then notify(errMsg) end
        return
    end
    keyInIgnition[plate] = inserted and true or false
    if veh ~= 0 and getVehPlate(veh) == plate then
        if inserted then
            meMessage('/me vkládá klíč do zapalování')
            setEngine(veh, true)
            notify(('Klíč vložen • SPZ %s'):format(plate))
        else
            meMessage('/me vytahuje klíč ze zapalování')
            setEngine(veh, false)
            notify(('Klíč vytažen • SPZ %s'):format(plate))
        end
    else

        if inserted then
            notify(('Klíč vložen • SPZ %s'):format(plate))
        else
            notify(('Klíč vytažen • SPZ %s'):format(plate))
        end
    end
end)
