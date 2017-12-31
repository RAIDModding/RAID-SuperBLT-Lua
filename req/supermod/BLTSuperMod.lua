
BLTSuperMod = blt_class()

BLT:Require("req/supermod/SuperModAssetLoader")

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
	self._assets = self.AssetLoader:new(self)

	self:_replace_includes(xml)

	self:_load_xml(xml, {
		base_path = mod:GetPath()
	})
end

function BLTSuperMod:_load_xml(xml, parent_scope)
	BLTSuperMod._recurse_xml(xml, parent_scope, {
		assets = function(tag, scope)
			self._assets:FromXML(tag, scope)
		end,

		-- These tags are used by the Wren-based XML Tweaker
		wren = function(tag, scope) end,
		tweak = function(tag, scope) end,
	})
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

function BLTSuperMod._recurse_xml(xml, parent_scope, callbacks)
	for _, tag in ipairs(xml) do
		local scope = {}
		setmetatable(scope, {__index = parent_scope})

		for name, val in pairs(tag.params) do
			if name:sub(1,1) == ":" then
				name = name:sub(2)
				if not scope[name] then
					error("Trying to append to missing parameter '" .. name
							.. "' in " .. tag._doc.filename)
				end
				scope[name] = scope[name] .. val
			else
				scope[name] = val
			end
		end

		if tag.name == "group" then
			BLTSuperMod._recurse_xml(tag, scope, callbacks)
		elseif callbacks[tag.name] then
			callbacks[tag.name](tag, scope, callbacks)
		else
			error("Unknown tag name " .. tag.name .. " in:" .. tag._doc.filename)
		end
	end
end
