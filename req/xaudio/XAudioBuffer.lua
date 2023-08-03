---@class Buffer
---@field new fun(self, input: string):Buffer
local C = blt_class()
XAudio.Buffer = C

function C:init(input)
	local t = type(input)
	if t == "string" then
		input = blt.xaudio.loadbuffer(input)
	elseif t == "userdata" then
		-- Nothing needs to be done.
		-- TODO verify this is a buffer
	else
		error("Unknown XAudio.Buffer input type " .. type .. " for " .. tostring(input))
	end

	self._buffer = input
end

function C:close(force)
	self._buffer:close(force and true or false)
end

function C:get_length()
	return self._buffer:getsamplecount() / self._buffer:getsamplerate()
end
