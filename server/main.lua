local shopVehicles = {}
local hasSpawned = false

local function AddToTable(entity, netid, data)
    local mods = nil
    local owner = nil
    local miles = 0    
    local result = MySQL.query.await("SELECT * FROM "..sql.table.." WHERE plate = ?", {data.plate})[1]
    if result ~= nil then 
        if Config.Framework == 'esx' then
            owner = result.owner
        elseif Config.Framework == 'qb' or Config.Framework == 'qbx' then
            owner = result.citizenid
        end
        mods = json.decode(result.mods)
        miles = tonumber(result.drivingdistance)
    end
    shopVehicles[data.plate] = {
        netid = netid,
        shop_id = data.shop_id,
        shop_price = data.shop_price,
        shop_coords = data.shop_coords,                
        citizenid = owner,
        phone = data.phone,
        fullname = data.fullname,
        plate = data.plate,
        fuel = data.fuel,
        body = data.body,
        engine = data.engine,
        drivingdistance = miles,
        mods = mods,   
        model = Config.Vehicles[GetEntityModel(entity)].model,
        brand = Config.Vehicles[GetEntityModel(entity)].brand,
        type = Config.Vehicles[GetEntityModel(entity)].type, 
    }
end

local function IsShopOwner(citizenid)
    for i = 1, #Config.Cardealers, 1 do
        if Config.Cardealers[i].owner == citizenid then return true end        
    end
    return false
end

local function GetOwnerShopData(citizenid)
    for i = 1, #Config.Cardealers, 1 do
        if Config.Cardealers[i].owner == citizenid then 
            return Config.Cardealers[i] 
        end        
    end
    return nil
end

local function DeleteVehicleByShopId(shopId)
    local vehicles = GetGamePool('CVehicle')
    for i = 1, #vehicles, 1 do
        if DoesEntityExist(vehicles[i]) then
            local plate = GetPlate(vehicles[i])
            local parked = MySQL.query.await("SELECT * FROM "..sql.table.." WHERE shop_id = ? AND plate = ? AND "..sql.state.." = ?", {shopId, plate, 3})[1]
            if parked == nil then
                local vehicle = MySQL.query.await("SELECT * FROM "..sql.table.." WHERE shop_id = ? AND plate = ?", {shopId, plate})[1]
                if vehicle ~= nil and vehicle.plate == plate then
                    DeleteEntity(vehicles[i])
                    while DoesEntityExist(vehicles[i]) do
                        DeleteEntity(vehicles[i])
                        Wait(0)
                    end
                    vehicles[i] = nil
                end
            end
        end
    end
    MySQL.Async.execute('UPDATE '..sql.table..' SET '..sql.state..' = ?, shop_id = ?, shop_price = ?, shop_coords = ? WHERE shop_id = ?',  {1, 0, 0, 0, shopId})
end

local function DeleteCarDealer(src, data)
    if IsAdmin(src) then
        local citizenid = GetCitizenId(src)
        local fullname = GetCitizenFullname(src)
        if data.status == true then
            local path = GetResourcePath(GetCurrentResourceName())
            path = path:gsub('//', '/') .. '/shared/cardealers/' .. data.id .. '.lua'
            local file = io.open(path, 'r')
            if file ~= nil then
                local coords = Config.Cardealers[data.id].coords
                file:close()
                os.remove(path)
                DeleteVehicleByShopId(data.id)
                SendLogToDiscord('SYSTEM', "Citizenid: "..citizenid .. " - ".. fullname.. ' - just deleted a [CARDEALER] with id '..data.id..' at location `/tp '..coords.x..' '..coords.y..' '.. coords.z..'`')
                table.remove(Config.Cardealers, data.id)
                TriggerClientEvent('mh-cardealer:client:removeZone', -1 , {status = true, zoneid = data.id})
            end
        end
    else
        Notify(src, "No Access!", "error", 5000)
    end
end

local function CreateVehicle2(model, type, coords, heading)
    if heading == nil then heading = coords.w end
    local veh = CreateVehicleServerSetter(model, type, coords.x, coords.y, coords.z + 1, heading)
    local netId = NetworkGetNetworkIdFromEntity(veh)
    return veh, netId
end

