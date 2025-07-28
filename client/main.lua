local QBCore = exports['qb-core']:GetCoreObject()
local PlayerData = {}
local isInTrunk = false
local currentVehicle = nil

-- Get player data on resource start
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    PlayerData = {}
end)

RegisterNetEvent('QBCore:Player:SetPlayerData', function(val)
    PlayerData = val
end)

-- Function to check if vehicle model is blacklisted
local function IsVehicleBlacklisted(vehicle)
    local model = GetEntityModel(vehicle)
    local modelName = string.lower(GetDisplayNameFromVehicleModel(model))
    
    for _, blacklistedModel in pairs(Config.BlacklistedVehicles) do
        if string.lower(blacklistedModel) == modelName then
            return true
        end
    end
    return false
end

-- Function to check if vehicle is empty
local function IsVehicleEmpty(vehicle)
    for i = -1, GetVehicleMaxNumberOfPassengers(vehicle) - 1 do
        if GetPedInVehicleSeat(vehicle, i) ~= 0 then
            return false
        end
    end
    return true
end

-- Function to get trunk position
local function GetTrunkPosition(vehicle)
    local min, max = GetModelDimensions(GetEntityModel(vehicle))
    local trunkOffset = GetOffsetFromEntityInWorldCoords(vehicle, 0.0, min.y - 0.5, 0.0)
    return trunkOffset
end

-- Function to find a safe exit position behind the vehicle
local function GetSafeExitPosition(vehicle)
    local vehicleCoords = GetEntityCoords(vehicle)
    
    -- Use GetOffsetFromEntityInWorldCoords to ensure we always get the position behind the vehicle
    -- Y offset of -5.0 means 5 meters behind the vehicle (negative Y is behind)
    local behindPos = GetOffsetFromEntityInWorldCoords(vehicle, 0.0, -5.0, 0.0)
    
    -- Get ground Z coordinate
    local groundZ = behindPos.z
    local foundGround, groundCoord = GetGroundZFor_3dCoord(behindPos.x, behindPos.y, behindPos.z + 2.0, false)
    if foundGround then
        groundZ = groundCoord
    end
    
    return vector3(behindPos.x, behindPos.y, groundZ + 1.0)
end

-- Function to check if player is near vehicle trunk and return the closest one
local function IsNearVehicleTrunk()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local vehicles = QBCore.Functions.GetVehicles()
    local closestVehicle = nil
    local closestDistance = Config.InteractionDistance + 1.0 -- Start with distance beyond interaction range
    
    for _, vehicle in pairs(vehicles) do
        if DoesEntityExist(vehicle) then
            local trunkPos = GetTrunkPosition(vehicle)
            local distance = #(coords - trunkPos)
            
            -- Check if vehicle is within interaction distance and closer than previous vehicles
            if distance <= Config.InteractionDistance and distance < closestDistance then
                closestVehicle = vehicle
                closestDistance = distance
            end
        end
    end
    
    return closestVehicle or false
end

-- Function to disable ox_inventory completely and combat
local function DisableInventoryAndCombat()
    -- Disable inventory opening
    LocalPlayer.state.invBusy = true
    
    -- Disable inventory hotkeys
    LocalPlayer.state.invHotkeys = false
    
    -- Close inventory if it's currently open
    exports.ox_inventory:closeInventory()
    
    -- Disable weapon use while in trunk
    LocalPlayer.state.canUseWeapons = false
end

-- Function to enable ox_inventory and combat
local function EnableInventoryAndCombat()
    -- Enable inventory opening
    LocalPlayer.state.invBusy = false
    
    -- Enable inventory hotkeys
    LocalPlayer.state.invHotkeys = true
    
    -- Enable weapon use
    LocalPlayer.state.canUseWeapons = true
end

