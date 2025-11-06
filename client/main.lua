local shopVehicles = {}
local shopZones = {}
local blips = {}
local isLoggedIn = false
local inzone = false
local haspressed = false
local isGettingOut = false
local lastVehicle = nil
local lastLocation = nil
local lastHeading = nil
local isInTestRit = false
currentShopId = nil

local function DoesPlateExsist(plate)
    for i = 1, #shopVehicles, 1 do
        if shopVehicles[i].plate == plate then return true end
    end
    return false
end

local function GetVehicleData(plate)
    for i = 1, #shopVehicles, 1 do
        if shopVehicles[i].plate == plate then return shopVehicles[i] end
    end
    return nil
end

local function driveTimer(entity)
    local drivetime = 120000
    local driving = true
    isInTestRit = true
    local lastVehicle = entity
    while driving do
        if drivetime > 0 then drivetime = drivetime - 1000 end
        if drivetime <= 0 then driving = false end
        Wait(1000)
    end
    isInTestRit = false
    isGettingOut = true
    SetEntityCoords(lastVehicle, lastLocation, false, false, false, true)
    SetEntityHeading(lastVehicle, lastHeading)
    Wait(1000)
    FreezeEntityPosition(lastVehicle, true) 
    Wait(1000)
    SetFuel(lastVehicle, 100.0)
    DoVehicleDamage(entity, 1000.0, 1000.0)
    SetVehicleEngineOn(lastVehicle, false, false, true)
    TaskLeaveVehicle(PlayerPedId(), lastVehicle, 1)
    Wait(1500)
    isGettingOut = false
    lastVehicle = nil
    lastLocation = nil
    lastHeading = nil
    driving = false
end

local function OpenMenu(data)
    local engine = tonumber(data.engine / 10)
    local body = tonumber(data.body / 10)
    local drivingdistance = data.drivingdistance or 0
    local price = math.floor(data.shop_price)
    local options = {}

    options[#options + 1] = {
        title = FirstToUpper(data.brand) .. " " .. FirstToUpper(data.model),
        description = "Body: "..body.."%\nEngine: "..engine.."%\nMile(s): "..drivingdistance.."\nPrice: "..Config.MoneySign..price.."\n",
        arrow = false,
        onSelect = function()
        end
    }

    options[#options + 1] = {
        title = 'Test Rit',
        description = '',
        arrow = false,
        onSelect = function()
            local tmp = GetVehicleData(data.plate)
            lastLocation = GetEntityCoords(tmp.entity)
            lastHeading = GetEntityHeading(tmp.entity)
            TaskWarpPedIntoVehicle(PlayerPedId(), tmp.entity, -1)
            FreezeEntityPosition(tmp.entity, false)
            SetFuel(tmp.entity, 100.0)

            driveTimer(tmp.entity)
            haspressed = false
        end
    }

    options[#options + 1] = {
        title = 'Buy Vehicle',
        description = '',
        arrow = false,
        onSelect = function()
            TriggerServerEvent('mh-cardealer:server:buyVehicle', data)
            haspressed = false
        end
    }

    options[#options + 1] = {
        title = 'Close',
        description = '',
        arrow = false,
        onSelect = function()
            haspressed = false
        end
    }
    lib.registerContext({id = 'cardealerMenu', title = "MH Caldealer (ID:"..currentShopId..")", icon = "fa-solid fa-car", options = options})
    lib.showContext('cardealerMenu')
end

