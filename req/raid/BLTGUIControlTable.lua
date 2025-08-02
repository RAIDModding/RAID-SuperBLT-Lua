require("lib/managers/menu/raid_menu/controls/raidguicontroltable")

BLTGUIControlTable = BLTGUIControlTable or blt_class(RaidGUIControlTable)

function BLTGUIControlTable:move_left()
    -- route move_left to row
    if self._selected and self._selected_row then
        return self._selected_row:move_left()
    end
end

function BLTGUIControlTable:move_right()
    -- route move_right to row
    if self._selected and self._selected_row then
        return self._selected_row:move_right()
    end
end
