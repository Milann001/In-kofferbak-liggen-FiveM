local QBCore = exports['qb-core']:GetCoreObject()

-- Table to track players in trunks
local playersInTrunks = {} -- [vehicleNetId] = playerId

-- Callback to check if player can enter trunk
QBCore.Functions.CreateCallback('qb-trunk:server:canEnterTrunk', function(source, cb, vehicleNetId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then 
        cb(false, 'Speler niet gevonden!')
        return 
    end
    
    -- Check if someone is already in this trunk
    if playersInTrunks[vehicleNetId] then
        local otherPlayer = QBCore.Functions.GetPlayer(playersInTrunks[vehicleNetId])
        if otherPlayer then
            cb(false, 'Er zit al iemand in deze kofferbak!')
            return
        else
            -- Player not found, remove from table
            playersInTrunks[vehicleNetId] = nil
        end
    end
    
    cb(true, '')
end)

-- Server-side event when player enters trunk
RegisterNetEvent('qb-trunk:server:enterTrunk', function(vehicleNetId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Check if vehicle already has someone in trunk
    if playersInTrunks[vehicleNetId] then
        local otherPlayer = QBCore.Functions.GetPlayer(playersInTrunks[vehicleNetId])
        if otherPlayer then
            TriggerClientEvent('QBCore:Notify', src, 'Er zit al iemand in deze kofferbak!', 'error')
            return
        end
    end
    
    -- Add player to trunk
    playersInTrunks[vehicleNetId] = src
    
    print(('[qb-trunk] %s (%s) entered trunk of vehicle: %s'):format(
        Player.PlayerData.name,
        Player.PlayerData.citizenid,
        vehicleNetId
    ))
end)

-- Server-side event when player exits trunk
RegisterNetEvent('qb-trunk:server:exitTrunk', function(vehicleNetId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Remove player from trunk
    if playersInTrunks[vehicleNetId] == src then
        playersInTrunks[vehicleNetId] = nil
        
        print(('[qb-trunk] %s (%s) exited trunk of vehicle: %s'):format(
            Player.PlayerData.name,
            Player.PlayerData.citizenid,
            vehicleNetId
        ))
    end
end)

-- Server-side event for forced exit (when vehicle is deleted)
RegisterNetEvent('qb-trunk:server:forcedExit', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Find and remove player from any trunk
    for vehicleNetId, playerId in pairs(playersInTrunks) do
        if playerId == src then
            playersInTrunks[vehicleNetId] = nil
            print(('[qb-trunk] %s (%s) was forced out of trunk (vehicle deleted)'):format(
                Player.PlayerData.name,
                Player.PlayerData.citizenid
            ))
            break
        end
    end
end)

-- Clean up when player leaves
RegisterNetEvent('QBCore:Server:OnPlayerUnload', function(src)
    -- Remove player from any trunk they might be in
    for vehicleNetId, playerId in pairs(playersInTrunks) do
        if playerId == src then
            playersInTrunks[vehicleNetId] = nil
            print(('[qb-trunk] Player %s removed from trunk due to disconnect'):format(src))
            break
        end
    end
end)

-- Debug command to check trunk status (remove in production)
QBCore.Commands.Add('checktrunk', 'Check trunk status (Admin Only)', {}, false, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player.PlayerData.group == 'admin' then
        print('=== TRUNK STATUS ===')
        for vehicleNetId, playerId in pairs(playersInTrunks) do
            local player = QBCore.Functions.GetPlayer(playerId)
            if player then
                print(('Vehicle %s: %s (%s)'):format(vehicleNetId, player.PlayerData.name, player.PlayerData.citizenid))
            else
                print(('Vehicle %s: Player %s (OFFLINE - CLEANING UP)'):format(vehicleNetId, playerId))
                playersInTrunks[vehicleNetId] = nil
            end
        end
        print('==================')
        TriggerClientEvent('QBCore:Notify', src, 'Trunk status geprint in console', 'success')
    else
        TriggerClientEvent('QBCore:Notify', src, 'Je hebt geen toegang tot dit commando', 'error')
    end
end, 'admin')