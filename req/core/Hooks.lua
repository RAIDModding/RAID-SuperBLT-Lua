_G.Hooks = Hooks or {}
Hooks._registered_hooks = Hooks._registered_hooks or {}
Hooks._function_hooks = Hooks._function_hooks or {}

--[[
	Hooks:Register(key)
		Registers a hook so that functions can be added to it, and later called 
	key, Unique identifier for the hook, so that hooked functions can be added to it
]]
function Hooks:RegisterHook(key)
	self._registered_hooks[key] = self._registered_hooks[key] or {}
end

--[[
	Hooks:Register(key)
		Functionaly the same as Hooks:RegisterHook
]]
function Hooks:Register(key)
	self:RegisterHook(key)
end

--[[
	Hooks:AddHook(key, id, func)
		Adds a function call to a hook, so that it will be called when the hook is
	key, 	The unique identifier of the hook to be called on
	id, 	A unique identifier for this specific function call
	func, 	The function to call with the hook 
]]
function Hooks:AddHook(key, id, func)
	self._registered_hooks[key] = self._registered_hooks[key] or {}
	-- Update existing hook
	for k, v in pairs(self._registered_hooks[key]) do
		if v.id == id then
			v.func = func
			return
		end
	end
	-- Add new hook, if id doesn't exist
	local tbl = {
		id = id,
		func = func
	}
	table.insert(self._registered_hooks[key], tbl)
end

--[[
	Hooks:Add(key, id, func)
		Functionaly the same as Hooks:AddHook
]]
function Hooks:Add(key, id, func)
	self:AddHook(key, id, func)
end

--[[
	Hooks:UnregisterHook(key)
		Removes a hook, so that it will not call any functions
	key, The unique identifier of the hook to unregister
]]
function Hooks:UnregisterHook(key)
	self._registered_hooks[key] = nil
end

--[[
	Hooks:Unregister(key)
		Functionaly the same as Hooks:UnregisterHook
]]
function Hooks:Unregister(key)
	self:UnregisterHook(key)
end

--[[
	Hooks:Remove(id)
		Removes a hooked function call with the specified id to prevent it from being called
	id, Removes the function call and prevents it from being called
]]
function Hooks:Remove(id)
	for k, v in pairs(self._registered_hooks) do
		if type(v) == "table" then
			for x, y in pairs(v) do
				if y.id == id then
					y = nil
				end
			end
		end
	end
end

--[[
	Hooks:Call(key, ...)
			Calls a specified hook, and all of its hooked functions
	key,	The unique identifier of the hook to call its hooked functions
	args,	The arguments to pass to the hooked functions 
]]
function Hooks:Call(key, ...)
	if not self._registered_hooks[key] then
		return
	end

	-- print("[Hooks] Call: ", key, unpack({...}))

	for k, v in pairs(self._registered_hooks[key]) do
		if v then
			if type(v.func) == "function" then
				v.func(...)
			end
		end
	end
end

--[[
	Hooks:ReturnCall(key, ...)
		Calls a specified hook, and returns the first non-nil value returned by a hooked function
	key, 		The unique identifier of the hook to call its hooked functions
	args, 		The arguments to pass to the hooked functions
	returns, 	The first non-nil value returned by a hooked function
]]
function Hooks:ReturnCall(key, ...)
	if not self._registered_hooks[key] then
		return
	end

	for k, v in pairs(self._registered_hooks[key]) do
		if v then
			if type(v.func) == "function" then
				local r = {v.func(...)}
				if next(r) == 1 then
					return unpack(r)
				end
			end
		end
	end
end

--[[
	Hooks:PreHook(object, func, id, pre_call)
		Automatically hooks a function to be called before the specified function on a specified object
	object, 	The object for the hooked function to be called on
	func, 		The name of the function (as a string) on the object for the hooked call to be ran before
	id, 		The unique identifier for this prehook
	pre_call, 	The function to be called before the func on object
]]
function Hooks:PreHook(object, func, id, pre_call)
	if not object or type(pre_call) ~= "function" then
		self:_PrePostHookError(func, id)
		return
	end

	if not self:_ChkCreateTableStructure(object, func) then
		for k, v in pairs(self._function_hooks[object][func].overrides.pre) do
			if v.id == id then
				return
			end
		end
	end

	local func_tbl = {
		id = id,
		func = pre_call
	}
	table.insert(self._function_hooks[object][func].overrides.pre, func_tbl)
