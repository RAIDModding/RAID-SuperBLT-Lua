core:module("CoreMenuData")

Hooks:Register("CoreMenuData.LoadDataMenu")

function Data:_load_data(root, menu_id)
	-- Find the child menu with id = menu_id
	local menu = nil
	for _, c in ipairs(root) do
		if ((c._meta == "menu") and c.id and (c.id == menu_id)) then
			menu = c
			break
		end
	end

	if not menu then
		Application:error("Data:load_data(): No menu with id '" .. menu_id)
		return
	end

	-- Call a hook here to let us mutate the menu data before it is parsed
	Hooks:Call("CoreMenuData.LoadDataMenu", menu_id, menu)

	-- Parse the nodes
	for _, c in ipairs(menu) do
		local type = c._meta
		if type == "node" then
			self:_create_node(menu_id, c)
		elseif type == "default_node" then
			self._default_node_name = c.name
		end
	end
end

function Data:load_data(file_path, menu_id)
	if PackageManager:has(Idstring("menu"), file_path:id()) then
		self:_load_data(PackageManager:script_data(Idstring("menu"), file_path:id()), menu_id)
	end
end

function Data:_create_node(menu_id, c)
	local node_class = CoreMenuNode.MenuNode

	local type = c.type
	if type then
		node_class = CoreSerialize.string_to_classtable(type)
	end

	local name = c.name
	if name then
		self._nodes[name] = node_class:new(c)
	end
end
