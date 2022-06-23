_G.LuaNetworking = _G.LuaNetworking or {}
LuaNetworking.HiddenChannel = 4
LuaNetworking.AllPeers = "GNAP"
LuaNetworking.AllPeersString = "{1}/{2}/{3}"
LuaNetworking.SinglePeer = "GNSP"
LuaNetworking.SinglePeerString = "{1}/{2}/{3}/{4}"
LuaNetworking.ExceptPeer = "GNEP"
LuaNetworking.ExceptPeerString = "{1}/{2}/{3}/{4}"
LuaNetworking.Split = "[/]"

---Checks if the game is in a multiplayer state, and has an active multiplayer session
---@return boolean @The active multiplayer session, or `false`
function LuaNetworking:IsMultiplayer()
	if not managers.network then
		return false
	end
	return managers.network:session()
end

---Checks if the local player is the host of the multiplayer game session  
---Functionally identical to `Network:is_server()`
---@return boolean @`true` if a multiplayer session is running and the local player is the host of it, or `false`
function LuaNetworking:IsHost()
	if not Network then
		return false
	end
	return not Network:is_client()
end

---Checks if the local player is a client of the multiplayer game session  
---Functionally identical to `Network:is_client()`
---@return boolean @`true` if a multiplayer session is running and the local player is not the host of it, or `false`
function LuaNetworking:IsClient()
	if not Network then
		return false
	end
	return Network:is_client()
end

---Returns the peer ID of the local player
---@return integer @Peer ID of the local player or `0` if no multiplayer session is active
function LuaNetworking:LocalPeerID()
	if managers.network == nil or managers.network:session() == nil or managers.network:session():local_peer() == nil then
		return 0
	end
	return managers.network:session():local_peer():id() or 0
end

---Converts a table to a string representation
---@param tbl table @Table to convert into a string
---@return string @String representation of `tbl`
function LuaNetworking:TableToString(tbl)
	local str = ""
	for k, v in pairs(tbl) do
		if str ~= "" then
			str = str .. ","
		end
		str = str .. ("{0}|{1}"):gsub("{0}", tostring(k)):gsub("{1}", tostring(v))
	end
	return str
end

---Converts the string representation of a table to a table
---@param str string @String representation of a table
---@return table @Table created from `str`
function LuaNetworking:StringToTable(str)
	local tbl = {}
	local tblPairs = string.split(str, "[,]")
	for k, v in pairs(tblPairs) do
		local pairData = string.split(v, "[|]")
		tbl[pairData[1]] = pairData[2]
	end
	return tbl
end

---Returns the name of the player associated with the specified peer ID
---@param id integer @Peer ID of the player to get the name from
---@return string @Name of the player with peer ID `id`, or `"No Name"` if the player could not be found
function LuaNetworking:GetNameFromPeerID(id)
	if managers.network and managers.network:session() and managers.network:session():peers() then
		for k, v in pairs(managers.network:session():peers()) do
			if k == id then
				return v:name()
			end
		end
	end

	return "No Name"
end

---Returns an accessor for the session peers table
---@return table @Table of all players in the current multiplayer session
function LuaNetworking:GetPeers()
	if managers.network and managers.network:session() then
		return managers.network:session():peers()
	else
		return {}
	end
end

---Returns the number of players in the multiplayer session
---@return integer @Number of players in the current session
function LuaNetworking:GetNumberOfPeers()
	local i = 0
	for k, v in pairs(self:GetPeers()) do
		i = i + 1
	end
	return i
end

---Sends networked data with a message id to all connected players
---@param id string @Unique name of the data to send
---@param data string @Data to send
function LuaNetworking:SendToPeers(id, data)
	local dataString = LuaNetworking.AllPeersString
	dataString = dataString:gsub("{1}", LuaNetworking.AllPeers)
	dataString = dataString:gsub("{2}", id)
	dataString = dataString:gsub("{3}", data)
	LuaNetworking:SendStringThroughChat(dataString)
end

---Sends networked data with a message id to a specific player
---@param peer integer @Peer ID of the player to send the data to
---@param id string @Unique name of the data to send
---@param data string @Data to send
function LuaNetworking:SendToPeer(peer, id, data)
	local dataString = LuaNetworking.SinglePeerString
	dataString = dataString:gsub("{1}", LuaNetworking.SinglePeer)
	dataString = dataString:gsub("{2}", peer)
	dataString = dataString:gsub("{3}", id)
	dataString = dataString:gsub("{4}", data)
	LuaNetworking:SendStringThroughChat(dataString)
end