local function DeleteAllShopVehicles()
    local vehicles = GetGamePool('CVehicle')
    for i = 1, #vehicles, 1 do
        if DoesEntityExist(vehicles[i]) then
            local plate = GetPlate(vehicles[i])
            local parked = MySQL.query.await("SELECT * FROM "..sql.table.." WHERE plate = ? AND "..sql.state.." = ?", {plate, 3})[1]
            if parked == nil then
                local vehicle = MySQL.query.await("SELECT * FROM "..sql.table.." WHERE plate = ? AND "..sql.state.." = ?", {plate, 0})[1]
                if vehicle == nil then
                    if (GetPedInVehicleSeat(vehicles[i], -1) == 0) then
                        DeleteEntity(vehicles[i])
                        while DoesEntityExist(vehicles[i]) do
                            DeleteEntity(vehicles[i])
                            vehicles[i] = nil
                            Wait(0)
                        end
                    end
                end
            end
        end
    end
end

local function SpawnShopVehicles(src)
    hasSpawned = true
    shopVehicles = {}
    local vehicles = MySQL.query.await("SELECT * FROM "..sql.table.."")
    if type(vehicles) == 'table' and #vehicles >= 1 then
        DeleteAllShopVehicles()
        for k, vehicle in pairs(vehicles) do
            if vehicle.shop_id ~= 0 and vehicle.shop_price ~= 0 and vehicle.shop_coords ~= 0 then
                local days = CalculateDays(os.time(), Config.Cardealers[vehicle.shop_id].created_time)
                if days >= Config.DaysCardealerExist then
                    Config.Cardealers[vehicle.shop_id] = nil
                    DeleteCarDealer(src, {status = true, id = tonumber(vehicle.shop_id)})
                    return
                else
                    if not shopVehicles[vehicle.plate] then      
                        Wait(500)
                        local coords = json.decode(vehicle.shop_coords)
                        local _type = Config.Vehicles[GetHashKey(vehicle.vehicle)].type
                        local entity, netid = CreateVehicle2(GetHashKey(vehicle.vehicle), _type, coords, coords.w)
                        while not DoesEntityExist(entity) do Wait(0) end
                        local netid = NetworkGetNetworkIdFromEntity(entity)
                        local mods = json.decode(vehicle.mods)
                        SetVehicleNumberPlateText(entity, mods.plate)
                        local phone = GetPlayerPhoneNumber(src)
                        vehicle.phone = phone
                        local fullname = GetCitizenFullname(src)
                        vehicle.fullname = fullname
                        AddToTable(entity, netid, vehicle)
                    end
                end
            end
        end
        if #shopVehicles >= 1 then
            TriggerClientEvent("mh-cardealer:client:onjoin", -1, {status = true, vehicles = shopVehicles})
        end
    end
end

RegisterCommand("admincardealer", function(source, args, rawCommand)
    local src = source
    if IsAdmin(src) then TriggerClientEvent('mh-cardealer:client:OpenMainMenu', src) end
end, true)

RegisterServerEvent('mh-cardealer:server:setforsale', function(data)
    local src = source
    local citizenid = GetCitizenId(src)
    if IsShopOwner(citizenid) then
        local result = MySQL.query.await("SELECT * FROM "..sql.table.." WHERE "..sql.owner.." = ? AND plate = ?", {citizenid, data.plate})[1]
        if result ~= nil then
            MySQL.Async.execute("UPDATE "..sql.table.." SET "..sql.state.." = ?, shop_id = ?, shop_price = ?, shop_coords = ? WHERE plate = ? AND "..sql.owner.." = ?",  {
                4, data.shop_id, data.shop_price, json.encode(data.shop_coords), data.plate, citizenid
            })
            local result1 = MySQL.query.await("SELECT * FROM "..sql.table.." WHERE "..sql.owner.." = ? AND plate = ?", {citizenid, data.plate})[1]
            if result1 ~= nil then
                local vehicle = NetworkGetEntityFromNetworkId(data.netid)
                if result1.fullname == nil then result1.fullname = GetCitizenFullname(src) end
                if result1.phone == nil then result1.phone = GetPlayerPhoneNumber(src) end
                AddToTable(vehicle, data.netid, result1)
                if shopVehicles[data.plate] then
                    shopVehicles[data.plate].shop_id = data.shop_id
                    shopVehicles[data.plate].shop_price = data.shop_price
                    shopVehicles[data.plate].shop_coords = data.shop_coords
                end
                TriggerClientEvent("mh-cardealer:client:addVehicle", -1, {status = true, vehicle = shopVehicles[data.plate]})
                Notify(src, 'The vehicle with number plate ('..data.plate..') is added for sale!', "success", 5000)
            end
        end
    else
        Notify(src, 'You are not the owner of this cardealer...!', "error", 5000)
    end
end)

