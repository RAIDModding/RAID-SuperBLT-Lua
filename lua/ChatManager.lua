Hooks:RegisterHook("ChatManagerOnSendMessage")
Hooks:PreHook(ChatManager, "send_message", "BLT.ChatManager.send_message",
	function(self, channel_id, sender, message)
		Hooks:Call("ChatManagerOnSendMessage", channel_id, sender, message)
	end
)

Hooks:RegisterHook("ChatManagerOnReceiveMessage")
Hooks:PreHook(ChatManager, "_receive_message", "BLT.ChatManager._receive_message",
	function(self, channel_id, name, peer_id, message, color, icon, system_message)
		Hooks:Call("ChatManagerOnReceiveMessage", channel_id, name, message, color, icon)
	end
)
