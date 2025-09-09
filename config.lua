Config = {}

-- Item name for car keys
Config.ItemName = 'carkeys'

-- Ignition settings
Config.IgnitionKey = 'Y' --key to toggle ignition

-- Locking settings
Config.LockKey = 'L'
Config.LockProgressDuration = 2000
Config.NearbyVehicleDistance = 4.0

-- Admin groups allowed to use /addkey
Config.AdminGroups = { admin = true, superadmin = true }

-- Notification: 'ox' (ox_lib) or 'esx' you can add your own notify
Config.NotifyProvider = 'ox'


--do not touch!
Config.UseOxInventoryIfPresent = true -- do not touch!
Config.MeRadius = 20.0 --do not touch!
