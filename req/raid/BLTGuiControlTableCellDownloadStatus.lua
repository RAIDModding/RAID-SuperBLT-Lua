BLTGuiControlTableCellDownloadStatus = BLTGuiControlTableCellDownloadStatus or class(RaidGUIControl)
BLTGuiControlTableCellDownloadStatus.FONT = tweak_data.gui.fonts.din_compressed
BLTGuiControlTableCellDownloadStatus.FONT_SIZE = tweak_data.gui.font_sizes.small

function BLTGuiControlTableCellDownloadStatus:init(parent, params, cell_data, table_params)
	params.font = params.font or BLTGuiControlTableCellDownloadStatus.FONT
	params.font_size = params.font_size or BLTGuiControlTableCellDownloadStatus.FONT_SIZE

	BLTGuiControlTableCellDownloadStatus.super.init(self, parent, params)

	self._table_params = table_params
	self._data = {
		value = params.value,
	}

	self._object = self._panel:panel({
		w = params.w,
		h = params.height,
		layer = params.layer,
		x = params.x,
		y = params.y,
	})

	self._text = self._object:label({
		w = params.w,
		h = params.height,
		layer = params.layer + 1,
		x = 0,
		text = params.text,
		font = params.font,
		font_size = params.font_size,
		fit_text = true,
		color = self._table_params.row_params.highlight_color,
	})
	self._text:set_center_y(params.height / 2)

	self._progress = self._object:progress_bar({
		w = params.w,
		h = params.height,
		layer = params.layer + 1,
		x = 0,
		bar_width = params.w,
		border_width = 1,
		color = Color.white,
	})
	self._progress:set_center_y(params.height / 2)
	self:set_progress(cell_data.progress)
end

function BLTGuiControlTableCellDownloadStatus:highlight_on()
	if self._text and self._table_params and self._table_params.row_params and self._table_params.row_params.color and self._table_params.row_params.highlight_color then
		self._text:set_color(self._table_params.row_params.highlight_color)
	end
end

function BLTGuiControlTableCellDownloadStatus:highlight_off()
	if self._text and self._table_params and self._table_params.row_params and self._table_params.row_params.color and self._table_params.row_params.highlight_color then
		self._text:set_color(self._table_params.row_params.highlight_color)
	end
end

function BLTGuiControlTableCellDownloadStatus:select_on()
	if self._text and self._params.selected_color and self._params.color then
		self._text:set_color(self._params.selected_color)
	end
end

function BLTGuiControlTableCellDownloadStatus:select_off()
	if self._text and self._params.selected_color and self._params.color then
		self._text:set_color(self._params.color)
	end
end

function BLTGuiControlTableCellDownloadStatus:on_double_click(button)
	if self._params.on_double_click_callback then
		self._params.on_double_click_callback(button, self, self._data)
	end
end

function BLTGuiControlTableCellDownloadStatus:set_text(text)
	if self._text then
		self._text:set_text(text)
	end
end

function BLTGuiControlTableCellDownloadStatus:set_progress(progress)
	if self._progress then
		self._progress:set_progress(progress)
		if progress == 0 then
			self._progress:hide()
		else
			self._progress:show()
		end
	end
end
