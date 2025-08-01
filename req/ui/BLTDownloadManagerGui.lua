require("lib/managers/menu/raid_menu/controls/raidguicontrol")
require("lib/managers/menu/raid_menu/controls/raidguicontrollabel")
require("lib/managers/menu/raid_menu/controls/raidguicontroltablecell")

BLT:Require("req/raid/BLTGUIControlTableRow")
BLT:Require("req/raid/BLTGUIControlTableCellImage")
BLT:Require("req/raid/BLTGuiControlTableCellDownloadStatus")
BLT:Require("req/raid/BLTGUIControlTableCellButton")

---@class BLTDownloadManagerGui
---@field new fun(self, ws, fullscreen_ws, node):BLTDownloadManagerGui
---@field translate fun(self, string, upper_case)
---@field set_legend fun(self, legend)
---@field set_controller_bindings fun(self, bindings, clear_old)
---@field super table
---@field _node table
---@field _root_panel table
BLTDownloadManagerGui = BLTDownloadManagerGui or blt_class(RaidGuiBase)
BLTDownloadManagerGui.TABLE_ROW_HEIGHT = 64
BLTDownloadManagerGui.TABLE_MOD_ICON_SIZE = 48
BLTDownloadManagerGui.FALLBACK_GUI_ICON = "grid_item_fg"

local padding = 10

function BLTDownloadManagerGui:init(ws, fullscreen_ws, node)
	BLTDownloadManagerGui.super.init(self, ws, fullscreen_ws, node, "blt_download_manager")
	self._root_panel.ctrls = self._root_panel.ctrls or {}

	BLT.Downloads:register_event_handler(BLT.Downloads.EVENTS.download_added,
		"blt_download_manager_gui_on_download_added",
		callback(self, self, "_on_download_list_changed"))
	BLT.Downloads:register_event_handler(BLT.Downloads.EVENTS.download_removed,
		"blt_download_manager_gui_on_download_removed",
		callback(self, self, "_on_download_list_changed"))
end

function BLTDownloadManagerGui:_set_initial_data()
	self._node.components.raid_menu_header:set_screen_name("blt_download_manager")
end

