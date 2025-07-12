
function RaidGUIPanel:stepper_icons(params)
	local control = BLTGUIControlStepperIcons:new(self, params)
	self:_add_control(control)
	return control
end

function RaidGUIPanel:stepper_icons_simple(params)
	local control = BLTGUIControlStepperIconsSimple:new(self, params)
	self:_add_control(control)
	return control
end
