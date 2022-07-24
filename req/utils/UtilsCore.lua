_G.Utils = _G.Utils or {}

---Copies an existing class into an orig table, so that class functions can be overwritten and called again easily
---@param class table @The class table to clone
function _G.CloneClass(class)
	if not class.orig then
		class.orig = clone(class)
	end
end

function Utils.MakeValueOutput(value, output)
	if type(value) == "string" then
		output[#output + 1] = '"'
		output[#output + 1] = value
		output[#output + 1] = '"'
	else
		output[#output + 1] = tostring(value)
	end
end

function Utils.MakeTableOutput(tbl, output, has, tabs, depth, maxDepth)
	has[tbl] = true
	output[#output + 1] = tostring(tbl)

	if next(tbl) then
		output[#output + 1] = " {\n"
		local nextTabs = tabs .. "\t"
		depth = depth + 1

		for k, v in pairs(tbl) do
			output[#output + 1] = nextTabs
			Utils.MakeValueOutput(k, output)
			output[#output + 1] = " = "

			if (type(v) == "table") and not has[v] and (depth < maxDepth) then
				Utils.MakeTableOutput(v, output, has, nextTabs, depth, maxDepth)
			else
				Utils.MakeValueOutput(v, output)
			end

			output[#output + 1] = "\n"
		end

		output[#output + 1] = tabs
		output[#output + 1] = "}"
	else
		output[#output + 1] = " {}"
	end
end

---Returns a string representing value
---If value is a table, ToString returns a string representing the table and its contents
---ToString will include the contents of nested tables down to maxDepth or 1
---@param value @Any value
---@param maxDepth? number @Controls the depth that ToString will read to (defaults to ``1``)
---@return string @A string representing value
function Utils.ToString(value, maxDepth)
	local output = {}

	if type(value) == "table" then
		local has = {}
		local tabs = ""
		local depth = 0
		maxDepth = maxDepth or 1
		Utils.MakeTableOutput(value, output, has, tabs, depth, maxDepth)
	else
		Utils.MakeValueOutput(value, output)
	end

	return table.concat(output)
end

---Prints the contents of a table to your console  
---May cause game slowdown if the table is fairly large, only for debugging purposes
---PrintTable will include the contents of nested tables down to maxDepth or 1
---@param tbl table @The table to print to console
---@param maxDepth? number @Controls the depth that PrintTable will read to (defaults to ``1``)
function Utils.PrintTable(tbl, maxDepth)
	local output = nil

	if type(tbl) == "table" then
		output = {"\n"} -- Start the output on a new line. Doing this here to avoid a possibly large copy later.
		local has = {}
		local tabs = ""
		local depth = 0
		maxDepth = maxDepth or 1
		Utils.MakeTableOutput(tbl, output, has, tabs, depth, maxDepth)
	else
		output = {}
		Utils.MakeValueOutput(tbl, output)
	end

	log(table.concat(output))
end

_G.PrintTable = Utils.PrintTable

---Saves the contents of a table to the specified file
---@param tbl table @The table to save to a file
---@param file string @The path (relative to payday2_win32_release.exe) and file name to save the table to
function _G.SaveTable(tbl, file)
	Utils.DoSaveTable(tbl, {}, file, nil, "")
end

function Utils.DoSaveTable(tbl, cmp, fileName, fileIsOpen, preText)
	local file = nil
	if fileIsOpen == nil then
		file = io.open(fileName, "w")
	else
		file = fileIsOpen
	end

	cmp = cmp or {}
	if tbl and type(tbl) == "table" then
		for k, v in pairs(tbl) do
			if type(v) == "table" and not cmp[v] then
				cmp[v] = true
				file:write(preText .. string.format("[\"%s\"] -> table", tostring (k)) .. "\n")
				Utils.DoSaveTable(v, cmp, fileName, file, preText .. "\t")
			else
				file:write(preText .. string.format("\"%s\" -> %s", tostring(k), tostring(v)) .. "\n")
			end
		end
	else
		file:write(preText .. tostring(tbl) .. "\n")
	end

	if fileIsOpen == nil then
		file:close()
	end
end

---@class Vector3
Vector3 = Vector3 or {}
Vector3.StringFormat = "%08f,%08f,%08f"
Vector3.MatchFormat = "([-0-9.]+),([-0-9.]+),([-0-9.]+)"

---Converts a Vector3 to a string, useful in conjunction with Networking
---@param v Vector3 @The Vector3 to convert to a formatted string
---@return string @A formatted string containing the data of the Vector3
function Vector3.ToString(v)
	return string.format(Vector3.StringFormat, v.x, v.y, v.z)
end

---Converts a formatted string to a Vector3, useful in conjunction with Networking
---@param string string @The string to convert to a Vector3
---@return Vector3? @A Vector3 of the converted string or ``nil`` if no conversion could be made
function string.ToVector3(string)
	local x, y, z = string:match(Vector3.MatchFormat)
	if x ~= nil and y ~= nil and z ~= nil then
		return Vector3(tonumber(x), tonumber(y), tonumber(z))
	end
	return nil
end

---Returns if a string exists or not
---@param str string @The string to check
---@return boolean @``false`` if the string is ``""`` or ``nil``, ``true`` otherwise
function string.is_nil_or_empty(str)
	return str == "" or str == nil
end

---Rounds a number to the specified precision (decimal places)
---@param num number @The number to round
---@param idp integer @The number of decimal places to round to (defaults to ``0``)
---@return number @The input number rounded to the input precision
function math.round_with_precision(num, idp)
	local mult = 10 ^ (idp or 0)
	return math.floor(num * mult + 0.5) / mult
end

---Returns whether you are in GameState (loadout, ingame, end screens like victory and defeat) or not
---@return boolean @``true`` if you are in GameState, ``false`` otherwise
function Utils:IsInGameState()
	return game_state_machine and string.find(game_state_machine:current_state_name(), "game") and true or false
end

---Returns wether you are currently in a loading state or not
---@return boolean @``true`` if you are in a loading state, ``false`` otherwise
function Utils:IsInLoadingState()
	if not BaseNetworkHandler then
		return false
	end
	return BaseNetworkHandler._gamestate_filter.waiting_for_players[game_state_machine:last_queued_state_name()]
end

---Returns wether you are currently in game (you're able to use your weapons, spot, call teammates etc) or not  
---Only returns true if currently ingame, does not check for GameState like ``Utils:IsInGameState()``
---@return boolean @``true`` if you are in game, ``false`` otherwise
function Utils:IsInHeist()
	if not BaseNetworkHandler then
		return false
	end
	return BaseNetworkHandler._gamestate_filter.any_ingame_playing[game_state_machine:last_queued_state_name()]
end

---Returns whether you are currently in custody or not
---@return boolean @``true`` if you are in custody, ``false`` otherwise
function Utils:IsInCustody()
	local player = managers.player:local_player()
	local in_custody = false
	if managers and managers.trade and not alive(player) then
		local session = managers.network:session()

		if session and session:local_peer() and session:local_peer():id() then
			in_custody = managers.trade:is_peer_in_custody(managers.network:session():local_peer():id())
		end
	end
	return in_custody
end

---Checks current primary weapon's weapon category
---@param type string @The weapon category to check for (refer to weapontweakdata.lua)
---@return boolean @``true`` if the weapon has ``type`` as category, ``false`` otherwise
function Utils:IsCurrentPrimaryOfCategory(type)
	local primary = managers.blackmarket:equipped_primary()
	if primary then
		local category = tweak_data.weapon[primary.weapon_id].category
		return category == string.lower(type)
	end
	return false
end

---Checks current secondary weapon's weapon category
---@param type string @The weapon category to check for (refer to weapontweakdata.lua)
---@return boolean @``true`` if the weapon has ``type`` as category, ``false`` otherwise
function Utils:IsCurrentSecondaryOfCategory(type)
	local secondary = managers.blackmarket:equipped_secondary()
	if secondary then
		local category = tweak_data.weapon[secondary.weapon_id].category
		return category == string.lower(type)
	end
	return false
end

---Checks if a specific weapon is currently equipped
---@param type string @The weapon's name ID (refer to weapontweakdata.lua)
---@return boolean @``true`` if the currently equipped weapon matches ``type``, ``false`` otherwise
function Utils:IsCurrentWeapon(type)
	local weapon = managers.player:local_player():inventory():equipped_unit():base()._name_id
	return weapon == string.lower(type)
end

---Checks if the currently equipped weapon is your primary weapon
---@return boolean @``true`` if the current weapon is a primary, ``false`` if not and ``nil`` if no weapon is equipped
function Utils:IsCurrentWeaponPrimary()
	local weapon = managers.player:local_player():inventory():equipped_unit():base():selection_index()
	return weapon and (managers.player._current_state ~= "mask_off" and weapon == 2)
end

---Checks if the currently equipped weapon is your secondary weapon
---@return boolean @``true`` if the current weapon is a secondary, ``false`` if not and ``nil`` if no weapon is equipped
function Utils:IsCurrentWeaponSecondary()
	local weapon = managers.player:local_player():inventory():equipped_unit():base():selection_index()
	return weapon and (managers.player._current_state ~= "mask_off" and weapon == 1)
end

---Gets the point in the world where the player is aiming at as a Vector3
---@param player table @The player to get the aiming position of
---@param maximum_range number @The maximum distance to check for a point in cm (defaults to ``100000``)
---@return Vector3|boolean @A Vector3 containing the location that the player is looking at, or ``false`` if the player was not looking at anything or was looking at something past the maximum_range
function Utils:GetPlayerAimPos(player, maximum_range)
	local player_camera = player:camera()
	local ray = self:GetCrosshairRay(player_camera:position(), player_camera:position() + player_camera:forward() * (maximum_range or 100000))
	if not ray then
		return false
	end
	return ray.hit_position
end

---Gets a ray between two points and checks for a collision with a slot mask along the ray
---@param from Vector3 @The starting position of the ray (defaults to the player's head)
---@param to Vector3 @The ending position of the ray (defaults to 1m in from of the player's head)
---@param slot_mask? string @The collision group to check against the ray (defaults to all objects the player can shoot)
---@return table|boolean @A table containing the ray information or ``false`` if no viewport camera exists
function Utils:GetCrosshairRay(from, to, slot_mask)
	local viewport = managers.viewport
	if not viewport:get_current_camera() then
		return false
	end

	slot_mask = slot_mask or "bullet_impact_targets"

	if not from then
		from = viewport:get_current_camera_position()
	end

	if not to then
		to = Vector3()
		mvector3.set(to, viewport:get_current_camera_rotation():y())
		mvector3.multiply(to, 20000)
		mvector3.add(to, from)
	end

	local colRay = World:raycast("ray", from, to, "slot_mask", managers.slot:get_mask(slot_mask))
	return colRay
end

---Gets the string value of a toggle menu item and converts it to a boolean value
---@param item table @The toggle menu item to get a boolean value from
---@return boolean @``true`` if the toggle item is on, ``false`` otherwise
function Utils:ToggleItemToBoolean(item)
	return item:value() == "on" and true or false
end

---Escapes special characters in a URL to turn it into a usable URL
---@param input_url string @The url to escape the characters of
---@return string @A url string with escaped characters
function Utils:EscapeURL(input_url)
	local url = input_url:gsub(" ", "%%20")
	url = url:gsub("!", "%%21")
	url = url:gsub("#", "%%23")
	url = url:gsub("-", "%%2D")
	return url
end

---Converts a date given by year, month and day into a timestamp
---@param year integer @Year of the date
---@param month integer @Month of the date
---@param day integer @Day of the date
---@return integer @Timestamp
function Utils:TimestampToEpoch(year, month, day)
	-- Adapted from http://stackoverflow.com/questions/4105012/convert-a-string-date-to-a-timestamp
	local offset = os.time() - os.time(os.date("!*t"))
	local time = os.time({
		day = day,
		month = month,
		year = year,
	})
	return (time or 0) + (offset or 0)
end

---Splits a string at every occurence of a delimiter up to an optional maximum number of times
---@param str string @String to split
---@param delim string @Substring at which to split ``str``
---@param max_num? integer @Maximum amount of splits (defaults to ``0``, which is no limit)
---@return table @Table containing all split substrings
function string.blt_split(str, delim, max_num)
	-- Eliminate bad cases...
	if string.find(str, delim) == nil then
		return {str}
	end
	max_num = max_num or 0

	local result = {}
	local pat = "(.-)" .. delim .. "()"
	local nb = 0
	local lastPos
	for part, pos in string.gmatch(str, pat) do
		nb = nb + 1
		result[nb] = part
		lastPos = pos
		if nb == max_num then
			break
		end
	end

	-- Handle the last field
	if nb ~= maxNb then
		result[nb + 1] = string.sub(str, lastPos)
	end
	return result
end
