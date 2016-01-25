local net = require("net")

-- but i'm not a rapper
local function wrapper(f)
  return function(...)
    local status, err = pcall(f, ...)
    if not status then
      err = err:gsub("^[^:]+:[^:]+:%s*", "")
      console.es(err)
      return
    end
  end
end

-- echo
console.defineCommand("echo", "prints message", wrapper(function(...)
  local t = table.concat({...}, " ")
  t = t:gsub("\\n", "\n")

  print(t)
end))

console.defineCommand("nick", "sets your nickname", wrapper(function(nick)
  nickname = nick

  console.i("nick set to %s", nick)
end))

console.defineCommand("host", "creates a server", wrapper(function(port, name, max_players, password)
  -- local max_players = tonumber(max_players)
  -- local private = not password or password == ""
  -- assert(max_players, "argument #2 must be a number")
  -- assert(max_players <= 32, "argument #2 must be lower or equal than 32")
  -- assert(max_players >= 2, "argument #2 must be greater or equal than 32")

  local port = tonumber(port) or 14970
  assert(port, "port must be a number")
  assert(port > 1024 and port < 65536, "port must be a number 1024-65536")
  assert(not server_thread, "server is already running")

  server_thread = love.thread.newThread("serverthread.lua"):start(port)

  console.i("server running at port %d", port)
end))

console.defineCommand("connect", "connects to a server", function(ip, port)
  assert(not client, "already connected, disconnect first")
  --assert(nickname, "nickname not set, use nick command")
  nickname = "lel"

  client = net.Client(ip or "localhost", port or 14970)

  local buf = Buffer.new(3 + #nickname)
  buf:writeUInt8(255, 0) -- r 
  buf:writeUInt8(0, 1) -- g
  buf:writeUInt8(0, 2) -- b

  --buf:write(nickname, 3) -- nickname

  client:send(net.commands.HELLO, buf)

  client:on("receive", function(self, command, buf)
    commands[command](buf)
  end)
  client:once("connect", function(self)
    console.i("connected")
  end)
  client:once("connect_error", function(self)
    client = nil
  end)

  console.i("connecting")
end)



local function round(num, idp)
  local mult = 10 ^ (idp or 0)
  return math.floor(num * mult + 0.5) / mult
end

-- stolen from https://github.com/james2doyle/lit-pretty-bytes/blob/master/pretty-bytes.lua
local function format_bytes(num, space)
  local units = {'B', 'kB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'}

  space = space and ' ' or ''

  if num < 1 then
    return num .. ' B'
  end

  local exponent = math.min(math.floor(math.log(num) / math.log(1000)), #units)
  local num = round((num / math.pow(1000, exponent)), 2) * 1
  -- add 1 to compensate for 1 indexed arrays
  local unit = units[exponent + 1]

  return num .. space .. unit
end

console.defineCommand("net_info", "displays network information", function()
  -- local ping = client.server:round_trip_time()
  -- local bw_up = format_bytes(client.host:total_sent_data(), true)
  -- local bw_down = format_bytes(client.host:total_received_data(), true)
  -- console.i("ping: %dms\nbandwidth up: %s down: %s", ping, bw_up, bw_down)
end)

console.defineCommand("say", "sends a chat message", function(...)
  local msg = table.concat({...}, " ")

  client:send(net.commands.CHAT, Buffer.new(msg))
end)

-- gameplay commands
console.defineCommand("respawn", "respawns the snek", wrapper(function()
  assert(client, "not connected")

  client:send(net.commands.RESPAWN)
end))
console.defineCommand("up", "moves snek up", wrapper(function()
  assert(client, "not connected")

  local buf = Buffer.new(2)
  buf:writeUInt8(0, 0)

  client:send(net.commands.TURN, buf)
end))
console.defineCommand("down", "moves snek down", wrapper(function()
  assert(client, "not connected")

  local buf = Buffer.new(2)
  buf:writeUInt8(2, 0)

  client:send(net.commands.TURN, buf)
end))
console.defineCommand("left", "moves snek left", wrapper(function()
  assert(client, "not connected")

  local buf = Buffer.new(2)
  buf:writeUInt8(3, 0)

  client:send(net.commands.TURN, buf)
end))
console.defineCommand("right", "moves snek right", wrapper(function()
  assert(client, "not connected")

  local buf = Buffer.new(2)
  buf:writeUInt8(1, 0)

  client:send(net.commands.TURN, buf)
end))