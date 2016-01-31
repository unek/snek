local net = {}  

local Object = require("classic")
local EventEmitter = require("eventemitter")

local lube = require("lib.lube")

local messagesSchema = require("schemas.messages_capnp")

-- local instance of a server
net.Server = EventEmitter:extend()
function net.Server:new(ip, port)
  EventEmitter.new(self)

  self.clients = {}
  self.bind_host = ip .. ":" .. port

  self.server = lube.enetServer()
  self.server:listen(port)
  self.server.handshake = "handsnake"

  self.server.callbacks.connect = function(clientid)
    self.clients[clientid] = net.Player(self, clientid)

    self:emit("connect", self.clients[clientid])
  end

  self.server.callbacks.disconnect = function(clientid)
    self.clients[clientid]:disconnect(true)

    self:emit("disconnect", self.clients[clientid])
  end

  self.server.callbacks.recv = function(data, clientid)
    local client = self.clients[clientid]

    -- todo: pcall
    local message = messagesSchema.Message.parse(data)

    -- decompress the data if needed
    local data = message.message
    if message.compressed then
      data = love.math.decompress(data)
    end

    self:emit("receive", client, message.type, data)
  end
end

function net.Server:update(dt)
  self.server:update(dt)
end

function net.Server:broadcast(type, data, compressed)
  local message = messagesSchema.Message.serialize({
    type = type,
    message = data,
    compressed = compressed
  })

  self.server:send(message)
end

-- client on a local server
net.Player = Object:extend()
function net.Player:new(server, clientid)
  self.server = server
  self.clientid = clientid
end

function net.Player:disconnect()

end

function net.Player:send(type, data, compressed)
  local message = messagesSchema.Message.serialize({
    type = type,
    message = data,
    compressed = compressed
  })

  self.server.server:send(message)
end

function net.Player:misbehave(val)

end

-- remote server
net.Client = EventEmitter:extend()
function net.Client:new(ip, port)
  EventEmitter.new(self)

  self.client = lube.enetClient()
  self.client.handshake = "handsnake"
  
  local success, error = self.client:connect(ip, port)
  self.connected = success

  self.client.callbacks.connect = function()
    self:emit("connect")
  end

  self.client.callbacks.disconnect = function()
    self:emit("disconnect")
  end

  self.client.callbacks.recv = function(data)
    -- todo: pcall
    local message = messagesSchema.Message.parse(data)

    -- decompress the data if needed
    local data = message.message
    if message.compressed then
      data = love.math.decompress(data)
    end

    self:emit("receive", message.type, data)
  end
end

function net.Client:update(dt)
  self.client:update(dt)
end

function net.Client:send(type, data, compressed)
  local message = messagesSchema.Message.serialize({
    type = type,
    message = data,
    compressed = compressed
  })

  self.client:send(message)
end


return net
