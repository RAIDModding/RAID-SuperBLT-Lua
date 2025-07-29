---@class BLTDownloadManagerGui
---@field new fun(self, ws, fullscreen_ws, node):BLTDownloadManagerGui
---@field translate fun(self, string, upper_case)
---@field set_legend fun(self, legend)
---@field set_controller_bindings fun(self, bindings, clear_old)
---@field super table
---@field _node table
---@field _root_panel table
BLTDownloadManagerGui = BLTDownloadManagerGui or blt_class(RaidGuiBase)

local padding = 10

function BLTDownloadManagerGui:init(ws, fullscreen_ws, node)
	BLTDownloadManagerGui.super.init(self, ws, fullscreen_ws, node, "blt_download_manager")
	self._root_panel.ctrls = self._root_panel.ctrls or {}

	self._listening_to = {}
	for _, update in ipairs(BLT.Downloads:pending_downloads()) do
		update:register_event_handler("blt_download_manager_gui_on_update_change",
			callback(self, self, "_on_update_change"))
		self._listening_to[update] = true
	end
	BLT.Downloads:register_event_handler(BLT.Downloads.EVENTS.added, "blt_download_manager_gui_on_update_added",
		callback(self, self, "_on_update_added"))
end

function BLTDownloadManagerGui:_set_initial_data()
	self._node.components.raid_menu_header:set_screen_name("blt_download_manager")
end

function BLTDownloadManagerGui:_layout()
	self._object = self._root_panel:panel({}) -- our main panel

	local header_height = self._node.components.raid_menu_header._screen_subtitle_label:bottom()
	local footer_height = self._node.components.raid_menu_footer._panel_h
	local table_h = self._object:h() - header_height - footer_height

	-- relua button
	self._relua_btn = self._object:long_secondary_button({
		name = "blt_relua_btn",
		text = self:translate("blt_download_relua_button", true),
		on_click_callback = callback(self, self, "clbk_relua_button"),
		y = math.floor(header_height * 0.75),
		x = math.floor(self._object:w() * 0.63),
		visible = table.size(BLT.Downloads:pending_downloads()) > 0 and BLT:CheckUpdatesReluaPossible(BLT.Downloads:pending_downloads()) or false
	})

	-- download_all button
	self._download_all_btn = self._object:long_secondary_button({
		name = "blt_download_all_btn",
		text = self:translate("blt_download_all", true),
		on_click_callback = callback(self, self, "clbk_download_all"),
		y = math.floor(header_height * 0.75),
		x = math.floor(self._object:w() * 0.8),
		visible = table.size(BLT.Downloads:pending_downloads()) > 0 or false
	})

	-- TODO: layout table headers (outside scroll)
	-- scroll
	self._download_manager_scroll = self._object:scrollable_area({
		layer = self._object:layer() + 1,
		name = "download_manager_scroll",
		scroll_step = 35,
		w = self._object:w(),
		h = self._object:h() - table_h,
	})
	-- TODO: layout dl table (inside scroll, with custom item/row class, bind to _data_source())

	--self._download_manager_scroll:setup_scroll_area()
end

function BLTDownloadManagerGui:_data_source()
	-- TODO: return initial update data for dl table
	return {}
end

function BLTDownloadManagerGui:_on_update_change(update, requires_update, error_reason)
	-- TODO: update related list row in dl table
end

function BLTDownloadManagerGui:_on_update_added(update)
	update:register_event_handler("blt_download_manager_gui_on_update_change",
		callback(self, self, "_on_update_change"))
	self._listening_to[update] = true

	-- TODO: refresh table to include newly added update
end

function BLTDownloadManagerGui:close()
	BLT.Downloads:remove_event_handler(BLT.Downloads.EVENTS.added, "blt_download_manager_gui_on_update_added")
	for update, listening in pairs(self._listening_to) do
		if update and listening then
			update:remove_event_handler("blt_download_manager_gui_on_update_change")
			self._listening_to[update] = nil
		end
	end

	BLT.Downloads:flush_complete_downloads()

	self._root_panel:clear()
	self._root_panel.ctrls = {}
end

function BLTDownloadManagerGui:clbk_download_all()
	BLT.Downloads:download_all()
end

function BLTDownloadManagerGui:clbk_relua_button()
	if setup and setup.quit_to_main_menu then
		QuickMenu:new(
			managers.localization:text("blt_download_relua_title"),
			managers.localization:text("blt_download_relua_text"),
			{
				{
					text = managers.localization:text("dialog_yes"),
					callback = function()
						setup.exit_to_main_menu = true
						setup:quit_to_main_menu()
					end,
				},
				{
					text = math.random() < 0.02 and "NEIN!" or managers.localization:text("dialog_no"),
					is_cancel_button = true,
				},
			},
			true
		)
	end
end

-- OLD CODE BELOW -- TODO?: something we need to rebuild?

-- function BLTDownloadManagerGui:setup()
-- 	self:make_into_listview("downloads_scroll", managers.localization:text("blt_download_manager"))
-- 	self._downloads_map = {}

-- 	-- Background
-- 	-- Added by make_into_listview

-- 	-- Back button
-- 	-- Automatically added by BLTCustomComponent

-- 	-- Title
-- 	-- This has already been added, thanks to make_into_listview

-- 	-- Download scroll panel
-- 	-- Again, this has already been added by make_into_listview

-- 	-- Add download items
-- 	local w, h = 80, 80
-- 	for i, download in ipairs(BLT.Downloads:pending_downloads()) do
-- 		local data = {
-- 			y = (h + padding) * (i - 1),
-- 			w = self._scroll:canvas():w(),
-- 			h = h,
-- 			update = download.update
-- 		}
-- 		local button = BLTDownloadControl:new(self._scroll:canvas(), data)
-- 		table.insert(self._buttons, button)

-- 		self._downloads_map[download.update:GetId()] = button
-- 	end

-- 	local num_downloads = table.size(BLT.Downloads:pending_downloads())
-- 	if num_downloads > 0 then
-- 		local button = BLTUIButton:new(self._scroll:canvas(), {
-- 			x = self._scroll:canvas():w() - w,
-- 			y = (h + padding) * num_downloads,
-- 			w = w,
-- 			h = h,
-- 			text = managers.localization:text("blt_download_all"),
-- 			center_text = true,
-- 			callback = callback(self, self, "clbk_download_all")
-- 		})
-- 		table.insert(self._buttons, button)

-- 		if BLT:CheckUpdatesReluaPossible(BLT.Downloads:pending_downloads()) then
-- 			-- relua btn
-- 			local relua_button = BLTUIButton:new(self._scroll:canvas(), {
-- 				x = self._scroll:canvas():w() - w * 2 - padding,
-- 				y = (h + padding) * num_downloads,
-- 				w = w,
-- 				h = h,
-- 				text = managers.localization:text("blt_download_relua_button"),
-- 				center_text = true,
-- 				callback = callback(self, self, "clbk_relua_button")
-- 			})
-- 			table.insert(self._buttons, relua_button)
-- 		end
-- 	end
-- end

-- function BLTDownloadManagerGui:update(t, dt)
-- 	for _, download in ipairs(BLT.Downloads:downloads()) do
-- 		local id = download.update:GetId()
-- 		local button = self._downloads_map[id]
-- 		if button then
-- 			button:update_download(download)
-- 		end
-- 	end
-- end
