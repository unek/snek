local args = {...}

local Buffer = require("buffer")
local net = require("net")

local Snek = require("snek")

local love = love or {}
love.timer = love.timer or require("love.timer")
love.math  = love.math  or require("love.math")
love.math.setRandomSeed(os.time() * 2.3)

local commands = {}
commands[net.commands.HELLO] = function(client, buf)
  if client.nickname then
    client:misbehave()
    return
  end

  local r = buf:readUInt8(0)
  local g = buf:readUInt8(1)
  local b = buf:readUInt8(2)

  local nickname = buf:toString("ascii", 3)

  client.nickname = nickname
  client.color = {r, g, b}

  -- send him all the sneks
  for i, snek in pairs(game.sneks) do
    client:send(net.commands.ADD_SNEK, snek:toBuffer())
  end
end
commands[net.commands.RESPAWN] = function(client)
  if not client.nickname then
    client:misbehave()
    return
  end
  
  if client.snek then
    if client.snek:canRespawn() then
      client.snek:respawn()
    end
  else
    if game.canRespawn(client) then
      game.spawnSnek(client)
    end
  end
end
commands[net.commands.TURN] = function(client, buf)
  local side = buf:readUInt8(0)

  if not client.snek then
    client:misbehave()
    return
  end

  client.snek:turn(side)
end
commands[net.commands.CHAT] = function(client, buf)
  if not client.nickname then
    client:misbehave()
    return
  end

  server:broadcast(net.commands.CHAT, Buffer.new(string.format("%s: %s", client.nickname, buf:toString())))
end

game = {}
game.sneks = {}
game.step = 1 / 48

function game.canRespawn(client)
  return true
end

local sneks = 0
function game.removeSnek(id)
  local buf = Buffer.new(3)
  buf:writeUInt16LE(id, 0)

  game.sneks[id].client.snek = nil
  game.sneks[id] = nil

  server:broadcast(net.commands.REMOVE_SNEK, buf)
end

function game.spawnSnek(client)
  local snek = Snek()
  client.snek = snek
  snek.client = client

  sneks = sneks + 1
  snek.id = sneks

  game.sneks[snek.id] = snek

  server:broadcast(net.commands.ADD_SNEK, snek:toBuffer())

  local buf = Buffer.new(3)
  buf:writeUInt16LE(snek.id, 0)
  client:send(net.commands.RESPAWN, buf)

  return snek
end

function game.tick()
  for i, snek in pairs(game.sneks) do
    snek:tick()
  end

  server:broadcast(net.commands.TICK)
end

function game.collide(self, x, y)
  for i, snek in pairs(game.sneks) do
    for _, block in pairs(snek.blocks) do
      if block.x == x and block.y == y then
        self:die()

        return true
      end
    end
  end
end

local last_update = 0
function game.update(dt)
  while last_update > game.step do
    game.tick()

    last_update = last_update - game.step
  end
  last_update = last_update + dt
end

server = net.Server("0.0.0.0", args[1])
server:on("connect", function(self, client)

end)
server:on("receive", function(self, client, command, buf)
  commands[command](client, buf)
end)

local dt = 0
while true do
  local time = love.timer.getTime()

  game.update(dt)
  server:update(dt)

  love.timer.sleep(game.step / 10)
  dt = love.timer.getTime() - time
end
