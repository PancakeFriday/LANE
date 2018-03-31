local Property = require "property"
require "spriteeditor"

-- http://www.love2d.org/forums/viewtopic.php?t=11839
-- accepts point and angle in radians
local function change_angle ( x, y, a )
  local cd = math.cos ( a )
  local sd = math.sin ( a )
  return cd*x - sd*y, cd*y + sd*x
end

-- accepts a point (x, y), aabb center (rx, ry), aabb half-width/half-height (hw, hh) and an angle in radians (a)
local function point_vs_raabb ( x, y, rx, ry, hw, hh, a )
  -- translate point to aabb origin
  local lx, ly = x - rx, y - ry
  -- rotate point
  lx, ly = change_angle ( lx, ly, a )

  -- perform regular point vs aabb test
  if lx < -hw or lx > hw then
     return false
  end
  if ly < -hh or ly > hh then
     return false
  end
  return true
end


local Animation = Object:extend()

function Animation:new(sprites)
	-- This is what the keys table is supposed to look like
	--[[
	{
		1 = {
			name=...
			frames={
				"0.1"={
					spritehash=...
					properties=...
				},
				"0.5"={
					spritehash=...
					properties=...
				}
			}
		},
		2 = {

		}
	}
	]]--
	self.sprites = sprites
	self.keys = {}
	self.maxTime = 3
end

function Animation.loadData(d, sprites)
	local a = Animation(sprites)
	a.keys = d.keys
	for i, key in pairs(a.keys) do
		for time, value in pairs(key.frames) do
			setmetatable(value.properties, Property)
		end
	end

	return a
end

function Animation:getData()
	local t = {keys=self.keys,maxTime=self.maxTime}
	return t
end

function Animation:findKey(name)
	for i,v in pairs(self.keys) do
		if v.name == name then
			return i
		end
	end
end

function Animation:deleteKey(value)
	for i,v in pairs(self.keys) do
		local time = lume.find(v.frames, value)
		if time then
			v.frames[time] = nil
			if lume.count(v.frames) == 0 then
				self.keys[i] = nil
			end
			break
		end
	end
end

function Animation:getBaseKey(value)
	for i,v in pairs(self.keys) do
		if lume.find(v.frames, value) then
			return v
		end
	end
end

function Animation:addKey(name, time, spritehash, properties)
	local ind = self:findKey(name)
	if not ind then
		table.insert(self.keys, {
			name=name,
			frames={}
		})
		ind = #self.keys
	end
	self.keys[ind].frames[tostring(time)] = {
		spritehash = spritehash,
		properties=properties
	}
	return self.keys[ind].frames[tostring(time)]
end

function Animation:getMaxLayer()
	return #self.keys
end

function Animation:isValid(key)
	local quads = self.sprites[key.spritehash].quads
	local props = key.properties
	return quads[props.col] ~= nil and quads[props.col][props.row] ~= nil
end

function Animation:copyToTime(key, time)
	if key then
		local lind, uind = self:getLowerIndex(key, time)
		return self:addKey(key.name,
		time,
		key.frames[lind].spritehash,
		key.frames[lind].properties:copy())
	end
end

function Animation:selectKey(x,y,time)
	-- sort of reversed pairs
	for i=#self.keys, 1, -1 do
		key = self.keys[i]
		local lind, uind = self:getLowerIndex(key, time)
		if lind and self:isValid(key.frames[lind]) then
			local img, quads, props, qw, qh = self:getInterpolatedSprite(key, time, lind, uind)
			if quads[props.col] and quads[props.col][props.row] then
				if point_vs_raabb(x,y,props.pos.x, props.pos.y, qw/2*props.scale.x,qh/2*props.scale.y, -props.rot) then
					return key.frames[lind]
				end
			end
		end
	end
end

function Animation:draw(time)
	for i,key in pairs(self.keys) do
		local lind, uind = self:getLowerIndex(key, time)
		if lind and tonumber(lind) <= tonumber(time) then
			local img, quads, props, qw, qh = self:getInterpolatedSprite(key, time, lind, uind)
			if img then
				love.graphics.setColor(props.color.r, props.color.g, props.color.b, props.color.a)
				love.graphics.draw(img,
					quads[props.col][props.row],
					props.pos.x,
					props.pos.y,
					props.rot,
					props.scale.x,
					props.scale.y,
					qw/2,
					qh/2)
			end
		end
	end

	love.graphics.setColor(255,255,255)
end

function Animation:getQuadDimensions(value)
	local quads = self.sprites[value.spritehash].quads
	if not quads then
		return nil
	end
	local props = value.properties
	if not quads[props.col] or not quads[props.col][props.row] then
		return nil
	end
	local _, _, qw, qh = quads[props.col][props.row]:getViewport()
	return qw, qh
end

function Animation:getInterpolatedSprite(key, time, lind, uind)
	if not uind then
		local img = self.sprites[key.frames[lind].spritehash].img
		local quads = self.sprites[key.frames[lind].spritehash].quads
		local props = key.frames[lind].properties
		if not quads[props.col] or not quads[props.col][props.row] then
			return nil
		end
		local _, _, qw, qh = quads[props.col][props.row]:getViewport()
		return img, quads, props, qw, qh
	else
		local img = self.sprites[key.frames[lind].spritehash].img
		local quads = self.sprites[key.frames[lind].spritehash].quads
		local props = Property.getInterpolated(tonumber(time), tonumber(lind), tonumber(uind), key.frames[lind].properties, key.frames[uind].properties)
		if not quads[props.col] or not quads[props.col][props.row] then
			return nil
		end
		local _, _, qw, qh = quads[props.col][props.row]:getViewport()
		return img, quads, props, qw, qh
	end