function BLTDownloadManagerGui:_layout()
	self._object = self._root_panel:panel({}) -- our main panel

	local header_height = self._node.components.raid_menu_header._screen_subtitle_label:bottom()
	local footer_height = self._node.components.raid_menu_footer._panel_h
	local table_h = self._object:h() - header_height - footer_height
	local icon_w = BLTDownloadManagerGui.TABLE_ROW_HEIGHT
	local actions_w = 250

	-- relua button
	self._relua_btn = self._object:long_secondary_button({
		name = "blt_relua_btn",
		text = self:translate("blt_download_relua_button", true),
		on_click_callback = callback(self, self, "clbk_relua_button"),
		y = math.floor(header_height * 0.25),
		x = math.floor(self._object:w() * 0.63),
	})

	-- download_all button
	self._download_all_btn = self._object:long_secondary_button({
		name = "blt_download_all_btn",
		text = self:translate("blt_download_all", true),
		on_click_callback = callback(self, self, "clbk_download_all"),
		y = math.floor(header_height * 0.25),
		x = math.floor(self._object:w() * 0.8),
	})

	-- download scroll/table
	self._downloads_scroll = self._object:scrollable_area({
		layer = self._object:layer() + 1,
		name = "download_manager_scroll",
		scroll_step = 35,
		w = self._object:w(),
		h = table_h,
	})
	self._downloads_table = self._downloads_scroll:get_panel():table({
		loop_items = true,
		name = "downloads_table",
		on_selected_callback = callback(self, self, "bind_controller_inputs"),
		scrollable_area_ref = self._downloads_scroll,
		table_params = {
			columns = {
				-- mod icon cell
				{
					align = "left",
					cell_class = BLTGUIControlTableCellImage,
					color = tweak_data.gui.colors.raid_grey,
					header_padding = 32,
					header_text = " ", -- empty header
					highlight_color = tweak_data.gui.colors.raid_white,
					padding = 32,
					selected_color = tweak_data.gui.colors.raid_red,
					vertical = "center",
					w = icon_w,
				},
				-- mod name cell
				{
					align = "left",
					cell_class = RaidGUIControlTableCell,
					color = tweak_data.gui.colors.raid_grey,
					header_padding = -32,
					header_text = self:translate("blt_download_manager_header_mod", true),
					highlight_color = tweak_data.gui.colors.raid_white,
					padding = icon_w,
					selected_color = tweak_data.gui.colors.raid_red,
					vertical = "center",
					w = (self._downloads_scroll:w() - icon_w - actions_w * 2) / 2,
				},
				-- download status cell
				{
					align = "left",
					cell_class = BLTGuiControlTableCellDownloadStatus,
					color = tweak_data.gui.colors.raid_grey,
					header_padding = 0,
					header_text = self:translate("blt_download_manager_header_download_status", true),
					highlight_color = tweak_data.gui.colors.raid_white,
					padding = 0,
					selected_color = tweak_data.gui.colors.raid_red,
					vertical = "center",
					w = (self._downloads_scroll:w() - icon_w - actions_w * 2) / 2,
				},
				-- changelog cell
				{
					align = "left",
					cell_class = BLTGUIControlTableCellButton,
					color = tweak_data.gui.colors.raid_grey,
					header_padding = 0,
					header_text = " ",
					highlight_color = tweak_data.gui.colors.raid_white,
					on_cell_click_callback = callback(self, self, "on_cell_click_changelog"),
					padding = 0,
					selected_color = tweak_data.gui.colors.raid_red,
					vertical = "center",
					w = actions_w,
				},
				-- download cell
				{
					align = "left",
					cell_class = BLTGUIControlTableCellButton,
					color = tweak_data.gui.colors.raid_grey,
					header_padding = 0,
					header_text = " ",
					highlight_color = tweak_data.gui.colors.raid_white,
					on_cell_click_callback = callback(self, self, "on_cell_click_download"),
					padding = 0,
					selected_color = tweak_data.gui.colors.raid_red,
					vertical = "center",
					w = actions_w,
				}
			},
			data_source_callback = callback(self, self, "_data_source"),
			header_params = {
				font = tweak_data.gui.fonts.din_compressed,
				font_size = tweak_data.gui.font_sizes.small,
				header_height = 32,
				text_color = tweak_data.gui.colors.raid_white,
			},
			row_params = {
				row_class = BLTGUIControlTableRow,
				color = tweak_data.gui.colors.raid_grey,
				font = tweak_data.gui.fonts.din_compressed,
				font_size = tweak_data.gui.font_sizes.extra_small,
				height = BLTDownloadManagerGui.TABLE_ROW_HEIGHT,
				highlight_color = tweak_data.gui.colors.raid_white,
				row_background_color = tweak_data.gui.colors.raid_white:with_alpha(0),
				row_highlight_background_color = tweak_data.gui.colors.raid_white:with_alpha(0.1),
				row_selected_background_color = tweak_data.gui.colors.raid_white:with_alpha(0.1),
				selected_color = tweak_data.gui.colors.raid_red,
				spacing = 0,
			},
		},
		use_row_dividers = true,
		use_selector_mark = true,
		w = self._downloads_scroll:w() - padding * 2,
		y = header_height + padding,
		x = padding,
	})
	self._downloads_scroll:setup_scroll_area()

	self._downloads_table:set_selected(true)
	self:bind_controller_inputs()
end

function BLTDownloadManagerGui:_additional_active_controls()
	return {
		self._downloads_table
	}
end

function BLTDownloadManagerGui:bind_controller_inputs()
	local pending_downloads = BLT.Downloads:pending_downloads()
	local has_pending_downloads = (table.size(pending_downloads) > 0)
	local can_relua = has_pending_downloads and BLT:CheckUpdatesReluaPossible(pending_downloads)

	self._download_all_btn:set_visible(has_pending_downloads)
	self._relua_btn:set_visible(can_relua)

	local bindings = {
		-- TODO?: view patch notes (of selected mod)
		-- TODO?: download mod (of selected mod)
	}
	if has_pending_downloads then
		table.insert(bindings, {
			callback = callback(self, self, "clbk_download_all"),
			key = Idstring("menu_controller_face_left"),
		})
	end
	if can_relua then
		table.insert(bindings, {
			callback = callback(self, self, "clbk_relua_button"),
			key = Idstring("menu_controller_face_top"),
		})
	end
	self:set_controller_bindings(bindings, true)

	local legend = {
		controller = {
			"menu_legend_back",
		},
		keyboard = {
			{
				callback = callback(self, self, "_on_legend_pc_back", nil),
				key = "footer_back",
			},
		},
	}
	if has_pending_downloads then
		table.insert(legend.controller, {
			translated_text = managers.localization:get_default_macros().BTN_X .. " " ..
				self:translate("blt_download_all", true),
		})
	end
	if can_relua then
		table.insert(legend.controller, {
			translated_text = managers.localization:get_default_macros().BTN_Y .. " " ..
				self:translate("blt_download_relua_button", true),
		})
	end
	self:set_legend(legend)
