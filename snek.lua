local Buffer = require("buffer")
local Object = require("classic")

local net = require("net")

local Snek = Object:extend()
function Snek:new(x, y, dir)
  self.direction = love.math.random(0, 3)
  self.next_direction = self.direction

  self.maxlength = 8

  self.dead = false
  self.stopped = false

  self.speed = 3 -- this is actually like 1 / speed
  self.last_move = 0

  self.color = {255, 0, 0}

  self.blocks = {
    {x = x or love.math.random(2, 28), y = y or love.math.random(2, 18)}
  }
end

function Snek.fromBuffer(buf)
  local self = Snek()
  -- read basic information
  self.direction = buf:readUInt8(0)
  self.next_direction = buf:readUInt8(1)
  self.maxlength = buf:readUInt16LE(2)
  self.id = buf:readUInt16LE(4)

  self.dead = buf:readUInt8(6) == 1
  self.stopped = buf:readUInt8(7) == 1

  self.speed = buf:readUInt8(8)
  self.last_move = buf:readUInt8(9)

  -- block data
  local nblocks = buf:readUInt16LE(10)
  self.blocks = {}
  for i = 0, nblocks - 1, 2 do
    local x = tonumber(buf:readInt16LE(12 + i * 2))
    local y = tonumber(buf:readInt16LE(12 + (i + 1) * 2))
    table.insert(self.blocks, {x = x, y = y})
  end

  -- looks info
  local r = buf:readUInt8(12 + #self.blocks * 4 )
  local g = buf:readUInt8(12 + #self.blocks * 4 + 1)
  local b = buf:readUInt8(12 + #self.blocks * 4 + 2)
  self.color = {r, g, b}

  return self
end

function Snek:toBuffer()
  local buf = Buffer.new(12 + (#self.blocks + 1) * 2 * 2 + 1)
  -- basic info
  buf:writeUInt8(self.direction, 0)
  buf:writeUInt8(self.next_direction, 1)
  buf:writeUInt16LE(self.maxlength, 2)
  buf:writeUInt16LE(self.id, 4)

  buf:writeUInt8(self.dead and 1 or 0, 6)
  buf:writeUInt8(self.stopped and 1 or 0, 7)

  buf:writeUInt8(self.speed, 8)
  buf:writeUInt8(self.last_move, 9)

  buf:writeUInt16LE(#self.blocks, 10)

  local i = 12
  for _, block in ipairs(self.blocks) do
    buf:writeInt16LE(block.x, i)
    i = i + 2
    buf:writeInt16LE(block.y, i)
    i = i + 2
  end
  buf:writeUInt8(self.color[1], i)
  buf:writeUInt8(self.color[2], i + 1)
  buf:writeUInt8(self.color[3], i + 2)

  return buf
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

  if #self.blocks >= self.maxlength then
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

    local buf = Buffer.new(4)
    buf:writeUInt16LE(self.id, 0)
    buf:writeUInt8(dir, 2)
    server:broadcast(net.commands.TURN, buf)

    self.next_direction = dir
  end
  if client then
    self.next_direction = dir
  end
end

function Snek:die()
  self.dead = true
  if server then
    local buf = Buffer.new(3)
    buf:writeUInt16LE(self.id, 0)

    server:broadcast(net.commands.DIE, buf)
  end

  if client then
    local x, y = self:getScreenPosition()
    camera:shakeOn(x, y, 0.5, 20, 800)
  end
end

function Snek:stop()
  self.stopped = not self.stopped
  if server then
    local buf = Buffer.new(3)
    buf:writeUInt16LE(self.id, 0)

    server:broadcast(net.commands.STOP, buf)
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
