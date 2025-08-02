
BLTGUIControlMenuButton = BLTGUIControlMenuButton or blt_class(BLTGUIControlButton)

BLTGUIControlMenuButton.TEXT_PADDING = 16
BLTGUIControlMenuButton.TEXT_COLOR = tweak_data.gui.colors.raid_grey
BLTGUIControlMenuButton.TEXT_COLOR_DISABLED = tweak_data.gui.colors.raid_dark_grey
BLTGUIControlMenuButton.TEXT_HIGHLIGHT_COLOR = tweak_data.gui.colors.raid_white
BLTGUIControlMenuButton.SIDELINE_COLOR = tweak_data.gui.colors.raid_red
BLTGUIControlMenuButton.SIDELINE_W = 3

function BLTGUIControlMenuButton:init(parent, params)
	params.text_padding = BLTGUIControlMenuButton.SIDELINE_W + BLTGUIControlMenuButton.TEXT_PADDING + (params.text_padding or 0)
	params.font_size = params.font_size or tweak_data.gui.font_sizes.small
	params.color = params.color or BLTGUIControlMenuButton.TEXT_COLOR
	params.color_disabled = params.color_disabled or BLTGUIControlMenuButton.TEXT_COLOR_DISABLED
	params.highlight_color = params.highlight_color or BLTGUIControlMenuButton.TEXT_HIGHLIGHT_COLOR
	BLTGUIControlMenuButton.super.init(self, parent, params)
	self._object_text:set_color(self._params.color)
	self._sideline = self._object:rect({
		y = 0,
		w = BLTGUIControlMenuButton.SIDELINE_W,
		alpha = 0,
		x = 0,
		name = "menu_button_highlight_" .. self._name,
		h = self._object:h(),
		color = self._params.sideline_color or BLTGUIControlMenuButton.SIDELINE_COLOR
	})
end

function BLTGUIControlMenuButton:highlight_on()
	if not self._enabled then
		return
	end
	BLTGUIControlMenuButton.super.highlight_on(self)
	self._object_text:set_color(self._params.color)
	self._object:stop()
	self._object:animate(callback(self, self, "_animate_highlight_on"))
end

function BLTGUIControlMenuButton:highlight_off()
	if not self._enabled then
		return
	end
	BLTGUIControlMenuButton.super.highlight_off(self)
	self._object_text:set_color(self._params.highlight_color)
	self._object:stop()
	self._object:animate(callback(self, self, "_animate_highlight_off"))
end

function BLTGUIControlMenuButton:_animate_highlight_on()
	local starting_alpha = self._sideline:alpha()
	local duration = 0.2
	local t = duration - (1 - starting_alpha) * duration
	while duration > t do
		local dt = coroutine.yield()
		t = t + dt
		local alpha = Easing.quartic_out(t, 0, 1, duration)
		self._sideline:set_alpha(alpha)
		local description_r = Easing.quartic_out(t, self._params.color.r, self._params.highlight_color.r - self._params.color.r, duration)
		local description_g = Easing.quartic_out(t, self._params.color.g, self._params.highlight_color.g - self._params.color.g, duration)
		local description_b = Easing.quartic_out(t, self._params.color.b, self._params.highlight_color.b - self._params.color.b, duration)
		self._object_text:set_color(Color(description_r, description_g, description_b))
	end
	self._sideline:set_alpha(1)
	self._object_text:set_color(self._params.highlight_color)
end

function BLTGUIControlMenuButton:_animate_highlight_off()
	local starting_alpha = self._sideline:alpha()
	local duration = 0.2
	local t = duration - starting_alpha * duration
	while duration > t do
		local dt = coroutine.yield()
		t = t + dt
		local alpha = Easing.quartic_out(t, 1, -1, duration)
		self._sideline:set_alpha(alpha)
		local description_r = Easing.quartic_out(t, self._params.highlight_color.r, self._params.color.r - self._params.highlight_color.r, duration)
		local description_g = Easing.quartic_out(t, self._params.highlight_color.g, self._params.color.g - self._params.highlight_color.g, duration)
		local description_b = Easing.quartic_out(t, self._params.highlight_color.b, self._params.color.b - self._params.highlight_color.b, duration)
		self._object_text:set_color(Color(description_r, description_g, description_b))
	end
	self._sideline:set_alpha(0)
	self._object_text:set_color(self._params.color)
end

function BLTGUIControlMenuButton:enable()
	BLTGUIControlMenuButton.super.enable(self)
	self._object_text:set_color(self._params.color)
end

function BLTGUIControlMenuButton:disable()
	BLTGUIControlMenuButton.super.disable(self)
	self._object_text:set_color(self._params.color_disabled)
end
