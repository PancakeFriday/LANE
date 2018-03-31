local Mousefield = require "mousefield"
local suit = require "SUIT"

Sprite = Object:extend()

function Sprite:new(imgfile)
	self.img = nil
	self.imgsettings = nil
	self.name = ""
	self.hash = imgfile -- TODO: to be love.data.hash when 0.11 is released
	--self.hash = love.data.hash("md5", imgfile)

	if imgfile and (lume.find({".png", ".jpg", ".bmp"}, imgfile:sub(-4)) or imgfile:sub(-5) == ".jpeg") then
		self:loadSpritesheet(imgfile)

		local _,pos = imgfile:find(".*/")
		self.name = imgfile:sub((pos or 0)+1)
	end

	self.quads = {}
end

function Sprite.loadData(d)
	local s = Sprite()
	s.name = d.name
	local filedata = love.filesystem.newFileData(d.img,d.name)
	local imgdata = love.image.newImageData(filedata)
	local img = love.graphics.newImage(imgdata)

	s.img = img
	s.imgsettings = d.imgsettings

	for i,v in pairs(d.quads) do
		if not s.quads[i] then
			s.quads[i] = {}
		end
		for j,k in pairs(v) do
			s.quads[i][j] = love.graphics.newQuad(unpack(k))
		end
	end

	return s
end

function Sprite:getData()
	local quads = {}
	for i,v in pairs(self.quads) do
		table.insert(quads, {})
		for j,k in pairs(v) do
			x,y,w,h = k:getViewport()
			sw,sh = k:getTextureDimensions()
			quads[i][j] = {x,y,w,h,sw,sh}
		end
	end
	local imagedata = self.img:getData()
	local filedata = imagedata:encode("png")
	local t = {
		quads = quads,
		name = self.name,
		imgsettings = self.imgsettings,
		img = filedata:getString()
	}
	return t
end

function Sprite:loadSpritesheet(f)
	local file = io.open(f)
	local d = love.filesystem.newFileData(file:read("*all"), f)
	self.img = love.graphics.newImage(d)
	self.imgsettings = {width={text=""}, height={text=""}}
	file:close()
end

function Sprite:setupQuads()
	self.quads = lume.clear(self.quads) or {}

	local gridw = math.max(5, tonumber(self.imgsettings.width.text) or 5)
	local gridh = math.max(5, tonumber(self.imgsettings.height.text) or 5)
	for x=0, self.img:getWidth()-1,gridw do
		local i = math.floor(x/gridw)+1
		if not self.quads[i] then
			self.quads[i] = {}
		end
		for y=0, self.img:getHeight()-1, gridh do
			local j = math.floor(y/gridh)+1
			self.quads[i][j] = love.graphics.newQuad(x,y,gridw,gridh,self.img:getWidth(),self.img:getHeight())
		end
	end
end

local Spriteeditor = Mousefield:extend()

function Spriteeditor.setWindow(x,y,w,h)
	Spriteeditor.x = x
	Spriteeditor.y = y
	Spriteeditor.w = w
	Spriteeditor.h = h
end

function Spriteeditor:new(imgfile)
	self.super.new(self, Spriteeditor.x, Spriteeditor.y, Spriteeditor.w, Spriteeditor.h)
	self.ui = suit.new()
	self.sprites = {}
	self.current = ""
	self.col, self.row = nil, nil
end

function Spriteeditor:addSprite(imgfile_or_sprite)
	local name
	if type(imgfile_or_sprite) == "string" then
		local imgfile = imgfile_or_sprite
		local _,pos = imgfile:find(".*/")
		name = imgfile:sub((pos or 0)+1)

		self.sprites[name] = Sprite(imgfile_or_sprite)
	else
		local sprite = imgfile_or_sprite
		name = sprite.name
		self.sprites[name] = sprite
	end

	self:setCurrent(name)

	local img = self.sprites[self.current].img
	self.super.setWorld(self, 0,0,img:getWidth(), img:getHeight())
	local l,t,w,h = self.super.getWindow(self)
	local s = math.min(w/img:getWidth(), h/img:getHeight())
	self.super.setScale(self,s)
end

function Spriteeditor:setCurrent(name)
	self.current = name
	local img = self.sprites[self.current].img
	self.super.setWorld(self, 0,0,img:getWidth(), img:getHeight())
	local l,t,w,h = self.super.getWindow(self)
	local s = math.min(w/img:getWidth(), h/img:getHeight())
	self.super.setScale(self,s)
	self:unsetSelection()
