BLT.raid_menus = {}

RaidMenuHelper = RaidMenuHelper or {}
function RaidMenuHelper:CreateMenu(params)
	local name = string.gsub(params.name, "%s", "") --remove spaces from names, it doesn't seem to like them that much.
	local text = params.text or params.name_id or params.name --:shrug:
	local component_name = params.component_name or name
	self:RegisterMenu({
		name = name,
		input = params.input or "MenuInput",
		renderer = params.renderer or "MenuRenderer",
		callback_handler = params.callback_handler or MenuCallbackHandler,
		config = {
			{
				_meta = "menu",
				id = params.id or name,
				{_meta = "default_node", name = name},
				{
					_meta = "node",
					gui_class = params.gui_class or "MenuNodeGuiRaid",
					name = params.node_name or name,
					topic_id = params.topic_id or name,
					menu_components = params.menu_components or ("raid_menu_header raid_menu_footer raid_back_button " .. (params.components or name or "")),
					node_background_width = params.background_width or 0.4,
					node_padding = params.padding or 30
				}
			}
		}
	})
	if managers.raid_menu then
		managers.raid_menu.menus[component_name] = {name = component_name, class = params.class}
	end
	if params.class then
        if managers.menu_component then
            MenuHelper:AddComponent(component_name, params.class, params.args)
        else
            BLT:Log(LogLevel.ERROR, "BLTMenuHelper", "You're building the menu too early! menu component isn't loaded yet.")
        end
	end
	if params.localize == nil then
		params.localize = true
	end
    if params.inject_list then
        self:InjectButtons(params.inject_list, params.inject_after, {
            self:PrepareListButton(text, params.localize, self:MakeNextMenuClbk(component_name), params.flags)
		}, true)
	elseif params.inject_menu then
		local menu = managers.raid_menu.menus[params.inject_menu]
		local clbk = function() managers.raid_menu:open_menu(component_name) end --callbacks apparently break the back button
		if menu and menu.class then
			menu.class._items_data = menu.class._items_data or {}
			table.insert(menu.class._items_data, table.merge({
				type = "MenuButton",
				name = params.name.."Button",
				text = text,
				localize = params.localize,
				index = params.index,
				callback = clbk
			}, params.merge_data))
		else
			self:InjectButtons(params.inject_menu, params.inject_after, {
				self:PrepareButton(text, params.localize, clbk)
			})
		end
    end
    return params.name
end

function RaidMenuHelper:InjectButtons(menu, point, buttons, is_list)
    BLT.raid_menus[menu] = BLT.raid_menus[menu] or {}
    table.insert(BLT.raid_menus[menu], {
        buttons = buttons,
		point = point,
		is_list = is_list
    })
end

function RaidMenuHelper:PrepareButton(text, localize, callback)
	return {
		text = text,
		localize = localize,
		callback = callback,
	}
end

function RaidMenuHelper:PrepareListButton(text, localize, callback_s, flags)
	return {
		text = localize and managers.localization:to_upper_text(text) or text,
		callback = callback_s,
		availability_flags = flags
	}
end

function RaidMenuHelper:MakeClbk(name, func)
	RaidMenuCallbackHandler[name] = RaidMenuCallbackHandler[name] or func
	return name
end

function RaidMenuHelper:MakeNextMenuClbk(next_menu)
	local id = "open_menu_" .. next_menu
	RaidMenuCallbackHandler[id] = RaidMenuCallbackHandler[id] or function(this)
        managers.raid_menu:open_menu(next_menu)
	end
	return id
end

function RaidMenuHelper:InjectIntoAList(menu_comp, injection_point, buttons, list_name)
	local list = (list_name and menu_comp[list_name]) or menu_comp._list_menu or menu_comp.list_menu_options
	if list then
		if not list._injected_data_source then
			list._orig_data_source_callback = list._orig_data_source_callback or list._data_source_callback
			list._injected_to_data_source = list._injected_to_data_source or {}			
			list._data_source_callback = function()
				local t = list._orig_data_source_callback()
				for _, inject in pairs(list._injected_to_data_source) do
					if inject.buttons then
						for i, item in pairs(t) do
							if i == #t or (inject.point and tostring(item.text):lower() == tostring(inject.point):lower()) then
								for k = #inject.buttons, 1, -1 do
									table.insert(t, i + 1, inject.buttons[k])
								end
								break
							end
						end
					end
				end
				return t
			end
		end
		table.insert(list._injected_to_data_source, {buttons = buttons, point = injection_point})
		list:refresh_data()
	else
		BLT:Log(LogLevel.ERROR, "BLTMenuHelper", "Menu component given has no list, cannot inject into this menu.")
	end
end

---@deprecated @use MenuHelper:AddComponent instead
function RaidMenuHelper:CreateComponent(...)
	MenuHelper:AddComponent(...)
