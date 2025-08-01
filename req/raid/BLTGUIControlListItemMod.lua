require("lib/managers/menu/raid_menu/controls/raidguicontrol")

---@class BLTGUIControlListItemMod
---@field new fun(self, parent, params, data):BLTGUIControlListItemMod
---@field translate fun(self, text, upper_case_flag, additional_macros)
---@field super table
---@field _name string
---@field _panel table
---@field _params table
BLTGUIControlListItemMod = BLTGUIControlListItemMod or blt_class(RaidGUIControl)

BLTGUIControlListItemMod.HEIGHT = 104

BLTGUIControlListItemMod.NAME_CENTER_Y = 34

BLTGUIControlListItemMod.HIGHLIGHT_MARKER_W = 3
BLTGUIControlListItemMod.ICON_PADDING = 4
BLTGUIControlListItemMod.ICON_MAX_SIZE = 96

BLTGUIControlListItemMod.DISABLED_ICON = "ico_locker"
BLTGUIControlListItemMod.DISABLED_ICON_CENTER_DISTANCE_FROM_RIGHT = 43
BLTGUIControlListItemMod.DISABLED_COLOR = tweak_data.gui.colors.raid_dark_grey
BLTGUIControlListItemMod.ENABLED_COLOR = tweak_data.gui.colors.raid_dirty_white

function BLTGUIControlListItemMod:init(parent, params, data)
	BLTGUIControlListItemMod.super.init(self, parent, params)

	self._on_click_callback = params.on_click_callback
	self._on_item_selected_callback = params.on_item_selected_callback
	self._on_double_click_callback = params.on_double_click_callback
	self._data = data
	self._mod = data.mod
	self._color = params.color or tweak_data.gui.colors.raid_white
	self._selected_color = params.selected_color or tweak_data.gui.colors.raid_red
	self._mouse_over_sound = params.on_mouse_over_sound_event
	self._mouse_click_sound = params.on_mouse_click_sound_event

	self:_layout_panel(params)
	self:_layout_background(params)
	self:_layout_highlight_marker()
	self:_layout_icon(data)
	self:_layout_mod_name()
	self:_layout_mod_version()
	self:_layout_mod_status()

	self._selectable = self._data.selectable
	self._selected = false

	if self._mod:HasUpdates() then
		self:_layout_breadcrumb()

		for _, update in ipairs(self._mod:GetUpdates()) do
			update:register_event_handler("blt_mods_gui_list_on_update_change",
				callback(self, self, "_on_update_change"))
		end
	end

	self:highlight_off()

	self._is_mod_enabled = self._mod:IsEnabled() and self._mod:WasEnabledAtStart() and not self._mod:LastError()
	self:_layout_disabled_icon()
	if self._is_mod_enabled then
		self:_apply_enabled_layout()
	else
		self:_apply_disabled_layout()
	end
end

function BLTGUIControlListItemMod:close()
	for _, update in ipairs(self._mod:GetUpdates()) do
		update:remove_event_handler("blt_mods_gui_list_on_update_change")
	end
end

function BLTGUIControlListItemMod:_layout_breadcrumb()
	self._breadcrumb = self._object:breadcrumb({
		check_callback = function()
			return not not BLT.Downloads:get_pending_downloads_for(self._mod)
		end
	})
	self._breadcrumb:set_right(self._object:w())
	self._breadcrumb:set_center_y(self._object:h() / 2)
end

function BLTGUIControlListItemMod:_layout_disabled_icon()
	self._lock_icon = self._object:bitmap({
		color = tweak_data.gui.colors.raid_dark_grey,
		texture = tweak_data.gui.icons[BLTGUIControlListItemMod.DISABLED_ICON].texture,
		texture_rect = tweak_data.gui.icons[BLTGUIControlListItemMod.DISABLED_ICON].texture_rect,
	})
	self._lock_icon:set_center_x(self._object:w() - BLTGUIControlListItemMod.DISABLED_ICON_CENTER_DISTANCE_FROM_RIGHT)
	self._lock_icon:set_center_y(self._object:h() / 2)
end

function BLTGUIControlListItemMod:_apply_disabled_layout()
	self._lock_icon:show()
	self._item_icon:set_color(BLTGUIControlListItemMod.DISABLED_COLOR)
	self._item_label:set_color(BLTGUIControlListItemMod.DISABLED_COLOR)
	if self._missing_icon_text then
		self._missing_icon_text:set_color(BLTGUIControlListItemMod.DISABLED_COLOR)
	end
