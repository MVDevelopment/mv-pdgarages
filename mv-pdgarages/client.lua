local TDC = exports['qb-core']:GetCoreObject()
local spawnedVehicles = {}

CreateThread(function()
    local garageZones = {}
    for i = 1, #Config.vehicles do
        local v = Config.vehicles[i]
        garageZones[#garageZones + 1] = BoxZone:Create(
            v.coords, 3, 3, {
                name = 'box_zone',
                debugPoly = false,
                minZ = v.coords.z - 1,
                maxZ = v.coords.z + 1,
            }
        )
    end

    local garageCombo = ComboZone:Create(garageZones, { name = 'garageCombo', debugPoly = false })
    garageCombo:onPlayerInOut(function(isPointInside, point)
        if isPointInside then
            inGarage = true
            local PlayerJob = TDC.Functions.GetPlayerData().job
            if PlayerJob.type == 'leo' and PlayerJob.onduty then
                local currentGarage = nil
                for _, garage in pairs(Config.vehicles) do
                    if #(point - garage.coords) < 4 then
                        currentGarage = garage
                        break
                    end
                end

                if currentGarage then
                    if not currentGarage.command then
                        exports['qb-core']:DrawText('[E] GARAGE', 'left')
                        CreateThread(function()
                            while inGarage do
                                Wait(0)
                                if IsControlJustPressed(0, 38) then
                                    if IsPedInAnyVehicle(PlayerPedId(), false) then
                                        garage()
                                    else
                                        local menu = {}
                                        local playerGrade = TDC.Functions.GetPlayerData().job.grade.level

                                        for _, vehicleData in ipairs({
                                            {label = "Crown Victoria", vehicle = 'npolvic', grade = {0,1,2,3,4,5,6,7,8,9,10,11}},
                                            {label = "Ford Explorer", vehicle = 'npolexp', grade = {2,3,4,5,6,7,8,9,10,11}},
                                            {label = "Prison Bus", vehicle = 'npolcoach', grade = {3,4,5,6,7,8,9,10,11}},
                                            {label = "Police Bike", vehicle = 'npolmm', grade = {1,2,3,4,5,6,7,8,9,10,11}},
                                            {label = "Chevrolet Corvette", vehicle = 'npolvette', grade = {4,5,6,7,8,9,10,11}},
                                            {label = "Ford Mustang", vehicle = 'npolstang', grade = {4,5,6,7,8,9,10,11}},
                                            {label = "Dodge Challenger", vehicle = 'npolchal', grade = {2,3,4,5,6,7,8,9,10,11}},
                                            {label = "Dodge Charger", vehicle = 'npolchar', grade = {4,5,6,7,8,9,10,11}}
                                        }) do
                                            for _, grade in ipairs(vehicleData.grade) do
                                                if playerGrade == grade then
                                                    local menu2 = { label = vehicleData.label, color = "primary", action = "tcc-lspdjob:vehicle:spawn", triggertype = "client", value = { vehicle = vehicleData.vehicle, grade = vehicleData.grade } }

                                                    if spawnedVehicles and spawnedVehicles[vehicleData.vehicle] then
                                                        local vehEnt = spawnedVehicles[vehicleData.vehicle]
                                                        menu2.subMenu = {{ label = 'Върни в гараж', action = 'tcc-lspdjob:vehicle:return', triggertype = 'client', value = {vehicle = vehicleData.vehicle, entity = vehEnt} }}
                                                    end

                                                    table.insert(menu, menu2)
                                                    break
                                                end
                                            end
                                        end

                                        TriggerEvent('mv-interact:generateMenu', menu, '<b>POLICE DEPARTMENT</b><br>ГАРАЖ')
                                    end
                                end
                            end
                        end)
                    else
                        exports['qb-core']:HideText()
                    end
                end
            end
        else
            inGarage = false
            exports['qb-core']:HideText()
        end
    end)
end)

