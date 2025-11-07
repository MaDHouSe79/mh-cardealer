---------------------------------------------------------------------------------------------------
Config = {}                            -- Placeholder, do not remove or edit this.
Config.Cardealers = {}                 -- Placeholder, do not remove or edit this.
---------------------------------------------------------------------------------------------------
Config.Framework = "qb"                -- For qb/qbx/esx.
Config.Target = "qb-target"            -- For qb-target/ox_target
Config.MoneySign = "€"                 -- $ or €
---------------------------------------------------------------------------------------------------
Config.DiscordLink = ""
---------------------------------------------------------------------------------------------------
Config.UseAsJob = false                -- Players need to go to the citehall to get the this job.
Config.JobName = 'cardealer2'          -- Job name.
Config.DaysCardealerExist = 5          -- amount of days the cardealer exists.
Config.AutomaticDeleteAfterTime = true -- if true the cardealer automaticly delete after when the time of over.
---------------------------------------------------------------------------------------------------
Config.Display3DText = true
Config.DisplayInteract = trye          -- When true you see a interact text above the vehicle.
Config.InteractText = "Eye"            -- 'Eye' for target eye or 'E' for button press.
---------------------------------------------------------------------------------------------------
Config.SaveCardealersToFile = true     -- When true it save the cardealer to a file, when false the cardealer is only temponary as long as the server is online and not restarting.
Config.ShowNetIds = false              -- when there is no netid this vehuicle wil nog work, there has to be a netid in order to work.
Config.ShowPhone = true
---------------------------------------------------------------------------------------------------
Config.DebugPoly = false                -- Debug polyzones.
---------------------------------------------------------------------------------------------------

-- Vehicle keys (client side)
function SetClientVehicleOwnerKey(plate, vehicle)
    if Config.KeyScript == "qb-vehiclekeys" then
        TriggerServerEvent('qb-vehiclekeys:server:AcquireVehicleKeys', plate)
    elseif Config.KeyScript == "qbx_vehiclekeys" then
        TriggerEvent('vehiclekeys:client:SetOwner', plate)
    end
end
