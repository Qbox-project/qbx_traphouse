local ClosestTraphouse = nil
local InsideTraphouse = false
local CurrentTraphouse = nil
local TraphouseObj = {}
local POIOffsets = nil
local IsKeyHolder = false
local IsHouseOwner = false
local CanRob = true
local IsRobbingNPC = false
local RobbingTime = 3

-- zone check
local isInsideEntranceTarget = false
local isInsideExitTarget = false
local isInsideInteractionTarget = false

-- Functions

local function RegisterTraphouseEntranceTarget(traphouseID, traphouseData)
    local coords = traphouseData.coords.enter
    local boxName = 'traphouseEntrance' .. traphouseID
    local boxData = traphouseData.polyzoneBoxData.enter
    exports.ox_target:addBoxZone({
        name = boxName,
        coords = coords,
        size = vec3(boxData.width, boxData.length, boxData.height),
        rotation = boxData.heading,
        debug = boxData.debug,
        options = {
            {
                icon = 'fa-solid fa-house',
                type = 'client',
                event = 'qb-traphouse:client:EnterTraphouse',
                label = Lang:t('targetInfo.enter'),
                distance = boxData.distance
            },
        },
        
    })

    Config.TrapHouses[traphouseID].polyzoneBoxData.enter.created = true
end

local function RegisterTraphouseEntranceZone(traphouseID, traphouseData)
    local coords = traphouseData.coords.enter
    local boxData = traphouseData.polyzoneBoxData.enter

    local zone = lib.zones.box({
        coords = coords,
        size = vec3(boxData.length, boxData.width, boxData.height),
        rotation = boxData.heading,
        debug = boxData.debug,
        onEnter = function()
            isInsideEntranceTarget = true
            lib.showTextUI('[E] ' .. Lang:t('targetInfo.enter'), {position = 'left-center'})
        end,
        onExit = function()
            isInsideEntranceTarget = false
            lib.hideTextUI()
        end
    })

    boxData.created = true
    boxData.zone = zone
end

local function SetTraphouseEntranceTargets()
    if Config.TrapHouses and next(Config.TrapHouses) then
        for id, traphouse in pairs(Config.TrapHouses) do
            if traphouse and traphouse.coords and traphouse.coords.enter then
                if Config.UseTarget then
                    RegisterTraphouseEntranceTarget(id, traphouse)
                else
                    RegisterTraphouseEntranceZone(id, traphouse)
                end
            end
        end
    end
end

local function RegisterTraphouseInteractionZone(traphouseID, traphouseData)
    local coords = traphouseData.coords.interaction
    local boxData = traphouseData.polyzoneBoxData.interaction

    local zone = lib.zones.box({
        coords = coords,
        size = vec3(boxData.length, boxData.width, boxData.height),
        rotation = boxData.heading,
        debug = boxData.debug,
        onEnter = function()
            isInsideInteractionTarget = true
            lib.showTextUI('[E] ' .. Lang:t('targetInfo.options'), {position = 'left-center'})
        end,
        onExit = function()
            isInsideInteractionTarget = false
            lib.hideTextUI()
        end
    })

    boxData.created = true
    boxData.zone = zone
end

local function RegisterTraphouseInteractionTarget(traphouseID, traphouseData)
    local coords = traphouseData.coords.interaction
    local boxName = 'traphouseInteraction' .. traphouseID
    local boxData = traphouseData.polyzoneBoxData.interaction
    
    local options = {
        {
            type = "client",
            event = "qb-traphouse:client:target:TakeOver",
            icon = 'fas fa-skull',
            label = Lang:t("targetInfo.take_over"),
        },
    }
    if IsKeyHolder then
        options = {
            {
                type = "client",
                event = "qb-traphouse:client:target:ViewInventory",
                icon = 'fas fa-boxes-stacked',
                label = Lang:t("targetInfo.inventory"),
            },
            {
                type = "client",
                event = "qb-traphouse:client:target:TakeMoney",
                icon = 'fas fa-sack-dollar',
                label = Lang:t('targetInfo.take_cash', {value = traphouseData.money}),
            },
        }

        if IsHouseOwner then
            options[#options+1] = {
                type = "client",
                event = "qb-traphouse:client:target:SeePinCode",
                icon = 'fas fa-key',
                label = Lang:t("targetInfo.pin_code_see"),
                traphouseData = traphouseData
            }
        end
    end

    exports.ox_target:addBoxZone({
        name = boxName,
        coords = coords,
        size = vec3(boxData.width, boxData.length, boxData.height),
        rotation = boxData.heading,
        debug = boxData.debug,
        options = options,
        distance = boxData.distance
    })


    boxData.created = true
