BLTOptionsMenu = BLTOptionsMenu or class(BLTMenu)
function BLTOptionsMenu:Init(root)
    self:Title({
        text = "menu_header_options_main_screen_name"
    })
    self:SubTitle({
        text = "blt_options_menu_lua_mod_options"
    })
end

function BLTOptionsMenu:on_escape()
    MenuCallbackHandler:perform_blt_save()
end

BLTKeybindsMenu = BLTKeybindsMenu or class(BLTMenu)
function BLTKeybindsMenu:Init(root)
    self:Title({text = "menu_header_options_main_screen_name"})
    self:SubTitle({text = "blt_options_menu_keybinds"})
	local last_mod
	for i, bind in ipairs(BLT.Keybinds:keybinds()) do
		if bind:IsActive() and bind:ShowInMenu() then
			-- Seperate keybinds by mod
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
        name = "blt_options",
        name_id = "blt_options_menu_lua_mod_options",
        inject_list = "raid_menu_left_options",
        class = BLTOptionsMenu,
        inject_after = "network"
    })

    RaidMenuHelper:CreateMenu({
		name = "blt_keybinds",
		name_id = "blt_options_menu_keybinds",
        inject_list = "raid_menu_left_options",
        class = BLTKeybindsMenu
	})

    RaidMenuHelper:CreateMenu({
        name = "blt_mods",
        name_id = "blt_options_menu_blt_mods",
        inject_list = "raid_menu_left_options",
        class = BLTModsGui,
        inject_after = "network"
    })

    RaidMenuHelper:CreateMenu({
        name = "blt_download_manager",
        name_id = "blt_download_manager",
        inject_list = "raid_menu_left_options",
        class = BLTDownloadManagerGui,
        inject_after = "network"
    })

    RaidMenuHelper:CreateMenu({
        name = "view_blt_mod",
        class = BLTViewModGui
    })
end)