end

function BLTGUIControlListItemMod:_apply_enabled_layout()
	self._lock_icon:hide()
	self._item_icon:set_color(BLTGUIControlListItemMod.ENABLED_COLOR)
	self._item_label:set_color(BLTGUIControlListItemMod.ENABLED_COLOR)
	if self._missing_icon_text then
		self._missing_icon_text:set_color(BLTGUIControlListItemMod.ENABLED_COLOR)
	end
end

function BLTGUIControlListItemMod:_layout_panel(params)
	self._object = self._panel:panel({
		name = "list_item_" .. self._name,
		h = BLTGUIControlListItemMod.HEIGHT,
		w = params.w,
		x = params.x,
		y = params.y,
	})
end

function BLTGUIControlListItemMod:_layout_background(params)
	self._item_background = self._object:rect({
		color = tweak_data.gui.colors.raid_list_background,
		h = self._object:h() - 2,
		name = "list_item_back_" .. self._name,
		visible = false,
		w = params.w,
		x = 0,
		y = 1,
	})
end

function BLTGUIControlListItemMod:_layout_highlight_marker()
	self._item_highlight_marker = self._object:rect({
		color = self._selected_color,
		h = self._object:h() - 2,
		name = "list_item_highlight_" .. self._name,
		visible = false,
		w = BLTGUIControlListItemMod.HIGHLIGHT_MARKER_W,
		x = 0,
		y = 1,
	})
end

function BLTGUIControlListItemMod:_layout_icon(data)
	self._item_icon = self._object:image({
		color = tweak_data.gui.colors.raid_dirty_white,
		name = "list_item_icon_" .. self._name,
		layer = 10,
		texture = data.icon.texture,
		texture_rect = data.icon.texture_rect,
		x = BLTGUIControlListItemMod.ICON_PADDING + BLTGUIControlListItemMod.HIGHLIGHT_MARKER_W,
		y = BLTGUIControlListItemMod.ICON_PADDING,
	})
	local ogw, ogh = self._item_icon:w(), self._item_icon:h()
	if self._item_icon:h() > BLTGUIControlListItemMod.ICON_MAX_SIZE then
		self._item_icon:set_h(BLTGUIControlListItemMod.ICON_MAX_SIZE)
		self._item_icon:set_w(ogw * BLTGUIControlListItemMod.ICON_MAX_SIZE / ogh)
	end
	if self._item_icon:w() > BLTGUIControlListItemMod.ICON_MAX_SIZE then
		self._item_icon:set_w(BLTGUIControlListItemMod.ICON_MAX_SIZE)
		self._item_icon:set_h(ogh * BLTGUIControlListItemMod.ICON_MAX_SIZE / ogw)
	end
	data.icon.w, data.icon.h = self._item_icon:w(), self._item_icon:h()
	if data.missing_icon then
		self._missing_icon_text = self._object:label({
			name = "no_image_text",
			fit_size = true,
			font_size = tweak_data.gui.font_sizes.small,
			font = tweak_data.gui.fonts.din_compressed,
			layer = 11,
			text = data.missing_icon_text,
			align = "center",
			vertical = "center",
		})
		self._missing_icon_text:set_center_x(self._item_icon:center_x())
		self._missing_icon_text:set_center_y(self._item_icon:center_y())
	end
end

function BLTGUIControlListItemMod:_layout_mod_name()
	self._item_label = self._object:label({
		color = tweak_data.gui.colors.raid_dirty_white,
		font = tweak_data.gui.fonts.din_compressed,
		font_size = tweak_data.gui.font_sizes.small,
		name = "list_item_label_" .. self._name,
		text = self._mod:GetName(),
		x = self._item_icon:x() + self._item_icon:w() + BLTGUIControlListItemMod.ICON_PADDING,
		fit_text = true,
	})
	self._item_label:set_center_y(BLTGUIControlListItemMod.NAME_CENTER_Y)
end