end

local function RegisterTraphouseExitZone(coords, traphouseID, traphouseData)
    local boxData = traphouseData.polyzoneBoxData.exit

    local zone = lib.zones.box({
        coords = coords,
        size = vec3(boxData.length, boxData.width, boxData.height),
        rotation = boxData.heading,
        debug = boxData.debug,
        onEnter = function()
            isInsideExitTarget = true
            lib.showTextUI('[E] ' .. Lang:t('targetInfo.leave'), {position = 'left-center'})
        end,
        onExit = function()
            isInsideExitTarget = false
            lib.hideTextUI()
        end
    })

    boxData.created = true
    boxData.zone = zone
end

local function RegisterTraphouseExitTarget(coords, traphouseID, traphouseData)
    local boxName = 'traphouseExit' .. traphouseID
    local boxData = traphouseData.polyzoneBoxData.exit
    exports.ox_target:addBoxZone({
        name = boxName,
        coords = coords,
        size = vec3(boxData.width, boxData.length, boxData.height),
        rotation = boxData.heading,
        debug = boxData.debug,
        options = {
            {
                type = 'client',
                event = 'qb-traphouse:client:target:ExitTraphouse',
                icon = 'fa-solid fa-house-circle-xmark',
                label = Lang:t("targetInfo.leave"),
                traphouseID = traphouseID,
                distance = boxData.distance
            }
        }
    })

    boxData.created = true
end

local function OpenHeaderMenu(data)

    local options = {
        {
            event = "qb-traphouse:client:target:TakeOver",
            icon = 'fas fa-skull',
            title = Lang:t("targetInfo.take_over"),
            arrow = true
        },
    }
    if IsKeyHolder then
        options = {
            {
                event = "qb-traphouse:client:target:ViewInventory",
                icon = 'fas fa-boxes-stacked',
                title = Lang:t("targetInfo.inventory"),
                arrow = true,
            },
            {
                event = "qb-traphouse:client:target:TakeMoney",
                icon = 'fas fa-sack-dollar',
                title = Lang:t('targetInfo.take_cash', {value = data.money}),
                arrow = true
            },
        }

        if IsHouseOwner then
            options[#options+1] = {
                event = "qb-traphouse:client:target:SeePinCode",
                icon = 'fas fa-key',
                title = Lang:t("targetInfo.pin_code_see"),
                args = {
                    traphouseData = data
                }
            }
        end
    end
    
    lib.registerContext({
        id = 'traphouse',
        title = 'Options',
        options = options
    })
    lib.showContext("traphouse")

end

local function HasKey(CitizenId)
    local haskey = false
    if ClosestTraphouse ~= nil then
        if Config.TrapHouses[ClosestTraphouse].keyholders ~= nil and next(Config.TrapHouses[ClosestTraphouse].keyholders) ~= nil then
            for _, data in pairs(Config.TrapHouses[ClosestTraphouse].keyholders) do
                if data.citizenid == CitizenId then
                    haskey = true
                end
            end
        end
    end
    return haskey
end

local function IsOwner(CitizenId)
    local retval = false
    if ClosestTraphouse ~= nil then
        if Config.TrapHouses[ClosestTraphouse].keyholders ~= nil and next(Config.TrapHouses[ClosestTraphouse].keyholders) ~= nil then
            for _, data in pairs(Config.TrapHouses[ClosestTraphouse].keyholders) do
                if data.citizenid == CitizenId then
                    if data.owner then
                        retval = true
                    else
                        retval = false
                    end
                end
            end
        end
    end
    return retval
