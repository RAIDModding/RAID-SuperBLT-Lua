BLTDownloadManager = BLTDownloadManager or blt_class( BLTModule )
BLTDownloadManager.__type = "BLTDownloadManager"

function BLTDownloadManager:init()

	self._pending_downloads = {}
	self._downloads = {}

end

--------------------------------------------------------------------------------

function BLTDownloadManager:get_pending_download( update )
	for i, download in ipairs( self._pending_downloads ) do
		if download.update:GetId() == update:GetId() then
			return download, i
		end
	end
	return false
end

function BLTDownloadManager:get_pending_downloads_for( mod )
	local result = nil
	for _, update in ipairs( mod:GetUpdates() ) do
		for i, download in ipairs( self._pending_downloads ) do
			if download.update:GetId() == update:GetId() then
				if not result then result = {} end
				table.insert(result, download)
			end
		end
	end
	return result or false
end

function BLTDownloadManager:pending_downloads()
	return self._pending_downloads
end

function BLTDownloadManager:add_pending_download( update )

	-- Check if the download already exists
	for _, download in ipairs( self._pending_downloads ) do
		if download.update:GetId() == update:GetId() then
			BLT:Log(LogLevel.INFO, string.format("[Downloads] Pending download already exists for %s (%s)", update:GetName(), update:GetParentMod():GetName()))
			return false
		end
	end

	-- Add the download for the future
	local download = {
		update = update,
	}
	table.insert( self._pending_downloads, download )
	BLT:Log(LogLevel.INFO, string.format("[Downloads] Added pending download for %s (%s)", update:GetName(), update:GetParentMod():GetName()))

	return true

end

--------------------------------------------------------------------------------

function BLTDownloadManager:downloads()
	return self._downloads
end

function BLTDownloadManager:get_download( update )
	for i, download in ipairs( self._downloads ) do
		if download.update:GetId() == update:GetId() then
			return download, i
		end
	end
	return false
end

function BLTDownloadManager:get_download_from_http_id( http_id )
	for i, download in ipairs( self._downloads ) do
		if download.http_id == http_id then
			return download, i
		end
	end
	return false
end

function BLTDownloadManager:download_all()
	for _, download in ipairs( self:pending_downloads() ) do
		if not download.update:DisallowsUpdate() then
			self:start_download( download.update )
		end
	end
end

function BLTDownloadManager:start_download( update )

	-- Check if the download already going
	if self:get_download( update ) then
		BLT:Log(LogLevel.INFO, string.format("[Downloads] Download already exists for %s (%s)", update:GetName(), update:GetParentMod():GetName()))
		return false
	end

	-- If there is a .git or .hg file at the root of the mod, don't update it
	-- the dev has most likely misclicked, so let's not wipe their work
	local moddir = Application:nice_path( update:GetInstallDirectory() .. "/" .. update:GetInstallFolder(), true )
	if file.DirectoryExists(moddir .. ".hg") or file.DirectoryExists(moddir .. ".git") then
		QuickMenu:new(
			"Update Blocked", -- TODO i18n
			"Mercerial or Git version control are in use for this mod, update blocked", -- TODO i18n
			{},
			true
		)
		return false
	end

	-- Check if this update is allowed to be updated by the download manager
	if update:DisallowsUpdate() then
		MenuCallbackHandler[ update:GetDisallowCallback() ]( MenuCallbackHandler, update )
		return false
	end

	-- Start the download
	local url = update:GetDownloadURL()
	local http_id = dohttpreq( url, callback(self, self, "clbk_download_finished"), callback(self, self, "clbk_download_progress") )

	-- Cache the download for access
	local download = {
		update = update,
		http_id = http_id,
		state = "waiting"
	}
	table.insert( self._downloads, download )

	return true

end

