-- Move the listener around to follow the player

local l = blt.xaudio.listener

local buff = XAudio.Buffer:new("test.ogg")
local src = XAudio.Source:new()
src:set_buffer(buff)

local last_played = 0

local mvec_cam_fwd = Vector3()
local mvec_cam_up = Vector3()

Hooks:PostHook(PlayerMovement, "update", "XAudioUpdateListenerPosition", function(self, unit, t, dt)
	if not blt.xaudio.issetup() then return end

	local pos = self:m_stand_pos()
	l:setposition(pos.x, pos.y, pos.z)

	-- XXX REMOVEME testing only
	if last_played + 3 < t then
		if last_played == 0 then
			src:set_position(pos)
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
