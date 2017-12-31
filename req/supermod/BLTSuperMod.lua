
BLTSuperMod = blt_class()
BLTSuperMod._dynamic_unloaded_assets = {}

BLTSuperMod.DYNAMIC_LOAD_TYPES = {
	unit = true,
	effect = true
}

function BLTSuperMod.try_load(mod, file_name)
	local supermod_path = "mods/" .. mod:GetId() .. "/" .. (file_name or "supermod.xml")

	-- Attempt to read the mod defintion file
	local file = io.open(supermod_path)
	if file then

		-- Read the file contents
		local file_contents = file:read("*all")
		file:close()

		-- Parse it
		local xml = blt.parsexml(file_contents)
		xml._doc = {
			filename = supermod_path
		}

		return BLTSuperMod:new(mod, xml)
	end

	return nil
end

function BLTSuperMod:new(mod, xml)
	self._mod = mod

	self:_replace_includes(xml)

	self:_load_xml(xml, {
		base_path = ""
	})
end

function BLTSuperMod:_refine_scope(xml, scope)
	local new_scope = {}
	setmetatable(new_scope, {__index = scope})

	for name, val in pairs(xml.params) do
		new_scope[name] = val
	end

	return new_scope
end

function BLTSuperMod:_load_xml(xml, scope)
	for _, tag in ipairs(xml) do
		local lscope = self:_refine_scope(xml, scope)
		if tag.name == "group" then
			self:_load_xml(tag, lscope)
		elseif tag.name == "assets" then
			self:_load_assets(tag, lscope)
		else
			error("Unknown tag name " .. tag.name .. " in root :" .. tag._doc.filename)
		end
	end
end

function BLTSuperMod:_load_assets(xml, scope)
	for _, tag in ipairs(xml) do
		local lscope = self:_refine_scope(xml, scope)
		if tag.name == "group" then
			self:_load_assets(tag, lscope)
		elseif tag.name == "file" then
			local name = tag.params.name
			local path = tag.params.path or (self._mod:GetPath() .. lscope.base_path .. name)
			self:_load_asset(name, path, lscope)
		else
			error("Unknown tag name " .. tag.name .. " in <assets> :" .. tag._doc.filename)
		end
	end
end

local function _flush_assets(dres)
	dres = dres or (managers and managers.dyn_resource)
	if not dres then return end

	local next_to_load = {}

	local i = 1
	for _, asset in pairs(BLTSuperMod._dynamic_unloaded_assets) do
		local ext = Idstring(asset.extension)
		local dbpath = Idstring(asset.dbpath)

		--log("Loading " .. asset.dbpath .. " " .. asset.extension .. " from " .. asset.file)

		DB:create_entry(ext, dbpath, asset.file)

		if asset.dyn_package then
			dres:load(ext, dbpath, dres.DYN_RESOURCES_PACKAGE, function()
				-- This is called when the asset is done loading.
				-- Should we wait for these to all be called?
			end)

			i = i + 1
		end
	end

	BLTSuperMod._dynamic_unloaded_assets = {}
end
Hooks:Add("DynamicResourceManagerCreated", "BLTAssets.DynamicResourceManagerCreated", _flush_assets)

function BLTSuperMod:_load_asset(name, file, params)
	local dot_index = name:find(".", 1, true)
	local dbpath = name:sub(1, dot_index - 1)
	local extension = name:sub(dot_index + 1)

	local dyn_package = BLTSuperMod.DYNAMIC_LOAD_TYPES[extension] or false
	if params.dyn_package == "true" then
		dyn_package = true
	elseif params.dyn_package == "false" then
		dyn_package = false
	end

	table.insert(BLTSuperMod._dynamic_unloaded_assets, {
		dbpath = dbpath,
		extension = extension,
		file = file,
		dyn_package = dyn_package
	})

	_flush_assets()
end

function BLTSuperMod:_replace_includes(xml)
	for i, tag in ipairs(xml) do
		tag._doc = xml._doc

		if tag.name == ":include" then
			local file_path = "mods/" .. self._mod:GetId() .. "/" .. tag.params.src

			-- Attempt to read the mod defintion file
			local file = io.open(file_path)
			assert(file, "Could not open " .. file_path)

			-- Read the file contents
			local file_contents = file:read("*all")
			file:close()

			-- Parse it
			local included = blt.parsexml(file_contents)
			assert(included, "Parsed file " .. file_path .. " resolves to nil. Is it valid?")
			included._doc = {
				filename = file_path
			}

			-- Substitute it in
			tag = included
			xml[i] = included
		end

		self:_replace_includes(tag)
	end
end
