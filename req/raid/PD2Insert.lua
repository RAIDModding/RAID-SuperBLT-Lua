--This file contains code from payday 2.

--They are defined but the PD2 files don't actually exist so we'll just swap them with raid ones.
tweak_data.menu.pd2_massive_font = "ui/fonts/pf_din_text_comp_pro_medium_42_mf"
tweak_data.menu.pd2_large_font = "ui/fonts/pf_din_text_comp_pro_medium_32_mf"
tweak_data.menu.pd2_medium_font = "ui/fonts/pf_din_text_comp_pro_medium_24_mf"
tweak_data.menu.pd2_small_font = "ui/fonts/pf_din_text_comp_pro_medium_18_mf"

--Allow mods to hook to these classes
local function pre_require(path)
	local path_lower = path:lower()
	BLT:RunHookTable(BLT.hook_tables.pre[path_lower], path_lower)
end

local function post_require(path)
	local path_lower = path:lower()
	BLT:RunHookTable(BLT.hook_tables.post[path_lower], path_lower)
	BLT:RunHookTable(BLT.hook_tables.wildcards, path_lower)
end

pre_require("lib/managers/menu/ScrollablePanel")
ScrollablePanel = ScrollablePanel or class()
local PANEL_PADDING = 10
local FADEOUT_SPEED = 5
local SCROLL_SPEED = 28
ScrollablePanel.SCROLL_SPEED = SCROLL_SPEED

function ScrollablePanel:init(parent_panel, name, data)
	data = data or {}
	self._alphas = {}
	self._x_padding = data.x_padding ~= nil and data.x_padding or data.padding ~= nil and data.padding or PANEL_PADDING
	self._y_padding = data.y_padding ~= nil and data.y_padding or data.padding ~= nil and data.padding or PANEL_PADDING
	self._force_scroll_indicators = data.force_scroll_indicators
	self._color = data.color or tweak_data.gui.colors.raid_red
	self._scroll_speed = data.scroll_speed or SCROLL_SPEED
	self._fadeout_speed = data.fadeout_speed or FADEOUT_SPEED
	self._scroll_width = data.scroll_width or 6
	local layer = data.layer ~= nil and data.layer or 50
	data.name = data.name or name and name .. "Base"
	self._panel = parent_panel:panel(data)
	self._scroll_panel = self._panel:panel({
		name = name and name .. "Scroll",
		x = self:x_padding(),
		y = self:y_padding(),
		w = self._panel:w() - self:x_padding() * 2,
		h = self._panel:h() - self:y_padding() * 2
	})
	self._canvas = self._scroll_panel:panel({
		name = name and name .. "Canvas",
		w = self._scroll_panel:w(),
		h = self._scroll_panel:h()
	})

	self._scroll_bar = self:panel():panel({
		name = "scroll_bar",
		halign = "right",
		w = self._scroll_width,
		layer = layer - 1,
	})
	self._scroll_bar:rect({
		name = "scroll",
		color = self._color,
        halign = "grow",
        valign = "grow"
	})

	if data.left_scrollbar then
		self._scroll_bar:set_x(2)
	else
		self._scroll_bar:set_right(self:panel():w() - self:scrollbar_x_padding())
	end

	self._bar_minimum_size = data.bar_minimum_size or 5
	self._thread = self._panel:animate(self._update, self)

	self:canvas():set_w(self:panel():w() - self._scroll_width)
end

function ScrollablePanel:set_scroll_color(color)
	self._color = color or Color.white
	if not self:alive() then
		return
	end

	self._scroll_bar:child("scroll"):set_color(self._color)
end

function ScrollablePanel:alive()
	return alive(self:panel())
end

function ScrollablePanel:panel()
	return self._panel
end

function ScrollablePanel:scroll_panel()
	return self._scroll_panel
end

function ScrollablePanel:canvas()
	return self._canvas
end

function ScrollablePanel:x_padding()
	return self._x_padding
end

function ScrollablePanel:y_padding()
	return self._y_padding
end

function ScrollablePanel:scrollbar_x_padding()
	if self._x_padding == 0 then
		return PANEL_PADDING
	else
		return self._x_padding
	end
end

function ScrollablePanel:scrollbar_y_padding()
	if self._y_padding == 0 then
		return PANEL_PADDING
	else
		return self._y_padding
	end
end

function ScrollablePanel:set_pos(x, y)
	if x ~= nil then
		self:panel():set_x(x)
	end

	if y ~= nil then
		self:panel():set_y(y)
	end
end

function ScrollablePanel:set_size(w, h)
	self:panel():set_size(w, h)
	self:scroll_panel():set_size(w - self:x_padding() * 2, h - self:y_padding() * 2)
	self._scroll_bar:set_right(self:panel():w() - self:scrollbar_x_padding())
	self:canvas():set_w(self:canvas_max_width())
end

function ScrollablePanel:on_canvas_updated_callback(callback)
	self._on_canvas_updated = callback
end

function ScrollablePanel:canvas_max_width()
	return self:canvas_scroll_width()
end

function ScrollablePanel:canvas_scroll_width()
	return math.max(0, self:scroll_panel():w() - (self._scroll_bar:w() - 2))
end

function ScrollablePanel:canvas_scroll_height()
	return self:scroll_panel():h()
end

