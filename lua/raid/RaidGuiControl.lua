function RaidGUIControl:layer()
    -- temp vanilla fix: [string "lib/managers/menu/raid_menu/controls/raidguic..."]:398: attempt to index field '_object' (a nil value)
    return self._object and self._object:layer() or self._params.layer
end
