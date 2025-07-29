BLTGUIControlTableCellImageText = BLTGUIControlTableCellImageText or class(RaidGUIControl)
BLTGUIControlTableCellImageText.FONT = tweak_data.gui.fonts.din_compressed
BLTGUIControlTableCellImageText.FONT_SIZE = tweak_data.gui.font_sizes.small

local padding = 10

function BLTGUIControlTableCellImageText:init(parent, params, cell_data, table_params)
	params.font = params.font or BLTGUIControlTableCellImageText.FONT
	params.font_size = params.font_size or BLTGUIControlTableCellImageText.FONT_SIZE

	BLTGUIControlTableCellImageText.super.init(self, parent, params)

	self._table_params = table_params
	self._data = {
		value = params.value,
	}

	self._object = self._panel:panel({
		w = params.w - params.x,
		h = params.height,
		layer = params.layer,
		x = params.x,
		y = params.y,
	})
	local text_x = (cell_data.icon_w > 0) and (cell_data.icon_w + padding) or 0
	self._text = self._object:label({
		w = params.w - params.x - text_x,
		h = params.height,
		layer = params.layer + 1,
		x = text_x,
		text = params.text,
		font = params.font,
		font_size = params.font_size,
		fit_text = true,
	})
	self._text:set_center_y(params.height / 2)
	self._icon = self._object:bitmap({
		w = cell_data.icon_w,
		h = cell_data.icon_h,
		layer = params.layer + 1,
		alpha = 1,
		x = 0,
		texture = cell_data.texture,
		texture_rect = cell_data.texture_rect
	})
	self._icon:set_center_y(params.height / 2)
end

function BLTGUIControlTableCellImageText:highlight_on()
	if self._text and self._table_params and self._table_params.row_params and self._table_params.row_params.color and self._table_params.row_params.highlight_color then
		self._text:set_color(tweak_data.gui.colors.raid_table_cell_highlight_on)
	end
end

function BLTGUIControlTableCellImageText:highlight_off()
	if self._text and self._table_params and self._table_params.row_params and self._table_params.row_params.color and self._table_params.row_params.highlight_color then
		self._text:set_color(tweak_data.gui.colors.raid_table_cell_highlight_off)
	end
end

function BLTGUIControlTableCellImageText:select_on()
	if self._text and self._params.selected_color and self._params.color then
		self._text:set_color(tweak_data.gui.colors.raid_red)
	end
end

function BLTGUIControlTableCellImageText:select_off()
	if self._text and self._params.selected_color and self._params.color then
		self._text:set_color(self._params.color)
	end
end

function BLTGUIControlTableCellImageText:on_double_click(button)
	if self._params.on_double_click_callback then
		self._params.on_double_click_callback(button, self, self._data)
	end
end