local function AddToTable(entity, data)
    if not DoesPlateExsist(data.plate) then
        shopVehicles[#shopVehicles + 1] = {
            entity = entity,
            shop_id = data.shop_id,
            shop_price = data.shop_price,
            shop_coords = data.shop_coords,     
            netid = data.netid,
            phone = data.phone,
            citizenid = data.citizenid,
            model = data.model,
            brand = data.brand,
            type = data.type,
            plate = data.plate,
            body = data.body,
            engine = data.engine,
            fuel = data.fuel,
            mods = data.mods,
            drivingdistance = data.drivingdistance
        }
        if Config.Target == "qb-target" then
            exports['qb-target']:AddTargetEntity(entity, {
                options = {
                    {
                        type = 'client',
                        event = '',
                        icon = 'fas fa-car',
                        label = "View Vehicle Info",
                        action = function()
                            OpenMenu(data)
                        end,
                        canInteract = function()
                            return true
                        end
                    }, {
                        type = 'client',
                        event = '',
                        icon = 'fas fa-car',
                        label = "Cancel Sell",
                        action = function()
                            TriggerServerEvent('mh-cardealer:server:cancelSale', data)
                        end,
                        canInteract = function()
                            return true
                        end
                    },
                },
                distance = 3.0
            })
        elseif Config.Target == "ox_target" then
            exports.ox_target:addLocalEntity(entity, {
                {
                    type = 'client',
                    event = '',
                    icon = 'fas fa-car',
                    label = "View Vehicle Info",
                    onSelect = function()
                        OpenMenu(data)
                    end,
                    canInteract = function()
                        return true
                    end,
                    distance = 3.0
                },
                {
                    type = 'client',
                    event = '',
                    icon = 'fas fa-car',
                    label = "Cancel Sell",
                    onSelect = function()
                        TriggerServerEvent('mh-cardealer:server:cancelSale', data)
                    end,
                    canInteract = function()
                        if data.citizenid ~= PlayerData.citizenid then return false end
                        return true
                    end,
                    distance = 3.0
                },
            })
        end
    end
end

local function DeleteFromTable(plate)
    for i = 1, #shopVehicles, 1 do
        if shopVehicles[i].plate == plate then
            table.remove(shopVehicles, i)
            return true
        end
    end
    return false
end

local function CloseAllVehicleDoors(vehicle)
    local doords = GetNumberOfVehicleDoors(vehicle)
    for i = 0, doords, 1 do SetVehicleDoorShut(vehicle, i, false) end
    Wait(100)
    FreezeEntityPosition(vehicle, true)
end

