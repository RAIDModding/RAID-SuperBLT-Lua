
local c = blt_class()
BLTSuperMod.AssetLoader = c

c.DYNAMIC_LOAD_TYPES = {
	unit = true,
	effect = true
}

local _dynamic_unloaded_assets = {}
local _flush_assets
local _currently_loading_assets = {}

local next_asset_id = 1

function c:init(mod)
	self._mod = mod

	self.script_loadable_packages = {
	}
end

function c:FromXML(xml, parent_scope)
	-- Prevent the :name parameter from entering the <assets> scope
	parent_scope.name = nil

	-- Recurse over the XML, and find all the <file/> tags
	BLTSuperMod._recurse_xml(xml, parent_scope, {
		file = function(...) self:_asset_from_xml(...) end
	})
end

function c:_asset_from_xml(tag, scope)
	local name = scope.name
	local path = scope.path or (scope.base_path .. name)
	self:LoadAsset(name, path, scope)
end

function c:LoadAsset(name, file, params)
	local dot_index = name:find(".", 1, true)
	local dbpath = name:sub(1, dot_index - 1)
	local extension = name:sub(dot_index + 1)

	local dyn_package = c.DYNAMIC_LOAD_TYPES[extension] or false
	if params.dyn_package == "true" then
		dyn_package = true
	elseif params.dyn_package == "false" then
		dyn_package = false
	end

	local spec = {
		dbpath = dbpath,
		extension = extension,
		file = self._mod._mod:GetPath() .. file,
		dyn_package = dyn_package,
		id = next_asset_id,
	}

	next_asset_id = next_asset_id + 1

	if params.target == "immediate" or not params.target then
		_dynamic_unloaded_assets[spec.id] = spec
		_flush_assets()
	elseif params.target == "scripted" then
		local group_name = params.load_group

		local group = self.script_loadable_packages[group_name] or {
			assets = {},
			loaded = false
		}
		self.script_loadable_packages[group_name] = group

		table.insert(group.assets, spec)
	else
		error("Unrecognised load type " .. params.target)
	end
end

function c:LoadAssetGroup(group_name)
	assert(group_name, "cannot load nil group")
	local group = self.script_loadable_packages[group_name]

	if not group then
		error("Group '" .. group_name .. "' does not exist")
	end

	if group.loaded then return end

	group.loaded = true

	for _, spec in ipairs(group.assets) do
		_dynamic_unloaded_assets[spec.id] = spec
	end

	_flush_assets()
end

function c:FreeAssetGroup(group_name)
	assert(group_name, "cannot free nil group")
	local group = self.script_loadable_packages[group_name]

	if not group then
		error("Group '" .. group_name .. "' does not exist")
	end

	-- We don't care if the group is loaded or not, as each asset
	-- is checked if it's unloaded.

	group.loaded = false

	for _, spec in ipairs(group.assets) do
		-- If it's queued to be loaded, ignore it.
		_dynamic_unloaded_assets[spec.id] = nil

		local ext = Idstring(spec.extension)
		local dbpath = Idstring(spec.dbpath)

		if spec._entry_created then
			spec._entry_created = false
			DB:remove_entry(ext, dbpath)
		end

		if spec._targeted_package then
			managers.dyn_resource:unload(ext, dbpath, spec._targeted_package, false)
			spec._targeted_package = nil

			_currently_loading_assets[spec] = nil
		end
	end
end


-- Asset system - independent of any object
_flush_assets = function(dres)
	dres = dres or (managers and managers.dyn_resource)
	if not dres then return end

	local next_to_load = {}

	local i = 1
	for id, asset in pairs(_dynamic_unloaded_assets) do
		local ext = Idstring(asset.extension)
		local dbpath = Idstring(asset.dbpath)
		local path = asset.file

		if not io.file_is_readable(path) then
			error("Cannot load unreadable asset " .. path)
		end

		-- TODO a good way to log this
		-- log("Loading " .. asset.dbpath .. " " .. asset.extension .. " from " .. path)

		if not asset._entry_created then
			blt.ignoretweak(dbpath, ext)
			DB:create_entry(ext, dbpath, path)
			asset._entry_created = true
		end

		if asset.dyn_package and not asset._targeted_package then
			asset._targeted_package = dres.DYN_RESOURCES_PACKAGE

			_currently_loading_assets[asset] = {}

			dres:load(ext, dbpath, asset._targeted_package, function()
				-- This is called when the asset is done loading.
				-- Should we wait for these to all be called?

				_currently_loading_assets[asset] = nil

				if BLT.DEBUG_MODE then
					log("[BLT] Assets remaining to load:")
					for spec, info in pairs(_currently_loading_assets) do
						log("\t" .. spec.dbpath)
					end
					log("\tEnd of asset list")
				end
			end)

			-- Warn the user if a file has not loaded in the last fifteen seconds
			DelayedCalls:Add("SuperBLTAssetLoaderModelWatchdog", 15, function()
				if next(_currently_loading_assets) then
log("[BLT] No asset has been loaded in the last 15 seconds, and these assets have not yet loaded.")
log("[BLT] This suggests they may be corrupt, and could prevent the game from exiting the current level:")
					for spec, info in pairs(_currently_loading_assets) do
						log("\t" .. spec.dbpath .. "." .. spec.extension .. " (" .. path .. ")")
					end
				end
			end)

			i = i + 1
		end
	end

	_dynamic_unloaded_assets = {}
end
Hooks:Add("DynamicResourceManagerCreated", "BLTAssets.DynamicResourceManagerCreated", _flush_assets)