end

function BLTDownloadManagerGui:_data_source()
	local result = {}
	for _, download in ipairs(BLT.Downloads:pending_downloads()) do
		local mod = download.update:GetParentMod()

		local mod_name = mod:GetName()
		local download_name = download.update:GetName() or mod_name
		if mod_name ~= download_name then
			download_name = download_name .. " (" .. mod_name .. ")"
		end

		table.insert(result, {
			{
				info = download_name,
				text = download_name,
				w = BLTDownloadManagerGui.TABLE_MOD_ICON_SIZE,
				h = BLTDownloadManagerGui.TABLE_MOD_ICON_SIZE,
				value = {
					texture = mod:HasModImage() and mod:GetModImage() or
						tweak_data.gui.icons[BLTDownloadManagerGui.FALLBACK_GUI_ICON].texture,
					texture_rect = (not mod:HasModImage()) and
						tweak_data.gui.icons[BLTDownloadManagerGui.FALLBACK_GUI_ICON].texture_rect or nil,
				},
			},
			{
				info = download_name,
				text = download_name,
				value = download,
			},
			{
				info = download_name,
				text = self:translate("blt_download_ready"),
				value = download,
			},
			{
				info = download_name,
				text = self:translate("blt_view_patch_notes", true),
				value = download,
				visible = download.update:GetPatchNotes() ~= nil,
			},
			{
				info = download_name,
				text = self:translate("blt_update_now", true),
				value = download,
			},
		})
	end
	table.sort(result, function(a, b)
		return a[1].info < b[1].info
	end)
	return result
end

function BLTDownloadManagerGui:on_cell_click_changelog(_, _, data)
	local update = data.value.update
	if update then
		update:ViewPatchNotes()
	end
end

function BLTDownloadManagerGui:on_cell_click_download(_, _, data)
	local update = data.value.update
	if update then
		if not BLT.Downloads:get_download(update) then
			BLT.Downloads:start_download(update,
				callback(self, self, "_on_download_completed")
			)
		end
	end
end

function BLTDownloadManagerGui:_on_download_completed(download)
	self:bind_controller_inputs()
end

function BLTDownloadManagerGui:_on_download_list_changed()
	self._downloads_table:refresh_data()
	self._downloads_scroll:setup_scroll_area()
	self:bind_controller_inputs()
end

function BLTDownloadManagerGui:close()
	BLT.Downloads:remove_event_handler(BLT.Downloads.EVENTS.download_added,
		"blt_download_manager_gui_on_download_added")
	BLT.Downloads:remove_event_handler(BLT.Downloads.EVENTS.download_removed,
		"blt_download_manager_gui_on_download_removed")
	BLT.Downloads:flush_complete_downloads()

	self._root_panel:clear()
	self._root_panel.ctrls = {}
end

function BLTDownloadManagerGui:clbk_download_all()
	BLT.Downloads:download_all(
		callback(self, self, "_on_download_completed")
	)
end

function BLTDownloadManagerGui:clbk_relua_button()
	if setup and setup.quit_to_main_menu then
		QuickMenu:new(
			self:translate("blt_download_relua_title"),
			self:translate("blt_download_relua_text"),
			{
				{
					text = self:translate("dialog_yes"),
					callback = function()
						setup.exit_to_main_menu = true
						setup:quit_to_main_menu()
					end,
				},
				{
					text = math.random() < 0.02 and "NEIN!" or self:translate("dialog_no"),
					is_cancel_button = true,
				},
			},
			true
		)
	end
end
