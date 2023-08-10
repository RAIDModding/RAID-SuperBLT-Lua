Hooks:RegisterHook("MenuComponentManagerInitialize")
Hooks:PostHook(MenuComponentManager, "init", "BLT.MenuComponentManager.init", function(self)
	managers.menu_component = managers.menu_component or self -- Make it available as early as possible
	Hooks:Call("MenuComponentManagerInitialize", self)
end)

Hooks:RegisterHook("MenuComponentManagerUpdate")
Hooks:PostHook(MenuComponentManager, "update", "BLT.MenuComponentManager.update", function(self, t, dt)
	Hooks:Call("MenuComponentManagerUpdate", self, t, dt)
end)

Hooks:RegisterHook("MenuComponentManagerPreSetActiveComponents")
Hooks:PreHook(MenuComponentManager, "set_active_components", "BLT.MenuComponentManager.set_active_components", function(self, components, node)
	Hooks:Call("MenuComponentManagerPreSetActiveComponents", self, components, node)
end)

Hooks:RegisterHook("MenuComponentManagerOnMousePressed")
Hooks:PostHook(MenuComponentManager, "mouse_pressed", "BLT.MenuComponentManager.mouse_pressed", function(self, o, button, x, y)
	return Hooks:ReturnCall("MenuComponentManagerOnMousePressed", self, o, button, x, y)
end)

Hooks:RegisterHook("MenuComponentManagerOnMouseMoved")
Hooks:PostHook(MenuComponentManager, "mouse_moved", "BLT.MenuComponentManager.mouse_moved", function(self, o, x, y)
	return Hooks:ReturnCall("MenuComponentManagerOnMouseMoved", self, o, x, y)
end)

Hooks:RegisterHook("MenuComponentManagerOnMouseClicked")
Hooks:PostHook(MenuComponentManager, "mouse_clicked", "BLT.MenuComponentManager.mouse_clicked", function(self, o, button, x, y)
	return Hooks:ReturnCall("MenuComponentManagerOnMouseClicked", self, o, button, x, y)
end)

--- This handles injecting modded menus
if BLT:GetGame() == "raid" then
	Hooks:PostHook(MenuComponentManager, "set_active_components", "BLT.MenuComponentManager.set_active_components", function(self, components, node)
		for name, comp in pairs(self._active_components) do
			if BLT.raid_menus[name] then --Create only when necessary
				if not comp.orig_create then
					comp.orig_create = comp.create
					comp.create = function(this, ...)
						local r = comp.orig_create(this, ...)
						for _, inject in pairs(BLT.raid_menus[name]) do
							if inject.is_list then
								RaidMenuHelper:InjectIntoAList(r, inject.point, inject.buttons, inject.list_name)
							else
								for _, btn in pairs(inject.buttons) do
									if btn.inject_type then
										BLTMenu[btn.inject_type](r, btn)
									else
										BLTMenu.MenuButton(r, btn)
									end
									if r._layout then
										r:_layout()
									end
								end
							end
						end
						return r
					end
				end
			end
		end
	end)

	--- Port of PD2's "special_btn_released" callback function so it can be 
	--- used in conjunction with "special_btn_pressed", which is already supported.
	function MenuRenderer:special_btn_released(...)
		if self:active_node_gui() and self:active_node_gui().special_btn_released and self:active_node_gui():special_btn_released(...) then
			return true
		end

		return managers.menu_component:special_btn_released(...)
	end

	function MenuComponentManager:special_btn_released(...)
		for _, component in pairs(self._active_components) do
			if component.component_object and component.component_object.special_btn_released then
				local handled = component.component_object:special_btn_released(...)
				if handled then
					return true
				end
			end
		end

		if self._game_chat_gui and self._game_chat_gui:input_focus() == true then
			return true
		end
	end
end