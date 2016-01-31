local args = {...}

local net = require("net")

local Snek = require("snek")

local love = love or {}
love.timer = love.timer or require("love.timer")
love.math  = love.math  or require("love.math")
love.math.setRandomSeed(os.time() * 2.3)

local messagesSchema = require('schemas.messages_capnp')

local messages = {}
messages.HELLO = function(client, data)
  if client.nickname then
    client:misbehave()
    return
  end

  local message = messagesSchema.Message.Hello.parse(data)
  client.nickname = message.nickname
  client.color = {255, 0, 0}

  -- send him all the sneks
  for i, snek in pairs(game.sneks) do
    client:send("ADD_SNEK", snek:toMessage())
  end
end
messages.RESPAWN = function(client)
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
messages.TURN = function(client, data)
  local message = messagesSchema.Message.Turn.parse(data)

  if not client.snek then
    client:misbehave()
    return
  end

  client.snek:turn(message.direction)
end
messages.CHAT = function(client, data)
  if not client.nickname then
    client:misbehave()
    return
  end

  -- todo
end

game = {}
game.sneks = {}
game.step = 1 / 48

function game.canRespawn(client)
  return true
end

local sneks = 0
function game.removeSnek(id)
  game.sneks[id].client.snek = nil
  game.sneks[id] = nil

  -- todo: make a schema for removesnek, not sure why it's not there
  local data = messagesSchema.Message.Respawn.serialize({
    id = id
  })
  server:broadcast("REMOVE_SNEK", data)
end

function game.spawnSnek(client)
  local snek = Snek()
  client.snek = snek
  snek.client = client

  sneks = sneks + 1
  snek.id = sneks

  game.sneks[snek.id] = snek

  server:broadcast("ADD_SNEK", snek:toMessage())

  local data = messagesSchema.Message.Respawn.serialize({
    id = snek.id
  })
  client:send("RESPAWN", data)

  return snek
end

function game.tick()
  for i, snek in pairs(game.sneks) do
    snek:tick()
  end

  server:broadcast("TICK")
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
server:on("receive", function(self, client, command, data)
  messages[command](client, data)
end)

local dt = 0
while true do
  local time = love.timer.getTime()

  game.update(dt)
  server:update(dt)

  love.timer.sleep(game.step / 10)
  dt = love.timer.getTime() - time
end
