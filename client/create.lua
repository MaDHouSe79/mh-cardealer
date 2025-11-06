local enable = false
local points = {}
local blipcoords = nil
local tmpPoly = nil

local function GetCenterPointFromAreaPoints(coords)
    local v1 = vector3(points[1].x, points[1].y, coords.z - 1.0)
    local v2 = vector3(points[2].x, points[2].y, coords.z - 1.0)
    local v3 = vector3(points[3].x, points[3].y, coords.z - 1.0)
    local v4 = vector3(points[4].x, points[4].y, coords.z - 1.0)
    local center = CalculateCenterPoint(v1, v2, v3, v4)
    return center
end

local function SaveArea()
    if hasAccess then
        if #points == 4 then
            local coords = GetEntityCoords(PlayerPedId())
            local center = GetCenterPointFromAreaPoints(coords)  
            local data = {shape = points, blip = center, minZ = coords.z - 1.0, maxZ = coords.z + 4.0}
            TriggerServerEvent('mh-cardealer:server:CreateCardealer', {status = true, cardealer = data})
            blipcoords, points = nil, {}
        elseif #points < 4 then
            Notify("You need atleast 4 points, you have ("..#points..") points added so far...", "error", 5000)
            return
        end
        
    else
        Notify("No Access!", "error", 5000)
    end
end

RegisterNetEvent('mh-adminjobs:client:enablecreatemode', function()
    if hasAccess then
        enable = true
        Notify("you need 4 points to make a square for your area, use (/add-point) at 1 of the 4 points to make an square!", "success", 5000)
    else
        Notify("No Access!", "error", 5000)
    end
end)

RegisterNetEvent('mh-adminjobs:client:addpoint', function()
    if enable then
        if hasAccess then
            local coords = GetEntityCoords(PlayerPedId())
            if #points < 4 then
                points[#points + 1] = vector2(coords.x, coords.y)
                if tmpPoly ~= nil then tmpPoly:destroy() end
                Wait(100)
                tmpPoly = PolyZone:Create(points, {name = "testzone", minZ = coords.z - 1.0, maxZ = coords.z + 4.0, debugPoly = true})
                if #points == 4 then
                    Notify("You have 4 points to make one area, now create the blip area, go to the center of this area and type (/add-blip)!", "success", 5000)
                end
            end
        else
            Notify("No Access!", "error", 5000)
        end
    end
end)

RegisterNetEvent('mh-adminjobs:client:savearea', function()
    if enable then
        if hasAccess then
            if #points >= 4 then
                SaveArea()
                if tmpPoly ~= nil then tmpPoly:destroy() end
                enable = false
                tmpPoly = nil
            elseif #points < 4 then
                Notify("Need at least 4 points to save an area!", "error", 5000)
            end
        else
            Notify("No Access!", "error", 5000)
        end
    end
end)