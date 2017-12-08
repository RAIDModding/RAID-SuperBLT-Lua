local C = blt_class(XAudio.Source)
XAudio.UnitSource = C

function C:init(unit, source)
	self.super:init(source)
	self._unit = unit
end

function C:update(...)
	self.super:update(...)

	local unit = self._unit
	if self._unit == XAudio.PLAYER then
		unit = XAudio._player_unit
	end

	local pos = unit:position()
	self:set_position(pos)
	-- TODO velocity and direction
end
