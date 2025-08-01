
BLTGUIControlButton = BLTGUIControlButton or blt_class(RaidGUIControlButton)

function BLTGUIControlButton:init(parent, params)
	BLTGUIControlButton.super.init(self, parent, params)
end

function BLTGUIControlButton:_animate_press()
	-- do nothing
end

function BLTGUIControlButton:_animate_release()
	-- do nothing
end