function ScrollablePanel:update_canvas_size(h)
	local orig_w = self:canvas():w()
	if h then
		max_h = h
	else
		max_h = 0
		for i, panel in pairs(self:canvas():children()) do
			local h = panel:y() + panel:h()

			if max_h < h then
				max_h = h
			end
		end
	end
	local show_scrollbar = self:canvas_scroll_height() < max_h
	local max_w = show_scrollbar and self:canvas_scroll_width() or self:canvas_max_width()

	self:canvas():grow(max_w - self:canvas():w(), max_h - self:canvas():h())

	if self._on_canvas_updated then
		self._on_canvas_updated(max_w)
	end
	if not h then
		max_h = 0
		for i, panel in pairs(self:canvas():children()) do
			local h = panel:y() + panel:h()

			if max_h < h then
				max_h = h
			end
		end
	end

	if max_h <= self:scroll_panel():h() then
		max_h = self:scroll_panel():h()
	end

	self:set_canvas_size(nil, max_h)
end

function ScrollablePanel:set_canvas_size(w, h)
	w = w or self:canvas():w()
	h = h or self:canvas():h()
	if h <= self:scroll_panel():h() then
		h = self:scroll_panel():h()
		self:canvas():set_y(0)
	end
	self:canvas():set_size(w, h)
	local show_scrollbar = (h - self:scroll_panel():h()) > 0.5
	if not show_scrollbar then
		self._scroll_bar:set_alpha(0)
		self._scroll_bar:set_visible(false)
	else
		self._scroll_bar:set_alpha(1)
		self._scroll_bar:set_visible(true)
		self:_set_scroll_indicator()
		self:_check_scroll_indicator_states()
	end
end

function ScrollablePanel:is_scrollable()
	return self:scroll_panel():h() < self:canvas():h()
end

function ScrollablePanel:scroll(x, y, direction)
	if self:panel():inside(x, y) then
		self:perform_scroll(self._scroll_speed * TimerManager:main():delta_time() * 200, direction)
		return true
	end
end

function ScrollablePanel:perform_scroll(speed, direction)
	if self:canvas():h() <= self:scroll_panel():h() then
		return
	end

	local scroll_amount = speed * direction
	local max_h = self:canvas():h() - self:scroll_panel():h()
	max_h = max_h * -1
	local new_y = math.clamp(self:canvas():y() + scroll_amount, max_h, 0)

	self:canvas():set_y(new_y)
	self:_set_scroll_indicator()
	self:_check_scroll_indicator_states()
end

function ScrollablePanel:scroll_to(y)
	if self:canvas():h() <= self:scroll_panel():h() then
		return
	end

	local scroll_amount = -y
	local max_h = self:canvas():h() - self:scroll_panel():h()
	max_h = max_h * -1
	local new_y = math.clamp(scroll_amount, max_h, 0)

	self:canvas():set_y(new_y)
	self:_set_scroll_indicator()
	self:_check_scroll_indicator_states()
end

function ScrollablePanel:scroll_with_bar(target_y, current_y)
	local scroll_panel = self:scroll_panel()
	local canvas = self:canvas()
	if target_y < current_y then
		if target_y < scroll_panel:world_bottom() then
			local mul = scroll_panel:h() / canvas:h()

			self:perform_scroll((current_y - target_y) / mul, 1)
		end
		current_y = target_y
	elseif current_y < target_y then
		if scroll_panel:world_y() < target_y then
			local mul = scroll_panel:h() / canvas:h()

			self:perform_scroll((target_y - current_y) / mul, -1)
		end
		current_y = target_y
	end
end

function ScrollablePanel:release_scroll_bar()
	self._pressing_arrow_up = false
	self._pressing_arrow_down = false

	if self._grabbed_scroll_bar then
		self._grabbed_scroll_bar = false

		return true
	end
end

function ScrollablePanel:_set_scroll_indicator()
	if self:canvas():h() ~= 0 then
		self._scroll_bar:set_h(math.max((self:panel():h() * self:scroll_panel():h()) / self:canvas():h(), self._bar_minimum_size))
	end
end

function ScrollablePanel:_check_scroll_indicator_states()
	local up_alpha = self:canvas():top() < 0 and 1 or 0
	local down_alpha = self:scroll_panel():h() < self:canvas():bottom() and 1 or 0

	local canvas_h = self:canvas():h() ~= 0 and self:canvas():h() or 1
	local at = self:canvas():top() / (self:scroll_panel():h() - canvas_h)
	local max = self:panel():h() - self._scroll_bar:h()

	self._scroll_bar:set_top(max * at)
end

function ScrollablePanel._update(o, self)
	while true do
		local dt = coroutine.yield()

		for element_name, data in pairs(self._alphas) do
			data.current = math.step(data.current, data.target, dt * data.speed)
			local element = self:panel():child(element_name)

			if alive(element) then
				element:set_alpha(data.current)
			end
		end
	end
end

function ScrollablePanel:mouse_moved(button, x, y)
	if self._grabbed_scroll_bar then
		self:scroll_with_bar(y, self._current_y)

		self._current_y = y

		return true, "grab"
	elseif alive(self._scroll_bar) and self._scroll_bar:visible() and self._scroll_bar:inside(x, y) then
		return true, "hand"
	end
end

function ScrollablePanel:mouse_clicked(o, button, x, y)
	if alive(self._scroll_bar) and self._scroll_bar:visible() and self._scroll_bar:inside(x, y) then
		return true
	end
end

function ScrollablePanel:mouse_pressed(button, x, y)
	if alive(self._scroll_bar) and self._scroll_bar:visible() and self._scroll_bar:inside(x, y) then
		self._grabbed_scroll_bar = true
		self._current_y = y

		return true
	end
end

function ScrollablePanel:mouse_released(button, x, y)
	return self:release_scroll_bar()
end
post_require("lib/managers/menu/ScrollablePanel")

local orig_map_append = table.map_append
function table.map_append(t, ...)
	orig_map_append(t, ...)
	return t
end