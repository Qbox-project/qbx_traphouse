local QBCore = exports['qb-core']:GetCoreObject()
local PlayerData = {}
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
local traphouseInteraction = nil
local traphouseExit = nil
local traphouseEntranceTarget = nil

-- Functions
local function RegisterTraphouseEntranceTarget(traphouseID, traphouseData)
    local coords = traphouseData.coords['enter']
    local boxData = traphouseData.boxData['enter']

    traphouseEntranceTarget = exports.ox_target:addBoxZone({
        coords = coords,
        size = vec3(2, 2, 2),
        rotation = boxData.heading,
        options = {
            {
                name = 'qb-traphouse:entrance',
                event = 'qb-traphouse:client:EnterTraphouse',
                icon = "fa-solid fa-door-open",
                label = Lang:t('targetInfo.enter'),
                distance = boxData.distance
            }
        }
    })

    Config.TrapHouses[traphouseID].boxData['enter'].created = true
end

local function RegisterTraphouseEntranceZone(traphouseData)
    local coords = traphouseData.coords['enter']
    local boxData = traphouseData.boxData['enter']
    local zone = lib.zones.box({
        coords = coords,
        size = vec3(2, 2, 2),
        rotation = boxData.heading,
        onEnter = function(_)
            isInsideEntranceTarget = true

            lib.showTextUI('[E] - ' .. Lang:t('targetInfo.enter'), 'left')
        end,
        onExit = function(_)
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
            if traphouse and traphouse.coords and traphouse.coords['enter'] then
                if Config.UseTarget then
                    RegisterTraphouseEntranceTarget(id, traphouse)
                else
                    RegisterTraphouseEntranceZone(traphouse)
                end
            end
        end
    end
end

local function RegisterTraphouseInteractionZone(traphouseData)
    local coords = traphouseData.coords['interaction']
    local boxData = traphouseData.boxData['interaction']
    local zone = lib.zones.box({
        coords = coords,
        size = vec3(2, 2, 2),
        rotation = boxData.heading,
        onEnter = function(_)
            isInsideInteractionTarget = true

            lib.showTextUI('[E] - ' .. Lang:t('targetInfo.options'), 'left')
        end,
        onExit = function(_)
            isInsideInteractionTarget = false

            lib.hideTextUI()
            lib.hideContext()
        end
    })

    boxData.created = true
    boxData.zone = zone
end

local function RegisterTraphouseInteractionTarget(traphouseData)
    local coords = traphouseData.coords['interaction']
    local boxData = traphouseData.boxData['interaction']
    local options = {
        {
            name = 'qb-traphouse:takeOver',
            event = "qb-traphouse:client:target:TakeOver",
            label = Lang:t("targetInfo.take_over")
        }
    }

    if IsKeyHolder then
        options = {
            {
                name = 'qb-traphouse:viewInventory',
                icon = "fa-solid fa-box-open",
                label = Lang:t("targetInfo.inventory"),
                distance = boxData.distance,
                onSelect = function(data)
                    TriggerEvent("qb-traphouse:client:target:ViewInventory", data)
                end,
                traphouseData = traphouseData
            },
            {
                name = 'qb-traphouse:takeMoney',
                icon = "fa-solid fa-money-bill",
                event = "qb-traphouse:client:target:TakeMoney",
                label = Lang:t('targetInfo.take_cash', {
                    value = traphouseData.money
                }),
                distance = boxData.distance
            }
        }

        if IsHouseOwner then
            options[#options + 1] = {
                name = 'qb-traphouse:pinCode',
                icon = "fa-solid fa-key",
                label = Lang:t("targetInfo.pin_code_see"),
                distance = boxData.distance,
                onSelect = function(data)
                    TriggerEvent("qb-traphouse:client:target:SeePinCode", data)
                end,
                traphouseData = traphouseData
            }
        end
    end

    traphouseInteraction = exports.ox_target:addBoxZone({
        coords = coords,
        size = vec3(2, 2, 2),
        rotation = boxData.heading,
        options = options
    })

    boxData.created = true
end

local function RegisterTraphouseExitZone(coords, traphouseData)
    local boxData = traphouseData.boxData['exit']
    local zone = lib.zones.box({
        coords = coords,
        size = vec3(2, 2, 2),
        rotation = boxData.heading,
        onEnter = function(_)
            isInsideExitTarget = true

            lib.showTextUI('[E] - ' .. Lang:t("targetInfo.leave"), 'left')
        end,
        onExit = function(_)
            isInsideExitTarget = false

            lib.hideTextUI()
        end
    })

    boxData.created = true
    boxData.zone = zone
end

local function RegisterTraphouseExitTarget(coords, traphouseID, traphouseData)
    local boxData = traphouseData.boxData.exit

    traphouseExit = exports.ox_target:addBoxZone({
        coords = coords,
        size = vec3(2, 2, 2),
        rotation = boxData.heading,
        options = {
            {
                name = 'qb-traphouse:exit',
                icon = "fa-solid fa-door-open",
                distance = boxData.distance,
                label = Lang:t("targetInfo.leave"),
                onSelect = function(_)
                    TriggerEvent('qb-traphouse:client:target:ExitTraphouse', traphouseID)
                end
            }
        }
    })

    boxData.created = true
end

local function OpenHeaderMenu(data)
    local headerMenu = {}

    if IsKeyHolder then
        headerMenu[#headerMenu + 1] = {
            title = Lang:t("targetInfo.inventory"),
            icon = "fa-solid fa-box-open",
            event = "qb-traphouse:client:target:ViewInventory",
            args = {
                traphouseData = data
            }
        }
        headerMenu[#headerMenu + 1] = {
            title = Lang:t('targetInfo.take_cash', {
                value = data.money
            }),
            icon = "fa-solid fa-money-bill",
            event = "qb-traphouse:client:target:TakeMoney"
        }

        if IsHouseOwner then
            headerMenu[#headerMenu + 1] = {
                title = Lang:t("targetInfo.pin_code_see"),
                icon = "fa-solid fa-lock",
                event = "qb-traphouse:client:target:SeePinCode",
                args = {
                    traphouseData = data
                }
            }
        end
    else
        headerMenu[#headerMenu + 1] = {
            title = Lang:t("targetInfo.take_over"),
            icon = "fa-solid fa-key",
            event = "qb-traphouse:client:target:TakeOver"
        }
    end

    lib.registerContext({
        id = 'open_traphouseHeader',
        title = Lang:t("targetInfo.options"),
        options = headerMenu
    })
    lib.showContext('open_traphouseHeader')
end

local function HasKey(CitizenId)
    local haskey = false

    if ClosestTraphouse then
        if Config.TrapHouses[ClosestTraphouse].keyholders and next(Config.TrapHouses[ClosestTraphouse].keyholders) then
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

    if ClosestTraphouse then
        if Config.TrapHouses[ClosestTraphouse].keyholders  and next(Config.TrapHouses[ClosestTraphouse].keyholders) then
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

    for id, data in pairs(Config.TrapHouses) do
        if current then
            if #(pos - data.coords.enter) < dist then
                current = id
                dist = #(pos - data.coords.enter)
            end
        else
            dist = #(pos - data.coords.enter)
            current = id
        end
    end

    ClosestTraphouse = current
    IsKeyHolder = HasKey(PlayerData.citizenid)
    IsHouseOwner = IsOwner(PlayerData.citizenid)
end

local function EnterTraphouse(data)
    local coords = {
        x = data.coords.enter.x,
        y = data.coords.enter.y,
        z = data.coords.enter.z - Config.MinZOffset
    }

    TriggerServerEvent("InteractSound_SV:PlayOnSource", "houses_door_open", 0.25)

    data = exports['qb-interior']:CreateTrevorsShell(coords)
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

    exports['qb-interior']:DespawnInterior(TraphouseObj, function()
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
        exports.ox_target:removeZone(traphouseInteraction)

        data.boxData.interaction.created = false

        exports.ox_target:removeZone(traphouseExit)

        data.boxData.exit.created = false
    else
        if Config.TrapHouses[k] and Config.TrapHouses[k].boxData.interaction and Config.TrapHouses[k].boxData.interaction.zone then
            Config.TrapHouses[k].boxData.interaction.zone:remove()
            Config.TrapHouses[k].boxData.interaction.created = false
            Config.TrapHouses[k].boxData.interaction.zone = nil
        end

        if Config.TrapHouses[k] and Config.TrapHouses[k].boxData['exit'] and Config.TrapHouses[k].boxData.exit.zone then
            Config.TrapHouses[k].boxData.exit.zone:remove()
            Config.TrapHouses[k].boxData.exit.created = false
            Config.TrapHouses[k].boxData.exit.zone = nil
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
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
end)

RegisterNetEvent('qb-traphouse:client:EnterTraphouse', function()
    if ClosestTraphouse then
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
            combat = true
        }
    }) then
        TriggerServerEvent('qb-traphouse:server:AddHouseKeyHolder', PlayerData.citizenid, TraphouseId, true)
    else
        lib.notify({
            description = Lang:t("error.cancelled"),
            type = 'error'
        })
    end
