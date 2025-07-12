BLTGUIControlStepperIcons = BLTGUIControlStepperIcons or class(RaidGUIControlStepper)

function BLTGUIControlStepperIcons:_create_stepper_controls()
	local sideline_params = {
		alpha = 0,
		color = RaidGUIControlStepper.SIDELINE_COLOR,
		h = self._object:h(),
		w = RaidGUIControlStepper.SIDELINE_W,
		x = 0,
		y = 0,
	}

	self._sideline = self._object:rect(sideline_params)

	local stepper_w = self._params.stepper_w or RaidGUIControlStepperSimple.DEFAULT_WIDTH
	local stepper_params = {
		data_source_callback = self._params.data_source_callback,
		name = self._name .. "_stepper_icons",
		on_item_selected_callback = self._params.on_item_selected_callback,
		start_from_last = self._stepper_params.start_from_last,
		w = stepper_w,
		x = self._object:w() - stepper_w,
		y = 0,
	}
	self._stepper = self._object:stepper_icons_simple(stepper_params)

	self._description = self._object:text({
		align = "left",
		color = RaidGUIControlStepper.TEXT_COLOR,
		font = tweak_data.gui.fonts.din_compressed,
		font_size = tweak_data.gui.font_sizes.small,
		h = self._object:h(),
		layer = self._object:layer() + 1,
		text = self._params.description,
		vertical = "center",
		w = self._object:w() - stepper_w - RaidGUIControlStepper.SIDELINE_W - RaidGUIControlStepper.TEXT_PADDING * 2,
		x = RaidGUIControlStepper.SIDELINE_W + RaidGUIControlStepper.TEXT_PADDING,
		y = 0,
	})
end