local function CreateBlip(id, coords, label, data)
	local blip = AddBlipForCoord(coords.x, coords.y)
	SetBlipSprite(blip, data.sprite)
	SetBlipScale(blip, 0.6)
	SetBlipColour(blip, data.color)
	SetBlipAsShortRange(blip, true)
	BeginTextCommandSetBlipName('STRING')
	AddTextComponentSubstringPlayerName(label)
	EndTextCommandSetBlipName(blip)
    blips[#blips + 1] = {id = id, blip = blip}
end

local function DeleteBlips()
    for k, v in pairs(blips) do
        if DoesBlipExist(v.blip) then
            RemoveBlip(v.blip)
            v.blip = nil
        end
    end
    blips = {}
end

local function DeleteZones()
    for k, zone in pairs(shopZones) do
        if zone ~= nil then
            zone:destroy()
            zone = nil
        end
    end
    shopZones = {}
end

local function CreateZones()
    for k, shop in pairs(Config.Cardealers) do
        shopZones[#shopZones + 1] = PolyZone:Create(shop.zone.shape, {name = shop.id, minZ = shop.zone.minZ, maxZ = shop.zone.maxZ, debugGrid = Config.DebugPoly, gridDivisions = 25})
        CreateBlip(shop.id, shop.coords, "Cardealer", shop.blip)
    end
end

local function DeleteZoneBlip(id)
    for k, v in pairs(blips) do
        if v.id == id then
            if DoesBlipExist(v.blip) then
                RemoveBlip(v.blip)
                v.blip = nil
                break
            end
        end
    end
end

RegisterNetEvent('mh-cardealer:client:delete-blip', function(data)
    if data.status == true then DeleteZoneBlip(data.id) end
end)

RegisterNetEvent('mh-cardealer:client:removeZone', function(data)
    if data.status == true then
        for k, zone in pairs(shopZones) do
            if zone ~= nil and tonumber(zone.name) == tonumber(data.zoneid) then
                lib.hideTextUI()
                zone:destroy()
                table.remove(Config.Cardealers, tonumber(data.zoneid))
                DeleteZoneBlip(data.zoneid)
                Notify("Cardealer zone deleted by admin!", "success", 5000)
                break
            end
        end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        DeleteBlips()
        DeleteZones()         
        PlayerData = {}
        isLoggedIn = false
        shopVehicles = {}
    end
end)

AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
        TriggerServerEvent('mh-cardealer:server:onjoin')
        HasAccess()
    end
end)

RegisterNetEvent(OnPlayerLoaded, function()
    TriggerServerEvent('mh-cardealer:server:onjoin')
    HasAccess()
end)

RegisterNetEvent(OnPlayerUnload, function()
    PlayerData = {}
    isLoggedIn = false
end)

RegisterNetEvent(OnJobUpdate, function(job)
    PlayerData.job = job
end)

RegisterNetEvent('mh-cardealer:client:notify', function(data)
    if data.status == true then Notify(data.message, data.type, data.length) end
end)

RegisterNetEvent('mh-cardealer:client:removeVehicle', function(data)
    local vehicle = NetworkGetEntityFromNetworkId(data.netid)
    if DoesEntityExist(vehicle) then
        DeleteFromTable(data.plate)
        FreezeEntityPosition(vehicle, false)
    end
end)

RegisterNetEvent('mh-cardealer:client:UpdateCardealer', function(data)
    if data.status == true then
        shopZones[#shopZones + 1] = PolyZone:Create(data.cardealer.zone.shape, {name = data.cardealer.id, minZ = data.cardealer.zone.minZ, maxZ = data.cardealer.zone.maxZ, debugGrid = data.cardealer.zone.debugPoly, gridDivisions = 25})
        CreateBlip(data.cardealer.id, data.cardealer.coords, "Cardealer", data.cardealer.blip)
    end
end)

RegisterNetEvent('mh-cardealer:client:addVehicle', function(data)
    if NetworkDoesEntityExistWithNetworkId(data.vehicle.netid) then
        local vehicle = NetworkGetEntityFromNetworkId(data.vehicle.netid)
        if DoesEntityExist(vehicle) then
            if not DoesPlateExsist(data.vehicle.plate) then
                AddToTable(vehicle, data.vehicle)
                CloseAllVehicleDoors(vehicle)
            end
        end
    end
end)

RegisterNetEvent('mh-cardealer:client:onjoin', function(data)
    if data.status == true then
        PlayerData = GetPlayerData()
        isLoggedIn = true
        HasAccess()
        CreateZones()
        local vehicles = data.vehicles
        for k, vehicle in pairs(vehicles) do
            if not DoesPlateExsist(vehicle.plate) then
                while not NetworkDoesEntityExistWithNetworkId(vehicle.netid) do Wait(0) end
                if NetworkDoesEntityExistWithNetworkId(vehicle.netid) then
                    NetworkRequestControlOfNetworkId(vehicle.netid)
                    local entity = NetworkGetEntityFromNetworkId(vehicle.netid)
                    if DoesEntityExist(entity) then
                        if not DoesPlateExsist(data.plate) then
                            SetEntityAsMissionEntity(entity, true, true)
                            SetVehicleProperties(entity, vehicle.mods)
                            DoVehicleDamage(entity, vehicle.body, vehicle.engine)
                            SetFuel(entity, vehicle.fuel + 0.0)
                            SetVehicleKeepEngineOnWhenAbandoned(vehicle, true)
                            AddToTable(entity, vehicle)
                        end
                    end
                end
            end
        end
        Wait(1500)
        for i = 1, #shopVehicles, 1 do
            if shopVehicles[i] ~= nil then
                local vehicle = NetToVeh(shopVehicles[i].netid)  
                if DoesEntityExist(vehicle) then
                    FreezeEntityPosition(vehicle, true)
                end
            end
        end
    end
end)

CreateThread(function()
    while true do
        local sleep = 1000
        if isLoggedIn and hasAccess then
            local ped = PlayerPedId()
            if IsPedInAnyVehicle(ped, false) then
                local vehicle = GetVehiclePedIsIn(ped, false)
                if vehicle ~= nil and vehicle ~= -1 and inzone and currentShopId ~= nil and not haspressed then
                    sleep = 0
                    DisplayHelpText("Press E to sell this car!")
                    if IsControlJustPressed(0, 38) then -- E
                        haspressed = true
                        isGettingOut = true
                        SetVehicleEngineOn(vehicle, false, false, true)
                        TaskLeaveVehicle(ped, vehicle, 1)
                        Wait(2000)
                        isGettingOut = false
                        local coords = GetEntityCoords(vehicle)
                        local heading = GetEntityHeading(vehicle)              
                        local data = {
                            shop_id = currentShopId,
                            shop_price = Config.Vehicles[GetEntityModel(vehicle)].price,
                            shop_coords = vector4(coords.x, coords.y, coords.z, heading),
                            netid = VehToNet(vehicle),
                            plate = GetPlate(vehicle),
                            mods = GetVehicleProperties(vehicle),
                        }
                        TriggerServerEvent('mh-cardealer:server:setforsale', data)
                        Wait(1000)
                        haspressed = false
                        sleep = 1000
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

CreateThread(function()
    while true do
        if isLoggedIn then
            for k, shopzone in pairs(shopZones) do
                shopzone:onPointInOut(PolyZone.getPlayerPosition, function(isPointInside, point)
                    if isPointInside then
                        if not inzone then
                            inzone = true
                            currentShopId = shopzone.name
                            lib.showTextUI('Owned Cardealer [ID: '..shopzone.name..']', {position = "top-center", icon = 'car', style = {borderRadius = 0, backgroundColor = '#000000', color = 'white'}})
                        end
                    else
                        if inzone then
                            inzone = false 
                            currentShopId = nil
                            haspressed = false
                            lib.hideTextUI()
                        end
                    end
                end)
            end
        end
        Wait(1000)
    end
end)

CreateThread(function()
    while true do
        local sleep = 0
        if isLoggedIn and Config.Display3DText then
            for i = 1, #shopVehicles, 1 do
                if shopVehicles[i] ~= nil and currentShopId ~= nil then
                    if NetworkDoesEntityExistWithNetworkId(shopVehicles[i].netid) then
                        local vehicle = NetToVeh(shopVehicles[i].netid)
                        if DoesEntityExist(vehicle) then
                            local playerCoords = GetEntityCoords(PlayerPedId())
                            local vehicleCoords = GetEntityCoords(vehicle)
                            local distance = GetDistance(playerCoords, vehicleCoords)
                            if distance < 3.0 then
                                local model, brand, price = shopVehicles[i].model, shopVehicles[i].brand, math.floor(shopVehicles[i].shop_price)
                                local phone = shopVehicles[i].phone or 0
                                if model ~= nil and brand ~= nil and price ~= nil then
                                    local netixTxt = ""
                                    if Config.ShowNetIds then netixTxt = netixTxt .. "Netid: ~y~"..shopVehicles[i].netid.."~w~\n" end
                                    local phoneTxt = ""
                                    if Config.ShowPhone then phoneTxt = phoneTxt .. "Call: ~y~"..phone.."~w~\n" end
                                    local txt = netixTxt.."Brand: ~g~" .. FirstToUpper(brand) .. "~w~\nModel: ~b~" .. FirstToUpper(model).. "~w~\nPrice: ~o~"..Config.MoneySign..price.."~w~\n"..phoneTxt
                                    Draw3DText(vehicleCoords.x, vehicleCoords.y, vehicleCoords.z, txt, 0, 0.04, 0.04)
                                    if Config.DisplayInteract then
                                        local txt2 = "Interact: ~g~ Use "..Config.InteractText.." ~w~"
                                        Draw3DText(vehicleCoords.x, vehicleCoords.y, vehicleCoords.z - 0.4, txt2, 0, 0.04, 0.04)
                                    end
                                end   
                            end
                        end
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

CreateThread(function()
    while true do
        local sleep = 1000
        if isLoggedIn and isGettingOut then
            sleep = 5
            if IsPauseMenuActive() then SetFrontendActive(false) end
            DisableAllControlActions(0)
            EnableControlAction(0, 1, true)
            EnableControlAction(0, 2, true)
            EnableControlAction(0, 245, true)
            EnableControlAction(0, 38, true)
            EnableControlAction(0, 0, true)
            EnableControlAction(0, 322, true)
            EnableControlAction(0, 288, true)
            EnableControlAction(0, 213, true)
            EnableControlAction(0, 249, true)
            EnableControlAction(0, 46, true)
            EnableControlAction(0, 47, true)
        end
        Wait(sleep)
    end
end)