function BLTGUIControlListItemMod:_layout_mod_version()
	self._version_label = self._object:label({
		color = tweak_data.gui.colors.raid_dark_grey,
		font = tweak_data.gui.fonts.din_compressed,
		font_size = tweak_data.gui.font_sizes.small,
		name = "version_label_" .. self._name,
		text = self._mod:GetVersion(),
		x = self._item_label:x() + self._item_label:w() + BLTGUIControlListItemMod.ICON_PADDING,
		fit_text = true,
	})
	self._version_label:set_center_y(BLTGUIControlListItemMod.NAME_CENTER_Y)
end

function BLTGUIControlListItemMod:_layout_mod_status()
	-- Mod update status
	self._mod_status = self._object:label({
		color = tweak_data.gui.colors.raid_dark_grey,
		font = tweak_data.gui.fonts.din_compressed,
		font_size = tweak_data.gui.font_sizes.small,
		name = "mod_status_" .. self._name,
		x = self._item_label:x(),
		y = self._item_label:bottom(),
		text = "",
		fit_text = true,
	})

	self:_refresh_mod_status()
end

function BLTGUIControlListItemMod:_refresh_mod_status()
	if not (self._mod_status and self._mod) then
		return
	end

	if self._mod:GetUpdateError() then
		self._mod_status:set_text(self:translate("blt_update_mod_error_short"))
		self._mod_status:set_color(tweak_data.gui.colors.raid_red)
	elseif self._mod:IsCheckingForUpdates() then
		self._mod_status:set_text(self:translate("blt_checking_updates"))
	elseif BLT.Downloads:get_pending_downloads_for(self._mod) then
		self._mod_status:set_text(self:translate("blt_update_mod_available_short", false, {
			name = self._mod:GetName()
		}))
		self._mod_status:set_color(tweak_data.gui.colors.progress_yellow)
	else
		self._mod_status:hide()
	end
end

function BLTGUIControlListItemMod:_on_update_change(update, requires_update, error_reason)
	self:_refresh_mod_status()
end

---

function BLTGUIControlListItemMod:on_mouse_released(button)
	if self._mouse_click_sound then
		managers.menu_component:post_event(self._mouse_click_sound)
	end

	if self._on_click_callback then
		self._on_click_callback(button, self, self._data)
	end

	if self._params.list_item_selected_callback then
		self._params.list_item_selected_callback(self._name)
	end
end

function BLTGUIControlListItemMod:mouse_double_click(o, button, x, y)
	if self._params.no_click then
		return
	end

	if self._on_double_click_callback then
		self._on_double_click_callback(nil, self, self._data)

		return true
	end
end

function BLTGUIControlListItemMod:selected()
	return self._selected
end

function BLTGUIControlListItemMod:select()
	self._selected = true
	self._item_background:show()
	if self._is_mod_enabled then
		self._item_label:set_color(self._selected_color)
	end
	self._item_highlight_marker:show()

	-- if self._data.breadcrumb then
	-- 	managers.breadcrumb:remove_breadcrumb(self._data.breadcrumb.category, self._data.breadcrumb.identifiers)
	-- end
	-- managers.breadcrumb:remove_breadcrumb(BreadcrumbManager.CATEGORY_OPERATIONS, {
	-- 	"operations_pending",
	-- })

	if self._on_item_selected_callback then
		self._on_item_selected_callback(self, self._data)
	end
end

function BLTGUIControlListItemMod:unfocus()
	self._item_background:hide()
	self._item_highlight_marker:hide()
end

function BLTGUIControlListItemMod:unselect()
	self._selected = false
	self._item_background:hide()
	if self._is_mod_enabled then
		self._item_label:set_color(self._color)
	end
	self._item_highlight_marker:hide()
end

function BLTGUIControlListItemMod:data()
	return self._data
end

function BLTGUIControlListItemMod:highlight_on()
	self._item_background:show()
	if self._mouse_over_sound then
		managers.menu_component:post_event(self._mouse_over_sound)
	end

	if not self._is_mod_enabled then
		return
	end

	if self._selected then
		self._item_label:set_color(self._selected_color)
	else
		self._item_label:set_color(self._color)
	end
end

function BLTGUIControlListItemMod:highlight_off()
	if not managers.menu:is_pc_controller() then
		self._item_highlight_marker:hide()
		self._item_background:hide()
	end
	if not self._selected then
		self._item_background:hide()
	end
end

function BLTGUIControlListItemMod:confirm_pressed()
	if self._selected then
		self:on_mouse_released(self._name)
		return true
	end
end
