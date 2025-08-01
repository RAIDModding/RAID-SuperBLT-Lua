---@class BLTDownloadManager : BLTModule
---@field new fun(self):BLTDownloadManager
BLTDownloadManager = BLTDownloadManager or blt_class(BLTModule)
BLTDownloadManager.__type = "BLTDownloadManager"

function BLTDownloadManager:init()
	---@diagnostic disable-next-line: undefined-field
	BLTDownloadManager.super.init(self)

	self._pending_downloads = {}
	self._downloads = {}
	self._event_handlers = {}
end

--------------------------------------------------------------------------------

function BLTDownloadManager:get_pending_download(update)
	for i, download in ipairs(self._pending_downloads) do
		if download.update:GetId() == update:GetId() then
			return download, i
		end
	end
	return false
end

function BLTDownloadManager:get_pending_downloads_for(mod)
	local result = nil
	for _, update in ipairs(mod:GetUpdates()) do
		for i, download in ipairs(self._pending_downloads) do
			if download.update:GetId() == update:GetId() then
				if not result then
					result = {}
				end
				table.insert(result, download)
			end
		end
	end
	return result or false
end

function BLTDownloadManager:pending_downloads()
	return self._pending_downloads
end

function BLTDownloadManager:add_pending_download(update)
	-- Check if the download already exists
	for _, download in ipairs(self._pending_downloads) do
		if download.update:GetId() == update:GetId() then
			BLT:Log(LogLevel.INFO,
				string.format("[Downloads] Pending download already exists for %s (%s)", update:GetName(),
					update:GetParentMod():GetName()))
			return false
		end
	end

	-- Add the download for the future
	local download = {
		update = update
	}
	table.insert(self._pending_downloads, download)

	-- trigger change event
	self:call_event_handlers()

	BLT:Log(LogLevel.INFO,
		string.format("[Downloads] Added pending download for %s (%s)", update:GetName(), update:GetParentMod():GetName()))

	return true
end

--------------------------------------------------------------------------------

function BLTDownloadManager:downloads()
	return self._downloads
end

function BLTDownloadManager:get_download(update)
	for i, download in ipairs(self._downloads) do
		if download.update:GetId() == update:GetId() then
			return download, i
		end
	end
	return false
end

function BLTDownloadManager:get_download_from_http_id(http_id)
	for i, download in ipairs(self._downloads) do
		if download.http_id == http_id then
			return download, i
		end
	end
	return false
end

function BLTDownloadManager:download_all(complete_clbk, progress_clbk)
	for _, download in ipairs(self:pending_downloads()) do
		if not download.update:DisallowsUpdate() then
			self:start_download(download.update, complete_clbk, progress_clbk)
		end
	end
end

function BLTDownloadManager:start_download(update, complete_clbk, progress_clbk)
	-- Check if the download already going
	if self:get_download(update) then
		BLT:Log(LogLevel.INFO,
			string.format("[Downloads] Download already exists for %s (%s)", update:GetName(),
				update:GetParentMod():GetName()))
		return false
	end

	-- Check if this update is allowed to be updated by the download manager
	if update:DisallowsUpdate() then
		MenuCallbackHandler[update:GetDisallowCallback()](MenuCallbackHandler, update)
		return false
	end

	-- If there is a .git or .hg file at the root of the mod, don't update it
	-- the dev has most likely misclicked, so let's not wipe their work
	local moddir = Application:nice_path(update:GetInstallDirectory() .. "/" .. update:GetInstallFolder(), true)
	if file.DirectoryExists(moddir .. ".hg") or file.DirectoryExists(moddir .. ".git") then
		QuickMenu:new(
			"Update Blocked",                                                  -- TODO i18n
			"Mercurial or Git version control are in use for this mod, update blocked", -- TODO i18n
			nil,
			true
		)
		return false
	end

	-- Start the download
	local url = update:GetDownloadURL()
	local http_id = dohttpreq(url, callback(self, self, "clbk_download_finished", complete_clbk),
		callback(self, self, "clbk_download_progress", progress_clbk))

	-- Cache the download for access
	local download = {
		update = update,
		http_id = http_id,
		state = "waiting"
	}
	table.insert(self._downloads, download)

	return true
