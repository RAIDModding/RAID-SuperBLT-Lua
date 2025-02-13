# RAID-SuperBLT Basemod Changelog

This lists the changes between different versions of the RAID-SuperBLT basemod,
the changes for the DLL are listed in their own changelog.
Contributors other than maintainers are listed in parenthesis after specific changes.

## `master` branch

- added `Utils.GetFontBySize()` to help mods with scaling fonts
- added new icon for SBLT by [Dribbleondo](https://www.youtube.com/channel/UCD_C63csNn6SDm9IirZN3oA)
- improved reloading game logic in BLTDownloadManagerGui. it now only shows the button to reload if no mod using the `assets` module

## v1.2.0

- added BLT.fonts table, reflecting pd2 font presets
- added open contact button
- added Util.OpenUrl and Util.OpenUrlSafe (with yes no msgbox)
- added reload button to BLTDownloadManagerGui if developer.txt is present
- added min_sblt_version for supermod.xml
- fixed crashes in main menu due to missing event handlers when using arrow keys or enter
- fixed always applying default localization
- fixed QuickMenu cancel button flag for raid

## v1.1.0

- fixed auto updater download validation for pure-xml mods (as in v1.0.1)
- fixed menu ui updates
- improved menu visuals (no blend_mode "add" in panels and texts)
- deprecated MenuManager:register_menu_new (use RaidMenuHelper:RegisterMenu instead)

## v1.0.3

- fixed RaidMenuHelper:CreateMenu() when BeardLib is not installed (implemented table.merge)

## v1.0.2

- fixed keybinds menu
- fixed dependencies system

## v1.0.1

- equalized features of mod and supermod, and got rid of own mod.txt

## v1.0.0

- based on PD2-SuperBLT v1.4.0
- tons of patches and fixes for RAID
- ported raid specific features from RaidBLT
- removed linux/w32/pd2/vr codes
- added modworkshop provider for auto updates
