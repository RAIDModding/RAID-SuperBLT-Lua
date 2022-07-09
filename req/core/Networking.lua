_G.LuaNetworking = _G.LuaNetworking or {}
LuaNetworking.HiddenChannel = 4
LuaNetworking.AllPeers = "GNAP"
LuaNetworking.AllPeersString = "%s/%s/%s"
LuaNetworking.SinglePeer = "GNSP"
LuaNetworking.SinglePeerString = "%s/%s/%s/%s"
LuaNetworking.ExceptPeer = "GNEP"
LuaNetworking.ExceptPeerString = "%s/%s/%s/%s"
LuaNetworking.Split = "[/]"

-- Technically we don't need the message identifiers anymore cause we're only sending to the peers we want to send to anyways
-- For backwards compatibility, we'll keep them for now and they can be phased out at a later date

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
		str = str .. string.format("%s|%s", tostring(k), tostring(v))
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
	for k, v in pairs(self:GetPeers()) do
		if k == id then
			return v:name()
		end
	end

	return "No Name"
end

---Returns an accessor for the session peers table
---@return table @Table of all players in the current multiplayer session
function LuaNetworking:GetPeers()
	return managers.network and managers.network:session() and managers.network:session():peers() or {}
end

---Returns the number of players in the multiplayer session
---@return integer @Number of players in the current session
function LuaNetworking:GetNumberOfPeers()
	return table.size(self:GetPeers())
end

---Sends networked data with a message id to all connected players
---@param id string @Unique name of the data to send
---@param data string @Data to send
function LuaNetworking:SendToPeers(id, data)
	local message = LuaNetworking.AllPeersString:format(LuaNetworking.AllPeers, id, data)
	self:SendStringThroughChat(message, self:GetPeers())
end

---Sends networked data with a message id to a specific player
---@param peer_id integer @Peer ID of the player to send the data to
---@param id string @Unique name of the data to send
---@param data string @Data to send
function LuaNetworking:SendToPeer(peer_id, id, data)
	local message = LuaNetworking.SinglePeerString:format(LuaNetworking.SinglePeer, peer_id, id, data)
	self:SendStringThroughChat(message, { self:GetPeers()[peer_id] })
end

---Sends networked data with a message id to all connected players except specific ones
---@param peer_id integer|integer[] @Peer ID or table of peer IDs of the player(s) to exclude
---@param id string @Unique name of the data to send
---@param data string @Data to send
function LuaNetworking:SendToPeersExcept(peer_id, id, data)
	local except = type(peer_id) == "table" and table.list_to_set(peer_id) or { [peer_id] = true }
	local peerStr = type(peer_id) == "table" and table.concat(peer_id, ",") or peer_id
	local message = LuaNetworking.ExceptPeerString:format(LuaNetworking.ExceptPeer, peerStr, id, data)
	self:SendStringThroughChat(message, table.filter(self:GetPeers(), function (peer) return except[peer:id()] == nil end))
end

function LuaNetworking:SendStringThroughChat(message, receivers)
	for _, peer in pairs(receivers or self:GetPeers()) do
		if peer:ip_verified() then
			peer:send("send_chat_message", LuaNetworking.HiddenChannel, message)
		end
	end

	local local_peer = managers.network and managers.network:session() and managers.network:session():local_peer()
	BLT:Log(LogLevel.INFO, string.format("[LuaNetworking] %s: %s", local_peer and local_peer:name() or "", message))
end

Hooks:Add("ChatManagerOnReceiveMessage","ChatManagerOnReceiveMessage_Network", function(channel_id, name, message, color, icon)
	if tonumber(channel_id) ~= LuaNetworking.HiddenChannel then
		return
	end

	BLT:Log(LogLevel.INFO, string.format("[LuaNetworking] %s: %s", name, message))

	local senderID
	for k, v in pairs(LuaNetworking:GetPeers()) do
		if v:name() == name then
			senderID = k
		end
	end

	LuaNetworking:ProcessChatString(senderID or name, message, color, icon)
end)

Hooks:RegisterHook("NetworkReceivedData")
function LuaNetworking:ProcessChatString(sender, message, color, icon)
	local splitData = string.split(message, LuaNetworking.Split)
	local msgType = splitData[1]
	if msgType == LuaNetworking.AllPeers then
		self:ProcessAllPeers(sender, message, color, icon)
	elseif msgType == LuaNetworking.SinglePeer then
		self:ProcessSinglePeer(sender, message, color, icon)
	elseif msgType == LuaNetworking.ExceptPeer then
		self:ProcessExceptPeer(sender, message, color, icon)
	end
end

function LuaNetworking:ProcessAllPeers(sender, message, color, icon)
	local splitData = string.split(message, LuaNetworking.Split, nil, 2)
	Hooks:Call("NetworkReceivedData", sender, splitData[2], splitData[3])
end

function LuaNetworking:ProcessSinglePeer(sender, message, color, icon)
	local splitData = string.split(message, LuaNetworking.Split, nil, 3)
	local toPeer = tonumber(splitData[2])

	if toPeer == LuaNetworking:LocalPeerID() then
		Hooks:Call("NetworkReceivedData", sender, splitData[3], splitData[4])
	end
end

function LuaNetworking:ProcessExceptPeer(sender, message, color, icon)
	local splitData = string.split(message, LuaNetworking.Split, nil, 3)
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
LuaNetworking._networked_colour_string = "r:%.4g|g:%.4g|b:%.4g|a:%.4g"

---Creates a string representation of a color
---@param col any
---@return string
function LuaNetworking:ColourToString(col)
	return LuaNetworking._networked_colour_string:format(col.r, col.g, col.b, col.a)
end

---Converts a string representation of a color to a color
---@param str string
---@return any
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