RegisterServerEvent('mh-cardealer:server:cancelSale', function(data)
    local src = source
    local citizenid = GetCitizenId(src)
    if data.citizenid == citizenid then
        local vehicle = NetworkGetEntityFromNetworkId(data.netid)
        if DoesEntityExist(vehicle) then
            MySQL.Async.execute('UPDATE '..sql.table..' SET '..sql.state..' = ?, shop_id = ?, shop_price = ?, shop_coords = ? WHERE plate = ? AND '..sql.owner..' = ?',  {0, 0, 0, 0, data.plate, data.citizenid})
            TaskWarpPedIntoVehicle(GetPlayerPed(src), vehicle, -1)
            TriggerClientEvent('mh-cardealer:client:removeVehicle', -1, {statue = true, netid = data.netid, plate = data.plate})
        end
    else
        Notify(src, "You are not the owner of this vehicle....", "error", 5000)
    end
end)

RegisterServerEvent('mh-cardealer:server:buyVehicle', function(data)
    local src = source
    local Player = GetPlayer(src)
    if data.citizenid ~= Player.PlayerData.citizenid then
        local moneyType = 'cash'
        if Config.Framework == 'esx' then moneyType = 'money' end
        local money = GetMoney(src, moneyType)
        if money >= data.shop_price then
            if RemoveMoney(src, moneyType, data.shop_price, 'buy-vehicle') then
                MySQL.Async.execute('UPDATE '..sql.table..' SET '..sql.state..' = ?, '..sql.owner..' = ?, shop_id = ?, shop_price = ?, shop_coords = ? WHERE plate = ? AND '..sql.owner..' = ?',  {0, Player.PlayerData.citizenid, 0, 0, 0, data.plate, data.citizenid })
                local vehicle = NetworkGetEntityFromNetworkId(data.netid)
                if DoesEntityExist(vehicle) then
                    TaskWarpPedIntoVehicle(GetPlayerPed(src), vehicle, -1)
                    TriggerClientEvent('mh-cardealer:client:removeVehicle', -1, {statue = true, netid = data.netid, plate = data.plate})
                end
            end
        else
            Notify(src, "You have no cash....", "error", 5000)
        end
    else
        Notify(src, "You can not buy your own vehicle....", "error", 5000)
    end
end)