local function garage()
    CreateThread(function()
        while true do
            Citizen.Wait(0)
            local PlayerJob = TDC.Functions.GetPlayerData().job
            if inGarage and PlayerJob.type == 'leo' then
                if PlayerJob.onduty then sleep = 5 end
                if IsPedInAnyVehicle(PlayerPedId(), false) then
                    if IsControlJustReleased(0, 38) then
                        TDC.Functions.DeleteVehicle(GetVehiclePedIsIn(PlayerPedId()))
                        break
                    end
                end
            else
                break
            end
        end
    end)
end

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    PlayerJob = job
end)

RegisterNetEvent('tcc-lspdjob:vehicle:spawn', function(dacca)
    local vehicle = dacca.vehicle
    local PlayerData = TDC.Functions.GetPlayerData()
    local jobName = PlayerData.job.name
    local Grades = PlayerData.job.grade.level
    local grade = dacca.grade
    local spawned = false

    local playerPed = PlayerPedId()
    local playerPos = GetEntityCoords(playerPed)

    local closestGarage = nil
    local closestDist = math.huge

    for _, garage in pairs(Config.vehicles) do
        local dist = #(playerPos - garage.coords)
        if dist < closestDist then
            closestDist = dist
            closestGarage = garage
        end
    end

    if closestGarage then
        for _, spot in pairs(closestGarage.spots) do
            local isUsed = TDC.Functions.SpawnClear(spot.coords, closestGarage.radius)
            if isUsed then
                for _, grade in pairs(grade) do
                    if Grades == grade then
                        TDC.Functions.SpawnVehicle(vehicle, function(veh)
                            local plate = TDC.Functions.GetPlate(veh)
                            SetEntityHeading(veh, spot.heading)
                            SetVehicleModKit(veh, 0)

                            if vehicle == "npolvic" then
                                local livery = 0
                                if jobName == "police" then
                                    livery = 12
                                elseif jobName == "bcso" then
                                    livery = 2
                                end

                                SetVehicleMod(veh, 48, livery, false)
                                SetVehicleColours(veh, 112, 0) -- primary color
                                SetVehicleModColor_1(veh, 0, 112, 0)
                                SetVehicleModColor_2(veh, 0, 0)
                                SetVehicleInteriorColor(veh, 0) -- black
                                SetVehicleMod(veh, 16, 4, false) -- armor
                                SetVehicleMod(veh, 12, 2, false) -- brakes
                                SetVehicleMod(veh, 11, 3, false) -- engine
                                SetVehicleWindowTint(veh, 1) -- tint

                                local callsign = tostring(LocalPlayer.state.callsign or "569")
                                local chislo1 = tonumber(callsign:sub(1, 1))
                                local chislo2 = tonumber(callsign:sub(2, 2))
                                local chislo3 = tonumber(callsign:sub(3, 3))

                                SetVehicleMod(veh, 42, chislo1, false) -- chislo 1
                                SetVehicleMod(veh, 44, chislo2, false) -- chislo 2
                                SetVehicleMod(veh, 45, chislo3, false) -- chislo 3

                                for i = 1, 12 do
                                    if DoesExtraExist(veh, i) then
                                        SetVehicleExtra(veh, i, 0) -- sirens
                                    end
                                end
                            end

                            if vehicle == "npolexp" then
                                local livery = 0
                                if jobName == "police" then
                                    livery = 9
                                elseif jobName == "bcso" then
                                    livery = 2
                                end

                                SetVehicleMod(veh, 48, livery, false)
                                SetVehicleColours(veh, 112, 0) -- primary color
                                SetVehicleModColor_1(veh, 0, 112, 0)
                                SetVehicleModColor_2(veh, 0, 0)
                                SetVehicleInteriorColor(veh, 0) -- black
                                SetVehicleMod(veh, 16, 4, false) -- armor
                                SetVehicleMod(veh, 12, 2, false) -- brakes
                                SetVehicleMod(veh, 11, 3, false) -- engine
                                SetVehicleWindowTint(veh, 1) -- tint

                                local callsign = tostring(LocalPlayer.state.callsign or "569")
                                local chislo1 = tonumber(callsign:sub(1, 1))
                                local chislo2 = tonumber(callsign:sub(2, 2))
                                local chislo3 = tonumber(callsign:sub(3, 3))

                                SetVehicleMod(veh, 42, chislo1, false) -- chislo 1
                                SetVehicleMod(veh, 44, chislo2, false) -- chislo 2
                                SetVehicleMod(veh, 45, chislo3, false) -- chislo 3

                                for i = 1, 12 do
                                    if DoesExtraExist(veh, i) then
                                        SetVehicleExtra(veh, i, 0) -- sirens
                                    end
                                end
                            end

                            if vehicle == "npolmm" then
                                local livery = 0
                                if jobName == "police" then
                                    livery = 0
                                elseif jobName == "bcso" then
                                    livery = 1
                                end

                                SetVehicleMod(veh, 48, livery, false)
                                SetVehicleMod(veh, 16, 4, false) -- armor
                                SetVehicleMod(veh, 12, 2, false) -- brakes
                                SetVehicleMod(veh, 11, 3, false) -- engine
                            end

                            if vehicle == "npolvette" then
                                local livery = 0
                                if jobName == "police" then
                                    livery = 2
                                elseif jobName == "bcso" then
                                    livery = 1
                                end

                                SetVehicleMod(veh, 48, livery, false)
                                SetVehicleColours(veh, 112, 0) -- primary color
                                SetVehicleModColor_1(veh, 0, 112, 0)
                                SetVehicleModColor_2(veh, 0, 0)
                                SetVehicleInteriorColor(veh, 0) -- black
                                SetVehicleMod(veh, 16, 4, false) -- armor
                                SetVehicleMod(veh, 12, 2, false) -- brakes
                                SetVehicleMod(veh, 11, 3, false) -- engine
                                SetVehicleWindowTint(veh, 1) -- tint

                                local callsign = tostring(LocalPlayer.state.callsign or "569")
                                local chislo1 = tonumber(callsign:sub(1, 1))
                                local chislo2 = tonumber(callsign:sub(2, 2))
                                local chislo3 = tonumber(callsign:sub(3, 3))

                                SetVehicleMod(veh, 42, chislo1, false) -- chislo 1
                                SetVehicleMod(veh, 44, chislo2, false) -- chislo 2
                                SetVehicleMod(veh, 45, chislo3, false) -- chislo 3

                                for i = 1, 12 do
                                    if DoesExtraExist(veh, i) then
                                        SetVehicleExtra(veh, i, 0) -- sirens
                                    end
                                end
                            end

                            if vehicle == "npolstang" then
                                local livery = 0
                                if jobName == "police" then
                                    livery = 2
                                elseif jobName == "bcso" then
                                    livery = 1
                                end

                                SetVehicleMod(veh, 48, livery, false)
                                SetVehicleColours(veh, 112, 0) -- primary color
                                SetVehicleModColor_1(veh, 0, 112, 0)
                                SetVehicleModColor_2(veh, 0, 0)
                                SetVehicleInteriorColor(veh, 0) -- black
                                SetVehicleMod(veh, 16, 4, false) -- armor
                                SetVehicleMod(veh, 12, 2, false) -- brakes
                                SetVehicleMod(veh, 11, 3, false) -- engine
                                SetVehicleWindowTint(veh, 1) -- tint

                                local callsign = tostring(LocalPlayer.state.callsign or "569")
                                local chislo1 = tonumber(callsign:sub(1, 1))
                                local chislo2 = tonumber(callsign:sub(2, 2))
                                local chislo3 = tonumber(callsign:sub(3, 3))

                                SetVehicleMod(veh, 42, chislo1, false) -- chislo 1
                                SetVehicleMod(veh, 44, chislo2, false) -- chislo 2
                                SetVehicleMod(veh, 45, chislo3, false) -- chislo 3

                                for i = 1, 12 do
                                    if DoesExtraExist(veh, i) then
                                        SetVehicleExtra(veh, i, 0) -- sirens
                                    end
                                end
                            end

                            if vehicle == "npolchal" then
                                local livery = 0
                                if jobName == "police" then
                                    livery = 2
                                elseif jobName == "bcso" then
                                    livery = 1
                                end

                                SetVehicleMod(veh, 48, livery, false)
                                SetVehicleColours(veh, 112, 0) -- primary color
                                SetVehicleModColor_1(veh, 0, 112, 0)
                                SetVehicleModColor_2(veh, 0, 0)
                                SetVehicleInteriorColor(veh, 0) -- black
                                SetVehicleMod(veh, 16, 4, false) -- armor
                                SetVehicleMod(veh, 12, 2, false) -- brakes
                                SetVehicleMod(veh, 11, 3, false) -- engine
                                SetVehicleWindowTint(veh, 1) -- tint

                                local callsign = tostring(LocalPlayer.state.callsign or "569")
                                local chislo1 = tonumber(callsign:sub(1, 1))
                                local chislo2 = tonumber(callsign:sub(2, 2))
                                local chislo3 = tonumber(callsign:sub(3, 3))

                                SetVehicleMod(veh, 42, chislo1, false)
                                SetVehicleMod(veh, 44, chislo2, false)
                                SetVehicleMod(veh, 45, chislo3, false)

                                for i = 1, 12 do
                                    if DoesExtraExist(veh, i) then
                                        SetVehicleExtra(veh, i, 0) -- sirens
                                    end
                                end
                            end

                            if vehicle == "npolchar" then
                                local livery = 0
                                if jobName == "police" then
                                    livery = 6
                                elseif jobName == "bcso" then
                                    livery = 1
                                end

                                SetVehicleMod(veh, 48, livery, false)
                                SetVehicleColours(veh, 112, 0) -- primary color
                                SetVehicleModColor_1(veh, 0, 112, 0)
                                SetVehicleModColor_2(veh, 0, 0)
                                SetVehicleInteriorColor(veh, 0) -- black
                                SetVehicleMod(veh, 16, 4, false) -- armor
                                SetVehicleMod(veh, 12, 2, false) -- brakes
                                SetVehicleMod(veh, 11, 3, false) -- engine
                                SetVehicleWindowTint(veh, 1) -- tint

                                local callsign = tostring(LocalPlayer.state.callsign or "569")
                                local chislo1 = tonumber(callsign:sub(1, 1))
                                local chislo2 = tonumber(callsign:sub(2, 2))
                                local chislo3 = tonumber(callsign:sub(3, 3))

                                SetVehicleMod(veh, 42, chislo1, false) -- chislo 1
                                SetVehicleMod(veh, 44, chislo2, false) -- chislo 2
                                SetVehicleMod(veh, 45, chislo3, false) -- chislo 3

                                for i = 1, 12 do
                                    if DoesExtraExist(veh, i) then
                                        SetVehicleExtra(veh, i, 0) -- sirens
                                    end
                                end
                            end

                            TriggerEvent("vehiclekeys:client:SetOwner", plate)
                            TriggerServerEvent('tcc-policejob:server:SaveVehicle', plate, vehicle)
                        end, spot.coords, true)
                        spawned = true
                        spawnedVehicles[vehicle] = true
                        break
                    end
                end
            end
            if spawned then break end
        end
    end

    if not spawned then
        TDC.Functions.Notify('ВСИЧКИ ПАРКОМЕСТА СА ЗАЕТИ', 'error')
    end
end)

RegisterNetEvent('tcc-lspdjob:vehicle:return', function(data)
    local vehicle = spawnedVehicles[data.vehicle]
    if vehicle and DoesEntityExist(vehicle) then
        DeleteVehicle(vehicle)
    end
    spawnedVehicles[data.vehicle] = nil
end)