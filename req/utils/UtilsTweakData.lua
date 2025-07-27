Hooks:PostHook(TweakData, "init", "SBLT_UtilsTweakData_Init", function()
	Utils._setup_fixed_fonts_table()
end)


Hooks:PostHook(GuiTweakData, "init", "SBLT_UtilsGuiTweakData_Init", function(self)
	Utils._setup_blt_icon_tweakdata(self)
end)
