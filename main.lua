--love.window.maximize()

lume = require "lume"
Object = require "classic"

Gamestate = require "gamestate"
local Animations = require "animations"

love.graphics.setDefaultFilter("nearest", "nearest", 1)
function love.graphics.printUnscaled(camera, ...)
	local args = {...}
	love.graphics.push()
	local sx, sy = camera:getScale()
	local px, py = camera:getPosition()
	love.graphics.translate(-args[2]-px, -args[3]-py)
	love.graphics.scale(1/sx, 1/sy)
	love.graphics.translate((args[2]*sx+px*sx), (args[3]*sy+py*sy))
	args[2] = args[2]*sx
	args[3] = args[3]*sy
	love.graphics.print(unpack(args))
	love.graphics.pop()
end

function love.graphics.arrow(x1,y1,x2,y2,angle,len)
	local oldangle = lume.angle(x1,y1,x2,y2)
	love.graphics.line(x1,y1,x2,y2)
	local x,y = lume.vector(oldangle+angle, len)
	love.graphics.line(x2,y2,x2-x,y2-y)
	local x,y = lume.vector(oldangle-angle, len)
	love.graphics.line(x2,y2,x2-x,y2-y)
end

local gamestate_set = false
function love.load()
	Gamestate:register(Animations, "Animations")
end

function love.update(dt)
	if not gamestate_set then
		Gamestate:set(Animations)
		gamestate_set = true
	end

	Gamestate:update(dt)
end

function love.draw()
	Gamestate:draw()
end

function love.textedited(text, start, length)
	Gamestate:textedited(text, start, length)
end

function love.textinput(t)
	Gamestate:textinput(t)
end

function love.keypressed(key)
	Gamestate:keypressed(key)
end

function love.keyreleased(key)
	Gamestate:keyreleased(key)
end

function love.mousepressed(x,y,button)
	Gamestate:mousepressed(x,y,button)
end

function love.mousereleased(x,y,button)
	Gamestate:mousereleased(x,y,button)
end

function love.wheelmoved(x,y)
	Gamestate:wheelmoved(x,y)
end

function love.resize(w,h)
	Gamestate:resize(w,h)
end
