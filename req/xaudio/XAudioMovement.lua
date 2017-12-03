-- Move the listener around to follow the player

blt.xaudio.setup() -- removeme
local l = blt.xaudio.listener

local buff = blt.xaudio.loadbuffer("test.ogg")
local src = blt.xaudio.newsource()
src:setbuffer(buff)

local last_played = 0

local mvec_cam_fwd = Vector3()
local mvec_cam_up = Vector3()

-- This is our wu-to-meters conversion
-- You can get it using blt.xaudio.getworldscale() if you need to use it
-- This means we can use positions from the game without worrying about
--  unit conversion or anything.
blt.xaudio.setworldscale(300)

Hooks:PostHook(PlayerMovement, "update", "XAudioUpdateListenerPosition", function(self, unit, t, dt)
	local pos = self:m_stand_pos()
	l:setposition(pos.x, pos.y, pos.z)

	-- XXX REMOVEME testing only
	if last_played + 3 < t then
		if last_played == 0 then
			src:setposition(pos.x, pos.y, pos.z)
		end

		last_played = t
		src:play()
	end

	local state = self:current_state()
	if not state then return end

	-- TODO jumping/falling?
	local velocity = state._last_velocity_xy

	if velocity then
		l:setvelocity(velocity.x, velocity.y, velocity.z)
	end

	if state._ext_camera then
		local rotation = state._ext_camera:rotation()
		mrotation.y(rotation, mvec_cam_fwd)
		mrotation.z(rotation, mvec_cam_up)
		l:setorientation(
			mvec_cam_fwd.x, mvec_cam_fwd.y, mvec_cam_fwd.z,
			mvec_cam_up.x, mvec_cam_up.y, mvec_cam_up.z
		)
	end
end)
