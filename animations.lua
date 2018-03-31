local suit = require "SUIT"
local Gamera = require "gamera"
local Mousefield = require "mousefield"
local Guirec = require "guirec"
local AnimationFactory = require "animationfactory"
local Spriteeditor = require "spriteeditor"
local Property = require "property"

local Animations = Object:extend()

local regularfont = love.graphics.newFont("LektonCode/LektonCode-Regular.ttf", 13)
regularfont:setFilter("nearest","nearest")
local boldfont = love.graphics.newFont("LektonCode/LektonCode-Bold.ttf", 15)

function Animations:new()
end

function Animations:load()
	self.ui = suit.new()
	self.fileexplorer = require "fileexplorer"

	self.mousefield = Mousefield(0,0,1,1)
	self.mousefield:setScale(4)
	self.timeline = {
		currentTime = 0,
		mousefield=Mousefield(0,0,1,1,{onlyScaleX=true, maxScale=4, minScale=1})
	}
	self.layers = {
		mousefield=Mousefield(0,0,1,1,{maxScale=1,minScale=1})
	}

	self.animations = AnimationFactory()

	self:setupWindows()
	self:setupSymbols()

	Spriteeditor.setWindow(self.guirecs[1].x+20, self.guirecs[1].y+110, self.guirecs[1].w-40, 310)
	self.sprites = Spriteeditor()

	self.add_button = love.graphics.newImage("symbols/add.png")
	self.add_button_bg = love.graphics.newImage("symbols/add_bg.png")
	self.properties = {
		Position = {values={{text="", n="x"}, {text="", n="y"}}, pos={x=7,y=50}, cb={checked=false}},
		Rotation = {values={{text="", n="d"}}, pos={x=7,y=120}, cb={checked=false}},
		Scale = {values={{text="", n="x"}, {text="", n="y"}}, pos={x=7,y=190}, cb={checked=false}},
	}
end

function Animations:setupWindows()
	local xwin, ywin, wwin, hwin = Gamestate:getWindow()
	local w1 = 2*20+90*3+2*5
	self.guirecs = {
		Guirec(xwin,ywin,w1,hwin-ywin), -- left guirec
		Guirec(xwin+60, ywin+80, 200, 25), -- spritesheet list
		Guirec(xwin+60, ywin+80, 200, 25), -- spritesheet dropdown
		Guirec(xwin+w1+5, ywin, wwin-w1-300, 150), -- timeline, background
		Guirec(xwin+w1+10, ywin+35, wwin-w1-310, 110), -- timeline, foreground
		Guirec(xwin+w1+270, ywin+5, 200, 25), -- timeline, names list
		Guirec(wwin/2-125, 150, 270, 80), -- timeline, names dropdown
		Guirec(xwin+w1+5, ywin+155, wwin-w1-300, hwin-ywin-155), -- main window
		Guirec(xwin+wwin-300+10, ywin+250, 265, hwin-ywin-250), -- properties
		Guirec(xwin+wwin-300+10, ywin,265, 245), -- layout
	}

	self.background = love.graphics.newImage("background.png")
	self.background:setWrap("repeat", "repeat")
	self.background_quad = love.graphics.newQuad(0,0,self.guirecs[1].w-40,310,self.background:getWidth(), self.background:getHeight())

	self.mousefield:setWindow(self.guirecs[8].x+10, self.guirecs[8].y+10, self.guirecs[8].w-20, self.guirecs[8].h-20)
	self.mousefield:setWorld(-200,-200,400,400)
	self.timeline.mousefield:setWindow(self.guirecs[5].x,self.guirecs[5].y,self.guirecs[5].w, self.guirecs[5].h)
	self.timeline.mousefield:setWorld(-40,0,5000,5000)
	self.layers.mousefield:setWindow(self.guirecs[10].x+10,self.guirecs[10].y+40,240,190)
	self.layers.mousefield:setWorld(0,0,240,240)
end

