local Gamera = require "gamera"
local suit = require "SUIT"
local Fileexplorer = Object:extend()

local function scandir(directory)
    local t, popen = {}, io.popen
	local pfile
	local osString = love.system.getOS()
	if osString ~= "Windows" then
		pfile = popen('ls -a "'..directory..'"')
	else
		pfile = popen('dir "'..directory..'" /b')
	end
    for filename in pfile:lines() do
		if filename == "." or filename == ".." or filename:sub(1,1) ~= "." then
			table.insert(t,filename)
		end
    end
    pfile:close()
    return t
end

local function is_dir(path)
    local f = io.open(path, "r")
	if not f then
		return
	end
    local ok, err, code = f:read(1)
    f:close()
    return code == 21
end

function Fileexplorer:new()
	self.ui = suit.new()
	self.state = "closed"
	self.w, self.h = 630, 450
	self.expw, self.exph = 590, 340
	self.camera = Gamera.new(0,0,self.expw,self.exph)
	self.camera:setWindow(0, 0, self.expw, self.exph)

	self.filename = {text=""}
	self.currentdir = love.filesystem.getWorkingDirectory()
	self:evaluatePath(self.currentdir)

	self.actionTitle = ""
	self.actionName = ""
	self.actionFun = function() end
end

function Fileexplorer:evaluatePath(p)
	if is_dir(p) then
		self.currentdir = p
		self.currentdirContents = scandir(p)
		for i,v in pairs(self.currentdirContents) do
			local t = v
			if is_dir(self.currentdir.."/"..v) then
				self.currentdirContents[i] = self.currentdirContents[i] .. "/"
			end
		end

		self.camera:setWorld(0,0,self.expw,math.max(20*#self.currentdirContents, self.exph))
	else
		local _,pos = p:find(".*/")
		self.filename = {text=p:sub(pos+1)}
	end
end

function Fileexplorer:update(dt)
end

function Fileexplorer:draw()
	if self:isOpen() then
		local xwin, ywin, _, _ = Gamestate:getWindow()
		local xpos, ypos = love.graphics.getDimensions()
		xpos,ypos = xpos/2 - self.w/2, ypos/2 - self.h/2
		self.ui.layout:reset(xpos+20, ypos,5,0)
		self.ui:Label(self.actionTitle, {align = "left"}, self.ui.layout:row(400,30))
		local s = self.ui:Input(self.filename, self.ui.layout:row())
		if self.ui:Button(self.actionName, self.ui.layout:col(90,30)).hit then
			self.actionFun(self.currentdir.."/"..self.filename.text)
			self:close()
		end
		if self.ui:Button("Cancel", self.ui.layout:col(90,30)).hit then
			self:close()
		end

		love.graphics.setColor(100,100,100,255)
		love.graphics.rectangle("fill", xpos, ypos, self.w, self.h)

		local expx, expy = xpos + 20, ypos + 10+60
		self.camera:setWindow(expx, expy, self.expw, self.exph)
		love.graphics.setColor(50,50,50,255)
		love.graphics.rectangle("fill",expx,expy,self.expw,self.exph)

		self.camera:draw(function(l,t,w,h)
			for i,v in pairs(self.currentdirContents) do
				if (i%2)==0 then
					love.graphics.setColor(70,70,70,255)
				else
					love.graphics.setColor(90,90,90,255)
				end

				local mx, my = love.mouse.getPosition()
				mx,my = self.camera:toWorld(mx,my)

				if mx > 0 and mx < self.expw then
					if my > (i-1)*20 and my < i*20 then
						if love.mouse.isDown(1) then
							love.graphics.setColor(220,119,21)
						else
							love.graphics.setColor(255,164,75)
						end
					end
				end

				love.graphics.rectangle("fill",0, (i-1)*20, w, 20)
				love.graphics.setColor(255,255,255)
				love.graphics.print(v, 5, (i-1)*20)
			end
		end)

		self.ui:draw()
	end
end

function Fileexplorer:open(at, an, af)
	self.state = "open"
	self.actionTitle = at
	self.actionName = an
	self.actionFun = af or function() end
end

function Fileexplorer:isOpen()
	return self.state == "open"
end

function Fileexplorer:close()
	self.state = "closed"
end

function Fileexplorer:isClosed()
	return self.state == "closed"
end

function Fileexplorer:textedited(...)
	if self:isOpen() then
		self.ui:textedited(...)
	end
end

function Fileexplorer:textinput(...)
	if self:isOpen() then
		self.ui:textinput(...)
	end
end

function Fileexplorer:keypressed(key)
	if self:isOpen() then
		self.ui:keypressed(key)
	end
end

function Fileexplorer:mousepressed(x,y,button)
	if self:isOpen() then
		mx,my = self.camera:toWorld(x,y)

		local l,t,w,h = self.camera:getWindow()
		if x > l and x < l+w and
		y > t and y < t+h then
			for i,v in pairs(self.currentdirContents) do
				if my > (i-1)*20 and my < i*20 then
					if button == 1 then
						if v == "./" then

						elseif v == "../" then
							local _,p = self.currentdir:find(".*/")
							self:evaluatePath(self.currentdir:sub(1,p-1))
						else
							self:evaluatePath(self.currentdir.."/"..v)
						end
					end
				end
			end
		end
	end
end

function Fileexplorer:wheelmoved(x,y)
	if self:isOpen() then
		local xc,yc = self.camera:getPosition()
		self.camera:setPosition(xc,yc-10*y)
	end
end

return Fileexplorer()
