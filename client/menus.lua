local menu = nil
local menu2 = nil
local menu3 = nil
local radialmenu = nil

function OpenAdminMenu2(data)
    TriggerCallback('mh-cardealer:server:IsAdmin', function(result)
        if result.status and result.isadmin then
            local options = {}
            options[#options + 1] = {
                title = "Cardealer ID " .. data.id .. "",
                icon = "fa-solid fa-car",
                description = "Name: "..data.label.."\nOwner: "..data.owner.."\nFullname: "..data.fullname.."\nPhone "..data.phone,
                arrow = false,
                onSelect = function() 
                end
            }

            options[#options + 1] = {
                title = "Go to",
                icon = "fa-solid fa-car",
                description = "Press and you will teleport to this location",
                arrow = false,
                onSelect = function()
                    SetEntityCoords(PlayerPedId(), data.coords.x, data.coords.y, data.coords.z + 1)
                end
            }

            options[#options + 1] = {
                title = "Delete Cardealer",
                icon = "fa-solid fa-car",
                description = "Press and you will teleport to this location",
                arrow = false,
                onSelect = function()
                    TriggerServerEvent('mh-cardealer:server:delete-cardealer', {status = true, id = data.id})
                end
            }

            options[#options + 1] = {
                title = 'back',
                icon = "fa-solid fa-stop",
                description = '',
                arrow = false,
                onSelect = function()
                    OpenAdminMenu()
                end
            }
            lib.registerContext({id = 'mhcardealerMenu2', title = "MH Cardealer Admin Menu", icon = "fa-solid fa-warehouse", options = options})
            lib.showContext('mhcardealerMenu2')
        end
    end)
end

function OpenAdminMenu()
    TriggerCallback('mh-cardealer:server:IsAdmin', function(result)
        if result.status and result.isadmin then
            local options = {}
            for k, v in pairs(Config.Cardealers) do
                options[#options + 1] = {
                    title = "Cardealer ID " .. v.id .. "",
                    icon = "fa-solid fa-car",
                    description = "",
                    arrow = false,
                    onSelect = function()
                        OpenAdminMenu2(v)
                    end
                }
            end

            options[#options + 1] = {
                title = 'close',
                icon = "fa-solid fa-stop",
                description = '',
                arrow = false,
                onSelect = function()
                end
            }
            lib.registerContext({id = 'mhcardealerMenu', title = "MH Cardealer Admin Menu", icon = "fa-solid fa-warehouse", options = options})
            lib.showContext('mhcardealerMenu')
        end
    end)
end

function OpenMenu()
    TriggerCallback('mh-cardealer:server:IsShopOwner', function(result)
        if result.status and result.isowner then
            local data = result.data
            local options = {}
            options[#options + 1] = {
                title = "Delete Cardealer",
                icon = "fa-solid fa-car",
                description = "Delete you cardealer",
                arrow = false,
                onSelect = function()
                    TriggerServerEvent('mh-cardealer:server:delete-cardealer', {status = true, id = data.id})
                end
            }
            options[#options + 1] = {
                title = 'close',
                icon = "fa-solid fa-stop",
                description = '',
                arrow = false,
                onSelect = function()
                end
            }
            lib.registerContext({id = 'mhcardealer', title = "MH Cardealer Menu", icon = "fa-solid fa-warehouse", options = options})
            lib.showContext('mhcardealer')
        end
    end)
end

function CreateMenu()
    local Menu = {
        id = 'carcealer', 
        title = 'Cardealer', 
        icon = 'car', 
        items = {
            {
                id = "enable_create",
                title = "Enable Create",
                icon = 'plus',
                type = 'client',
                event = 'mh-adminjobs:client:enablecreatemode',
                shouldClose = true
            }, {
                id = "add_point",
                title = "Add Point",
                icon = 'plus',
                type = 'client',
                event = 'mh-adminjobs:client:addpoint',
                shouldClose = true
            }, {
                id = "save_area",
                title = "Save Area",
                icon = 'plus',
                type = 'client',
                event = 'mh-adminjobs:client:savearea',
                shouldClose = true
            },
        }
    }
    if #Menu.items == 0 then
        if menu3 then
            exports['qb-radialmenu']:RemoveOption(menu3)
            menu3 = nil
        end
    else
        menu3 = exports['qb-radialmenu']:AddOption(Menu, menu3)
    end
end

RegisterNetEvent('mh-cardealer:client:OpenMainMenu', function()
    OpenAdminMenu()
end)

RegisterNetEvent('mh-cardealer:client:OpenMenu', function()
    OpenMenu()
end)

RegisterNetEvent('qb-radialmenu:client:onRadialmenuOpen', function()
    CreateMenu()
end)