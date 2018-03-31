local Gamera = require "gamera"

local Mousefield = Object:extend()

function Mousefield:new(x,y,w,h,options)
	self.camera = Gamera.new(0,0,w,h)
	self.camera:setWindow(x,y,w,h)

	self.grabbed = false
	self.grabPosition = {x=0,y=0}

	self.options = options or {}
	self.options.onlyScaleX = self.options.onlyScaleX or false
	self.options.maxScale = self.options.maxScale or 100
	self.options.minScale = self.options.minScale or 0.1

	self.clicktime = 0
end

function Mousefield:setWorld(...)
	self.camera:setWorld(...)
end

function Mousefield:getWorld()
	return self.camera:getWorld()
end

function Mousefield:setWindow(...)
	self.camera:setWindow(...)
end

function Mousefield:getWindow()
	return self.camera:getWindow()
end

function Mousefield:setScale(...)
	self.camera:setScale(...)
end

function Mousefield:getScale()
	return self.camera:getScale()
end

function Mousefield:getPosition()
	return self.camera:getPosition()
end

function Mousefield:toWorld(...)
	return self.camera:toWorld(...)
end

function Mousefield:toScreen(...)
	return self.camera:toScreen(...)
end

function Mousefield:update(dt)
	self.clicktime = self.clicktime + dt
	if self.grabbed then
		local pos = self.grabPosition
		local mx, my = love.mouse.getPosition()
		local s = self.camera:getScale()

		local dx, dy = (mx-pos.x)/s, (my-pos.y)/s
		local cx, cy = self.camera:getPosition()
		self.camera:setPosition(cx-dx, cy-dy)
		self.grabPosition.x = mx
		self.grabPosition.y = my
	end
end

function Mousefield:draw(fun)
	self.camera:draw(fun)
end

function Mousefield:mousepressed(x,y,button,fun)
	self.clicktime = 0

	fun = fun or function() end
	local l,t,w,h = self.camera:getWindow()
	if x > l and x < l+w then
		if y > t and y < t+h then
			self.grabbed = true
			self.grabPosition = {x=x, y=y}
			fun(l,t,w,h)
		end
	end
end

function Mousefield:mousereleased(x,y,button)
	self.grabbed = false
end

function Mousefield:onClick(fun)
	if self.clicktime < 0.3 then
		fun(self.camera:getWorld())
	end
end

function Mousefield:wheelmoved(x,y)
	local mx, my = love.mouse:getPosition()
	local l,t,w,h = self.camera:getWindow()
	if mx > l and mx < l+w then
		if my > t and my < t+h then
			local sx, sy = self.camera:getScale()
			if self.options.onlyScaleX then
				sx = sx * (1+y/10)
			else
				sx = sx * (1+y/10)
				sy = sy * (1+y/10)
			end
			self.camera:setScale(lume.clamp(sx, self.options.minScale, self.options.maxScale),lume.clamp(sy, self.options.minScale, self.options.maxScale))
		end
	end
end

return Mousefield