end

-- get the index where time > index[time] and time < (index+1)[time] or time == index[time]
function Animation:getLowerIndex(key, time)
	local sort = function(a,b)
		return tonumber(a)<tonumber(b)
	end
	time = tonumber(time)
	local prevktime
	for ktime, value in lume.pairsByKeys(key.frames, sort) do
		if tonumber(ktime) == time then
			return ktime
		elseif tonumber(ktime) > time and prevktime and tonumber(prevktime) < time then
			return prevktime, ktime
		end
		prevktime = ktime
	end

	return prevktime
end

function Animation:shiftLayer(key, dir)
	local pos = lume.find(self.keys,key)
	table.insert(self.keys, pos-dir, table.remove(self.keys,pos))
end

function Animation:getName(values)
	for name,key in pairs(self.keys) do
		if lume.find(key, values) then
			return name
		end
	end
end

function Animation:getNextKeyframe(value)
	local sort = function(a,b)
		return tonumber(a)<tonumber(b)
	end
	for i,v in pairs(self.keys) do
		local time = lume.find(v.frames, value)
		if time then
			for ktime, values in pairs(v.frames) do
				if tonumber(ktime) > tonumber(time) then
					return values, ktime
				end
			end
			-- return lowest key
			for ktime, values in lume.pairsByKeys(v.frames, sort) do
				return values, ktime
			end
		end
	end
end

function Animation:setMaxTime(n)
	self.maxTime = n
end

function Animation:getMaxTime()
	return self.maxTime
end

local AnimationFactory = Object:extend()
AnimationFactory.keySymbol = love.graphics.newImage("symbols/key.png")

function AnimationFactory:new()
	self.current = ""
	self.animations = {}
	self.sprites = {}
end

function AnimationFactory:getData()
	local sprites = {}
	for i,v in pairs(self.sprites) do
		sprites[i] = v:getData()
	end
	local animations = {}
	for i,v in pairs(self.animations) do
		animations[i] = v:getData()
	end

	local t = {
		sprites=sprites,
		animations=animations
	}
	return lume.serialize(t)
end

function AnimationFactory:loadData(d)
	local t = lume.deserialize(d)
	for i,v in pairs(t.sprites) do
		self.sprites[i] = Sprite.loadData(v)
	end
	for i,v in pairs(t.animations) do
		self.animations[i] = Animation.loadData(v, self.sprites)
	end
end

function AnimationFactory:newAnimation(name)
	self.animations[name] = Animation(self.sprites)
end

function AnimationFactory:renameAnimation(name)
	if self.current ~= "" then
		self.animations[name] = self.animations[self.current]
		self.animations[self.current] = nil
	end
end

function AnimationFactory:getAnimations()
	local t = {}
	for i,v in pairs(self.animations) do
		table.insert(t, i)
	end
	return t
end

function AnimationFactory:getKeys()
	if self.current ~= "" then
		return self.animations[self.current].keys
	else
		return {}
	end
end

function AnimationFactory:getNext()
	self.current = ""
	for name,_ in pairs(self.animations) do
		self.current = name
		break
	end
end

function AnimationFactory:getMaxLayer(time)
	if self.current ~= "" then
		return self.animations[self.current]:getMaxLayer(time)
	else
		return 0
	end
end

function AnimationFactory:shiftLayer(values, dir)
	if self.current ~= "" then
		self.animations[self.current]:shiftLayer(values,dir)
	end
end

function AnimationFactory:isValid(key)
	if self.current ~= "" then
		return self.animations[self.current]:isValid(key)
	end
end

function AnimationFactory:selectKey(x,y,time)
	if self.current ~= "" then
		return self.animations[self.current]:selectKey(x,y,time)
	end
end

function AnimationFactory:copyToTime(name, time)
	if self.current ~= "" then
		return self.animations[self.current]:copyToTime(name, time)
	end
end

function AnimationFactory:getNextName()
	return "Sprite"..(lume.count(self.animations[self.current].keys)+1)
end

function AnimationFactory:getName(values)
	if self.current ~= "" then
		return self.animations[self.current]:getName(values)
	end
end

function AnimationFactory:addKey(name, time, sprite, properties)
	if not lume.find(self.sprites, sprite) then
		self.sprites[sprite.hash] = sprite
	end
	return self.animations[self.current]:addKey(name, time, lume.find(self.sprites, sprite), properties)
end

function AnimationFactory:getBaseKey(value)
	if self.current ~= "" then
		return self.animations[self.current]:getBaseKey(value)
	end
end

function AnimationFactory:deleteKey(value)
	if self.current ~= "" then
		self.animations[self.current]:deleteKey(value)
	end
end

function AnimationFactory:removeCurrent()
	self.animations[self.current] = nil
end

function AnimationFactory:setCurrent(name)
	self.current = name
end

function AnimationFactory:getNextKeyframe(value)
	if self.current ~= "" then
		return self.animations[self.current]:getNextKeyframe(value)
	end
end

function AnimationFactory:getCurrent()
	return self.current
end

function AnimationFactory:getQuadDimensions(value)
	if self.current ~= "" then
		return self.animations[self.current]:getQuadDimensions(value)
	end
end

function AnimationFactory:setMaxTime(n)
	if self.current ~= "" then
		self.animations[self.current]:setMaxTime(n)
	end
end

function AnimationFactory:getMaxTime()
	if self.current ~= "" then
		return self.animations[self.current]:getMaxTime()
	end
	return 0
end

function AnimationFactory:draw(time)
	for i,v in pairs(self.animations) do
		v:draw(time)
	end
end

return AnimationFactory
