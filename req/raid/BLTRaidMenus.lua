BLTOptionsMenu = BLTOptionsMenu or class(RaidMenuLeftOptions)

function BLTOptionsMenu:init(ws, fullscreen_ws, node, component_name)
	BLTOptionsMenu.super.init(self, ws, fullscreen_ws, node, component_name)
	self.list_menu_options:show()
end

function BLTOptionsMenu:_set_initial_data()
	self._node.components.raid_menu_header:set_screen_name("menu_header_options_main_screen_name", "blt_options_menu_lua_mod_options")
end

function BLTOptionsMenu:_layout()
	BLTOptionsMenu.super._layout(self)
	self:_layout_list_menu()
	self:bind_controller_inputs()
end

function BLTOptionsMenu:close()
	BLTOptionsMenu.super.close(self)
	MenuCallbackHandler:perform_blt_save()
end

function BLTOptionsMenu:_layout_list_menu()
	local list_menu_options_params = {
		h = 640,
		w = 480,
		y = 144,
		x = 0,
		name = "blt_options_menu_list",
		selection_enabled = true,
		vertical_spacing = 2,
		loop_items = true,
		on_item_clicked_callback = callback(self, self, "_on_list_menu_options_item_selected"),
		data_source_callback = callback(self, self, "_list_menu_options_data_source"),
		item_class = RaidGUIControlListItemMenu,
		blt_can_sort_list = true
	}
	self.list_menu_options = self._root_panel:create_custom_control(RaidGUIControlSingleSelectList, list_menu_options_params)
	self.list_menu_options:set_selected(true)
end

function BLTOptionsMenu:_list_menu_options_data_source()
	return {} -- filled by RaidMenuHelper:CreateMenu injection
end

BLTKeybindsMenu = BLTKeybindsMenu or class(BLTMenu)
function BLTKeybindsMenu:Init(root)
	self:Title({text = "menu_header_options_main_screen_name"})
	self:SubTitle({text = "blt_options_menu_keybinds"})
	local last_mod
	for i, bind in ipairs(BLT.Keybinds:keybinds()) do
		if bind:IsActive() and bind:ShowInMenu() then
			-- Separate keybinds by mod
			if last_mod ~= bind:ParentMod() then
				self:Label({text = bind:ParentMod():GetName(), localize = false})
			end
			self:KeyBind({
				name = bind:Id(),
				text = bind:Name(),
				keybind_id = bind:Id(),
				x_offset = 10,
				localize = false,
				desc = bind:Description(),
				localize_desc = false
			})

			last_mod = bind:ParentMod()
		end
	end
end

function BLTKeybindsMenu:on_escape()
	MenuCallbackHandler:perform_blt_save()
end

Hooks:Add("MenuComponentManagerInitialize", "BLT.MenuComponentManagerInitialize", function()
	RaidMenuHelper:CreateMenu({
		name = "blt_mods",
		name_id = "blt_options_menu_blt_mods",
		class = BLTModsGui,
		inject_list = "raid_menu_left_options",
		inject_after = "network",
		icon = "menu_item_cards"
	})

	RaidMenuHelper:CreateMenu({
		name = "blt_keybinds",
		name_id = "blt_options_menu_keybinds",
		class = BLTKeybindsMenu,
		inject_list = "raid_menu_left_options",
		inject_after = "network",
		icon = "menu_item_controls"
	})

	RaidMenuHelper:CreateMenu({
		name = "blt_options",
		name_id = "blt_options_menu_lua_mod_options",
		class = BLTOptionsMenu,
		inject_list = "raid_menu_left_options",
		inject_after = "network",
		icon = "menu_item_options"
	})

	RaidMenuHelper:CreateMenu({
		name = "blt_download_manager",
		name_id = "blt_download_manager",
		class = BLTDownloadManagerGui,
	})
end)