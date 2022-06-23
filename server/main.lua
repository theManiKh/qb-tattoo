local QBCore = exports['qb-core']:GetCoreObject()

QBCore.Functions.CreateCallback('qb-tattooshop:GetPlayerTattoos', function(source, cb)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if Player then
        MySQL.query('SELECT tattoos FROM players WHERE citizenid = @citizenid', {
            ['@citizenid'] = Player.PlayerData.citizenid
        }, function(result)
            if result[1].tattoos then
                cb(json.decode(result[1].tattoos))
            else
                cb()
            end
        end)
    else
        cb()
    end
end)

QBCore.Functions.CreateCallback('qb-tattooshop:PurchaseTattoo', function(source, cb, tattooList, price, tattoo)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if Player.PlayerData.money.cash >= price then
        Player.Functions.RemoveMoney('cash', price)
        TriggerClientEvent('QBCore:Notify', source, "You bought a tattoo", "success")

        table.insert(tattooList, tattoo)

        MySQL.query('UPDATE players SET tattoos = @tattoos WHERE citizenid = @citizenid', {
            ['@tattoos'] = json.encode(tattooList),
            ['@citizenid'] = Player.PlayerData.citizenid
        })
        cb(true)
        TriggerClientEvent('qb-tattoo:server:settattos', source, tattooList)
    else
        cb(false)
        TriggerClientEvent('qb-tattoo:server:settattos', source, tattooList)
        TriggerClientEvent('QBCore:Notify', source, "not enough cash", "error")
    end
end)

RegisterNetEvent('qb-tattooshop:server:RemoveTattoo', function(tattooList)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    MySQL.query('UPDATE players SET tattoos = @tattoos WHERE citizenid = @citizenid', {
        ['@tattoos'] = json.encode(tattooList),
        ['@citizenid'] = Player.PlayerData.citizenid
    })
end)


RegisterNetEvent('qb-tattooshop:server:SelectTattoos', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    MySQL.query('SELECT tattoos FROM players WHERE citizenid = @citizenid', {
        ['@citizenid'] = Player.PlayerData.citizenid
    }, function(result)
        if result[1].tattoos then
            local tats = json.decode(result[1].tattoos)
            TriggerClientEvent('qb-tattoo:server:settattos', src, tats)
        end
    end)
end)