end

local function SetClosestTraphouse()
    local pos = GetEntityCoords(cache.ped, true)
    local current = nil
    local dist = nil
    for id, _ in pairs(Config.TrapHouses) do
        if current ~= nil then
            if #(pos - Config.TrapHouses[id].coords.enter) < dist then
                current = id
                dist = #(pos - Config.TrapHouses[id].coords.enter)
            end
        else
            dist = #(pos - Config.TrapHouses[id].coords.enter)
            current = id
        end
    end
    ClosestTraphouse = current
    IsKeyHolder = HasKey(QBX.PlayerData.citizenid)
    IsHouseOwner = IsOwner(QBX.PlayerData.citizenid)
end

local function EnterTraphouse(data)
    local coords = { x = data.coords.enter.x, y = data.coords.enter.y, z= data.coords.enter.z - Config.MinZOffset}
    TriggerServerEvent("InteractSound_SV:PlayOnSource", "houses_door_open", 0.25)
    data = exports['qbx_interior']:CreateTrevorsShell(coords)
    TraphouseObj = data[1]
    POIOffsets = data[2]
    CurrentTraphouse = ClosestTraphouse
    InsideTraphouse = true
    TriggerEvent('qb-weathersync:client:DisableSync')
    FreezeEntityPosition(TraphouseObj, true)
end

local function LeaveTraphouse(k, data)
    TriggerServerEvent("InteractSound_SV:PlayOnSource", "houses_door_open", 0.25)
    DoScreenFadeOut(250)
    Wait(250)
    exports['qbx_interior']:DespawnInterior(TraphouseObj, function()
        TriggerEvent('qb-weathersync:client:EnableSync')
        DoScreenFadeIn(250)
        SetEntityCoords(cache.ped, data.coords.enter.x, data.coords.enter.y, data.coords.enter.z + 0.5)
        SetEntityHeading(cache.ped, 107.71)
        TraphouseObj = nil
        POIOffsets = nil
        CurrentTraphouse = nil
        InsideTraphouse = false
    end)

    if Config.UseTarget then
        exports.ox_target:removeZone('traphouseInteraction' .. k)
        data.polyzoneBoxData.interaction.created = false

        exports.ox_target:removeZone('traphouseExit' .. k)
        data.polyzoneBoxData.exit.created = false
    else
        if Config.TrapHouses[k] and Config.TrapHouses[k].polyzoneBoxData.interaction and Config.TrapHouses[k].polyzoneBoxData.interaction.zone then
            Config.TrapHouses[k].polyzoneBoxData.interaction.zone:remove()
            Config.TrapHouses[k].polyzoneBoxData.interaction.created = false
            Config.TrapHouses[k].polyzoneBoxData.interaction.zone = nil
        end

        if Config.TrapHouses[k] and Config.TrapHouses[k].polyzoneBoxData.exit and Config.TrapHouses[k].polyzoneBoxData.exit.zone then
            Config.TrapHouses[k].polyzoneBoxData.exit.zone:remove()
            Config.TrapHouses[k].polyzoneBoxData.exit.created = false
            Config.TrapHouses[k].polyzoneBoxData.exit.zone = nil
        end

        isInsideExitTarget = false
        isInsideInteractionTarget = false
    end
end

local function RobTimeout(timeout)
    SetTimeout(timeout, function()
        CanRob = true
    end)
end

-- Events

RegisterNetEvent('qb-traphouse:client:EnterTraphouse', function()
    if ClosestTraphouse ~= nil then
        local data = Config.TrapHouses[ClosestTraphouse]
        if not IsKeyHolder then
            SendNUIMessage({
                action = "open"
            })
            SetNuiFocus(true, true)
        else
            EnterTraphouse(data)
        end
    end
end)