---Sends networked data with a message id to all connected players except specific ones
---@param peer integer|table @Peer ID or table of peer IDs of the player(s) to exclude
---@param id string @Unique name of the data to send
---@param data string @Data to send
function LuaNetworking:SendToPeersExcept(peer, id, data)
	local dataString = LuaNetworking.ExceptPeerString
	local peerStr = peer
	if type(peer) == "table" then
		peerStr = ""
		for k, v in pairs(peer) do
			if peerStr ~= "" then
				peerStr = peerStr .. ","
			end
			peerStr = peerStr .. tostring(v)
		end
	end

	dataString = dataString:gsub("{1}", LuaNetworking.ExceptPeer)
	dataString = dataString:gsub("{2}", peerStr)
	dataString = dataString:gsub("{3}", id)
	dataString = dataString:gsub("{4}", data)
	LuaNetworking:SendStringThroughChat(dataString)
end

function LuaNetworking:SendStringThroughChat(message)
	local chat_manager = managers.chat
	if chat_manager._receivers == nil then
		chat_manager._receivers = {}
	end
	chat_manager:send_message(LuaNetworking.HiddenChannel, tostring(LuaNetworking:LocalPeerID()), message)
end

Hooks:Add("ChatManagerOnReceiveMessage","ChatManagerOnReceiveMessage_Network", function(channel_id, name, message, color, icon)
	name = name:gsub("%%", "%%%%")
	message = message:gsub("%%", "%%%%")
	local s = string.format("[%s] %s: %s", channel_id, name, message)
	BLT:Log(LogLevel.INFO, s)

	local senderID = nil
	if LuaNetworking:IsMultiplayer() then
		if name == managers.network:session():local_peer():name() then
			senderID = LuaNetworking:LocalPeerID()
		end

		for k, v in pairs(managers.network:session():peers()) do
			if v:name() == name then
				senderID = k
			end
		end
	end

	if senderID == LuaNetworking:LocalPeerID() then
		return
	end

	if tonumber(channel_id) == LuaNetworking.HiddenChannel then
		LuaNetworking:ProcessChatString(senderID or name, message, color, icon)
	end
end)

Hooks:RegisterHook("NetworkReceivedData")
function LuaNetworking:ProcessChatString(sender, message, color, icon)
	local splitData = string.split(message, LuaNetworking.Split)
	local msgType = splitData[1]
	if msgType == LuaNetworking.AllPeers then
		LuaNetworking:ProcessAllPeers(sender, message, color, icon)
	end
	if msgType == LuaNetworking.SinglePeer then
		LuaNetworking:ProcessSinglePeer(sender, message, color, icon)
	end
	if msgType == LuaNetworking.ExceptPeer then
		LuaNetworking:ProcessExceptPeer(sender, message, color, icon)
	end
end

function LuaNetworking:ProcessAllPeers(sender, message, color, icon)
	local splitData = string.split(message, LuaNetworking.Split)
	Hooks:Call("NetworkReceivedData", sender, splitData[2], splitData[3])
end

function LuaNetworking:ProcessSinglePeer(sender, message, color, icon)
	local splitData = string.split(message, LuaNetworking.Split)
	local toPeer = tonumber(splitData[2])

	if toPeer == LuaNetworking:LocalPeerID() then
		Hooks:Call("NetworkReceivedData", sender, splitData[3], splitData[4])
	end
end

function LuaNetworking:ProcessExceptPeer(sender, message, color, icon)
	local splitData = string.split(message, LuaNetworking.Split)
	local exceptedPeers = string.split(splitData[2], "[,]")

	local excepted = false
	for k, v in pairs(exceptedPeers) do
		if tonumber(v) == LuaNetworking:LocalPeerID() then
			excepted = true
		end
	end

	if not excepted then
		Hooks:Call("NetworkReceivedData", sender, splitData[3], splitData[4])
	end
end

-- Extensions
LuaNetworking._networked_colour_string = "r:{1}|g:{2}|b:{3}|a:{4}"
function LuaNetworking:ColourToString(col)
	local dataString = LuaNetworking._networked_colour_string
	dataString = dataString:gsub("{1}", math.round_with_precision(col.r, 4))
	dataString = dataString:gsub("{2}", math.round_with_precision(col.g, 4))
	dataString = dataString:gsub("{3}", math.round_with_precision(col.b, 4))
	dataString = dataString:gsub("{4}", math.round_with_precision(col.a, 4))
	return dataString
end

function LuaNetworking:StringToColour(str)
	local data = string.split(str, "[|]")
	if #data < 4 then
		return nil
	end

	local split_str = "[:]"
	local r = tonumber(string.split(data[1], split_str)[2])
	local g = tonumber(string.split(data[2], split_str)[2])
	local b = tonumber(string.split(data[3], split_str)[2])
	local a = tonumber(string.split(data[4], split_str)[2])

	return Color(a, r, g, b)
end
