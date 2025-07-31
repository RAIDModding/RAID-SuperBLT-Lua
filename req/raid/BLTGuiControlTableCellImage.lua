require("lib/managers/menu/raid_menu/controls/raidguicontrol")
require("lib/managers/menu/raid_menu/controls/raidguicontrolimage")
require("lib/managers/menu/raid_menu/controls/raidguicontroltablecellimage")

BLTGUIControlTableCellImage = BLTGUIControlTableCellImage or blt_class(RaidGUIControlTableCellImage)

function BLTGUIControlTableCellImage:init(parent, params, ...)
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
	-- if self._table_params and self._table_params.row_params and self._table_params.row_params.color and self._table_params.row_params.highlight_color then
	-- 	self:set_color(self._table_params.row_params.highlight_color)
	-- end
end

function BLTGUIControlTableCellImage:highlight_off()
	-- if self._table_params and self._table_params.row_params and self._table_params.row_params.color and self._table_params.row_params.selected_color then
	-- 	self:set_color(self._table_params.row_params.selected_color)
	-- end
end

function BLTGUIControlTableCellImage:select_on()
	-- if self._params.selected_color and self._params.color then
	-- 	self:set_color(tweak_data.gui.colors.raid_red)
	-- end
end

function BLTGUIControlTableCellImage:select_off()
	-- if self._params.selected_color and self._params.color then
	-- 	self:set_color(self._params.color)
	-- end
end

function BLTGUIControlTableCellImage:on_double_click(button)
	if self._params.on_double_click_callback then
		self._params.on_double_click_callback(button, self, self._data)
	end
end
