# Alpha-DVCars

![Alpha-DVCars Banner](https://media.wickdev.me/25b5827a14.png)

## Overview
Alpha-DVCars is an advanced vehicle cleanup system for FiveM servers. It automatically removes unoccupied vehicles at configurable intervals to help maintain server performance and reduce entity count.

## Features
- **Automatic Cleanup**: Removes unoccupied vehicles at configurable intervals
- **Advanced UI**: Modern Arabic UI with countdown timer and progress bar
- **Player Protection**: Never deletes vehicles that players are in or on
- **Emergency Vehicle Protection**: Option to exclude emergency vehicles from cleanup
- **Player Vehicle Protection**: Option to exclude player-owned vehicles (with license plates)
- **Configurable Radius**: Set the radius around players where vehicles will be cleaned
- **Command Integration**: Uses `/dvall` command with fallback to built-in deletion

## Installation
1. Download the resource
2. Place it in your server's resources folder
3. Add `ensure alpha-dvcars` to your server.cfg
4. Configure the settings in `config.lua` to your liking

## Configuration
```lua
Config = {}

Config.AutoDeleteInterval = 15 -- Cleanup interval in minutes
Config.DeleteRadius = 1000.0 -- Radius around players to check for vehicles
Config.ExcludePlayerVehicles = true -- Exclude vehicles with license plates
Config.ExcludeEmergencyVehicles = true -- Exclude emergency vehicles
Config.EmergencyClasses = {
    [18] = true,
    [19] = true
}
Config.ShowUI = true -- Show the UI
Config.AutoStart = true -- Start the system automatically
Config.UseDvallCommand = true -- Use /dvall command
Config.FallbackToBuiltIn = true -- Use built-in deletion as fallback
Config.ProtectPlayerCurrentVehicle = true -- Protect vehicles players are in or on
```

## Commands
- `/dvall` - Manually trigger vehicle cleanup
- `/dvcars` - Toggle the cleanup system on/off
- `/dvinterval [minutes]` - Change the cleanup interval

## UI Features
- Modern Arabic interface
- Real-time countdown to next cleanup
- Progress bar showing time remaining
- Status indicator showing if the system is active
- Automatic display in the last 30 seconds before cleanup
- Pulsing warning effect when cleanup is imminent

## Credits
- Developed by **AlphaDev**
- UI Design by **AlphaDev**
- Arabic Localization by **AlphaDev**

## License
© 2024 AlphaDev. All Rights Reserved.

This resource is protected by copyright law. Unauthorized distribution, modification, or resale is strictly prohibited.

## Support
For support, please contact AlphaDev through the appropriate channels.

---

*Alpha-DVCars - Keeping your server clean and performant*
