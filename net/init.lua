local net = {}

net.commands = {
  TICK     = 0x01,
  HELLO    = 0x10,
  CHAT     = 0x11,

  ADD_SNEK = 0x20,
  REMOVE_SNEK = 0x21,
  RESPAWN  = 0x22,
  TURN     = 0x23,
  RESIZE   = 0x24,
  DIE      = 0x25,
  STOP     = 0x26
}

local Object = require("classic")
local EventEmitter = require("eventemitter")

local lube = require("lib.lube")

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

    local command = string.byte(data:sub(0, 1))
    local buf     = Buffer.new(data:sub(2))

    self:emit("receive", client, command, buf)
  end
end

function net.Server:update(dt)
  self.server:update(dt)
end

function net.Server:broadcast(command, buf)
  local buf = buf and buf:toString() or ""
  self.server:send(string.char(command) .. buf)
end

-- client on a local server
net.Player = Object:extend()
function net.Player:new(server, clientid)
  self.server = server
  self.clientid = clientid
end

function net.Player:disconnect(weknow)

end

function net.Player:send(command, buf)
  local buf = buf and buf:toString() or ""
  self.server.server:send(string.char(command) .. buf, self.clientid)
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
    local command = string.byte(data:sub(0, 1))
    local buf     = Buffer.new(data:sub(2))

    self:emit("receive", command, buf)
  end
end

function net.Client:update(dt)
  self.client:update(dt)
end

function net.Client:send(command, buf)
  local buf = buf and buf:toString() or ""
  self.client:send(string.char(command) .. buf)
end


return net
