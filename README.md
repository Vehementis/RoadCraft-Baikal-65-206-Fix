# How to fix the truck:

1. Download this Git repo as Zip
2. Open `Steam` -> right klick `RoadCraft` -> `Settings` -> `Local Files` -> `Browse`
3. navigate to `root` -> `paks` -> `client` -> `default`
4. delete or rename `default_other.pak.cache` (if you dont do that the game will crash on start after changing the `default_other.pak`)
5. extrract the files from `RoadCraft-Baikal-65-206-Fix.zip`
6. right klick `default_other.pak` and open it with 7-zip
7. navigate to `ssl\autogen_designer_wizard\trucks\auto_baikal_65206_heavy_dumptruck_old` and replace the `auto_baikal_65206_heavy_dumptruck_old.cls` with the one from my mod
8. navigate to `ssl\autogen_designer_wizard\trucks\auto_baikal_65206_heavy_dumptruck_res` and replace the `auto_baikal_65206_heavy_dumptruck_res.cls` with the one from my mod
9. save the changes to `default_other.pak`
10. have fun!!!

## Notes
- This is just intended as a fix for the bug of the missing back wall.
- I increased the strength of the lid to a level that feels right for the game.
  - The sand will still force open the lid if the force gets too strong.
- I made the lid of the rusty version weaker than the lid of the restored one.
- If you want to increase the strength of the lid on the rusty version, you can just open the `auto_baikal_65206_heavy_dumptruck_old.cls` file and change the value of the line `sandForceScalar` to `1`.
  - If you want to be really cheaty, you can also change `minVolumeDifToForceLid` and `minVolumeToForceLid` to `1`, and it should basically never open due to force.
- If you tip the vehicle sideways, it will still spill over the side wall.