RegisterNetEvent('qb-traphouse:client:TakeoverHouse', function(TraphouseId)
    if lib.progressBar({
        duration = math.random(1000, 3000),
        label = Lang:t("info.taking_over"),
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            mouse = false,
            combat = true
        }
    }) then -- if completed
        TriggerServerEvent('qb-traphouse:server:AddHouseKeyHolder', QBX.PlayerData.citizenid, TraphouseId, true)
    else -- if canceled
        exports.qbx_core:Notify(Lang:t("error.cancelled"), "error")
    end
end)

RegisterNetEvent('qb-traphouse:client:target:ViewInventory', function ()
    for i = 1, #Config.TrapHouses do
        exports.ox_inventory:openInventory('stash', ('traphouse_%s'):format(i))
    end
end)

RegisterNetEvent('qb-traphouse:client:target:TakeOver', function ()
    TriggerServerEvent('qb-traphouse:server:TakeoverHouse', CurrentTraphouse)
end)

RegisterNetEvent('qb-traphouse:client:target:TakeMoney', function ()
    TriggerServerEvent("qb-traphouse:server:TakeMoney", CurrentTraphouse)
end)

RegisterNetEvent('qb-traphouse:client:target:SeePinCode', function (data)
    exports.qbx_core:Notify(Lang:t('info.pin_code', { value = data.traphouseData.pincode }))
end)

RegisterNetEvent('qb-traphouse:client:target:ExitTraphouse', function (data)
    LeaveTraphouse(data.traphouseID, Config.TrapHouses[data.traphouseID])
end)

RegisterNetEvent('qb-traphouse:client:SyncData', function(k, data)
    Config.TrapHouses[k] = data
    IsKeyHolder = HasKey(QBX.PlayerData.citizenid)
    IsHouseOwner = IsOwner(QBX.PlayerData.citizenid)

    if Config.UseTarget then
        exports.ox_target:removeZone('traphouseInteraction' .. k)
        Config.TrapHouses[k].polyzoneBoxData.interaction.created = false

        exports.ox_target:removeZone('traphouseExit' .. k)
        data.polyzoneBoxData.exit.created = false
    else
        if Config.TrapHouses[k] and Config.TrapHouses[k].polyzoneBoxData.interaction and Config.TrapHouses[k].polyzoneBoxData.interaction.zone then
            Config.TrapHouses[k].polyzoneBoxData.interaction.zone:remove()
            Config.TrapHouses[k].polyzoneBoxData.interaction.created = false
            Config.TrapHouses[k].polyzoneBoxData.interaction.zone = nil
        end

        if Config.TrapHouses[k] and Config.TrapHouses[k].polyzoneBoxData.exit and Config.TrapHouses[k].polyzoneBoxData.exit.zone then
            Config.TrapHouses[k].polyzoneBoxData.exit.zone:remove()
            Config.TrapHouses[k].polyzoneBoxData.exit.created = false
            Config.TrapHouses[k].polyzoneBoxData.exit.zone = nil
        end

        isInsideInteractionTarget = false
    end
end)

RegisterNetEvent('qb-traphouse:client:target:CloseMenu', function ()
    TriggerEvent('qb-menu:client:closeMenu')
end)


-- NUI