-- Function to enter trunk (exported for radialmenu)
local function EnterTrunk()
    local ped = PlayerPedId()
    
    -- Check if player is in a vehicle
    if IsPedInAnyVehicle(ped, false) then
        QBCore.Functions.Notify(Config.Text.MustBeOutsideVehicle, 'error')
        return
    end
    
    local vehicle = IsNearVehicleTrunk()
    
    if not vehicle then
        QBCore.Functions.Notify('Je staat niet bij een kofferbak!', 'error')
        return
    end
    
    if not DoesEntityExist(vehicle) then
        QBCore.Functions.Notify('Voertuig bestaat niet!', 'error')
        return
    end
    
    -- Check if vehicle is blacklisted
    if IsVehicleBlacklisted(vehicle) then
        QBCore.Functions.Notify(Config.Text.VehicleBlacklisted, 'error')
        return
    end
    
    -- Check if vehicle is locked
    if GetVehicleDoorLockStatus(vehicle) ~= 0 and GetVehicleDoorLockStatus(vehicle) ~= 1 then
        QBCore.Functions.Notify(Config.Text.VehicleLocked, 'error')
        return
    end
    
    if not IsVehicleEmpty(vehicle) then
        QBCore.Functions.Notify('Er zit nog iemand in de auto!', 'error')
        return
    end
    
    -- Check if someone is already in trunk (server-side check)
    QBCore.Functions.TriggerCallback('qb-trunk:server:canEnterTrunk', function(canEnter, message)
        if not canEnter then
            QBCore.Functions.Notify(message, 'error')
            return
        end
        
        -- Load animation
        RequestAnimDict(Config.EnterAnimation.dict)
        while not HasAnimDictLoaded(Config.EnterAnimation.dict) do
            Wait(10)
        end
        
        -- Open trunk
        SetVehicleDoorOpen(vehicle, 5, false, false)
        
        -- Start progress bar
        if lib.progressCircle({
            duration = Config.ProgressBarDuration,
            position = 'bottom',
            useWhileDead = false,
            canCancel = true,
            disable = {
                car = true,
                move = true,
                combat = true
            },
            anim = {
                dict = Config.EnterAnimation.dict,
                clip = Config.EnterAnimation.clip
            },
            label = Config.Text.ProgressText
        }) then
            -- Progress completed, put player in trunk
            local ped = PlayerPedId()
            currentVehicle = vehicle
            isInTrunk = true
            
            -- Notify server that player entered trunk
            TriggerServerEvent('qb-trunk:server:enterTrunk', NetworkGetNetworkIdFromEntity(vehicle))
            
            -- Set player invisible and freeze
            SetEntityVisible(ped, false, false)
            FreezeEntityPosition(ped, true)
            
            -- Attach player to vehicle
            AttachEntityToEntity(ped, vehicle, 0, 0.0, -2.0, 0.5, 0.0, 0.0, 0.0, false, false, false, false, 20, true)
            
            -- Close trunk
            SetVehicleDoorShut(vehicle, 5, false)
            
            -- Disable inventory completely and combat
            DisableInventoryAndCombat()
            
            -- Start trunk loop
            TrunkLoop()
            
            QBCore.Functions.Notify('Je zit nu in de kofferbak', 'success')
        else
            -- Progress cancelled, close trunk
            SetVehicleDoorShut(vehicle, 5, false)
        end
    end, NetworkGetNetworkIdFromEntity(vehicle))
end