end)

RegisterNetEvent('qb-traphouse:client:target:ViewInventory', function(data)
    local TraphouseInventory = {}

    TraphouseInventory.label = "traphouse_" .. CurrentTraphouse
    TraphouseInventory.items = data.traphouseData.inventory
    TraphouseInventory.slots = 2

    TriggerServerEvent("inventory:server:OpenInventory", "traphouse", CurrentTraphouse, TraphouseInventory)
end)

RegisterNetEvent('qb-traphouse:client:target:TakeOver', function()
    TriggerServerEvent('qb-traphouse:server:TakeoverHouse', CurrentTraphouse)
end)

RegisterNetEvent('qb-traphouse:client:target:TakeMoney', function()
    TriggerServerEvent("qb-traphouse:server:TakeMoney", CurrentTraphouse)
end)

RegisterNetEvent('qb-traphouse:client:target:SeePinCode', function(data)
    lib.notify({
        description = Lang:t('info.pin_code', {
            value = data.traphouseData.pincode
        })
    })
end)

RegisterNetEvent('qb-traphouse:client:target:ExitTraphouse', function(traphouseID)
    LeaveTraphouse(traphouseID, Config.TrapHouses[traphouseID])
end)

RegisterNetEvent('qb-traphouse:client:SyncData', function(k, data)
    Config.TrapHouses[k] = data

    IsKeyHolder = HasKey(PlayerData.citizenid)
    IsHouseOwner = IsOwner(PlayerData.citizenid)

    if Config.UseTarget then
        exports.ox_target:removeZone(traphouseEntranceTarget)

        Config.TrapHouses[k].boxData['interaction'].created = false
    else
        if Config.TrapHouses[k] and Config.TrapHouses[k].boxData['interaction'] and Config.TrapHouses[k].boxData['interaction'].zone then
            Config.TrapHouses[k].boxData['interaction'].zone:remove()
            Config.TrapHouses[k].boxData['interaction'].created = false
            Config.TrapHouses[k].boxData['interaction'].zone = nil
        end

        isInsideInteractionTarget = false
    end
end)

