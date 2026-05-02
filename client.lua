ESX = nil

Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(0)
    end
end)

RegisterNetEvent('testdv:attempt')
AddEventHandler('testdv:attempt', function()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)

    local vehicle = nil

    -- Prüfen, ob Spieler im Fahrzeug sitzt
    if IsPedInAnyVehicle(playerPed, false) then
        vehicle = GetVehiclePedIsIn(playerPed, false)
    else
        -- Nächstes Fahrzeug in 10m Radius finden
        local vehicles = GetGamePool('CVehicle')
        local minDist = 10.0
        for _, veh in ipairs(vehicles) do
            if DoesEntityExist(veh) then
                local dist = #(playerCoords - GetEntityCoords(veh))
                if dist < minDist then
                    minDist = dist
                    vehicle = veh
                end
            end
        end
    end

    if vehicle and vehicle ~= 0 and DoesEntityExist(vehicle) then
        local wasInVehicle = IsPedInVehicle(playerPed, vehicle, false)

        -- Fahrzeugdaten speichern
        local vehicleProps = {}
        pcall(function()
            vehicleProps = ESX.Game.GetVehicleProperties(vehicle)
        end)
        
        local pos = GetEntityCoords(vehicle)
        local heading = GetEntityHeading(vehicle)
        local model = GetEntityModel(vehicle)

        -- Prüfen, ob das Fahrzeug ein Geisterfahrzeug ist
        local netId = VehToNet(vehicle)
        local isNetworked = NetworkGetEntityIsNetworked(vehicle)
        local netExists = NetworkDoesNetworkIdExist(netId)
        local isGhost = not isNetworked or not netExists

        if isGhost then
            ESX.ShowNotification('~y~Geisterfahrzeug erkannt! Wird entfernt...')
        else
            ESX.ShowNotification('~g~Fahrzeug wird neu gespawnt...')
        end

        -- Für Netzwerk-Fahrzeuge: RequestControl
        if isNetworked and netExists then
            NetworkRequestControlOfEntity(vehicle)
            local timeout = 0
            while not NetworkHasControlOfEntity(vehicle) and timeout < 100 do
                Citizen.Wait(10)
                timeout = timeout + 1
            end
        end

        -- Sicher löschen
        SetEntityAsMissionEntity(vehicle, true, true)
        Citizen.Wait(100)
        
        DeleteEntity(vehicle)
        Citizen.Wait(300)
        
        -- Erzwungenes Löschen
        local deleteTimeout = 0
        while DoesEntityExist(vehicle) and deleteTimeout < 100 do
            if NetworkGetEntityIsNetworked(vehicle) then
                NetworkRequestControlOfEntity(vehicle)
            end
            DeleteEntity(vehicle)
            Citizen.Wait(50)
            deleteTimeout = deleteTimeout + 1
        end

        if DoesEntityExist(vehicle) then
            ESX.ShowNotification('~r~Fahrzeug konnte nicht gelöscht werden!')
            return
        end

        Citizen.Wait(1500)

        -- Neu spawnen
        ESX.Game.SpawnVehicle(model, pos, heading, function(spawnedVehicle)
            if spawnedVehicle and DoesEntityExist(spawnedVehicle) then
                Citizen.Wait(300)

                -- Zustand wiederherstellen
                SetVehicleFixed(spawnedVehicle)
                SetVehicleDeformationFixed(spawnedVehicle)
                SetVehicleDirtLevel(spawnedVehicle, 0.0)
                
                -- Alle Fenster reparieren
                for window = 0, 3 do
                    SmashVehicleWindow(spawnedVehicle, window)
                    FixVehicleWindow(spawnedVehicle, window)
                end

                -- Reifen reparieren
                for tire = 0, 3 do
                    SetVehicleTyreBurst(spawnedVehicle, tire, false, 1000.0)
                end

                -- Treibstoff
                SetVehicleFuelLevel(spawnedVehicle, 100.0)

                -- Eigenschaften anwenden (mit Fehlerbehandlung)
                if vehicleProps and vehicleProps.model then
                    pcall(function()
                        ESX.Game.SetVehicleProperties(spawnedVehicle, vehicleProps)
                    end)
                end

                -- Netzwerk-Einstellungen
                SetNetworkIdCanMigrate(NetworkGetNetworkIdFromEntity(spawnedVehicle), true)
                SetEntityAsMissionEntity(spawnedVehicle, false, false)

                -- Spieler wieder hineinsetzen
                if wasInVehicle then
                    Citizen.Wait(200)
                    if DoesEntityExist(spawnedVehicle) then
                        TaskWarpPedIntoVehicle(playerPed, spawnedVehicle, -1)
                    end
                end

                ESX.ShowNotification('~g~Fahrzeug erfolgreich respawned.')
            else
                ESX.ShowNotification('~r~Fehler beim Spawnen des Fahrzeug!')
            end
        end)
    else
        ESX.ShowNotification('~r~Kein Fahrzeug in der Nähe gefunden.')
    end
end)