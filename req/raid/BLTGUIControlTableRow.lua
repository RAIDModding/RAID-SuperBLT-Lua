require("lib/managers/menu/raid_menu/controls/raidguicontroltablerow")

BLTGUIControlTableRow = BLTGUIControlTableRow or blt_class(RaidGUIControlTableRow)

function BLTGUIControlTableRow:init(parent, params, row_data, table_params)
	RaidGUIControlTableRow.super.init(self, parent, params)

	self.cells = {}
	self.button_cells = {}
	self.row_data = row_data
	self._selected = false
	self._type = "raid_gui_control_table_row"

	local cell_params = clone(params)

	cell_params.layer = self:layer() + 150
	cell_params.y = 0
	self._selector_mark = self:rect({
		color = tweak_data.gui.colors.raid_red,
		h = params.height,
		visible = false,
		w = 2,
		x = 0,
		y = 0,
	})

	local x = 0

	for column_index, column_data in ipairs(table_params.columns) do
		local cell_class = column_data.cell_class or RaidGUIControlTableCell

		cell_params.name = self._params.name .. "_column_" .. column_index
		cell_params.x = x + (column_data.padding or 0)
		cell_params.w = column_data.w - 2 * (column_data.padding or 0)

		if row_data[column_index] and row_data[column_index].text then
			cell_params.text = row_data[column_index].text or ""
			cell_params.color = row_data[column_index].color or column_data.color or Color.white
		end

		cell_params.align = column_data.align
		cell_params.vertical = column_data.vertical
		cell_params.on_cell_click_callback = column_data.on_cell_click_callback
		cell_params.on_cell_double_click_callback = column_data.on_cell_double_click_callback
		cell_params.value = row_data[column_index].value or nil

		for column_data_item_key, column_data_value in pairs(column_data) do
			cell_params[column_data_item_key] = column_data_value
		end

		-- vanilla fix: pass row_data[column_index] (vanilla just does row_data, while not passing column_index at all)
		local cell = self:create_custom_control(cell_class, cell_params, row_data[column_index], table_params)

		if cell._params.on_click_callback then -- distinguish between regular cells and button cells
			table.insert(self.button_cells, cell)
		else
			table.insert(self.cells, cell)
		end

		x = x + column_data.w
	end
end

function BLTGUIControlTableRow:mouse_released(o, button, x, y)
	-- vanilla fix: actually pass params
	return self:on_mouse_released(o, button, x, y)
end

function BLTGUIControlTableRow:on_mouse_released(o, button, x, y)
	if self._params.on_row_click_callback then
		self._params.on_row_click_callback(self.row_data, self._params.row_index)
	end

	-- pass mouse_released event to button cells
	for _, cell in ipairs(self.button_cells) do
		if cell:inside(x, y) and cell.mouse_released then
			cell:mouse_released(o, button, x, y)
		end
	end

	return true
end

function BLTGUIControlTableRow:mouse_moved(o, x, y)
	local inside = self:inside(x, y)

	if inside then
		-- route mouse_moved to button cells
		for _, cell in ipairs(self.button_cells) do
			if cell:mouse_moved(o, x, y) then
				return true, self._pointer_type
			end
		end
	end

	if self:selected() then
		return
	end

	if inside then
		if not self._mouse_inside then
			self:on_mouse_over(x, y)
		end
		return true, self._pointer_type
	end

	if self._mouse_inside then
		self:on_mouse_out(x, y)
	end

	return false
end

function BLTGUIControlTableRow:select_off()
	BLTGUIControlTableRow.super.select_off(self)

	-- unselect all button cells
	for _, cell in ipairs(self.button_cells) do
		cell:select_off()
	end
end

function BLTGUIControlTableRow:move_left()
	if self._selected_button_idx then
		-- unselect current button
		self.button_cells[self._selected_button_idx]:select_off()
	end

	local btn_count = #self.button_cells

	if self._selected_button_idx == 1 then
		-- if current button was last one, unselect everything and return
		self._selected_button_idx = nil
		return true
	end

	-- try select next button
	for i = (self._selected_button_idx or (btn_count + 1)) - 1, btn_count, -1 do
		local button = self.button_cells[i]
		if button and button:visible() and button:enabled() then
			button:select_on()
			self._selected_button_idx = i -- remember and return
			return true
		end
	end

	-- no next btn
	self._selected_button_idx = nil
	return true
end

function BLTGUIControlTableRow:move_right()
	if self._selected_button_idx then
		-- unselect current button
		self.button_cells[self._selected_button_idx]:select_off()
	end

	local btn_count = #self.button_cells

	if self._selected_button_idx == btn_count then
		-- if current button was last one, unselect everything and return
		self._selected_button_idx = nil
		return true
	end

	-- try select next button
	for i = (self._selected_button_idx or 0) + 1, btn_count do
		local button = self.button_cells[i]
		if button and button:visible() and button:enabled() then
			button:select_on()
			self._selected_button_idx = i -- remember and return
			return true
		end
	end

	-- no next btn
	self._selected_button_idx = nil
	return true
end

function BLTGUIControlTableRow:confirm_pressed()
	if self._selected_button_idx then
		self.button_cells[self._selected_button_idx]:confirm_pressed()
	end
end
