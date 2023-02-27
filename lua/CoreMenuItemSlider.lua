local tweak_data = tweak_data

core:module("CoreMenuItemSlider")

local setup_gui = ItemSlider.setup_gui
function ItemSlider.setup_gui(self, node, row_item)
	local r = setup_gui(self, node, row_item)
	row_item.gui_slider_text:set_font_size(tweak_data.menu.stats_font_size)
	return r
end

function ItemSlider.set_value(self, value)
	self._value = math.min(math.max(self._min, value), self._max)
	self:dirty()
end

local reload = ItemSlider.reload
function ItemSlider.reload(self, row_item, node)
	local r = reload(self, row_item, node)
	if row_item then
		local value
		if self:show_value() then
			value = string.format("%.2f", self:value())
		else
			value = string.format("%.0f", self:percentage()) .. "%"
		end
		row_item.gui_slider_text:set_text(value)
	end
	return r
end
