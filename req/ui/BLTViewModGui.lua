---@class BLTViewModGui : BLTCustomComponent
---@field new fun(self):BLTViewModGui
BLTViewModGui = BLTViewModGui or blt_class(BLTCustomComponent)

-- Use the modified BLT back button
BLTViewModGui._add_back_button = BLTViewModGui._add_custom_back_button

local padding = 10

local small_font = BLT.fonts.small.font
local medium_font = BLT.fonts.medium.font

local small_font_size = BLT.fonts.small.font_size
local medium_font_size = BLT.fonts.medium.font_size

-- attaches white corners to panel, which will align correctly when 'panel' changes size
local function attach_corners(parent)
	local top_left = BoxGuiObject:new(parent, {sides = {3, 0, 3, 0}})
	top_left:set_aligns("left", "top")
	local bottom_left = BoxGuiObject:new(parent, {sides = {4, 0, 0, 3}})
	bottom_left:set_aligns("left", "bottom")
	local top_right = BoxGuiObject:new(parent, {sides = {0, 3, 4, 0}})
	top_right:set_aligns("right", "top")
	local bottom_right = BoxGuiObject:new(parent, {sides = {0, 4, 0, 4}})
	bottom_right:set_aligns("right", "bottom")
end

function BLTViewModGui:setup()
	-- Background
	self:make_background()

	-- Back button
	-- Automatically added by BLTCustomComponent

	-- Create page info
	self._mod = managers.menu_component._inspecting_blt_mod
	if self._mod then
		self:_setup_mod_info(self._mod)
		self:_setup_dev_info(self._mod)
		self:_setup_buttons(self._mod)
		self:refresh()
	else
		managers.menu:back(true)
	end
end

