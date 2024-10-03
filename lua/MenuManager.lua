Hooks:RegisterHook("MenuManagerInitialize")
Hooks:RegisterHook("MenuManagerPostInitialize")
Hooks:PostHook(MenuManager, "init", "BLT.MenuManager.init", function(self)
	Hooks:Call("MenuManagerInitialize", self)
	Hooks:Call("MenuManagerPostInitialize", self)
end)

Hooks:RegisterHook("MenuManagerOnOpenMenu")
Hooks:PostHook(MenuManager, "open_menu", "BLT.MenuManager.open_menu", function(self, menu_name, position)
	Hooks:Call("MenuManagerOnOpenMenu", self, menu_name, position)
end)

function MenuManager:show_download_progress(mod_name)
	local dialog_data = {}
	dialog_data.title = managers.localization:text("base_mod_download_downloading_mod", { ["mod_name"] = mod_name })
	dialog_data.mod_name = mod_name or "No Mod Name"

	local ok_button = {}
	ok_button.cancel_button = true
	ok_button.text = managers.localization:text("dialog_ok")

	dialog_data.focus_button = 1
	dialog_data.button_list = {
		ok_button
	}

	managers.system_menu:show_download_progress(dialog_data)
end

-- Create this function if it doesn't exist
function MenuCallbackHandler:can_toggle_chat()
	if managers and managers.menu then
		local input = managers.menu:active_menu() and managers.menu:active_menu().input
		return not input or input.can_toggle_chat and input:can_toggle_chat()
	else
		return true
	end
end

core:import("CoreMenuData")
core:import("CoreMenuLogic")
core:import("CoreMenuInput")
core:import("CoreMenuRenderer")
function MenuManager:register_menu_new(menu)
	if menu.name and self._registered_menus[menu.name] then
		return
	end

	menu.data = CoreMenuData.Data:new()
	menu.data:_load_data(menu.config, menu.id or menu.name)
	menu.data:set_callback_handler(menu.callback_handler)

	menu.logic = CoreMenuLogic.Logic:new(menu.data)
	menu.logic:register_callback("menu_manager_menu_closed", callback(self, self, "_menu_closed", menu.name))
	menu.logic:register_callback("menu_manager_select_node", callback(self, self, "_node_selected", menu.name))

	-- Input
	if not menu.input then
		menu.input = CoreMenuInput.MenuInput:new(menu.logic, menu.name)
	else
		menu.input = loadstring("return " .. menu.input)()
		menu.input = menu.input:new(menu.logic, menu.name)
	end

	-- Renderer
	if not menu.renderer then
		menu.renderer = CoreMenuRenderer.Renderer:new(menu.logic)
	else
		menu.renderer = loadstring("return " .. menu.renderer)()
		menu.renderer = menu.renderer:new(menu.logic)
	end
	menu.renderer:preload()

	if menu.name then
		self._registered_menus[menu.name] = menu
	end
end

--------------------------------------------------------------------------------
-- Add BLT save function

Hooks:Register("BLTOnSaveData")
function MenuCallbackHandler:perform_blt_save()
	BLT:Log(LogLevel.INFO, "[BLT] Performing save...")

	Hooks:Call("BLTOnSaveData", BLT.save_data)

	local success = io.save_as_json(BLT.save_data, BLTModManager.Constants:ModManagerSaveFile())
	if not success then
		BLT:Log(LogLevel.ERROR, "[BLT] Could not save file " .. BLTModManager.Constants:ModManagerSaveFile())
	end
end

function MenuCallbackHandler:close_blt_mods()
	managers.menu_component:close_blt_mods_gui()
end

function MenuCallbackHandler:close_blt_download_manager()
	managers.menu_component:close_blt_download_manager_gui()
end

--------------------------------------------------------------------------------
-- Add BLT dll update notification

function MenuCallbackHandler:blt_update_dll_dialog(update)
	local update_url = update:GetUpdateMiscData().update_url

	local dialog_data = {}
	dialog_data.title = managers.localization:text("blt_update_dll_title")
	dialog_data.text = managers.localization:text("blt_update_dll_text")

	local download_button = {}
	download_button.text = managers.localization:text("blt_update_dll_goto_website")
	download_button.callback_func = callback(self, self, "clbk_goto_paydaymods_download", update_url)

	local ok_button = {}
	ok_button.text = managers.localization:text("blt_update_later")
	ok_button.cancel_button = true

	dialog_data.button_list = { download_button, ok_button }
	managers.system_menu:show(dialog_data)
end

function MenuCallbackHandler:clbk_goto_paydaymods_download(update_url)
	os.execute("cmd /c start " .. update_url)
end

--------------------------------------------------------------------------------
-- Add visibility callback for showing keybinds

function MenuCallbackHandler:blt_show_keybinds_item()
	return BLT.Keybinds and BLT.Keybinds:has_menu_keybinds()
end

--------------------------------------------------------------------------------
-- Add settings callbacks

function MenuCallbackHandler:blt_choose_log_level(item)
	BLTLogs.log_level = math.clamp(item:value(), _G.LogLevel.NONE, _G.LogLevel.ALL)
end

function MenuCallbackHandler:blt_choose_log_lifetime(item)
	BLTLogs.lifetime = item:value()
end
