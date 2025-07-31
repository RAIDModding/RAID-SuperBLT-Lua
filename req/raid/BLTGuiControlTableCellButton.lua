require("lib/managers/menu/raid_menu/controls/raidguicontrol")
require("lib/managers/menu/raid_menu/controls/raidguicontrolbutton")
require("lib/managers/menu/raid_menu/controls/raidguicontrolbuttonshortsecondary")

BLTGUIControlTableCellButton = BLTGUIControlTableCellButton or class(RaidGUIControlButtonShortSecondary)

function BLTGUIControlTableCellButton:init(parent, params, cell_data, table_params)
	params.on_click_callback = params.on_cell_click_callback
	params.visible = cell_data.visible

	BLTGUIControlTableCellButton.super.init(self, parent, params)

	if self._object_image_highlight then
		self._object_image_highlight:hide()
		self._object_image:show()
	end

	self:set_center_y(params.height / 2)
end

function BLTGUIControlTableCellButton:highlight_on()
	-- nth
end

function BLTGUIControlTableCellButton:highlight_off()
	-- nth
end

function BLTGUIControlTableCellButton:select_on()
	-- nth
end

function BLTGUIControlTableCellButton:select_off()
	-- nth
end

function BLTGUIControlTableCellButton:on_double_click(button)
	-- nth
end
