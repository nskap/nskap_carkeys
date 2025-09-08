local ESX <const> = exports['es_extended']:getSharedObject()

local IgnitionInserted = {}

local function addKeyToPlayer(source, plate, count)
    count = count or 1
    return exports.ox_inventory:AddItem(source, Config.ItemName, count, { plate = plate })
end

local function removeKeyFromPlayer(source, plate, count)
    count = count or 1
    return exports.ox_inventory:RemoveItem(source, Config.ItemName, count, { plate = plate })
end

local function countKeys(source, plate)
    local count = exports.ox_inventory:Search(source, 'count', Config.ItemName, { plate = plate })
    return count or 0
end

ESX.RegisterServerCallback('nskap_keys:hasKey', function(source, cb, plate)
    cb(countKeys(source, plate) > 0)
end)

RegisterNetEvent('nskap_keys:toggleLock', function(plate, vehNet)
    local src = source
    if not plate or type(plate) ~= 'string' then return end
    if countKeys(src, plate) <= 0 then return end

    if vehNet then
        local veh = NetworkGetEntityFromNetworkId(vehNet)
        if DoesEntityExist(veh) then
            local state = GetVehicleDoorLockStatus(veh)
            local nowLocked = state == 1 or state == 0
            SetVehicleDoorsLocked(veh, nowLocked and 2 or 1)
            TriggerClientEvent('nskap_keys:playLockFx', -1, vehNet, nowLocked)
            TriggerClientEvent('nskap_keys:lockNotify', src, plate, nowLocked)
        end
    else
        TriggerClientEvent('nskap_keys:clientToggleLock', src, plate)
    end
end)

RegisterNetEvent('nskap_keys:toggleIgnition', function(plate)
    local src = source
    if type(plate) ~= 'string' then return end
    plate = ESX.Math.Trim(plate)

    local inserted = IgnitionInserted[plate] == true
    if not inserted then

        if countKeys(src, plate) <= 0 then
            TriggerClientEvent('nskap_keys:ignitionResult', src, false, plate, false, 'Nemáš správný klíč pro toto vozidlo.')
            return
        end
        removeKeyFromPlayer(src, plate, 1)
        IgnitionInserted[plate] = true
        TriggerClientEvent('nskap_keys:ignitionResult', src, true, plate, true)
    else

        addKeyToPlayer(src, plate, 1)
        IgnitionInserted[plate] = false
        TriggerClientEvent('nskap_keys:ignitionResult', src, true, plate, false)
    end
end)


local function registerUsable()
    exports.ox_inventory:RegisterUsableItem(Config.ItemName, function(source, item)
        TriggerClientEvent('nskap_keys:useItem', source, item)
    end)
end

CreateThread(registerUsable)

RegisterNetEvent('nskap_keys:me', function(msg, coords)
    local src = source
    if type(msg) ~= 'string' or type(coords) ~= 'vector3' then return end
    for _, id in ipairs(GetPlayers()) do
        local ped = GetPlayerPed(id)
        local pcoords = GetEntityCoords(ped)
        if #(pcoords - coords) <= (Config.MeRadius or 20.0) then
            TriggerClientEvent('chat:addMessage', id, { args = { '^6ME', msg } })
        end
    end
end)


RegisterCommand('addkey', function(src, args)
    local issuer = src
    if issuer ~= 0 then
        local xIssuer = ESX.GetPlayerFromId(issuer)
        if not xIssuer then return end
        local group = xIssuer.getGroup and xIssuer.getGroup() or 'user'
        if not Config.AdminGroups[group] then
            TriggerClientEvent('chat:addMessage', issuer, { args = { '^1SYSTEM', 'Nemáš oprávnění pro /addkey' } })
            return
        end
    end

    local target = tonumber(args[1] or '')
    local count = tonumber(args[2] or '1') or 1
    if not target or not GetPlayerPed(target) then
        if issuer ~= 0 then
            TriggerClientEvent('chat:addMessage', issuer, { args = { '^1SYSTEM', 'Použití: /addkey <id> [count]' } })
        end
        return
    end

    local ped = GetPlayerPed(target)
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then
        if issuer ~= 0 then
            TriggerClientEvent('chat:addMessage', issuer, { args = { '^1SYSTEM', 'Cíl nesedí v žádném vozidle.' } })
        end
        return
    end

    local plate = ESX.Math.Trim(GetVehicleNumberPlateText(veh))
    addKeyToPlayer(target, plate, count)
    if issuer ~= 0 then
        TriggerClientEvent('chat:addMessage', issuer, { args = { '^2SYSTEM', ('Přidán klíč pro SPZ %s hráči %d x%d'):format(plate, target, count) } })
    end
    TriggerClientEvent('chat:addMessage', target, { args = { '^2KEYS', ('Obdržel jsi klíč od vozidla se SPZ %s x%d'):format(plate, count) } })
end, false)

-- Exports
exports('AddKey', function(sourceId, plate, count)
    return addKeyToPlayer(sourceId, plate, count)
end)

exports('RemoveKey', function(sourceId, plate, count)
    return removeKeyFromPlayer(sourceId, plate, count)
end)

exports('HasKey', function(sourceId, plate)
    return countKeys(sourceId, plate) > 0
end)