end

function RaidMenuHelper:LoadJson(path)
	local file = io.open(path, "r")
	if file then
		local success, data = pcall(function() return json.decode(file:read("*all")) end)
		file:close()
		if success then
			self:LoadMenu(data, path)
			return true
		end
		BLT:Log(LogLevel.ERROR, "BLTMenuHelper", "Failed parsing json file at path '%s': %s", path, data)
	else
		BLT:Log(LogLevel.ERROR, "BLTMenuHelper", "Failed reading json file at path '%s'.")
	end
	return false
end

function RaidMenuHelper:LoadXML(path)
	local file = io.open(path, "r")
	if file then
		local data = ScriptSerializer:from_custom_xml(file:read("*all"))
		file:close()
		self:ConvertXMLData(data)
		self:LoadMenu(data, path)
	else
		BLT:Log(LogLevel.ERROR, "BLTMenuHelper", "Failed reading XML file at path '%s'", path)
	end
	return false
end

function RaidMenuHelper:ConvertXMLData(data)
	if type(data) == "table" then
		for _, v in pairs(data) do
			if type(v) == "table" and v._meta then
				v.type = v._meta --convert _meta to type
				v._meta = nil
				self:ConvertXMLData(v)
			end
		end
	end
end

function RaidMenuHelper:LoadMenu(data, path, mod)
	if not data.name then
		BLT:Log(LogLevel.ERROR, "BLTMenuHelper", "Creation of menu at path '%s' has failed, no menu name given.", tostring(path))
		return
	end
	local clss
	local get_value
	local function load_menu()
		if data.class then
			data.class = loadstring("return "..tostring(data.class))()
			clss = data.class
		else
			clss = class(BLTMenu)
			rawset(_G, clss, data.global_name or data.name.."Menu")
		end
		if data.get_value and clss then
			if data.get_value:starts("callback") then
				get_value = loadstring("return "..tostring(data.get_value))()
			elseif clss[data.callback] then
				get_value = callback(clss, clss, data.get_value)
			elseif type(data.get_value) == "function" then
				get_value = data.get_value
			else
				BLT:Log(LogLevel.WARN, "BLTMenuHelper", "Get value function given in menu named '%s' doesn't exist.", tostring(data.name))
			end
		end
		RaidMenuHelper:CreateMenu({
			name = data.name,
			name_id = data.name_id,
			localize = data.localize,
			class = clss,
			inject_menu = data.inject_menu,
		})
		if clss then
			clss._mod = mod
			clss._items_data = {}
			for k, item in ipairs(data) do
				if type(item) == "table" and item.type then
					item.type = string.CamelCase(item.type) -- write the types how you want(multi_choice, MultiChoice)
					if item.type == "Menu" then
						item.inject_menu = item.inject_menu or data.name
						item.get_value = item.get_value or data.get_value
						item.localize = Utils:FirstNonNil(item.localize, data.localize)
						self:LoadMenu(item, path, mod)
					else
						if item.callback then
							if item.callback:begins("callback") then
								item.callback = loadstring("return "..tostring(item.callback))
							elseif clss[item.callback] then
								item.callback = callback(clss, clss, item.callback)
							else
								BLT:Log(LogLevel.ERROR, "BLTMenuHelper", "Callback given to item named '%s' in menu named '%s' doesn't exist.", tostring(item.name), tostring(data.name))
							end
						end
						table.insert(clss._items_data, item)
					end
				end
			end
			clss._get_value = get_value
		else
			BLT:Log(LogLevel.ERROR, "BLTMenuHelper", "Failed to create menu named '%s', invalid class given!", tostring(data.menu.name))
		end
	end
	if managers and managers.menu_component then
		load_menu()
	else
		Hooks:Add("MenuComponentManagerInitialize", tostring(data.name)..".MenuComponentManagerInitialize", load_menu)
	end
end

core:import("CoreMenuData")
core:import("CoreMenuLogic")
core:import("CoreMenuInput")
core:import("CoreMenuRenderer")

function RaidMenuHelper:RegisterMenu(menu)
	local m_menu = managers.menu
	if menu.name and m_menu._registered_menus[menu.name] then
		return
	end

	menu.data = CoreMenuData.Data:new()
	menu.data:_load_data(menu.config, menu.id or menu.name)
	menu.data:set_callback_handler(menu.callback_handler)

	menu.logic = CoreMenuLogic.Logic:new(menu.data)
	menu.logic:register_callback("menu_manager_menu_closed", callback(m_menu, m_menu, "_menu_closed", menu.name))
	menu.logic:register_callback("menu_manager_select_node", callback(m_menu, m_menu, "_node_selected", menu.name))

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
		m_menu._registered_menus[menu.name] = menu
	end
end