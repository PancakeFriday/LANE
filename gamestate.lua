local Gamestate = {
	loaded = {},
	registered = {},
	names = {},
	xoff = 25,
	yoff = 2
}

local regularfont = love.graphics.newFont("LektonCode/LektonCode-Regular.ttf", 13)
local boldfont = love.graphics.newFont("LektonCode/LektonCode-Bold.ttf", 15)

function Gamestate:register(s, n)
	if not lume.find(self.registered, s) then
		table.insert(self.registered, s)
		table.insert(self.names, n)
	else
		print("[WARNING] Class ".." already registered as a gamestate!")
	end
end

function Gamestate:set(s)
	if not lume.find(self.registered, s) then
		error("Class is not registered as a gamestate. Call register(...) before setting it")
	end

	self.state = s
	if not self.loaded[s] then
		self:load()
		self.loaded[s] = true
	end
end

function Gamestate:call(f, ...)
	if self.state then
		if self.state[f] then
			self.state[f](self.state, ...)
		end
	end
end

function Gamestate:getWindow()
	local ww, wh = love.graphics.getDimensions()
	return self.xoff, self.yoff, ww-2, wh-2
end

function Gamestate:getTab(i)
	return 2,self.yoff+2+102*(i-1),self.xoff-4,100
end


function Gamestate:load(...)
	self:call("load", ...)
end

function Gamestate:update(...)
	self:call("update", ...)
end

function Gamestate:draw(...)
	love.graphics.setFont(regularfont)
	love.graphics.setColor(255,255,255)
	self:call("draw", ...)

	love.graphics.setColor(0,0,0)
	love.graphics.rectangle("fill",0,0,self.xoff,love.graphics.getHeight())

	love.graphics.setColor(80,80,80)
	love.graphics.setLineWidth(4)
	local ww, wh = love.graphics.getDimensions()
	love.graphics.rectangle("line",self.xoff,0,ww-self.xoff,wh)
	love.graphics.setLineWidth(1)

	love.graphics.setFont(boldfont)
	for i,v in pairs(self.registered) do
		if v == self.state then
			love.graphics.setColor(80,80,80)
		else
			love.graphics.setColor(40,40,40)
		end
		love.graphics.rectangle("fill",self:getTab(i))
		love.graphics.setColor(255,255,255)
		local t = self.names[i]
		love.graphics.print(t, (self.xoff-4)/2-boldfont:getHeight()/2, self.yoff+2+102*i-102/2+boldfont:getWidth(t)/2, 270/180*math.pi)
	end
	love.graphics.setFont(regularfont)
end

function Gamestate:textedited(...)
	self:call("textedited", ...)
end

function Gamestate:textinput(...)
	self:call("textinput", ...)
end

function Gamestate:keypressed(...)
	self:call("keypressed", ...)
end

function Gamestate:keyreleased(...)
	self:call("keyreleased", ...)
end

function Gamestate:mousepressed(...)
	local x1,y1,button = ...
	for i,v in pairs(self.registered) do
		local x2,y2,w,h = self:getTab(i)
		if x1 > x2 and x1 < x2 + w then
			if y1 > y2 and y1 < y2 + h then
				self:set(v)
			end
		end
	end

	self:call("mousepressed", ...)
end

function Gamestate:mousereleased(...)
	self:call("mousereleased", ...)
end

function Gamestate:wheelmoved(...)
	self:call("wheelmoved", ...)
end

function Gamestate:resize(...)
	self:call("resize", ...)
end

return Gamestate
