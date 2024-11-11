---@class BLTDownloadManagerGui
---@field new fun(self):BLTDownloadManagerGui
BLTDownloadManagerGui = BLTDownloadManagerGui or blt_class(BLTCustomComponent)

-- Use the modified BLT back button
BLTDownloadManagerGui._add_back_button = BLTDownloadManagerGui._add_custom_back_button

local padding = 10

function BLTDownloadManagerGui:setup()
	self:make_into_listview("downloads_scroll", managers.localization:text("blt_download_manager"), true)
	self._downloads_map = {}

	-- Background
	-- Added by make_into_listview

	-- Back button
	-- Automatically added by BLTCustomComponent

	-- Title
	-- This has already been added, thanks to make_into_listview

	-- Download scroll panel
	-- Again, this has already been added by make_into_listview

	-- Add download items
	local h = 80
	for i, download in ipairs(BLT.Downloads:pending_downloads()) do
		local data = {
			y = (h + padding) * (i - 1),
			w = self._scroll:canvas():w(),
			h = h,
			update = download.update
		}
		local button = BLTDownloadControl:new(self._scroll:canvas(), data)
		table.insert(self._buttons, button)

		self._downloads_map[download.update:GetId()] = button
	end

	local num_downloads = table.size(BLT.Downloads:pending_downloads())
	if num_downloads > 0 then
		local w, h = 80, 80
		local button = BLTUIButton:new(self._scroll:canvas(), {
			x = self._scroll:canvas():w() - w,
			y = (h + padding) * num_downloads,
			w = w,
			h = h,
			text = managers.localization:text("blt_download_all"),
			center_text = true,
			callback = callback(self, self, "clbk_download_all")
		})
		table.insert(self._buttons, button)

		if file.FileExists(BLTModManager.Constants.mods_directory .. "developer.txt") then
			-- relua btn
			local relua_button = BLTUIButton:new(self._scroll:canvas(), {
				x = self._scroll:canvas():w() - w * 2 - padding,
				y = (h + padding) * num_downloads,
				w = w,
				h = h,
				text = managers.localization:text("blt_download_relua_button"),
				center_text = true,
				callback = callback(self, self, "clbk_relua_button")
			})
			table.insert(self._buttons, relua_button)
		end
	end
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
				[1] = {
					text = math.random() < 0.02 and "NEIN!" or managers.localization:text("dialog_no"),
					is_cancel_button = true,
				},
				[2] = {
					text = managers.localization:text("dialog_yes"),
					callback = function()
						setup.exit_to_main_menu = true
						setup:quit_to_main_menu()
					end,
				},
			},
			true
		)
	end
end
--------------------------------------------------------------------------------

function BLTDownloadManagerGui:update(t, dt)
	for _, download in ipairs(BLT.Downloads:downloads()) do
		local id = download.update:GetId()
		local button = self._downloads_map[id]
		if button then
			button:update_download(download)
		end
	end
end

function BLTDownloadManagerGui:on_close()
	BLT.Downloads:flush_complete_downloads()
end
