Framework, CreateCallback, AddCommand = nil, nil, nil
sql, ply = {}, {}

if Config.Framework == "esx" then
    Framework = exports['es_extended']:getSharedObject()
    CreateCallback = Framework.RegisterServerCallback
    AddCommand = Framework.RegisterCommand

    sql = {table = "owned_vehicles", owner = "owner", state = "stored"}
    ply = {table = "users", owner = "identifier"}

    function GetPlayers()
        return Framework.Players
    end

    function GetPlayer(source)
        return Framework.GetPlayerFromId(source)
    end

    function GetJob(source)
        return Framework.GetPlayerFromId(source).job
    end

    function GetCitizenId(src)
        local xPlayer = GetPlayer(src)
        return xPlayer.identifier
    end

    function GetCitizenFullname(src)
        local xPlayer = GetPlayer(src)
        return xPlayer.name
    end

elseif Config.Framework == "qb" then
    Framework = exports['qb-core']:GetCoreObject()
    CreateCallback = Framework.Functions.CreateCallback
    AddCommand = Framework.Commands.Add

    sql = {table = "player_vehicles", owner = "citizenid", state = "state"}
    ply = {table = "players", owner = "citizenid"}

    function GetPlayers()
        return Framework.Players
    end

    function GetPlayer(source)
        return Framework.Functions.GetPlayer(source)
    end

    function GetJob(source)
        return Framework.Functions.GetPlayer(source).PlayerData.job
    end

    function GetPlayerDataByCitizenId(citizenid)
        return Framework.Functions.GetPlayerByCitizenId(citizenid) or Framework.Functions.GetOfflinePlayerByCitizenId(citizenid)
    end

    function GetPlayerPhoneNumber(source)
        local Player = Framework.Functions.GetPlayer(source)
        local info = Player.PlayerData.charinfo
        return info.phone
    end

    function GetCitizenId(src)
        local xPlayer = Framework.Functions.GetPlayer(src)
        return xPlayer.PlayerData.citizenid
    end

    function GetMoney(src, type)
        local Player = Framework.Functions.GetPlayer(src)
        return Player.Runctions.GetMoney(type)
    end

    function RemoveMoney(src, type, amount, reason)
        local Player = Framework.Functions.GetPlayer(src)
        return Player.Runctions.RemoveMoney(type, amount, reason)
    end

    function GetCitizenFullname(src)
        local Player = Framework.Functions.GetPlayer(src)
        return Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
    end

elseif Config.Framework == "qbx" then
    Framework = exports['qb-core']:GetCoreObject()
    CreateCallback = Framework.Functions.CreateCallback
    AddCommand = Framework.Commands.Add

    sql = {table = "player_vehicles", owner = "citizenid", state = "state"}
    ply = {table = "players", owner = "citizenid"}

    function GetPlayers()
        return Framework.Players
    end

    function GetPlayer(source)
        return Framework.Functions.GetPlayer(source)
    end

    function GetJob(source)
        return Framework.Functions.GetPlayer(source).PlayerData.job
    end

    function GetPlayerDataByCitizenId(citizenid)
        return Framework.Functions.GetPlayerByCitizenId(citizenid) or Framework.Functions.GetOfflinePlayerByCitizenId(citizenid)
    end

    function GetCitizenId(src)
        local xPlayer = Framework.Functions.GetPlayer(src)
        return xPlayer.PlayerData.citizenid
    end

    function GetMoney(src, type)
        local Player = Framework.Functions.GetPlayer(src)
        return Player.Runctions.GetMoney(type)
    end

    function RemoveMoney(src, type, amount, reason)
        local Player = Framework.Functions.GetPlayer(src)
        return Player.Runctions.RemoveMoney(type, amount, reason)
    end

    function GetCitizenFullname(src)
        local xPlayer = Framework.Functions.GetPlayer(src)
        return xPlayer.PlayerData.charinfo.firstname .. ' ' .. xPlayer.PlayerData.charinfo.lastname
    end

end

function IsAdmin(src)
    if IsPlayerAceAllowed(src, 'admin') or IsPlayerAceAllowed(src, 'command') then return true end
    return false
end

function Notify(src, message, type, length)
    TriggerClientEvent('mh-cardealer:client:notify', src, {status = true, message = message, type = type, length = length})
end

function SendLogToDiscord(name, message)
    if Config.DiscordLink == nil or name == nil or name == '' or message == nil or message == '' then return end
    PerformHttpRequest(Config.DiscordLink, function(err, text, headers) end, 'POST', json.encode({username = name, content = message}), { ['Content-Type'] = 'application/json' })
end