function Animations:setupSymbols()
	self.symbols = {
		newSpriteSheet={
			img=love.graphics.newImage("symbols/newAnim.png"),
			pos={x=self.guirecs[1].x+20,y=self.guirecs[1].y+80},
			onClick=function()
				self.fileexplorer:open("Choose spritesheet...", "Load", function(f)
					if lume.find({".png", ".jpg", ".bmp"}, f:sub(-4)) or f:sub(-5) == ".jpeg" then
						self.sprites:addSprite(f)
					end
				end)
			end,
		},
		delete={
			img=love.graphics.newImage("symbols/delete.png"),
			pos={x=self.guirecs[4].x+205,y=self.guirecs[4].y+5},
			onClick=function()
				self.animations:removeCurrent()
				self.animations:getNext()
			end,
		},
		newAnim={
			img=love.graphics.newImage("symbols/newAnim.png"),
			pos={x=self.guirecs[4].x+180,y=self.guirecs[4].y+5},
			onClick=function()
				self.newAnimWindow=true
				self.tempAnimName={text=""}
			end,
		},
		--play_backwards={
			--img=love.graphics.newImage("symbols/play_backwards.png"),
			--pos={x=self.guirecs[4].x+35,y=self.guirecs[4].y+5},
			--onClick=function()

			--end,
		--},
		play={
			img=love.graphics.newImage("symbols/play.png"),
			pos={x=self.guirecs[4].x+30,y=self.guirecs[4].y+5},
			onClick=function()
				if self.playing then
					self.playing = false
				else
					self.playing = true
				end
			end,
		},
		--jump_forward={
			--img=love.graphics.newImage("symbols/jump_forward.png"),
			--pos={x=self.guirecs[4].x+110,y=self.guirecs[4].y+5},
			--onClick=function()

			--end,
		--},
		scissor={
			img=love.graphics.newImage("symbols/scissor.png"),
			pos={x=self.guirecs[4].x+100,y=self.guirecs[4].y+5},
			onClick=function()
				self.animations:setMaxTime(self.timeline.currentTime)
			end,
		},
		--jump_backward={
			--img=love.graphics.newImage("symbols/jump_backward.png"),
			--pos={x=self.guirecs[4].x+10,y=self.guirecs[4].y+5},
			--onClick=function()

			--end,
		--},
		rename={
			img=love.graphics.newImage("symbols/rename.png"),
			pos={x=self.guirecs[4].x+230,y=self.guirecs[4].y+5},
			onClick=function()
				if self.animations.current ~= "" then
					self.newAnimWindow=true
					self.rename = true
					self.tempAnimName={text=self.animations.current}
				end
			end,
		},
		stop={
			img=love.graphics.newImage("symbols/stop.png"),
			pos={x=self.guirecs[4].x+5,y=self.guirecs[4].y+5},
			onClick=function()
				self.playing = false
				self.timeline.currentTime = 0
			end,
		}
	}
	self.symbols.play.img:setFilter("linear", "linear")
	--self.symbols.play_backwards.img:setFilter("linear", "linear")
end

function Animations:update(dt)
	if self.playing then
		self.timeline.currentTime = (self.timeline.currentTime + dt)%self.animations:getMaxTime()
	end

	local xwin, ywin, _, _ = Gamestate:getWindow()
	self.ui.layout:reset(20+xwin,20+ywin,5,0)
	if self.ui:Button("Save", self.ui.layout:col(90,30)).hit then
		self.fileexplorer:open("Choose filename...", "Save", function(f)
			if not lume.find({".ani"}, f:sub(-4)) then
				f = f ..".ani"
			end

			local animationdata = self.animations:getData()

			local f = io.open(f, "w")
			f:write(animationdata)
			f:close()
		end)
	end
	if self.ui:Button("Load", self.ui.layout:col(90,30)).hit then
		self.fileexplorer:open("Choose .ani file...", "Load", function(f)
			if lume.find({".ani"}, f:sub(-4)) then
				local f = io.open(f, "r")
				local d = f:read("*all")
				f:close()
				self.animations:loadData(d)
				for i,v in pairs(self.animations.sprites) do
					self.sprites:addSprite(v)
				end
			end
		end)
	end

	self.sprites:update(dt)
	self.timeline.mousefield:update(dt)

	if self.timeline.cursorgrabbed then
		local mx, my = love.mouse:getPosition()
		local dx, dy = mx-self.timeline.grabPosition.x, my-self.timeline.grabPosition.y
		local sx,sy = self.timeline.mousefield:getScale()
		dx = dx / sx
		local stepsize = 40/2^math.floor(math.log(sx, 2))
		local newTime = (lume.round(dx/stepsize))*stepsize/80
		self.timeline.currentTime = math.max(0,lume.round(self.timeline.oldTime + newTime,stepsize/80))
		if self.timeline.currentTime ~= self.timeline.oldTime then
			local n = #self.animations:getKeys()
			self.layers.mousefield:setWorld(0,0,240,math.max(240,n*30))
		end
	end

	if self.mousefield.mouseGrabPosition and self.mousefield.selectedKey then
		local mx, my = self.mousefield:toWorld(love.mouse.getPosition())
		local gx, gy = unpack(self.mousefield.mouseGrabPosition)
		local props = self.mousefield.selectedKey.properties
		local pprops = self.mousefield.mouseGrabProps
		if self.mousefield.mouseGrabAction == "g" then
			local dx = mx - gx
			local dy = my - gy
			props.pos.x = lume.round(pprops.pos.x + dx)
			props.pos.y = lume.round(pprops.pos.y + dy)
		elseif self.mousefield.mouseGrabAction == "s" then
			local d1 = math.sqrt((gx-pprops.pos.x)^2+(gy-pprops.pos.y)^2)
			local d2 = math.sqrt((mx-props.pos.x)^2 + (my-props.pos.y)^2)
			props.scale.x = lume.round(pprops.scale.x*(d2/d1), 0.001)
			props.scale.y = lume.round(pprops.scale.y*(d2/d1), 0.001)
		elseif self.mousefield.mouseGrabAction == "r" then
			local v1x, v1y = mx-props.pos.x, my-props.pos.y
			local v2x, v2y = gx-props.pos.x, gy-props.pos.y
			local d1 = lume.distance(v1x,v1y, 0, 0)
			local d2 = lume.distance(v2x,v2y, 0, 0)
			local a = -math.acos(((v1x*v2x)+(v1y*v2y))/(d1*d2))
			local dot = v1x*v2y-v2x*v1y
			if dot < 0 then a = -a end
			props.rot = lume.round(pprops.rot + a, 0.001)
		end
	end

	self.fileexplorer:update(dt)
	self.mousefield:update(dt)
	self.layers.mousefield:update(dt)