RegisterNUICallback('PinpadClose', function(_, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('ErrorMessage', function(data, cb)
    exports.qbx_core:Notify(data.message, 'error')
    cb('ok')
end)

RegisterNUICallback('EnterPincode', function(d, cb)
    local data = Config.TrapHouses[ClosestTraphouse]
    if tonumber(d.pin) == data.pincode then
        EnterTraphouse(data)
    else
        exports.qbx_core:Notify(Lang:t("error.incorrect_code"), 'error')
    end
    cb('ok')
end)

-- Threads

CreateThread(function()
    while true do
        local aiming, targetPed = GetEntityPlayerIsFreeAimingAt(PlayerId(-1))
        if targetPed ~= 0 and not IsPedAPlayer(targetPed) then
            local pos = GetEntityCoords(cache.ped)
            if ClosestTraphouse ~= nil then
                local data = Config.TrapHouses[ClosestTraphouse]
                local dist = #(pos - data.coords.enter)
                if dist < 200 then
                    if aiming then
                        local pcoords = GetEntityCoords(targetPed)
                        local peddist = #(pos - pcoords)
                        local InDistance = false
                        if peddist < 4 then
                            InDistance = true
                            if not IsRobbingNPC and CanRob then
                                if IsPedInAnyVehicle(targetPed) then
                                    TaskLeaveVehicle(targetPed, GetVehiclePedIsIn(targetPed), 1)
                                end
                                Wait(500)
                                InDistance = true

                                lib.requestAnimDict('random@mugging3')

                                SetEveryoneIgnorePlayer(cache.playerId, true)
                                TaskStandStill(targetPed, RobbingTime * 1000)
                                FreezeEntityPosition(targetPed, true)
                                SetBlockingOfNonTemporaryEvents(targetPed, true)
                                TaskPlayAnim(targetPed, 'random@mugging3', 'handsup_standing_base', 2.0, -2, 15.0, 1, 0, 0, 0, 0)
                                for _ = 1, RobbingTime / 2, 1 do
                                    PlayPedAmbientSpeechNative(targetPed, "GUN_BEG", "SPEECH_PARAMS_FORCE_NORMAL_CLEAR")
                                    Wait(2000)
                                end
                                FreezeEntityPosition(targetPed, true)
                                IsRobbingNPC = true
                                SetTimeout(RobbingTime, function()
                                    IsRobbingNPC = false
                                    RobTimeout(math.random(30000, 60000))
                                    if not IsEntityDead(targetPed) then
                                        if CanRob then
                                            if InDistance then
                                                SetEveryoneIgnorePlayer(cache.playerId, false)
                                                SetBlockingOfNonTemporaryEvents(targetPed, false)
                                                FreezeEntityPosition(targetPed, false)
                                                ClearPedTasks(targetPed)
                                                AddShockingEventAtPosition(99, GetEntityCoords(targetPed), 0.5)
                                                TriggerServerEvent('qb-traphouse:server:RobNpc', ClosestTraphouse)
                                                CanRob = false
                                            end
                                        end
                                    end
                                end)
                            end
                        else
                            if InDistance then
                                InDistance = false
                            end
                        end
                    end
                end
            else
                Wait(1000)
            end
        end
        Wait(3)
    end
end)

CreateThread(function ()
    local wait = 500
    while not LocalPlayer.state.isLoggedIn do
        -- do nothing
        Wait(wait)
    end

    SetTraphouseEntranceTargets()

    while true do
        wait = 500
        SetClosestTraphouse()

        if ClosestTraphouse ~= nil then
            if not InsideTraphouse then
                if isInsideEntranceTarget then
                    wait = 0
                    if IsControlJustPressed(0, 38) then
                        TriggerEvent("qb-traphouse:client:EnterTraphouse")
                        lib.hideTextUI()
                    end
                end
            else
                local data = Config.TrapHouses[ClosestTraphouse]
                if not data.polyzoneBoxData.exit.created then
                    local exitCoords = vector3(data.coords.enter.x + POIOffsets.exit.x, data.coords.enter.y + POIOffsets.exit.y, data.coords.enter.z - Config.MinZOffset + POIOffsets.exit.z)
                    if Config.UseTarget then
                        RegisterTraphouseExitTarget(exitCoords, CurrentTraphouse, data)
                    else
                        RegisterTraphouseExitZone(exitCoords, CurrentTraphouse, data)
                    end
                end

                if not data.polyzoneBoxData.interaction.created then
                    if Config.UseTarget then
                        RegisterTraphouseInteractionTarget(CurrentTraphouse, data)
                    else
                        RegisterTraphouseInteractionZone(CurrentTraphouse, data)
                    end
                end

                if isInsideExitTarget then
                    wait = 0
                    if IsControlJustPressed(0, 38) then
                        LeaveTraphouse(ClosestTraphouse, data)
                        lib.hideTextUI()
                    end
                end

                if isInsideInteractionTarget then
                    wait = 0
                    if IsControlJustPressed(0, 38) then
                        OpenHeaderMenu(data)
                        lib.hideTextUI()
                    end
                end
            end
        end
        Wait(wait)
    end

end)