end

--[[
	Hooks:RemovePreHook(id)
		Removes the prehook with id, and prevents it from being run
	id, The unique identifier of the prehook to remove
]]
function Hooks:RemovePreHook(id)
	for object_i, object in pairs(self._function_hooks) do
		for func_i, func in pairs(object) do
			for override_i, override in ipairs(func.overrides.pre) do
				if override.id == id then
					table.remove(func.overrides.pre, override_i)
				end
			end
		end
	end
end

--[[
	Hooks:PostHook(object, func, id, post_call)
		Automatically hooks a function to be called after the specified function on a specified object
	object, 	The object for the hooked function to be called on
	func, 		The name of the function (as a string) on the object for the hooked call to be ran after
	id, 		The unique identifier for this posthook
	post_call, 	The function to be called after the func on object
]]
function Hooks:PostHook(object, func, id, post_call)
	if not object or type(post_call) ~= "function" then
		self:_PrePostHookError(func, id)
		return
	end

	if not self:_ChkCreateTableStructure(object, func) then
		for k, v in pairs(self._function_hooks[object][func].overrides.post) do
			if v.id == id then
				return
			end
		end
	end

	local func_tbl = {
		id = id,
		func = post_call
	}
	table.insert(self._function_hooks[object][func].overrides.post, func_tbl)
end

--[[
	Hooks:RemovePostHook(id)
		Removes the posthook with id, and prevents it from being run
	id, The unique identifier of the posthook to remove
]]
function Hooks:RemovePostHook(id)
	for object_i, object in pairs(self._function_hooks) do
		for func_i, func in pairs(object) do
			for override_i, override in ipairs(func.overrides.post) do
				if override.id == id then
					table.remove(func.overrides.post, override_i)
				end
			end
		end
	end
end

--[[
	Hooks:OverrideFunction(object, func)
		Overrides a function completely while keeping existing hooks to it alive
	object, 	The object of the function to override
	func, 		The name of the function (as a string) on the object to override
	override,	The new function
]]
function Hooks:OverrideFunction(object, func, override)
	if not self._function_hooks[object] or not self._function_hooks[object][func] then
		object[func] = override
	else
		self._function_hooks[object][func].original = override
	end
end

--[[
	Hooks:GetFunction(object, func)
		Returns the current original function of this object
	object, 	The object of the function
	func, 		The name of the function (as a string) on the object
]]
function Hooks:GetFunction(object, func)
	if not self._function_hooks[object] or not self._function_hooks[object][func] then
		return object[func]
	else
		return self._function_hooks[object][func].original
	end
end

function Hooks:_PrePostHookError(func, id)
	BLT:Log(LogLevel.ERROR, string.format("[Hooks] Could not hook function '%s' (%s)", tostring(func), tostring(id)))
end

-- Helper to create the hooks table structure and function override
function Hooks:_ChkCreateTableStructure(object, func)
	if self._function_hooks[object] == nil then
		self._function_hooks[object] = {}
	end

	if self._function_hooks[object][func] then
		return
	end

	self._function_hooks[object][func] = {
		original = object[func],
		overrides = {
			pre = {},
			post = {}
		}
	}

	object[func] = function(...)
		local hooked_func = self._function_hooks[object][func]
		local r, _r = {}

		for k, v in ipairs(hooked_func.overrides.pre) do
			_r = {v.func(...)}
			if next(_r) then
				r = _r
			end
		end

		_r = {hooked_func.original(...)}
		if next(_r) then
			r = _r
		end

		for k, v in ipairs(hooked_func.overrides.post) do
			_r = {v.func(...)}
			if next(_r) then
				r = _r
			end
		end

		return unpack(r)
	end

	return true
end