end

function Animations:draw()
	self.guirecs[1]:draw(function(l,t,w,h)
		love.graphics.setColor(80,80,80,100)
		love.graphics.rectangle("fill", l, t, w, h)

		love.graphics.setColor(80,80,80,255)
		love.graphics.rectangle("fill", l+20, t+110, w - 40, 310)
		love.graphics.draw(self.background, self.background_quad, l+20, t+110)

		self.sprites:draw(self.mousefield.selectedKey)
	end)

	self.guirecs[2]:draw(function(l,t,w,h)
		local mx, my = love.mouse.getPosition()
		if mx > l and mx < l + w and
			my > t and my < t + h then
			if love.mouse.isDown(1) then
				love.graphics.setColor(60,60,60,100)
			else
				love.graphics.setColor(120,120,120,100)
			end
		else
			love.graphics.setColor(80,80,80,100)
		end
		love.graphics.rectangle("fill", l, t, w, h)

		if self.selectSprites then
			local j = 1
			for i,v in pairs(self.sprites:getSprites()) do
				if mx > l and mx < l + w and
					my > t+j*h and my < t+(j+1)*h then
					love.graphics.setColor(120,120,120,255)
				else
					love.graphics.setColor(80,80,80,255)
				end
				if v ~= self.sprites:getCurrentName() then
					love.graphics.rectangle("fill", l, t+j*h, w, h)
					love.graphics.setColor(255,255,255)
					love.graphics.print(v, l+8, (j)*h + t+3)
					j = j + 1
				end
			end
		end

		love.graphics.setColor(255,255,255)
		love.graphics.print(self.sprites:getCurrentName() or "", l+8, t+3)
	end)

	self.guirecs[4]:draw(function(l,t,w,h)
		love.graphics.setColor(80,80,80,100)
		love.graphics.rectangle("fill", l, t, w, h)

		local mx, my = love.mouse.getPosition()
		for i,v in pairs(self.symbols) do
			love.graphics.setColor(255,255,255)
			love.graphics.draw(v.img, v.pos.x, v.pos.y)
			if mx > v.pos.x and mx < v.pos.x + 25 then
				if my > v.pos.y and my < v.pos.y + 25 then
					if love.mouse.isDown(1) then
						love.graphics.setColor(120,120,120,50)
					else
						love.graphics.setColor(255,255,255,50)
					end
					love.graphics.rectangle("fill", v.pos.x, v.pos.y, 25, 25)
				end
			end
		end
	end)

	self.guirecs[5]:draw(function(l,t,w,h)
		love.graphics.setColor(255,255,255,110)
		love.graphics.line(l+1,t+20,l+w-1,t+20)
		love.graphics.line(100+l,t+1,100+l,t+h-1)

		self.timeline.mousefield:draw(function(lm,tm,wm,hm)
			love.graphics.setColor(255,255,255,20)
			local sx, sy = self.timeline.mousefield:getScale()
			local px, py = self.timeline.mousefield:getPosition()
			love.graphics.setLineWidth(1/sx)
			local stepsize = 1/2^(math.floor(sx/0.5)-1)
			-- round to previous power of two
			local stepsize = 40/2^math.floor(math.log(sx, 2))
			love.graphics.setScissor(l+100,t,w-100,h)
			love.graphics.setColor(255,255,255,10)
			love.graphics.rectangle("fill", 100, tm, self.animations:getMaxTime()*80, h)
			love.graphics.setColor(200,200,255,255)
			love.graphics.line(100+self.timeline.currentTime*80,tm,100+self.timeline.currentTime*80,hm+tm)
			love.graphics.setColor(255,255,255,160)
			for i=0,10000,stepsize do
				if (i/40)%2==0 then
					love.graphics.setColor(255,255,255,50)
				else
					love.graphics.setColor(255,255,255,20)
				end
				love.graphics.line(i+100,tm,i+100,hm+tm)
				love.graphics.setColor(255,255,255,255)
				love.graphics.printUnscaled(self.timeline.mousefield.camera,i/80, i+2/sx+100,2+tm)
			end
			love.graphics.setScissor(l+100,t+20,w-100,h-20)

			local keys = self.animations:getKeys()
			-- 80 offset is 1 second
			love.graphics.setColor(255,255,255,255)
			local row = 1
			for name,key in pairs(keys) do
				for time,value in pairs(key.frames) do
					-- check if this specific time indexs' quad exists
					if self.mousefield.selectedKey and self.mousefield.selectedKey == value then
						love.graphics.setColor(150,150,255,255)
					elseif self.animations:isValid(value) then
						love.graphics.setColor(255,255,255,255)
					else
						love.graphics.setColor(255,0,0,255)
					end
					love.graphics.polygon("fill",
						time*80 + 100-3/sx,row*25+8,
						time*80 + 100, row*25+5,
						time*80 + 100+3/sx, row*25+8,
						time*80 + 100, row*25+11)
				end
				row = row + 1
			end
			love.graphics.setScissor()
			love.graphics.setLineWidth(1)

			love.graphics.setScissor(l, t+20, 100, h-20)
			local mx, my = self.timeline.mousefield:toWorld(love.mouse.getPosition())
			local i = 1
			for name, key in pairs(keys) do
				if mx > lm and mx < lm+25/sx then
					if my > i*25 and my < i*25 + 25 then
						if love.mouse.isDown(1) then
							love.graphics.setColor(120,120,120,50)
						else
							love.graphics.setColor(255,255,255,50)
						end
						love.graphics.rectangle("fill", lm, i*25,25/sx,25)
					end
				end
				--if mx > lm/sx + 25 and mx < lm/sx + 100
				--and my > i*25 and my < i*25 + 25 then
					--cursor = love.mouse.getSystemCursor("ibeam")
					--love.mouse.setCursor(cursor)
				--else
					--love.mouse.setCursor()
				--end
				love.graphics.setColor(255,255,255,255)
				love.graphics.draw(self.animations.keySymbol, lm, i*25, 0, 1/sx, 1)
				--love.graphics.printUnscaled(self.timeline.mousefield.camera, key.name, lm+30/sx, i*25+3)
				self.ui.layout:reset(l+30, (i+1)*25+10-tm)
				self.ui:Input(key, {field="name",align="left",nobg=true}, self.ui.layout:row(100-25,25))
				i = i + 1
			end
			love.graphics.setScissor()
		end)

	end)

	self.guirecs[6]:draw(function(l,t,w,h)
		local mx, my = love.mouse.getPosition()
		if mx > l and mx < l + w and
			my > t and my < t + h then
			if love.mouse.isDown(1) then
				love.graphics.setColor(60,60,60,100)
			else
				love.graphics.setColor(120,120,120,100)
			end
		else
			love.graphics.setColor(80,80,80,100)
		end
		love.graphics.rectangle("fill", l, t, w, h)

		if self.selectAnimations then
			local j = 1
			for i,v in pairs(self.animations:getAnimations()) do
				if mx > l and mx < l + w and
					my > t+j*h and my < t+(j+1)*h then
					love.graphics.setColor(120,120,120,255)
				else
					love.graphics.setColor(80,80,80,255)
				end
				if v ~= self.animations:getCurrent() then
					love.graphics.rectangle("fill", l, t+j*h, w, h)
					love.graphics.setColor(255,255,255)
					love.graphics.print(v, l+8, (j)*h + t+3)
					j = j + 1
				end
			end
		end

		love.graphics.setColor(255,255,255)
		love.graphics.print(self.animations:getCurrent() or "", l+8, t+3)
	end)

	if self.newAnimWindow == true then
		self.guirecs[7]:draw(function(l,t,w,h)
			love.graphics.setColor(80,80,80)
			love.graphics.rectangle("fill", l, t, w, h)
			love.graphics.setColor(255,255,255)
			love.graphics.print("New animation name", l+10,t+10)
			self.ui.layout:reset(l+10,t+35,5,0)
			self.ui:Input(self.tempAnimName, self.ui.layout:row(180,30))
			if self.ui:Button("Submit", self.ui.layout:col(65,30)).hit then
				self.newAnimWindow = false
				if self.rename then
					self.animations:renameAnimation(self.tempAnimName.text)
					self.rename = nil
				else
					self.animations:newAnimation(self.tempAnimName.text)
				end
				self.animations:setCurrent(self.tempAnimName.text)
			end
		end)
	end

	self.guirecs[8]:draw(function(l,t,w,h)
		love.graphics.setColor(80,80,80,100)
		love.graphics.rectangle("fill", l, t, w, h)

		local s = self.mousefield:getScale()
		local wx,wy,ww,wh = self.mousefield:getWorld()
		love.graphics.setLineWidth(0.01/s)
		self.mousefield:draw(function(lm,tm,wm,hm)
			for x=math.floor(lm/5)*5,lm+wm,5 do
				if x == 0 then
					love.graphics.setColor(0,255,0,50)
				else
					love.graphics.setColor(255,255,255,50)
				end
				love.graphics.line(x, tm, x, hm+tm)
			end
			for y=math.floor(tm/5)*5,tm+hm,5 do
				if y == 0 then
					love.graphics.setColor(255,0,0,50)
				else
					love.graphics.setColor(255,255,255,50)
				end
				love.graphics.line(lm, y, lm+wm, y)
			end

			-- if you selected a quad in the spritesheet, this is the preview
			local mx, my = self.mousefield:toWorld(love.mouse.getPosition())
			if self.sprites:getCurrentName() ~= "" then
				if self.sprites:getFrame() and self.sprites:getQuad() then
					local col, row = self.sprites:getFrame()
					local sprite = self.sprites:getCurrentSprite()
					local quad = self.sprites:getQuad()
					local _, _, qw, qh = quad:getViewport()

					local xpos, ypos = math.floor(mx), math.floor(my)
					love.graphics.setColor(255,255,255,50)
					love.graphics.draw(sprite.img, quad, xpos, ypos, 0, 1, 1, qw/2, qh/2)
					love.graphics.setColor(255,255,255,150)
					love.graphics.rectangle("line", xpos-qw/2, ypos-qh/2, qw, qh)
					love.graphics.line(xpos, ypos-qh/2, xpos, ypos+qh/2)
					love.graphics.line(xpos-qw/2, ypos, xpos+qw/2, ypos)
				end
			end

			-- draw all the quads on the big canvas
			self.animations:draw(self.timeline.currentTime)
			if self.mousefield.selectedKey then
				local props = self.mousefield.selectedKey.properties
				local qw, qh = self.animations:getQuadDimensions(self.mousefield.selectedKey)
				if qw and qh then
					love.graphics.push()
					love.graphics.translate(props.pos.x-qw/2, props.pos.y-qh/2)
					love.graphics.push()
					love.graphics.translate(qw/2, qh/2)
					love.graphics.rotate(props.rot)
					love.graphics.scale(props.scale.x, props.scale.y)
					love.graphics.translate(-qw/2, -qh/2)
					love.graphics.rectangle("line", 0, 0, qw, qh)
					love.graphics.line(qw/2, 0, qw/2, qh)
					love.graphics.line(0, qh/2, qw, qh/2)
					love.graphics.pop()
					love.graphics.pop()
				end
			end
		end)
		love.graphics.setLineWidth(1)
	end)

	self.guirecs[9]:draw(function(l,t,w,h)
		love.graphics.setColor(80,80,80,100)
		love.graphics.rectangle("fill", l, t, w, h)

		self.ui.layout:reset(l+5,t+5,5,0)
		self.ui:Label("Properties", {align="left", font=boldfont}, self.ui.layout:row(150,20))
		if self.mousefield.selectedKey then
			local props = self.mousefield.selectedKey.tempProps
			if props then
				self.ui.layout:reset(l+5,t+25,5,0)
				self.ui:Label("Position", {align="left"}, self.ui.layout:row(150,20))
				self.ui:Label("x", {align="left"}, self.ui.layout:row(13,20))
				self.ui:Input(props.pos, {id="props.pos.x", type="number", field="x", align="left"}, self.ui.layout:col(90,20))
				self.ui:Label("y", {align="left"}, self.ui.layout:col(13,20))
				self.ui:Input(props.pos, {id="props.pos.y", type="number", field="y", align="left"}, self.ui.layout:col(90,20))

				self.ui.layout:reset(l+5,t+75,5,0)
				self.ui:Label("Scale", {align="left"}, self.ui.layout:row(150,20))
				self.ui:Label("x", {align="left"}, self.ui.layout:row(13,20))
				self.ui:Input(props.scale, {id="props.scale.x", type="number", field="x", align="left"}, self.ui.layout:col(90,20))
				self.ui:Label("y", {align="left"}, self.ui.layout:col(13,20))
				self.ui:Input(props.scale, {id="props.scale.y", type="number", field="y", align="left"}, self.ui.layout:col(90,20))
				self.ui.layout:reset(l+5,t+125,5,0)
				self.ui:Label("Rotation", {align="left"}, self.ui.layout:row(150,20))
				self.ui:Label("", {align="left"}, self.ui.layout:row(13,20))
				self.ui:Input(props, {id="props.rot", type="number", field="rot", align="left"}, self.ui.layout:col(90,20))

				self.ui.layout:reset(l+5,t+175,5,0)
				self.ui:Label("Frame", {align="left"}, self.ui.layout:row(150,20))
				self.ui:Label("row", {align="left"}, self.ui.layout:row(30,20))
				self.ui:Input(props, {id="props.row", type="number", field="row", align="left"}, self.ui.layout:col(64,20))
				self.ui:Label("col", {align="left"}, self.ui.layout:col(30,20))
				self.ui:Input(props, {id="props.col", type="number", field="col", align="left"}, self.ui.layout:col(64,20))

				self.ui.layout:reset(l+5,t+225,5,0)
				self.ui:Label("Color", {align="left"}, self.ui.layout:row(150,20))
				self.ui:Label("r", {align="left"}, self.ui.layout:row(30,20))
				self.ui:Input(props.color, {id="props.color.r", type="number", field="r", align="left"}, self.ui.layout:col(64,20))
				self.ui:Label("g", {align="left"}, self.ui.layout:col(30,20))
				self.ui:Input(props.color, {id="props.color.g", type="number", field="g", align="left"}, self.ui.layout:col(64,20))
				self.ui.layout:reset(l+5,t+275,5,0)
				self.ui:Label("b", {align="left"}, self.ui.layout:row(30,20))
				self.ui:Input(props.color, {id="props.color.b", type="number", field="b", align="left"}, self.ui.layout:col(64,20))
				self.ui:Label("a", {align="left"}, self.ui.layout:col(30,20))
				self.ui:Input(props.color, {id="props.color.a", type="number", field="a", align="left"}, self.ui.layout:col(64,20))
			end
		end
	end)

	self.guirecs[10]:draw(function(l,t,w,h)
		love.graphics.setColor(80,80,80,100)
		love.graphics.rectangle("fill", l, t, w, h)

		self.ui.layout:reset(l+5,t+5,5,0)
		self.ui:Label("Draw order", {align="left", font=boldfont}, self.ui.layout:row(150,20))

		self.layers.mousefield:draw(function(lm,tm,wm,hm)
			love.graphics.setColor(80,80,80,100)
			love.graphics.rectangle("fill",lm,tm,wm,hm)

			local keys = self.animations:getKeys()
			local mx, my = love.mouse.getPosition()
			local lw, tw, ww, hw = self.layers.mousefield:getWindow()
			for i,key in pairs(keys) do
				local j = i-1
				for time,value in pairs(key) do
					if self.mousefield.selectedKey and lume.find(key.frames,self.mousefield.selectedKey) then
						love.graphics.setColor(80,80,150,100)
					else
						love.graphics.setColor(80,80,80,100)
					end
					love.graphics.rectangle("fill",0,30*j,wm,30)
					love.graphics.setColor(255,255,255)
					love.graphics.print(key.name,10,5+30*j)

					if mx > lw+190 and mx < lw+210 then
						if my > tw+5+30*j and my < tw+25+30*j then
							if love.mouse.isDown(1) then
								love.graphics.setColor(255,255,255,60)
							else
								love.graphics.setColor(255,255,255,100)
							end
							love.graphics.rectangle("fill",190,5+30*j,20,20)
						end
					end
					if j <= 0 then
						love.graphics.setColor(255,255,255,80)
					end
					love.graphics.arrow(200,20+30*j,200,10+30*j,0.5,5)

					if mx > lw+210 and mx < lw+230 then
						if my > tw+5+30*j and my < tw+25+30*j then
							if love.mouse.isDown(1) then
								love.graphics.setColor(255,255,255,60)
							else
								love.graphics.setColor(255,255,255,100)
							end
							love.graphics.rectangle("fill",210,5+30*j,20,20)
						end
					end
					love.graphics.setColor(255,255,255)
					if j >= lume.count(keys)-1 then
						love.graphics.setColor(255,255,255,80)
					end
					love.graphics.arrow(220,10+30*j,220,20+30*j,0.5,5)
				end
			end
		end)
	end)

	self.ui:draw()

	self.fileexplorer:draw()