-- Function to exit trunk
local function ExitTrunk()
    if not currentVehicle or not DoesEntityExist(currentVehicle) then
        return
    end
    
    -- Check if vehicle is moving
    local speed = GetEntitySpeed(currentVehicle)
    if speed > 0.1 then
        QBCore.Functions.Notify(Config.Text.VehicleMoving, 'error')
        return -- Don't change any state, just return early
    end
    
    local ped = PlayerPedId()
    
    -- Store vehicle reference before clearing currentVehicle
    local exitVehicle = currentVehicle
    
    -- Reset variables ONLY when actually exiting (after speed check passes)
    isInTrunk = false
    currentVehicle = nil
    
    -- Hide text UI immediately
    lib.hideTextUI()
    
    -- Notify server that player is exiting trunk
    TriggerServerEvent('qb-trunk:server:exitTrunk', NetworkGetNetworkIdFromEntity(exitVehicle))
    
    -- Open trunk
    SetVehicleDoorOpen(exitVehicle, 5, false, false)
    
    -- Get safe exit position
    local safePos = GetSafeExitPosition(exitVehicle)
    
    -- Detach and reposition player
    DetachEntity(ped, true, true)
    SetEntityVelocity(ped, 0.0, 0.0, 0.0)
    SetPedCoordsKeepVehicle(ped, safePos.x, safePos.y, safePos.z)
    
    -- Re-enable player state
    SetEntityInvincible(ped, false)
    SetEntityCanBeDamaged(ped, true)
    SetEntityVisible(ped, true, false)
    FreezeEntityPosition(ped, false)
    SetEntityCollision(ped, true, true)
    
    -- Enable inventory and combat
    EnableInventoryAndCombat()
    
    -- Handle trunk closing with proper timing
    CreateThread(function()
        -- Wait for player to be fully positioned
        Wait(200)
        
        -- Ensure collision is stable
        for i = 1, 5 do
            SetEntityCollision(ped, true, true)
            Wait(50)
        end
        
        -- Close trunk
        if DoesEntityExist(exitVehicle) then
            SetVehicleDoorShut(exitVehicle, 5, false)
        end
    end)
    
    QBCore.Functions.Notify('Je bent uit de kofferbak gegaan', 'success')
end

-- Trunk loop for controls
function TrunkLoop()
    CreateThread(function()
        while isInTrunk do
            -- Show exit text UI
            lib.showTextUI(Config.Text.ExitTrunk)
            
            -- Disable all combat controls and make player invulnerable
            local ped = PlayerPedId()
            
            -- Disable all attack controls
            DisableControlAction(0, 24, true) -- Attack
            DisableControlAction(0, 25, true) -- Aim
            DisableControlAction(0, 47, true) -- Weapon
            DisableControlAction(0, 58, true) -- Weapon
            DisableControlAction(0, 140, true) -- Melee Attack Light
            DisableControlAction(0, 141, true) -- Melee Attack Heavy
            DisableControlAction(0, 142, true) -- Melee Attack Alternate
            DisableControlAction(0, 143, true) -- Melee Block
            DisableControlAction(0, 263, true) -- Melee Attack 1
            DisableControlAction(0, 264, true) -- Melee Attack 2
            DisableControlAction(0, 257, true) -- Attack 2
            
            -- Disable weapon wheel
            DisableControlAction(0, 37, true) -- Weapon Wheel
            
            -- Make player invulnerable to damage
            SetEntityInvincible(ped, true)
            
            -- Disable PED from being targeted
            SetEntityCanBeDamaged(ped, false)
            
            -- Check for exit key
            if IsControlJustPressed(0, 38) then -- E key
                ExitTrunk() -- Don't hide TextUI here, let ExitTrunk handle it
            end
            
            -- Check if vehicle still exists
            if not DoesEntityExist(currentVehicle) then
                -- Vehicle deleted, force exit
                DetachEntity(ped, true, true)
                SetEntityVisible(ped, true, false)
                FreezeEntityPosition(ped, false)
                
                -- Re-enable damage and vulnerability
                SetEntityInvincible(ped, false)
                SetEntityCanBeDamaged(ped, true)
                
                isInTrunk = false
                currentVehicle = nil
                
                -- Enable inventory and combat again
                EnableInventoryAndCombat()
                
                lib.hideTextUI()
                
                -- Notify server about forced exit
                TriggerServerEvent('qb-trunk:server:forcedExit')
                break
            end
            
            Wait(0)
        end
    end)
end

-- Event to handle radialmenu trigger
RegisterNetEvent('qb-trunk:client:enterTrunk', function()
    EnterTrunk()
end)

-- Export function for radialmenu
exports('EnterTrunk', EnterTrunk)
exports('IsNearVehicleTrunk', IsNearVehicleTrunk)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        if isInTrunk then
            ExitTrunk()
        end
        lib.hideTextUI()
        -- Make sure inventory and combat is enabled when resource stops
        EnableInventoryAndCombat()
    end
end)