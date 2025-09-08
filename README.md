# nskap_keys

Plate-bound vehicle keys for ESX Legacy with optional ox_inventory integration:
- Item locks/unlocks only the matching vehicle plate
- Ignition insert/remove on key `Y` with /me messages
- Engine cannot run without key; leaving key in ignition keeps engine running
- Command `/addkey <serverId> [count]` assigns key(s) for the vehicle the player sits in
- Exports to add/remove/check keys from other resources

## Requirements
- ESX Legacy (es_extended)
- ox_inventory recommended (for per-item plate metadata and nice tooltip); the script will try to work with vanilla inventories but metadata may not show.

## Install
1. Place this resource in `resources/[all]/nskap_keys`.
2. Ensure it in your server cfg after es_extended and ox_inventory.
3. Make sure your inventory has an item matching `Config.ItemName` (default: `vehiclekey`). For ox_inventory, add to `ox_inventory/data/items.lua` or a dedicated items file:

    ['vehiclekey'] = {
        label = 'Vehicle Key',
        weight = 15,
        stack = true,
        close = true,
        description = function(item)
            local plate = item.metadata and item.metadata.plate
            return plate and ('Plate: %s'):format(plate)
        end
    }

4. Optional: adjust `config.lua` (item name, keybind, distances).

## Usage
- Use the key item in inventory near the vehicle or while seated to toggle lock.
- Press `Y` while in driver seat to insert/remove the ignition key.
  - Inserts: engine starts and stays on.
  - Removes: engine stops. If you exit with key left inserted, engine remains on.
  - Auto /me messages are broadcast within `Config.MeRadius` meters.

## Command
- `/addkey <serverId> [count]` — Admin only (groups in `Config.AdminGroups`).
  - Target player must be seated in the vehicle. The key will be created for that vehicle plate.

## Exports
Server-side:
- exports['nskap_keys']:AddKey(source, plate, count?) — add key item with metadata { plate }.
- exports['nskap_keys']:RemoveKey(source, plate, count?) — remove key item with matching plate.
- exports['nskap_keys']:HasKey(source, plate) — returns boolean.

## Notes
- With non-ox inventories that lack metadata support, keys may not visually show their plate. Logic still attempts to enforce plate match on the server, but using ox_inventory is strongly recommended.
- If you already have a lock/unlock control bound elsewhere, consider disabling that or rely solely on using the key item.


## Showcase
https://medal.tv/games/gta-v/clips/l3BHcYXqwkFdri69n?invite=cr-MSxWam8sMzIxMzEwNjkw&v=42
