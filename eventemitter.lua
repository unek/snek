local Object = require("classic")

local EventEmitter = Object:extend()

function EventEmitter:new()
  self._listeners = {}
end

function EventEmitter:addListener(event, listener)
  if not self._listeners[event] then
    self._listeners[event] = {}
  end

  table.insert(self._listeners[event], listener)

  return self
end
EventEmitter.on = EventEmitter.addListener

function EventEmitter:removeListener(event, target_listener)
  local listeners = self._listeners[event]
  if not listeners then return self end

  for i, listener in pairs(listeners) do
    if listener == target_listener then
      table.remove(listeners, i)
    end
  end

  return self
end

function EventEmitter:once(event, listener)
  local func

  func = function(...)
    listener(...)
    self:removeListener(event, func)
  end

  return self:on(event, func)
end

function EventEmitter:emit(event, ...)
  local listeners = self._listeners[event]
  if not listeners then return self end

  for _, listener in ipairs(listeners) do
    listener(self, ...)
  end

  return self
end

function EventEmitter:emitModdable(event, ...)
  local listeners = self._listeners[event]
  if not listeners then return self end

  local values = {...}
  for _, listener in ipairs(listeners) do
    local res = {listener(self, unpack(values))}
    if res[1] ~= nil then
      values = res
    end
  end

  return unpack(values)
end

return EventEmitter
