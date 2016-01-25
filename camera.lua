local Object = require("classic")
local Camera = Object:extend()

function Camera:new()
  self.pos    = {}
  self.pos.x  = 0
  self.pos.y  = 0

  self.follow   = {}
  self.follow.x = 0
  self.follow.y = 0

  self.entity = nil

  self.shakes = {}

  self.smooth = true
end

function Camera:followEntity(ent)
  self.entity = ent

  return self
end

function Camera:setPosition(x, y)
  self.follow.x = x
  self.follow.y = y

  return self
end

function Camera:shake(time, power, speed)
  local angle = love.math.random(0, math.pi)
  local shake = {
    time     = time,
    max_time = time,
    x        = math.cos(angle),
    y        = math.sin(angle),
    power    = power,
    speed    = speed or 40
  }

  table.insert(self.shakes, shake)
end

function Camera:shakeOn(x, y, time, power, speed)
  local dist = ((self.pos.x - x) ^ 2 + (self.pos.y - y) ^ 2) ^ 0.5
  if dist > 600 then return end

  local power = power / math.sqrt(dist)
  return self:shake(time, power, speed)
end

function Camera:update(dt)
  local x, y = self.follow.x, self.follow.y

  if self.entity then
    x, y = self.entity:getScreenPosition()
  end

  if self.smooth then
    local dx, dy = x - self.pos.x, y - self.pos.y
    self.pos.x = self.pos.x + dx * 4 * dt
    self.pos.y = self.pos.y + dy * 4 * dt
  else
    self.pos.x = x
    self.pos.y = y
  end

  --love.audio.setPosition(self.pos.x / blocksize * soundscale, self.pos.y / blocksize * soundscale, 0)

  for i = #self.shakes, 1, -1 do
    local shake = self.shakes[i]
    if shake.time > 0 then
      shake.time = shake.time - dt
    else
      table.remove(self.shakes, i)
    end
  end
end

function Camera:push()
  local dx, dy = 0, 0
  for _, shake in pairs(self.shakes) do
    local ddx = shake.x * math.sqrt(shake.time / shake.max_time) * math.sin(shake.time * shake.speed * math.sqrt(shake.time / shake.max_time)) * shake.power
    local ddy = shake.y * math.sqrt(shake.time / shake.max_time) * math.sin(shake.time * shake.speed * math.sqrt(shake.time / shake.max_time)) * shake.power
    if ddx == ddx and ddy == ddy then -- sometimes it's nan for some reason, so there's that
      dx = dx + ddx
      dy = dy + ddy
    end
  end

  local w, h = love.graphics.getDimensions()
  love.graphics.push()
  love.graphics.translate(math.floor(-self.pos.x + w / 2 + dx), math.floor(-self.pos.y + h / 2 + dy))
end

function Camera:pop()
  love.graphics.pop()
end

return Camera
