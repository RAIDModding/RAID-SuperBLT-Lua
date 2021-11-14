DelayedCalls = DelayedCalls or {}
DelayedCalls._calls = DelayedCalls._calls or {}
DelayedCalls._remove_queue = DelayedCalls._remove_queue or {}

Hooks:Add("MenuUpdate", "MenuUpdate_Queue", function(t, dt)
	DelayedCalls:Update(t, dt)
end)

Hooks:Add("GameSetupUpdate", "GameSetupUpdate_Queue", function(t, dt)
	DelayedCalls:Update(t, dt)
end)

function DelayedCalls:Update(time, deltaTime)
	local calls = self._calls
	self._calls = {}

	for k, v in pairs(calls) do
		v.currentTime = v.currentTime + deltaTime
		if self._remove_queue[k] then
			-- Remove call if it has been queued for removal
			self._remove_queue[k] = nil
		elseif v.currentTime > v.timeToWait then
			if v.functionCall then
				v.functionCall()
			end
		else
			-- If a call with that id already exists, it has been added during call iteration
			-- If that is the case, prefer the existing one (new call overrides old)
			self._calls[k] = self._calls[k] or v
		end
	end
end

--[[
	DelayedCalls:Add(id, time, func)
		Adds a function to be automatically called after a set delay
	id, 	Unique identifier for this delayed call
	time, 	Time in seconds to call the specified function after
	func, 	Function call to call after the time runs out
]]
function DelayedCalls:Add(id, time, func)
	local queuedFunc = {
		functionCall = func,
		timeToWait = time,
		currentTime = 0
	}
	self._calls[id] = queuedFunc
end

--[[
	DelayedCalls:Remove(id)
		Removes a scheduled call before it can be automatically called
	id, Unique identifier for the delayed call remove
]]
function DelayedCalls:Remove(id)
	self._remove_queue[id] = true
end