end

function BLTDownloadManager:clbk_download_finished(complete_clbk, data, http_id, request_info)
	local download = self:get_download_from_http_id(http_id)
	if not download then
		return
	end
	local download_name = download.update:GetName()

	if not request_info.querySucceeded or string.is_nil_or_empty(data) then
		BLT:Log(LogLevel.ERROR, string.format("[Downloads] Download of '%s' failed", download_name))
		download.state = "failed"
		if complete_clbk then
			complete_clbk(download)
		end
		return
	end

	BLT:Log(LogLevel.INFO, string.format("[Downloads] Finished download of '%s'", download_name))

	-- Holy shit this is hacky, but to make sure we can update the UI correctly to reflect whats going on, we run this in a coroutine
	-- that we start through a UI animation
	self._coroutine_ws = self._coroutine_ws or managers.gui_data:create_fullscreen_workspace()
	download.coroutine = self._coroutine_ws:panel():panel({})

	local save = function()
		-- Create locals
		local wait = function(x)
			for i = 1, (x or 5) do
				coroutine.yield()
			end
		end

		local file_path = Application:nice_path(BLTModManager.Constants:DownloadsDirectory() ..
			tostring(download.update:GetId()) .. ".zip")
		local temp_install_dir = Application:nice_path(BLTModManager.Constants:DownloadsDirectory() .. tostring(http_id))
		local install_path = Application:nice_path(download.update:GetInstallDirectory() ..
			download.update:GetInstallFolder())

		local cleanup = function(full)
			io.remove_directory_and_files(temp_install_dir)
			if full then
				os.remove(file_path)
			end
			if complete_clbk then
				complete_clbk(download)
			end
		end

		-- Save download to disk
		BLT:Log(LogLevel.INFO, string.format("[Downloads] Saving '%s' data to file...", download_name))
		download.state = "saving"
		wait()

		-- Save file to downloads
		local f = io.open(file_path, "w+b")
		if f then
			f:write(data)
			f:close()
		else
			BLT:Log(LogLevel.ERROR, string.format("[Downloads] Failed to save '%s' data to file", download_name))
			download.state = "failed"
			cleanup()
			return
		end

		-- Start download extraction
		BLT:Log(LogLevel.INFO, string.format("[Downloads] Extracting '%s'...", download_name))
		download.state = "extracting"
		wait()

		unzip(file_path, temp_install_dir)

		-- Update extract_path, in case user renamed mod's folder
		local folders = file.GetDirectories(temp_install_dir, true)
		local extracted_folder_name = folders and #folders == 1 and folders[1] or download.update:GetInstallFolder()
		local extract_path = Application:nice_path(temp_install_dir .. "/" .. extracted_folder_name)

		-- Verify content hash with the server hash
		BLT:Log(LogLevel.INFO, string.format("[Downloads] Verifying '%s'...", download_name))
		download.state = "verifying"
		wait()

		local passed_check = false
		if download.update:UsesHash() then
			local local_hash = file.DirectoryHash(Application:nice_path(extract_path, true))
			local server_hash = download.update:GetServerHash()
			if server_hash == local_hash then
				passed_check = true
			else
				BLT:Log(LogLevel.ERROR, string.format("[Downloads] Failed to verify hashes of '%s'", download_name))
				BLT:Log(LogLevel.ERROR, "[Downloads] Server: ", server_hash)
				BLT:Log(LogLevel.ERROR, "[Downloads]  Local: ", local_hash)
			end
		else
			local definition_file = nil
			local is_pure_xml = false
			local mod_txt = extract_path ..
				"/mod.txt" -- Check the downloaded mod.txt (if it exists) to know we are downloading a valid mod with valid version.
			local supermod_xml = extract_path ..
				"/supermod.xml" -- Check the downloaded supermod.xml (if it exists) to know we are downloading a valid mod with valid version.
			if file.FileExists(mod_txt) then
				definition_file = mod_txt
			elseif file.FileExists(supermod_xml) then
				definition_file = supermod_xml
				is_pure_xml = true
			else
				BLT:Log(LogLevel.ERROR,
					string.format("[Downloads] Could not read mod data of '%s' (no mod.txt/supermod.xml found)",
						download_name))
			end

			if definition_file then
				local file = io.open(definition_file, "r")
				if file then
					local file_content = file:read("*all")
					file:close()
					local mod_data = is_pure_xml and blt.parsexml(file_content) or json.decode(file_content)
					if mod_data and (not is_pure_xml or mod_data.params) then -- Is the data valid json/xml?
						local version = is_pure_xml and mod_data.params.version or mod_data.version
						local server_version = download.update:GetServerVersion()
						-- Server version may be nil for simple URL based dependencies
						if server_version == nil or BLT:CompareVersions(version, server_version) == 0 then
							passed_check = true
						else -- Versions don't match
							BLT:Log(LogLevel.ERROR,
								string.format("[Downloads] Failed to compare downloaded version to announced '%s'",
									download_name))
							BLT:Log(LogLevel.ERROR, "[Downloads] Server: ", server_version)
							BLT:Log(LogLevel.ERROR, "[Downloads]  Local: ", version)
						end
					else
						BLT:Log(LogLevel.ERROR,
							string.format("[Downloads] Could not read mod data of '%s' (invalid mod %s)", download_name,
								is_pure_xml and "xml" or "json"))
					end
				else
					BLT:Log(LogLevel.ERROR,
						string.format("[Downloads] Could not read mod data of '%s' (%s unreadable)", download_name,
							is_pure_xml and "supermod.xml" or "mod.txt"))
				end
			end
		end
		if not passed_check then
			download.state = "failed"
			cleanup()
			return
		end

		-- Remove old installation, unless we're installing a mod (via dependencies)
		if not download.update:IsInstall() then
			wait()
			if file.DirectoryExists(install_path) then
				BLT:Log(LogLevel.INFO, string.format("[Downloads] Removing old installation of '%s'...", download_name))
				if not io.remove_directory_and_files(install_path) then
					BLT:Log(LogLevel.ERROR,
						string.format("[Downloads] Failed to delete old installation of '%s'", download_name))
					download.state = "failed"
					cleanup()
					return
				end
			end
			wait()
		end

		-- Move the temporary installation
		local move_success = file.MoveDirectory(extract_path, install_path)
		if not move_success then
			BLT:Log(LogLevel.ERROR,
				string.format("[Downloads] Failed to move installation directory of '%s'", download_name))
			download.state = "failed"
			cleanup()
			return
		end

		-- Mark download as complete
		BLT:Log(LogLevel.INFO, string.format("[Downloads] Finished '%s'", download_name))
		download.state = "complete"
		cleanup(true)
	end

	download.coroutine:animate(save)
end

function BLTDownloadManager:clbk_download_progress(progress_clbk, http_id, bytes, total_bytes)
	local download = self:get_download_from_http_id(http_id)
	if download then
		download.state = "downloading"
		download.bytes = bytes
		download.total_bytes = total_bytes
		if progress_clbk then
			progress_clbk(download)
		end
	end
end

function BLTDownloadManager:flush_complete_downloads()
	for i = #self._downloads, 0, -1 do
		local download = self._downloads[i]
		if download and download.state == "complete" then
			-- Remove download
			table.remove(self._downloads, i)

			-- Remove the pending download
			local _, idx = self:get_pending_download(download.update)
			table.remove(self._pending_downloads, idx)

			-- trigger change event
			self:call_event_handlers()
		end
	end
end

function BLTDownloadManager:register_event_handler(id, callback)
	self._event_handlers[id] = callback
end

function BLTDownloadManager:remove_event_handler(id)
	self._event_handlers[id] = nil
end

function BLTDownloadManager:call_event_handlers()
	for _, callback in pairs(self._event_handlers) do
		if callback then
			callback()
		end
	end
end
