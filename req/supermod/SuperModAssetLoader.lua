
local c = blt_class()
BLTSuperMod.AssetLoader = c

c.DYNAMIC_LOAD_TYPES = {
	unit = true,
	effect = true
}

local _dynamic_unloaded_assets = {}
local _flush_assets

function c:init(mod)
	self._mod = mod
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

	table.insert(_dynamic_unloaded_assets, {
		dbpath = dbpath,
		extension = extension,
		file = file,
		dyn_package = dyn_package
	})

	_flush_assets()
end


-- Asset system - independent of any object
_flush_assets = function(dres)
	dres = dres or (managers and managers.dyn_resource)
	if not dres then return end

	local next_to_load = {}

	local i = 1
	for _, asset in pairs(_dynamic_unloaded_assets) do
		local ext = Idstring(asset.extension)
		local dbpath = Idstring(asset.dbpath)
		local path = asset.file

		if not io.file_is_readable(path) then
			error("Cannot load unreadable asset " .. path)
		end

		log("Loading " .. asset.dbpath .. " " .. asset.extension .. " from " .. path)

		DB:create_entry(ext, dbpath, path)

		if asset.dyn_package then
			dres:load(ext, dbpath, dres.DYN_RESOURCES_PACKAGE, function()
				-- This is called when the asset is done loading.
				-- Should we wait for these to all be called?
			end)

			i = i + 1
		end
	end

	_dynamic_unloaded_assets = {}
end
Hooks:Add("DynamicResourceManagerCreated", "BLTAssets.DynamicResourceManagerCreated", _flush_assets)