end

function Animations:textedited(text, start, length)
    -- for IME input
    self.ui:textedited(text, start, length)
    self.fileexplorer:textedited(text, start, length)

	self.sprites:textedited(text,start,length)
end

function Animations:textinput(t)
	-- forward text input to SUIT
	self.ui:textinput(t)
	self.fileexplorer:textinput(t)

	self.sprites:textinput(t)
end

function Animations:keypressed(key)
	-- forward keypresses to SUIT
	self.ui:keypressed(key)
	self.fileexplorer:keypressed(key)

	self.sprites:keypressed(key)

	local mx, my = love.mouse.getPosition()
	local l,t,w,h = self.guirecs[8]:getCoordinates()
	-- HOTKEYS
	if mx > l and mx < l+w then
		if my > t and my < t+h then
			if self.mousefield.selectedKey then
				if key == "g" or key == "s" or key == "r" then
					local s = self.mousefield.selectedKey
					if self.mousefield.mouseGrabProps then
						s.properties = self.mousefield.mouseGrabProps:copy()
					end
					self.mousefield.mouseGrabPosition = {self.mousefield:toWorld(mx,my)}
					self.mousefield.mouseGrabAction = key
					self.mousefield.mouseGrabProps = s.properties:copy()
				end
			end
		end
	end
	-- play/pause the animations
	if key == "p" then
		self.symbols.play:onClick()
	end
	-- stop animation
	if key == "t" then
		self.symbols.stop:onClick()
	end
	if key == "d" then
		if self.mousefield.selectedKey then
			self.animations:deleteKey(self.mousefield.selectedKey)
			self.mousefield.selectedKey = nil
		end
	end
	-- Increase time by one step
	if key == "left" then
		local sx,sy = self.timeline.mousefield:getScale()
		local stepsize = 40/2^math.floor(math.log(sx, 2))
		self.timeline.currentTime = (lume.round(self.timeline.currentTime - stepsize/80, stepsize/80))%(self.animations:getMaxTime()+stepsize/80)
	end
	if key == "right" then
		local sx,sy = self.timeline.mousefield:getScale()
		local stepsize = 40/2^math.floor(math.log(sx, 2))
		self.timeline.currentTime = (lume.round(self.timeline.currentTime + stepsize/80, stepsize/80))%(self.animations:getMaxTime()+stepsize/80)
	end
	-- increase column
	if key == "c" then
		if self.mousefield.selectedKey then
			local p = self.mousefield.selectedKey.properties
			p.col = p.col + 1
			if not self.animations:getQuadDimensions(self.mousefield.selectedKey) then
				p.col = 1
			end
			self.mousefield.selectedKey.tempProps = p:copy()
		end
	end
	-- increase row
	if key == "w" then
		if self.mousefield.selectedKey then
			local p = self.mousefield.selectedKey.properties
			p.row = p.row + 1
			if not self.animations:getQuadDimensions(self.mousefield.selectedKey) then
				p.row = 1
			end
			self.mousefield.selectedKey.tempProps = p:copy()
		end
	end
	if key == "a" then
		if self.mousefield.selectedKey then
			local key = self.animations:getBaseKey(self.mousefield.selectedKey)
			local newkey = self.animations:copyToTime(key, self.timeline.currentTime)
			self.mousefield.selectedKey = newkey
		end
	end
	-- next key of current sprite
	if key == "n" then
		if self.mousefield.selectedKey then
			self.mousefield.selectedKey, time = self.animations:getNextKeyframe(self.mousefield.selectedKey)
			if time then
				self.timeline.currentTime = time
			end
		end
	end
