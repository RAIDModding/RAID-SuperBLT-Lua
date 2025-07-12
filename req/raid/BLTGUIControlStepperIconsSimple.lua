BLTGUIControlStepperIconsSimple = BLTGUIControlStepperIconsSimple or class(RaidGUIControlStepperSimple)

function BLTGUIControlStepperIconsSimple:_create_stepper_controls(sort_descending)
    BLTGUIControlStepperIconsSimple.super._create_stepper_controls(self, sort_descending)

    self._value_label:set_visible(false)

    local label_params = {
        align = "center",
        color = RaidGUIControlStepperSimple.TEXT_COLOR,
        h = self._object:h(),
        layer = self._object:layer() + 1,
        name = "stepper_simple_icons_value_icon",
        vertical = "center",
        y = 0,
        texture = tweak_data.gui.icons.waypoint_special_where.texture,
        texture_rect = tweak_data.gui.icons.waypoint_special_where.texture_rect,
    }
    self._value_icon = self._object:image(label_params)
    self._value_icon:set_center_x(self._object:w() / 2)

    self:_select_item(self._selected_item_index, true)
end

function BLTGUIControlStepperIconsSimple:_select_item(index, skip_animation)
    if not self._value_icon then
        return
    end

    local item = self._stepper_data[index]
    if not item then
        return
    end

    item.text = ""
    BLTGUIControlStepperIconsSimple.super._select_item(self, index, skip_animation)

    if skip_animation then
        self:set_icon_by_item(item)
    else
        self._value_label:stop()
        self._value_label:animate(callback(self, self, "_animate_value_icon_change"), item, item.disabled)
    end
end

function BLTGUIControlStepperIconsSimple:set_disabled_items(disabled_item_data)
    BLTGUIControlStepperIconsSimple.super.set_disabled_items(self, disabled_item_data)

    self._value_icon:set_color(self._value_label:color())
end

function BLTGUIControlStepperIconsSimple:set_enabled(enabled)
    BLTGUIControlStepperIconsSimple.super.set_enabled(self, enabled)

    self._value_icon:set_color(self._value_label:color())
end

function BLTGUIControlStepperIconsSimple:_animate_value_icon_change(o, item, disabled)
    local starting_alpha = self._value_icon:alpha()
    local duration = 0.13
    local t = duration - starting_alpha * duration

    while t < duration do
        local dt = coroutine.yield()

        t = t + dt

        local alpha = Easing.linear(t, 1, -1, duration)

        self._value_icon:set_alpha(alpha)
    end

    self._value_icon:set_alpha(0)
    self:set_icon_by_item(item)

    if disabled then
        self._value_icon:set_color(RaidGUIControlStepperSimple.TEXT_COLOR_DISABLED)
    else
        self._value_icon:set_color(RaidGUIControlStepperSimple.TEXT_COLOR)
    end

    duration = 0.18
    t = 0

    while t < duration do
        local dt = coroutine.yield()

        t = t + dt

        local alpha = Easing.quartic_out(t, 0, 1, duration)

        self._value_icon:set_alpha(alpha)
    end

    self._value_icon:set_alpha(1)
end

function BLTGUIControlStepperIconsSimple:set_icon_by_item(item)
    if item.icon_id then
        local v = tweak_data.gui.icons[item.icon_id]
        if v and v.texture and v.texture_rect then
            self._value_icon:set_image(v.texture)
            self:set_icon_texture_rect(v.texture_rect)
        end
    elseif item.texture and item.texture_rect then
        self._value_icon:set_image(item.texture)
        self:set_icon_texture_rect(item.texture_rect)
    end
end

function BLTGUIControlStepperIconsSimple:set_icon_texture_rect(texture_rect)
    self._value_icon:set_w(texture_rect[3] * self._value_icon:h() / texture_rect[4])
    self._value_icon:set_center_x(self._object:w() / 2)
    self._value_icon:set_texture_rect(texture_rect)
end
