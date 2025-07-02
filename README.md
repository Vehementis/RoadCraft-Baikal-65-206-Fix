# RoadCraft Baikal 65-206 Fix

This mod fixes the missing back wall bug in the Baikal 65-206 heavy dump truck, preventing sand from spilling out the back.

## How to fix the truck:

## Manual Installation
1. Download this Git repo as Zip (top right green `<> Code` Button -> `Download ZIP`)
2. Open `Steam` -> right click `RoadCraft` -> `Settings` -> `Local Files` -> `Browse`
3. navigate to `root` -> `paks` -> `client` -> `default`
4. delete or rename `default_other.pak.cache` (if you dont do that the game will crash on start after changing the `default_other.pak`)
5. extract the files from `RoadCraft-Baikal-65-206-Fix.zip`
6. right click `default_other.pak` and open it with 7-zip
7. navigate to `ssl\autogen_designer_wizard\trucks\auto_baikal_65206_heavy_dumptruck_old` and replace the `auto_baikal_65206_heavy_dumptruck_old.cls` with the one from my mod
8. navigate to `ssl\autogen_designer_wizard\trucks\auto_baikal_65206_heavy_dumptruck_res` and replace the `auto_baikal_65206_heavy_dumptruck_res.cls` with the one from my mod
9. save the changes to `default_other.pak`
10. have fun!!!

## Automatic Installation V3 (recommended)
1. Download this Git repo as Zip (top right green `<> Code` Button -> `Download ZIP`)
2. Open `Steam` -> right click `RoadCraft` -> `Settings` -> `Local Files` -> `Browse`
3. extract the files from `RoadCraft-Baikal-65-206-Fix.zip`
4. copy the `RoadCraft-Baikal-65-206-Fix` folder into the `RoadCraft` folder
5. open the `RoadCraft-Baikal-65-206-Fix` folder
6. double-click the `V3_installer.cmd` file to run it
7. wait for the script to finish and check for any error messages
8. have fun!!!

**V3 Installer Features:**
- **No external dependencies** - uses built-in Windows PowerShell and .NET ZIP libraries (no 7-Zip required)
- **Regex-based modifications** - uses pattern matching instead of file replacement, making it compatible with game updates and other mods

## Automatic Installation (legacy - use V3 instead)
1. Download this Git repo as Zip (top right green `<> Code` Button -> `Download ZIP`)
2. Open `Steam` -> right click `RoadCraft` -> `Settings` -> `Local Files` -> `Browse`
3. extract the files from `RoadCraft-Baikal-65-206-Fix.zip`
4. copy the `RoadCraft-Baikal-65-206-Fix` folder into the `RoadCraft` folder
5. open the `RoadCraft-Baikal-65-206-Fix` folder
6. execute the `install_fix.bat` file
7. check for any error messages
8. have fun!!!

- the script will backup your files before deletion or override
- if it fails you can use the backup to restore it or use steam to verify files
- 7zip is required for the installer (https://www.7-zip.org/)

## Notes
- This is just intended as a fix for the bug of the missing back wall.
- I increased the strength of the lid to a level that feels right for the game.
  - The sand will still force open the lid if the force gets too strong.
- I made the lid of the rusty version weaker than the lid of the restored one.
- **V3 Installer**: If you want to increase the strength of the lid on the rusty version, you can just open the `V3_config` folder and edit the `auto_baikal_65206_heavy_dumptruck_old.json` file and change the value of the line `sandForceScalar` to `1`.
- **Legacy method**: If you want to increase the strength of the lid on the rusty version, you can just open the `auto_baikal_65206_heavy_dumptruck_old.cls` file and change the value of the line `sandForceScalar` to `1`.
- If you tip the vehicle sideways, it will still spill over the side wall.