-- NUI
RegisterNUICallback('PinpadClose', function(_, cb)
    SetNuiFocus(false, false)

    cb('ok')
end)

RegisterNUICallback('ErrorMessage', function(data, cb)
    lib.notify({
        description = data.message,
        type = 'error'
    })

    cb('ok')
end)

RegisterNUICallback('EnterPincode', function(d, cb)
    local data = Config.TrapHouses[ClosestTraphouse]

    if tonumber(d.pin) == data.pincode then
        EnterTraphouse(data)
    else
        lib.notify({
            description = Lang:t("error.incorrect_code"),
            type = 'error'
        })
    end

    cb('ok')
end)

-- Threads
CreateThread(function()
    while true do
        local aiming, targetPed = GetEntityPlayerIsFreeAimingAt(cache.playerId)

        if targetPed ~= 0 and not IsPedAPlayer(targetPed) then
            local pos = GetEntityCoords(cache.ped)

            if ClosestTraphouse then
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

                                local dict = 'random@mugging3'

                                lib.requestAnimDict(dict)

                                SetEveryoneIgnorePlayer(cache.playerId, true)
                                TaskStandStill(targetPed, RobbingTime * 1000)
                                FreezeEntityPosition(targetPed, true)
                                SetBlockingOfNonTemporaryEvents(targetPed, true)
                                TaskPlayAnim(targetPed, dict, 'handsup_standing_base', 2.0, -2, 15.0, 1, 0, 0, 0, 0)
                                RemoveAnimDict(dict)

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

        Wait(0)
    end
end)

CreateThread(function()
    local wait = 500

    while not LocalPlayer.state.isLoggedIn do
        Wait(wait)
    end

    SetTraphouseEntranceTargets()

    if QBCore.Functions.GetPlayerData() then
        PlayerData = QBCore.Functions.GetPlayerData()
    end

    while true do
        wait = 500

        SetClosestTraphouse()

        if ClosestTraphouse then
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

                if not data.boxData['exit'].created then
                    local exitCoords = vec3(data.coords.enter.x + POIOffsets.exit.x, data.coords.enter.y + POIOffsets.exit.y, data.coords.enter.z - Config.MinZOffset + POIOffsets.exit.z)

                    if Config.UseTarget then
                        RegisterTraphouseExitTarget(exitCoords, CurrentTraphouse, data)
                    else
                        RegisterTraphouseExitZone(exitCoords, data)
                    end
                end

                if not data.boxData['interaction'].created then
                    if Config.UseTarget then
                        RegisterTraphouseInteractionTarget(data)
                    else
                        RegisterTraphouseInteractionZone(data)
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