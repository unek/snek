local Object = require("classic")

local net = require("net")

local Snek = Object:extend()
function Snek:new(x, y, dir)
  self.direction = love.math.random(0, 3)
  self.next_direction = self.direction

  self.max_length = 8

  self.dead = false
  self.stopped = false

  self.speed = 3 -- this is actually like 1 / speed
  self.last_move = 0

  self.color = {255, 0, 0}

  self.blocks = {
    {x = x or love.math.random(2, 28), y = y or love.math.random(2, 18)}
  }
end

function Snek.fromMessage(message)
  local self = Snek()
  self.id = message.id
  self.name = message.name

  self.direction = message.direction
  self.next_direction = message.next_direction
  self.max_length = message.max_length

  self.dead = message.dead
  self.stopped = message.stopped

  self.speed = message.speed
  self.last_move = message.last_move

  self.blocks = message.blocks

  --self.color = {message.color.r, message.color.g, message.color.b}

  return self
end

local messagesSchema = require('schemas.messages_capnp')
function Snek:toMessage()
  return messagesSchema.Snek.serialize({
    id = self.id,
    name = self.name,

    direction = self.direction,
    next_direction = self.next_direction,
    max_length = self.max_length,

    dead = self.dead,
    stopped = self.stopped,

    speed = self.speed,
    last_move = self.last_move,

    blocks = self.blocks,

    color = {r = self.color[1], g = self.color[2], b = self.color[3]}
  })
end

function Snek:tick()
  if self.dead then return end

  self.last_move = self.last_move - 1
  if self.last_move <= 0 then
    self.last_move = self.speed
  else
    return
  end

  if (self.next_direction + 2) % 4 ~= self.direction then
    self.direction = self.next_direction
  end

  local x, y = self.blocks[#self.blocks].x, self.blocks[#self.blocks].y
  local orig_x, orig_y = x, y
  if self.direction == 0 then
    y = y - 1
  end
  if self.direction == 1 then
    x = x + 1
  end
  if self.direction == 2 then
    y = y + 1
  end
  if self.direction == 3 then
    x = x - 1
  end

  if #self.blocks >= self.max_length then
    table.remove(self.blocks, 1)
  end

  -- collisions
  if server then
    if game.collide(self, x, y) then return end
  end

  local block = {x = x, y = y}

  table.insert(self.blocks, block)
end

function Snek:getColor()
  local r, g, b = unpack(self.color)
  if self.dead then
    r, g, b = 255, 255, 255
  end

  return r, g, b
end

function Snek:draw()
  for i, block in ipairs(self.blocks) do
    local alpha = (155 + (i / #self.blocks) * 100)
    if self.dead then
      alpha = (55 + (i / #self.blocks) * 100)
    end

    local r, g, b = self:getColor()
    love.graphics.setColor(r, g, b, alpha)
    love.graphics.rectangle("fill", block.x * 20, block.y * 20, 20, 20)
  end
end

function Snek:turn(dir)
  if server then
    if self.dead then return end
    if not self.stopped and self.next_direction ~= self.direction then return end 
    if not self.stopped and (dir + 2) % 4 == self.direction then return end

    local data = messagesSchema.Message.Turn.serialize({
      id = self.id,
      direction = dir
    })

    server:broadcast("TURN", data)

    self.next_direction = dir
  end
  if client then
    self.next_direction = dir
  end
end

function Snek:die()
  self.dead = true
  if server then
    local data = messagesSchema.Message.Die.serialize({
      id = self.id
    })

    server:broadcast("DIE", data)
  end

  if client then
    local x, y = self:getScreenPosition()
    camera:shakeOn(x, y, 0.5, 20, 800)
  end
end

function Snek:stop()
  self.stopped = not self.stopped
  if server then
    local data = messagesSchema.Message.Stop.serialize({
      id = self.id
    })

    server:broadcast("STOP", data)
  end
end

function Snek:canRespawn()
  return true
end

function Snek:respawn()
  if not self.dead then return end
  game.removeSnek(self.id)
  game.spawnSnek(self.client)
end

function Snek:getScreenPosition()
  local blocks = self.blocks[#self.blocks]
  return (blocks.x + 0.5) * 20, (blocks.y + 0.5) * 20
end

return Snek