end

function Animations:keyreleased(key)
	self.sprites:keyreleased(key)
end

function Animations:mousepressed(x,y,button)
	if self.fileexplorer:isOpen() then
		self.fileexplorer:mousepressed(x,y,button)
	else
		self.sprites:mousepressed(x,y,button)

		self.guirecs[2]:mousepressed(x,y,button,function(l,t,w,h)
			if self.selectSprites then
				local j = 1
				for i,v in pairs(self.sprites:getSprites()) do
					if v ~= self.sprites:getCurrentName() then
						if x > l and x < l + w and
							y > t+j*h and y < t+(j+1)*h then
							self.sprites:setCurrent(v)
						end
						j = j + 1
					end
				end
			end

			self.selectSprites = false
			if x > l and x < l + w and
				y > t and y < t + h then
				if button == 1 then
					self.selectSprites = true
				end
			end
		end)

		for i,v in pairs(self.symbols) do
			if x > v.pos.x and x < v.pos.x + 25 then
				if y > v.pos.y and y < v.pos.y + 25 then
					if button == 1 then
						v.onClick()
					end
				end
			end
		end

		self.guirecs[5]:mousepressed(x,y,button,function(l,t,w,h)
			self.timeline.cursorgrabbed = false
			local xl,_ = self.timeline.mousefield:toScreen(100+self.timeline.currentTime*80,0)
			if x>xl-4 and x<xl+4 then
				self.timeline.cursorgrabbed = true
				self.timeline.grabPosition = {x=x,y=y}
				self.timeline.oldTime = self.timeline.currentTime
				self.timeline.mousefield.clicktime = 0
			else
				self.timeline.mousefield:mousepressed(x,y,button)
			end

			-- check the key name
			local i = 1
			local keys = self.animations:getKeys()
			if keys then
				local mx, my = x, y
				local lm, tm, wm, hm = self.timeline.mousefield:getWindow()
				for i, key in pairs(keys) do
					if mx > lm and mx < lm + 25 then
						if my > tm + i*25 and my < tm + i*25 + 25 then
							if button == 1 then
								self.animations:copyToTime(key, self.timeline.currentTime)
							end
						end
					end
					i = i + 1
				end
			end
		end)

		self.guirecs[6]:mousepressed(x,y,button,function(l,t,w,h)
			if self.selectAnimations then
				local j = 1
				for i,v in pairs(self.animations:getAnimations()) do
					if v ~= self.animations:getCurrent() then
						if x > l and x < l + w and
							y > t+j*h and y < t+(j+1)*h then
							self.animations:setCurrent(v)
							local n = #self.animations:getKeys()
							self.layers.mousefield:setWorld(0,0,240,math.max(240,n*30))
							break
						end
						j = j + 1
					end
				end
			end

			self.selectAnimations = false
			if x > l and x < l + w and
				y > t and y < t + h then
				if button == 1 then
					self.selectAnimations = true
				end
			end
		end)

		self.mousefield:mousepressed(x,y,button)
		self.layers.mousefield:mousepressed(x,y,button)
	end