function BLTViewModGui:_setup_mod_info(mod)
	-- Page title
	local title = self:make_title(mod:GetName())
	self._title = title

	local version = self._panel:text({
		name = "version",
		font_size = medium_font_size,
		font = medium_font,
		layer = 10,
		color = tweak_data.screen_colors.title,
		alpha = 0.6,
		text = mod:GetVersion(),
		align = "left",
		vertical = "top"
	})
	BLT:make_fine_text(version)
	version:set_left(title:right() + padding)
	version:set_bottom(title:bottom() - 4)

	-- Mod info panel
	local info_panel = self._panel:panel({
		x = padding,
		y = title:bottom() + padding,
		w = self._panel:w() * 0.5 - padding * 2,
		h = self._panel:h() - title:bottom() - padding * 2
	})
	attach_corners(info_panel)
	self._info_panel = info_panel

	self._info_scroll = ScrollablePanel:new(info_panel, "info_scroll")
	local info_canvas = self._info_scroll:canvas()

	-- Load error
	local error_text
	if mod:Errors() then
		-- Build the errors string
		local error_str = ""
		for i, error in ipairs(mod:Errors()) do
			error_str = error_str .. (i > 1 and "\n" or "") .. managers.localization:text(error)
		end
		error_str = error_str .. "\n"

		-- Append any missing dependencies and if they available
		for _, dependency in ipairs(mod:GetMissingDependencies()) do
			local loc_str = dependency:GetServerData() and "blt_mod_missing_dependency_download" or "blt_mod_missing_dependency"
			error_str = error_str .. managers.localization:text(loc_str , {dependency = dependency:GetServerName()}) .. "\n"
		end
		error_str = error_str .. (#mod:GetMissingDependencies() > 0 and "\n" or "")

		for _, dependency_mod in ipairs(mod:GetDisabledDependencies()) do
			error_str = error_str .. managers.localization:text("blt_mod_disabled_dependency", {dependency = dependency_mod:GetName()}) .. "\n"
		end
		error_str = error_str .. (#mod:GetDisabledDependencies() > 0 and "\n" or "")

		-- Create the error text
		error_text = info_canvas:text({
			name = "error",
			x = padding,
			y = padding,
			w = info_canvas:w() - padding * 2,
			font_size = medium_font_size,
			font = medium_font,
			layer = 10,
			color = tweak_data.screen_colors.important_1,
			text = error_str,
			align = "left",
			vertical = "top",
			wrap = true,
			word_wrap = true
		})
		BLT:make_fine_text(error_text)
	end

	-- Mod description
	local desc = info_canvas:text({
		name = "desc",
		x = padding,
		y = padding,
		w = info_canvas:w() - padding * 2,
		font_size = medium_font_size,
		font = medium_font,
		layer = 10,
		color = tweak_data.screen_colors.title,
		text = mod:GetDescription(),
		align = "left",
		vertical = "top",
		wrap = true,
		word_wrap = true
	})
	BLT:make_fine_text(desc)
	if error_text then
		desc:set_top(error_text:bottom() + padding)
	end

	-- Mod author
	local author = info_canvas:text({
		name = "author",
		x = padding,
		y = padding,
		w = info_canvas:w() - padding * 2,
		font_size = medium_font_size,
		font = medium_font,
		layer = 10,
		color = tweak_data.screen_colors.title,
		text = managers.localization:text("blt_mod_info_author") .. ": " .. mod:GetAuthor(),
		align = "left",
		vertical = "top",
		wrap = true,
		word_wrap = true
	})
	BLT:make_fine_text(author)
	author:set_top(desc:bottom())

	-- Mod contact
	local contact = info_canvas:text({
		name = "contact",
		x = padding,
		y = padding,
		w = info_canvas:w() - padding * 2,
		font_size = medium_font_size,
		font = medium_font,
		layer = 10,
		color = tweak_data.screen_colors.title,
		text = managers.localization:text("blt_mod_info_contact") .. ": " .. mod:GetContact(),
		align = "left",
		vertical = "top",
		wrap = true,
		word_wrap = true
	})
	BLT:make_fine_text(contact)
	contact:set_top(author:bottom())
	-- min sblt version
	local min_sblt_ver = nil
	if mod:GetMinSBLTVer() then
		min_sblt_ver = info_canvas:text({
			name = "contact",
			x = padding,
			y = padding,
			w = info_canvas:w() - padding * 2,
			font_size = medium_font_size,
			font = medium_font,
			layer = 10,
			color = tweak_data.screen_colors.title,
			text = managers.localization:text("blt_mod_info_min_sblt_version") .. ": " .. mod:GetMinSBLTVer(),
			align = "left",
			vertical = "top",
			wrap = true,
			word_wrap = true
		})

		BLT:make_fine_text(min_sblt_ver)
		min_sblt_ver:set_top(contact:bottom())
	end

	-- Mod update status
	local update_status = info_canvas:text({
		name = "update_status",
		x = padding,
		y = padding,
		w = info_canvas:w() - padding * 2,
		font_size = medium_font_size,
		font = medium_font,
		layer = 10,
		color = tweak_data.screen_colors.title,
		align = "left",
		vertical = "top",
		wrap = true,
		word_wrap = true
	})
	update_status:set_top(min_sblt_ver ~= nil and min_sblt_ver:bottom() or contact:bottom())

	if mod:GetUpdateError() then
		update_status:set_text(managers.localization:text("blt_update_mod_error", {
			reason = mod:GetUpdateError()
		}))
		update_status:set_color(Color.red)
	elseif mod:IsCheckingForUpdates() then
		update_status:set_text(managers.localization:text("blt_checking_updates"))
		update_status:set_color(Color.blue)
	elseif BLT.Downloads:get_pending_downloads_for(mod) then
		update_status:set_text(managers.localization:text("blt_update_mod_available", {
			name = mod:GetName()
		}))
		update_status:set_color(Color.yellow)
	else
		update_status:hide()
	end

	BLT:make_fine_text(update_status)

	self._info_scroll:update_canvas_size()
end

function BLTViewModGui:_setup_dev_info(mod)
	local dev_panel = self._panel:panel({
		x = padding,
		y = padding,
		w = self._panel:w() * 0.5 - padding * 2,
		h = (self._panel:h() - self._title:bottom() + padding) * 0.5 - padding * 2
	})
	dev_panel:set_bottom(self._panel:h() - padding * 4)
	BoxGuiObject:new(dev_panel:panel({layer = 100}), {sides = {1, 1, 1, 1}})
	self._dev_panel = dev_panel

	self._dev_scroll = ScrollablePanel:new(dev_panel, "dev_scroll")
	local dev_canvas = self._dev_scroll:canvas()

	local info = dev_canvas:text({
		name = "dev_info",
		x = padding,
		y = padding,
		w = dev_canvas:w() - padding * 2,
		font_size = small_font_size,
		font = small_font,
		layer = 10,
		color = tweak_data.screen_colors.title,
		text = mod:GetDeveloperInfo(),
		align = "left",
		vertical = "top",
		wrap = true,
		word_wrap = true
	})
	BLT:make_fine_text(info)

	self._dev_scroll:update_canvas_size()
	self._dev_panel:set_visible(false)
end

function BLTViewModGui:_setup_buttons(mod)
	local buttons_panel = self._panel:panel({
		x = padding,
		y = padding,
		w = self._panel:w() * 0.5 - padding * 2,
		h = self._panel:h() - padding * 2
	})
	buttons_panel:set_top(self._info_panel:top())
	buttons_panel:set_left(self._info_panel:right() + padding)

	local button_w = 280
	local button_h = 230
	local btn
	local next_row_height

	if not mod:IsUndisablable() then
		btn = BLTUIButton:new(buttons_panel, {
			x = 0,
			y = 0,
			w = button_w,
			h = button_h,
			title = managers.localization:text("blt_mod_state_enabled"),
			text = managers.localization:text("blt_mod_state_enabled_desc"),
			image = "guis/blt/enable",
			image_size = 96,
			callback = callback(self, self, "clbk_toggle_enable_state")
		})
		table.insert(self._buttons, btn)
		self._enabled_button = btn
		next_row_height = button_h + padding
	end

	if self._mod:HasUpdates() then
		btn = BLTUIButton:new(buttons_panel, {
			x = 0,
			y = next_row_height or 0,
			w = button_w,
			h = button_h,
			title = managers.localization:text("blt_mod_updates_enabled"),
			text = managers.localization:text("blt_mod_updates_enabled_help"),
			image = "guis/blt/updates",
			image_size = 96,
			callback = callback(self, self, "clbk_toggle_updates_state")
		})
		table.insert(self._buttons, btn)
		self._updates_button = btn

		btn = BLTUIButton:new(buttons_panel, {
			x = button_w + padding,
			y = next_row_height or 0,
			w = button_w,
			h = button_h,
			title = managers.localization:text("blt_mod_check_for_updates"),
			text = managers.localization:text("blt_mod_check_for_updates_desc"),
			image = "guis/blt/check_updates",
			image_size = 96,
			callback = callback(self, self, "clbk_check_for_updates")
		})
		table.insert(self._buttons, btn)
		self._check_update_button = btn

		next_row_height = (next_row_height or 0) + button_h + padding
	end

	btn = BLTUIButton:new(buttons_panel, {
		x = 0,
		y = (next_row_height or 0),
		w = button_w,
		h = button_h * 0.5,
		title = managers.localization:text("blt_mod_toggle_dev"),
		text = managers.localization:text("blt_mod_toggle_dev_desc"),
		callback = callback(self, self, "clbk_toggle_dev_info")
	})
	table.insert(self._buttons, btn)

	if self._mod:IsContactWebsite() then
		btn = BLTUIButton:new(buttons_panel, {
			x = button_w + padding,
			y = (next_row_height or 0),
			w = button_w,
			h = button_h * 0.5,
			title = managers.localization:text("blt_mod_open_contact"),
			text = managers.localization:text("blt_mod_open_contact_desc"),
			callback = callback(self, self, "clbk_btn_open_contact", self._mod:GetContact())
		})
		table.insert(self._buttons, btn)
	end
end

--------------------------------------------------------------------------------

function BLTViewModGui:_mouse_pressed(button, x, y)
	if alive(self._info_scroll) then
		if self._info_scroll:mouse_pressed(button, x, y) then
			return true
		end
	end
	if alive(self._dev_scroll) then
		if self._dev_scroll:mouse_pressed(button, x, y) then
			return true
		end
	end
end

function BLTViewModGui:_mouse_released(button, x, y)
	if alive(self._info_scroll) then
		self._info_scroll:mouse_released(button, x, y)
	end
	if alive(self._dev_scroll) then
		self._dev_scroll:mouse_released(button, x, y)
	end
end

function BLTViewModGui:mouse_move(o, x, y)
	local used, pointer
	if alive(self._info_scroll) then
		used, pointer = self._info_scroll:mouse_moved(o, x, y)
	end

	if alive(self._dev_scroll) and not used then
		used, pointer = self._dev_scroll:mouse_moved(o, x, y)
	end
	if not used then
		return BLTViewModGui.super.mouse_move(self, o, x, y)
	else
		return used, pointer
	end
end

function BLTViewModGui:mouse_wheel_up(x, y)
	if alive(self._info_scroll) then
		self._info_scroll:scroll(x, y, 1)
	end
	if alive(self._dev_scroll) then
		self._dev_scroll:scroll(x, y, 1)
	end
end

function BLTViewModGui:mouse_wheel_down(x, y)
	if alive(self._info_scroll) then
		self._info_scroll:scroll(x, y, -1)
	end
	if alive(self._dev_scroll) then
		self._dev_scroll:scroll(x, y, -1)
	end
end

function BLTViewModGui:update(t, dt)
	if self._check_update_button and alive(self._check_update_button:image()) and self._mod then
		if self._mod:IsCheckingForUpdates() then
			self._check_update_button:image():set_rotation(self._check_update_button:image():rotation() + dt * 360)
		else
			self._check_update_button:image():set_rotation(0)
		end
	end
end

--------------------------------------------------------------------------------

function BLTViewModGui:clbk_toggle_enable_state()
	self._mod:SetEnabled(not self._mod:IsEnabled())
	self:refresh()
end

function BLTViewModGui:clbk_toggle_safemode_state()
	self._mod:SetSafeModeEnabled(not self._mod:IsSafeModeEnabled())
	self:refresh()
end

function BLTViewModGui:clbk_toggle_updates_state()
	self._mod:SetUpdatesEnabled(not self._mod:AreUpdatesEnabled())
	self:refresh()
end

function BLTViewModGui:clbk_check_for_updates()
	if not self._mod:IsCheckingForUpdates() then
		self._mod:CheckForUpdates(callback(self, self, "clbk_check_for_updates_finished"))
	end
end

function BLTViewModGui:clbk_check_for_updates_finished(cache)
	-- Does this mod need updating
	local requires_update = false
	local error_reason
	for update_id, data in pairs(cache) do
		-- An update for this mod needs updating
		requires_update = data.requires_update or requires_update

		-- Add the update to the download manager
		if data.requires_update then
			BLT.Downloads:add_pending_download(data.update)
		end
	end

	-- Show updates dialog
	if error_reason then
		QuickMenu:new(
			managers.localization:text("blt_update_mod_title", {name = self._mod:GetName()}),
			managers.localization:text("blt_update_mod_error", {reason = error_reason}),
			{
				{
					text = managers.localization:text("dialog_ok"),
					is_cancel_button = true
				}
			},
			true
		)
	elseif not requires_update then
		QuickMenu:new(
			managers.localization:text("blt_update_mod_title", {name = self._mod:GetName()}),
			managers.localization:text("blt_update_mod_up_to_date", {name = self._mod:GetName()}),
			{
				{
					text = managers.localization:text("dialog_ok"),
					is_cancel_button = true
				}
			},
			true
		)
	else
		QuickMenu:new(
			managers.localization:text("blt_update_mod_title", {name = self._mod:GetName()}),
			managers.localization:text("blt_update_mod_available", {name = self._mod:GetName()}),
			{
				{
					text = managers.localization:text("blt_update_mod_goto_manager"),
					callback = callback(self, self, "clbk_goto_download_manager")
				},
				{
					text = managers.localization:text("dialog_ok"),
					is_cancel_button = true
				}
			},
			true
		)
	end
end

function BLTViewModGui:clbk_goto_download_manager()
	MenuHelper:OpenMenu("blt_download_manager")
end

function BLTViewModGui:clbk_toggle_dev_info()
	local show_dev = not self._dev_panel:visible() -- get new state

	-- change info panel size
	if show_dev then
		self._info_panel:set_h(self._dev_panel:top() - self._title:bottom() - padding * 2)
	else
		self._info_panel:set_h(self._panel:h() - self._title:bottom() - padding * 2)
	end
	self._info_scroll:set_size(self._info_panel:size())
	self._info_scroll:update_canvas_size()

	-- change dev panel visibility
	self._dev_panel:set_visible(show_dev)
end

function BLTViewModGui:clbk_btn_open_contact(contact_url)
	Utils.OpenUrlSafe(contact_url)
end

function BLTViewModGui:refresh()
	-- Refresh mod enabled button
	if self._enabled_button then
		self._enabled_button:image():set_alpha(self._mod:IsEnabled() and 1 or 0.4)
		if self._mod:WasEnabledAtStart() then
			if self._mod:IsEnabled() then
				self._enabled_button:title():set_text(managers.localization:text("blt_mod_state_enabled"))
				self._enabled_button:text():set_text(managers.localization:text("blt_mod_state_enabled_desc"))
			else
				self._enabled_button:title():set_text(managers.localization:text("blt_mod_state_disabled_on_restart"))
				self._enabled_button:text():set_text(managers.localization:text("blt_mod_state_disabled_on_restart_desc"))
			end
		else
			if self._mod:IsEnabled() then
				self._enabled_button:title():set_text(managers.localization:text("blt_mod_state_enabled_on_restart"))
				self._enabled_button:text():set_text(managers.localization:text("blt_mod_state_enabled_on_restart_desc"))
			else
				self._enabled_button:title():set_text(managers.localization:text("blt_mod_state_disabled"))
				self._enabled_button:text():set_text(managers.localization:text("blt_mod_state_disabled_desc"))
			end
		end
	end

	-- Refresh automatic updates
	if self._updates_button then
		self._updates_button:image():set_alpha(self._mod:AreUpdatesEnabled() and 1 or 0.4)
		if self._mod:AreUpdatesEnabled() then
			self._updates_button:title():set_text(managers.localization:text("blt_mod_updates_enabled"))
			self._updates_button:text():set_text(managers.localization:text("blt_mod_updates_enabled_help"))
		else
			self._updates_button:title():set_text(managers.localization:text("blt_mod_updates_disabled"))
			self._updates_button:text():set_text(managers.localization:text("blt_mod_updates_disabled_help"))
		end
	end
end

MenuHelper:AddComponent("blt_view_mod", BLTViewModGui)

--------------------------------------------------------------------------------
-- Create the menu node for the BLT Mods menu

Hooks:Add("CoreMenuData.LoadDataMenu", "BLTViewModGui.CoreMenuData.LoadDataMenu", function(menu_id, menu)
	if menu_id ~= "start_menu" then
		return
	end

	local new_node = {
		["_meta"] = "node",
		["name"] = "view_blt_mod",
		["menu_components"] = "blt_view_mod",
		["back_callback"] = "perform_blt_save",
		["no_item_parent"] = true,
		["no_menu_wrapper"] = true,
		["scene_state"] = "crew_management",
		[1] = {
			["_meta"] = "default_item",
			["name"] = "back"
		}
	}
	table.insert(menu, new_node)
end)
