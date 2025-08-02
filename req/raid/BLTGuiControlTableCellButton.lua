require("lib/managers/menu/raid_menu/controls/raidguicontrol")
require("lib/managers/menu/raid_menu/controls/raidguicontrolbutton")
require("lib/managers/menu/raid_menu/controls/raidguicontrolbuttonshortsecondary")

BLTGUIControlTableCellButton = BLTGUIControlTableCellButton or blt_class(RaidGUIControlButtonShortSecondary)

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

function BLTGUIControlTableCellButton:select_on()
	self:set_selected(true)
end

function BLTGUIControlTableCellButton:select_off()
	self:set_selected(false)
end

function BLTGUIControlTableCellButton:on_double_click(button)
	if self._params.on_double_click_callback then
		self._params.on_double_click_callback(button, self, self._data)
	end
end

function BLTGUIControlTableCellButton:confirm_pressed()
	if self._params.no_click then
		return true
	end

	if self._selected and self._on_click_callback then
		self:_on_click_callback(self, self, self._data)
		return true
	end
end
