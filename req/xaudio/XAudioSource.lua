local C = blt_class()
XAudio.Source = C

C.PLAYING = 1
C.PAUSED = 2
C.STOPPED = 3
C.INITIAL = 4
C.OTHER = 5

function C:init(source)
	self._source = source and source._buffer or blt.xaudio.newsource()

	-- Get a source ID
	self._source_id = XAudio._next_source_id
	XAudio._next_source_id = XAudio._next_source_id + 1

	-- Add ourselves to the sources list
	XAudio._sources[self._source_id] = self

	-- Set our game paused paramter
	-- This determines if actions should be held until the game is un-paused again.
	self._pause_held = false
end

function C:close()
	-- Remove ourselves from the sources table
	XAudio._sources[self._source_id] = nil

	-- Close the audio source
	self._source:close()
end

for _, name in ipairs({
	"close",
	"play",
	"pause",
	"stop"
}) do
	C[name] = function(self, ...)
		self._source[name](self._source)
	end
end

function C:set_buffer(buffer, set)
	if self:is_active() then
		if set then
			self:stop()
		else
			error("Cannot set buffer on source with state " .. self._source:getstate())
		end
	end

	self._source:setbuffer(buffer._buffer)
end

function C:is_active()
	local state = self:get_state()
	return state == C.PLAYING or state == C.PAUSED
end

function C:get_state()
	local state = ({
		playing = C.PLAYING,
		paused = C.PAUSED,
		stoppped = C.STOPPED,
		initial = C.INITIAL
	})[self._source:getstate()]

	return state or C.OTHER
end

local function process_vector(x, y, z)
	if type(x) == "userdata" then -- We were passed a vector
		z = x.z
		y = x.y
		x = x.x
	end

	return x, y, z
end

function C:set_position(...)
	self._source:setposition(process_vector(...))
end

function C:set_velocity(...)
	self._source:setvelocity(process_vector(...))
end

function C:set_direction(...)
	self._source:setdirection(process_vector(...))
end

function C:update(t, dt, paused)
	-- Pause/unpause this source when the game is paused/unpaused
	if paused ~= self._pause_held and self:is_active() then
		self._pause_held = paused

		if paused and self:get_state() == C.PLAYING then
			self:pause()
			self._queue_paused = true
		elseif not paused and self._queue_paused then
			self:play()
			self._queue_paused = false
		end
	end
end