RegisterServerEvent('mh-cardealer:server:onjoin', function()
    local src = source
    local players = GetActivePlayers()
    if #players <= 1 then
        if not hasSpawned then
            hasSpawned = true
            SpawnShopVehicles(src)
        end
    elseif #players > 1 then
        if not hasSpawned then
            hasSpawned = true
            SpawnShopVehicles(#players)
        end
    end
    TriggerClientEvent("mh-cardealer:client:onjoin", -1, {status = true, vehicles = shopVehicles})
end)

RegisterServerEvent('mh-cardealer:server:delete-cardealer', function(data)
    local src = source
    if IsAdmin(src) and data.status == true then
        if data.id ~= nil then
            DeleteCarDealer(src, {status = true, id = tonumber(data.id)})
            TriggerClientEvent('mh-cardealer:client:delete-blip', -1, {status = true, id = data.id})
        elseif data.id == nil then
            Notify(src, "No id found...", "error", 5000)
        end
    else
        Notify(src, "No Access!", "error", 5000)
    end 
end)

RegisterServerEvent('mh-cardealer:server:CreateCardealer', function(data)
    local src = source
    if data.status == true then
        local citizenid = GetCitizenId(src)
        if not IsShopOwner(citizenid) then
            local count = #Config.Cardealers + 1
            local phone = GetPlayerPhoneNumber(src)
            local fullname = GetCitizenFullname(src)     
            if Config.SaveCardealersToFile then
                local path = GetResourcePath(GetCurrentResourceName())
                path = path:gsub('//', '/') .. '/shared/cardealers/' .. count .. '.lua'
                local file = io.open(path, 'a+')
                local shaper1 = ""
                for k, v in pairs(data.cardealer.shape) do shaper1 = shaper1 .. '            vector2('..v.x..', '..v.y..'),\n' end
                local shaper = 'shape = {\n'
                shaper = shaper ..''.. shaper1..''
                shaper = shaper .. '        },\n'
                local label = 'Config.Cardealers[' .. count .. '] = {\n' .. 
                '    id = ' .. count .. ',\n' ..
                '    label = "Cardealer ' .. count .. '",\n' ..
                '    owner = "' .. citizenid .. '",\n' ..
                '    fullname = "' .. fullname .. '",\n' ..
                '    phone = "' .. phone .. '",\n' ..
                '    created_time = ' .. os.time() .. ',\n' ..
                '    coords = vector4(' .. data.cardealer.blip.x .. ', ' .. data.cardealer.blip.y .. ', ' .. data.cardealer.blip.z - 1.0 ..', 0.0),\n' ..
                '    blip = {sprite = 782, color = 2},\n' ..
                '    zone = {\n' ..
                '        name = "' .. count .. '_zone_vehicleshop",\n'..
                '        '..shaper..''..
                '        minZ = ' .. data.cardealer.minZ .. ',\n' ..
                '        maxZ = ' .. data.cardealer.maxZ .. ',\n' ..
                '        debugPoly = Config.DebugPoly,\n' ..
                '    },\n'..
                '}\n'
                file:write(label)
                file:close()
            end
            local vectors = {}
            for k, v in pairs(data.cardealer.shape) do vectors[#vectors + 1] = vector2(v.x, v.y) end
            Config.Cardealers[count] = {
                id = count,
                label = "Cardealer "..count,
                owner = "" .. citizenid .. "",
                fullname = ""..fullname.."",
                phone = "" .. phone .. "",
                coords = vector4(data.cardealer.blip.x, data.cardealer.blip.y, data.cardealer.blip.z - 1.0, 0.0),
                blip = {sprite = 782, colour = 2},
                zone = {
                    name = count .. "_zone_vehicleshop",
                    shape = vectors,
                    minZ = data.cardealer.minZ,
                    maxZ = data.cardealer.maxZ,
                    debugPoly = Config.DebugPoly,
                },
            }
            TriggerClientEvent('mh-cardealer:client:UpdateCardealer', -1, {status = true, cardealer = Config.Cardealers[count]})
            SendLogToDiscord('SYSTEM', "Citizenid: "..citizenid .. " - ".. fullname.. ' - just created a [CARDEALER] With ID '..count..' at location `/tp '..data.cardealer.blip.x..' '..data.cardealer.blip.y..' '.. data.cardealer.blip.z..'`')
        else
            Notify(src, 'You already onwed a cardealer...', "error", 5000)
        end
    end
end)

CreateCallback('mh-cardealer:server:spawnvehicle', function(source, cb, model, coords, warp)
    local src = source
    local vehType = Config.Vehicles[GetHashKey(model)].type 
    local veh = CreateVehicleServerSetter(GetHashKey(model), vehType, coords.x, coords.y, coords.z, coords.w)
    local netId = NetworkGetNetworkIdFromEntity(veh)
    local plate = GetPlate(veh)
     SetVehicleNumberPlateText(veh, plate)
    if warp then TaskWarpPedIntoVehicle(GetPlayerPed(src), veh, -1) end
    cb(netId)
end)

CreateCallback("mh-cardealer:server:IsAdmin", function(source, cb)
    local src = source
    if IsAdmin(src) then
        cb({status = true, isadmin = true})
        return
    else
        cb({status = false, isadmin = false})
        return
    end
end)

CreateCallback("mh-cardealer:server:IsShopOwner", function(source, cb)
    local src = source
    local citizenid = GetCitizenId(src)
    if IsShopOwner(citizenid) then
        cb({status = true, isowner = true, data = GetOwnerShopData(citizenid)})
        return
    else
        cb({status = false, isowner = false})
        return
    end
end)

AddEventHandler('playerActivated', function()
    local src = source
    --SendLogToDiscord('SYSTEM', GetPlayerName(src) .. ' joined.')
end)

AddEventHandler('playerDropped', function(reason)
    local src = source
    --SendLogToDiscord('SYSTEM', GetPlayerName(src) .. ' left (' .. reason .. ')')
end)

RegisterCommand("uninstall-cardealer", function(source, args, rawCommand)
    if source > 0 then
        print("You can't use this command in F8 or in chat, you need to use the command in TxAdmin console.")
    else
        UnInstallDatabase()
        print("Database is uninstalled, now stop your server and delete the folder (mh-cardealer) from your server and start your server!")
    end
end, true)

RegisterCommand("install-cardealer", function(source, args, rawCommand)
    if source > 0 then
        print("You can't use this command in F8 or in chat, you need to use the command in TxAdmin console.")
    else
        InstallDatabase()
        print("Database installed, now restart your server!")
    end
end, true)