end

function Animations:mousereleased(x,y,button)
	if self.fileexplorer:isOpen() then

	else
		self.timeline.cursorgrabbed = false

		if self.sprites[self.currentSprite] then
			self.sprites[self.currentSprite]:mousereleased(x,y,button)
		end
		self.timeline.mousefield:mousereleased(x,y,button)
		self.mousefield:mousereleased(x,y,button)
		self.layers.mousefield:mousereleased(x,y,button)

		self.guirecs[9]:mousereleased(x,y,button,function(l,t,w,h)
			if x > l and x < l+w then
				if y > t and y < t+h then
					if not self.mousefield.mouseGrabPosition then
						if self.mousefield.selectedKey and self.mousefield.selectedKey.tempProps then
							self.mousefield.selectedKey.properties = self.mousefield.selectedKey.tempProps:copy()
						end
					end
				end
			end
		end)

		self.mousefield:onClick(function(l,t,w,h)
			local l,t,w,h = self.mousefield:getWindow()
			if x > l and x < l+w then
				if y > t and y < t+h then
					if self.mousefield.mouseGrabPosition then
						self.mousefield.selectedKey.tempProps = self.mousefield.selectedKey.properties:copy()
						self.mousefield.mouseGrabPosition = nil
						self.mousefield.mouseGrabAction = nil
						self.mousefield.mouseGrabProps = nil
					else
						if self.mousefield.selectedKey then
							self.mousefield.selectedKey.tempProps = nil
						end
						self.mousefield.selectedKey = nil
						if self.sprites:getQuad() then
							if self.sprites:getCurrentName() ~= "" and self.animations:getCurrent() ~= "" then
								local mx, my = self.mousefield:toWorld(x,y)
								local xpos, ypos = math.floor(mx), math.floor(my)
								local col, row = self.sprites:getFrame()
								local sprite = self.sprites:getCurrentSprite()
								local quad = self.sprites:getQuad()
								local _, _, qw, qh = quad:getViewport()
								local key = self.animations:addKey(self.animations:getNextName(),
									self.timeline.currentTime,
									sprite,
									Property(xpos,ypos,col,row))
								self.sprites:unsetSelection()
								key.tempProps = key.properties:copy()
								self.mousefield.selectedKey = key
								local n = #self.animations:getKeys()
								self.layers.mousefield:setWorld(0,0,240,math.max(240,n*30))
							end
						else
							local mx, my = self.mousefield:toWorld(x,y)
							local key = self.animations:selectKey(mx,my,self.timeline.currentTime)
							if key then
								self.mousefield.selectedKey = key
								self.mousefield.selectedKey.tempProps = self.mousefield.selectedKey.properties:copy()
							end
						end
					end
				end
			end
		end)

		-- check click on one of the polygons
		self.timeline.mousefield:onClick(function(l,t,w,h)
			-- 80 offset is 1 second
			local keys = self.animations:getKeys()
			if keys then
				local row = 1
				local mx, my = self.timeline.mousefield:toWorld(x,y)
				for i,key in pairs(keys) do
					for time,value in pairs(key.frames) do
						if math.sqrt((mx-(time*80+100))^2 + (my-(row*25+8))^2) < 6 then
							value.tempProps = value.properties:copy()
							self.mousefield.selectedKey = value
							self.timeline.currentTime = time
							break
						end
					end
					row = row + 1
				end
			end
		end)

		self.layers.mousefield:onClick(function(l,t,w,h)
			local keys = self.animations:getKeys()
			local lw, tw, ww, hw = self.layers.mousefield:getWindow()
			local mx, my = self.layers.mousefield:toWorld(x,y)
			for i,key in pairs(keys) do
				local j = i-1
				for time,value in pairs(key.frames) do
					if mx > 190 and mx < 210 then
						if my > 5+30*j and my < 25+30*j then
							if j > 0 and button == 1 then
								-- move it up one layer
								self.animations:shiftLayer(key, 1)
								break
							end
						end
					end

					if mx > 210 and mx < 230 then
						if my > 5+30*j and my < 25+30*j then
							if j < lume.count(keys)-1 and button == 1 then
								-- move it down one layer
								self.animations:shiftLayer(key, -1)
								break
							end
						end
					end
				end
			end
		end)

	end
end

function Animations:wheelmoved(x,y)
	if self.fileexplorer:isOpen() then
		self.fileexplorer:wheelmoved(x,y)
	else
		if self.sprites[self.currentSprite] then
			self.sprites[self.currentSprite]:wheelmoved(x,y)
		end
		self.timeline.mousefield:wheelmoved(x,y)
		self.mousefield:wheelmoved(x,y)
	end
end

function Animations:resize(w,h)
	self:setupWindows()
end

return Animations()
