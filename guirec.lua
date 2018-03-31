local Guirec = Object:extend()

function Guirec:new(x,y,w,h)
	self.x = x
	self.y = y
	self.w = w
	self.h = h
end

function Guirec:getCoordinates()
	return self.x, self.y, self.w, self.h
end

function Guirec:draw(fun)
	fun(self.x,self.y,self.w,self.h)
end

function Guirec:mousepressed(x,y,button,fun)
	fun(self.x,self.y,self.w,self.h)
end

function Guirec:mousereleased(x,y,button,fun)
	fun(self.x,self.y,self.w,self.h)
end

return Guirec