function BLTDownloadManager:clbk_download_finished( data, http_id )

	local download = self:get_download_from_http_id( http_id )
	BLT:Log(LogLevel.INFO, string.format("[Downloads] Finished download of %s (%s)", download.update:GetName(), download.update:GetParentMod():GetName()))

	-- Holy shit this is hacky, but to make sure we can update the UI correctly to reflect whats going on, we run this in a coroutine
	-- that we start through a UI animation
	self._coroutine_ws = self._coroutine_ws or managers.gui_data:create_fullscreen_workspace()
	download.coroutine = self._coroutine_ws:panel():panel({})

	local save = function()

		-- Create locals
		local wait = function( x )
			for i = 1, (x or 5) do
				coroutine.yield()
			end
		end

		local install_dir = download.update:GetInstallDirectory()
		local temp_dir = Application:nice_path( install_dir .. "_temp" )
		if install_dir == BLTModManager.Constants:ModsDirectory() then
			temp_dir = Application:nice_path( BLTModManager.Constants:DownloadsDirectory() .. "_temp" )
		end

		local file_path = Application:nice_path( BLTModManager.Constants:DownloadsDirectory() .. tostring(download.update:GetId()) .. ".zip" )
		local temp_install_dir = Application:nice_path( temp_dir .. "/" .. download.update:GetInstallFolder() )
		local install_path = Application:nice_path( download.update:GetInstallDirectory() .. download.update:GetInstallFolder() )
		local extract_path = Application:nice_path( temp_install_dir .. "/" .. download.update:GetInstallFolder() )

		local cleanup = function()
			SystemFS:delete_file( temp_install_dir )
		end

		wait()

		-- Prepare
		SystemFS:make_dir( temp_dir ) -- we dont wanna delete the temp dir at all, as it would not be thread safe. just make sure it exists.
		SystemFS:delete_file( file_path )
		cleanup()

		-- Save download to disk
		BLT:Log(LogLevel.INFO, "[Downloads] Saving to downloads...")
		download.state = "saving"
		wait()

		-- Save file to downloads
		local f = io.open( file_path, "wb+" )
		if f then
			f:write( data )
			f:close()
		end

		-- Start download extraction
		BLT:Log(LogLevel.INFO, "[Downloads] Extracting...")
		download.state = "extracting"
		wait()

		unzip( file_path, temp_install_dir )

		-- Update extract_path, in case user renamed mod's folder
		local folders = SystemFS:list(temp_install_dir, true)
		local extracted_folder_name = folders and #folders == 1 and folders[1]
		if extracted_folder_name and extracted_folder_name ~= download.update:GetInstallFolder() then
			extract_path = Application:nice_path( temp_install_dir .. "/" .. extracted_folder_name )
		end

		-- Verify content hash with the server hash
		BLT:Log(LogLevel.INFO, "[Downloads] Verifying...")
		download.state = "verifying"
		wait()

		local passed_check = false
		if download.update:UsesHash() then
			local local_hash = file.DirectoryHash( Application:nice_path( extract_path, true ) )
			local server_hash = download.update:GetServerHash()
			if server_hash == local_hash then
				passed_check = true
			else
				BLT:Log(LogLevel.ERROR, "[Downloads] Failed to verify hashes!")
				BLT:Log(LogLevel.ERROR, "[Downloads] Server: ", server_hash)
				BLT:Log(LogLevel.ERROR, "[Downloads]  Local: ", local_hash)
			end
		else
			local mod_txt = extract_path.."/mod.txt" -- Check the downloaded mod.txt (if it exists) to know we are downloading a valid mod with valid version.
			if SystemFS:exists(mod_txt) then
				local file = io.open(mod_txt, 'r')
				local mod_data = json.decode(file:read("*all"))
				if mod_data then -- Is the data valid json?
					local version = mod_data.version
					local server_version = download.update:GetServerVersion()
					if server_version == version then
						passed_check = true
					else -- Versions don't match
						BLT:Log(LogLevel.ERROR, "[Downloads] Failed to verify versions!")
						BLT:Log(LogLevel.ERROR, "[Downloads] Server: ", server_version)
						BLT:Log(LogLevel.ERROR, "[Downloads]  Local: ", version)
					end
				else
					BLT:Log(LogLevel.ERROR, "[Downloads] Could not read mod data of downloaded mod!")
				end
				file:close()
			else
				BLT:Log(LogLevel.ERROR, "[Downloads] Downloaded mod is not a valid mod!")
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
			if SystemFS:exists(install_path) then
				local old_install_path = install_path .. '_old'
				BLT:Log(LogLevel.INFO, "[Downloads] Removing old installation...")
				if not file.MoveDirectory( install_path, old_install_path ) then
					BLT:Log(LogLevel.ERROR, "[Downloads] Failed to rename old installation!")
					download.state = "failed"
					cleanup()
					return
				end

				if not SystemFS:delete_file( old_install_path ) then
					BLT:Log(LogLevel.ERROR, "[Downloads] Failed to delete old installation!")
					download.state = "failed"
					cleanup()
					return
				end
			end
		end

		-- Move the temporary installation
		local move_success = file.MoveDirectory( extract_path, install_path )
		if not move_success then
			BLT:Log(LogLevel.ERROR, "[Downloads] Failed to move installation directory!")
			download.state = "failed"
			cleanup()
			return
		end

		-- Mark download as complete
		BLT:Log(LogLevel.INFO, "[Downloads] Complete!")
		download.state = "complete"
		cleanup()

	end

	download.coroutine:animate( save )

end

function BLTDownloadManager:clbk_download_progress( http_id, bytes, total_bytes )
	local download = self:get_download_from_http_id( http_id )
	download.state = "downloading"
	download.bytes = bytes
	download.total_bytes = total_bytes
end

function BLTDownloadManager:flush_complete_downloads()

	BLT:Log(LogLevel.INFO, "[Downloads] Flushing complete downloads...")

	for i = #self._downloads, 0, -1 do
		local download = self._downloads[i]
		if download and download.state == "complete" then

			-- Remove download
			table.remove( self._downloads, i )

			-- Remove the pending download
			local _, idx = self:get_pending_download( download.update )
			table.remove( self._pending_downloads, idx )

		end
	end

end
