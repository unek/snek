local Buffer = require("buffer")
local Object = require("classic")
Snek = require("snek")

local net = require("net")

console = require("lib.console")
require("console_commands")

camera = require("camera")()

commands = {}
commands[net.commands.TICK] = function()
  for i, snek in pairs(sneks) do
    snek:tick()
  end
end
commands[net.commands.RESPAWN] = function(buf)
  local id = buf:readUInt16LE(0)

  me = id
  camera:followEntity(sneks[me])

  console.i("my id is %d", me)
end
commands[net.commands.ADD_SNEK] = function(buf)
  local snek = Snek.fromBuffer(buf)
  sneks[snek.id] = snek
end
commands[net.commands.REMOVE_SNEK] = function(buf)
  local id = buf:readUInt16LE(0)
  sneks[id] = nil
end
commands[net.commands.TURN] = function(buf)
  local id = buf:readUInt16LE(0)
  local side = buf:readUInt8(2)

  sneks[id]:turn(side)
end
commands[net.commands.RESIZE] = function(buf)
  local id = buf:readUInt16LE(0)
  local size = buf:readUInt16LE(2)

  sneks[id].maxlength = size
end
commands[net.commands.DIE] = function(buf)
  local id = buf:readUInt16LE(0)

  sneks[id]:die()
end
commands[net.commands.STOP] = function(buf)
  local id = buf:readUInt16LE(0)

  sneks[id]:stop()
end
commands[net.commands.CHAT] = function(buf)
  console.i("chat: %s", buf:toString())
end

me = nil
nickname = nil
sneks = {}

local bg_quad, bg
function love.load()
  io.stdout:setvbuf("no")

  -- console and console settings
  console.load(love.graphics.newFont("fonts/FiraMono-Regular.otf", 11))
  -- prompt
  console.ps = "$"
  -- font settings
  console.lineSpacing = 1
  -- colors
  console.colors.background = {0x1d, 0x1f, 0x21, 210}
  console.colors.editing    = {0x37, 0x3b, 0x41}
  console.colors.input      = {0x37, 0x3b, 0x41}
  console.colors.default    = {0xc5, 0xc8, 0xc6}

  console.colors["I"] = {0x81, 0xa2, 0xbe}
  console.colors["D"] = {0xb2, 0x94, 0xbb}
  console.colors["E"] = {0xcc, 0x66, 0x66}
  console.colors["P"] = console.colors.default

  bg_quad = love.graphics.newQuad(0, 0, 2 ^ 16, 2 ^ 16, 2, 2)

  local im = love.image.newImageData(2, 2)
  im:setPixel(0, 0, 46, 46, 46, 255)
  im:setPixel(1, 1, 46, 46, 46, 255)
  im:setPixel(0, 1, 40, 40, 40, 255)
  im:setPixel(1, 0, 40, 40, 40, 255)

  bg = love.graphics.newImage(im)
  bg:setWrap("repeat", "repeat")
  bg:setFilter("nearest", "nearest")
end

function love.update(dt)
  if client then client:update(dt) end

  camera:update(dt)

  console.update(dt)
  love.keyboard.setTextInput(console.visible)
end

function love.draw()
  camera:push()
  love.graphics.setColor(255, 255, 255)
  love.graphics.draw(bg, bg_quad, -2 ^ 16 * 20 / 2, -2 ^ 16 * 20 / 2, 0, 20, 20)

  if client then
    for i, snek in pairs(sneks) do
      snek:draw()
    end
  end
  camera:pop()

  console.draw()
end


function love.resize(w, h)
  console.resize(w, h)
end

function love.keypressed(key, scancode, is_repeat) 
  if console.keypressed(key) then return end

  if key == 'escape' then love.event.quit() end

  if client then
    if key == "space" or key == "return" then
      console.invokeCommand("respawn")
    end
    if key == "w" then
      console.invokeCommand("up")
    end
    if key == "a" then
      console.invokeCommand("left")
    end
    if key == "s" then
      console.invokeCommand("down")
    end
    if key == "d" then
      console.invokeCommand("right")
    end
  end
end

function love.mousepressed(x, y, button)
  if console.mousepressed(x, y, button) then return end
end

function love.textinput(t)
  if console.textinput(t) then return end
end

function love.threaderror(thread, errorstr)
  console.e("Thread error: %s", errorstr)
end