end

function Spriteeditor:getSprites()
	local t = {}
	for i,v in pairs(self.sprites) do
		table.insert(t, i)
	end
	return t
end

function Spriteeditor:getCurrentName()
	return self.current
end

function Spriteeditor:getCurrentSprite()
	return self.sprites[self.current]
end

function Spriteeditor:getFrame()
	return self.col, self.row
end

function Spriteeditor:getQuad()
	if self:getFrame() then
		return self.sprites[self.current].quads[self.col][self.row]
	end
end

function Spriteeditor:unsetSelection()
	self.col, self.row = nil, nil
end

function Spriteeditor:draw(selectedKey)
	local img, imgsettings
	if self.sprites[self.current] then
		img = self.sprites[self.current].img
		imgsettings = self.sprites[self.current].imgsettings
	end

	self.super.draw(self,function(l,t,w,h)
		if self.sprites[self.current] then
			love.graphics.setColor(255,255,255)
			love.graphics.draw(img, 0, 0)

			local gridw = math.max(5, tonumber(imgsettings.width.text) or 5)
			local gridh = math.max(5, tonumber(imgsettings.height.text) or 5)

			local mx, my = self.super.toWorld(self, love.mouse.getPosition())
			if mx > 0 and mx < img:getWidth() then
				if my > 0 and my < img:getHeight() then
					love.graphics.setColor(60,60,150,120)
					love.graphics.rectangle("fill", math.floor(mx/gridw)*gridw, math.floor(my/gridh)*gridh, gridw, gridh)
				end
			end

			if selectedKey then
				local col,row = selectedKey.properties.col, selectedKey.properties.row
				love.graphics.setColor(150,150,60,120)
				love.graphics.rectangle("fill", (col-1)*gridw, (row-1)*gridh, gridw, gridh)
			end

			if self.col and self.row then
				love.graphics.setColor(60,60,150,150)
				local x = gridw*(self.col-1)
				local y = gridh*(self.row-1)
				love.graphics.rectangle("fill",x,y,gridw,gridh)
			end

			love.graphics.setColor(255,255,255)
			love.graphics.setLineWidth(0.1)
			for i=gridw, img:getWidth()-1,gridw do
				love.graphics.line(i,0,i,img:getHeight())
			end
			for j=gridh, img:getHeight()-1, gridh do
				love.graphics.line(0,j,img:getWidth(),j)
			end
			love.graphics.setLineWidth(1)
		end
	end)

	if self.sprites[self.current] then
		local l,t,w,h = self.super.getWindow(self)
		self.ui.layout:reset(l,t+310,5,0)
		self.ui:Label("Frame width", self.ui.layout:row(130,30))
		self.ui:Input(imgsettings.width, {type="number"}, self.ui.layout:row(130,30))

		self.ui.layout:reset(l+150,t+310,5,0)
		self.ui:Label("Frame height", self.ui.layout:row(130,30))
		self.ui:Input(imgsettings.height, {type="number"}, self.ui.layout:row(130,30))

		self.ui:draw()
	end
end

function Spriteeditor:mousepressed(x,y,button)
	if self.current ~= "" then
		self.super.mousepressed(self, x, y, button, function(l,t,w,h)
			self.sprites[self.current]:setupQuads()

			local img = self.sprites[self.current].img
			local imgsettings = self.sprites[self.current].imgsettings

			local gridw = math.max(5, tonumber(imgsettings.width.text) or 5)
			local gridh = math.max(5, tonumber(imgsettings.height.text) or 5)
			local mx, my = self.super.toWorld(self, love.mouse.getPosition())
			local i = math.floor(mx/gridw)+1
			local j = math.floor(my/gridh)+1

			self.col = i
			self.row = j
		end)
	end
end

function Spriteeditor:textedited(...)
	self.ui:textedited(...)
end

function Spriteeditor:textinput(...)
	self.ui:textinput(...)
end

function Spriteeditor:keypressed(key)
	self.ui:keypressed(key)
end

function Spriteeditor:keyreleased(key)
	if self.current ~= "" then
		local imgsettings = self.sprites[self.current].imgsettings
		local gridw = math.max(5, tonumber(imgsettings.width.text) or 5)
		local gridh = math.max(5, tonumber(imgsettings.height.text) or 5)
		self.sprites[self.current]:setupQuads()
		self.sprites[self.current]:setupQuads()
	end
end

return Spriteeditor
