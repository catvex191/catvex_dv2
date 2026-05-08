ESX = nil
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

RegisterCommand('dv2', function(source, args, rawCommand)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer then
        local group = xPlayer.getGroup()
        if group == 'superadmin' or group == 'admin' then
            TriggerClientEvent('testdv:attempt', source)
        else
            TriggerClientEvent('esx:showNotification', source, 'Du hast keine Berechtigung für diesen Befehl.')
        end
    else
        TriggerClientEvent('esx:showNotification', source, 'Spieler nicht gefunden.')
    end
end, false)


print("[🐈‍⬛ CatVex] Script gestartet ✅")