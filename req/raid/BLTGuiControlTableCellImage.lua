require("lib/managers/menu/raid_menu/controls/raidguicontrol")
require("lib/managers/menu/raid_menu/controls/raidguicontrolimage")
require("lib/managers/menu/raid_menu/controls/raidguicontroltablecellimage")

BLTGUIControlTableCellImage = BLTGUIControlTableCellImage or blt_class(RaidGUIControlTableCellImage)

function BLTGUIControlTableCellImage:init(parent, params, cell_data, table_params)
	if params.value and params.value.texture and not params.texture then
		params.texture = params.value.texture
	end

	if params.value and params.value.texture_rect and not params.texture_rect then
		params.texture_rect = params.value.texture_rect
	end

	if params.height and not params.h then
		params.h = params.height
	end

	BLTGUIControlTableCellImage.super.init(self, parent, params)
end

function BLTGUIControlTableCellImage:highlight_on()
	-- nth
end

function BLTGUIControlTableCellImage:highlight_off()
	-- nth
end

function BLTGUIControlTableCellImage:select_on()
	-- nth
end

function BLTGUIControlTableCellImage:select_off()
	-- nth
end

function BLTGUIControlTableCellImage:on_double_click(button)
	if self._params.on_double_click_callback then
		self._params.on_double_click_callback(button, self, self._data)
	end
end
