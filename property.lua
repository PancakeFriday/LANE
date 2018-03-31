local Property = Object:extend()

function Property:new(posx, posy, col, row)
	self.pos = {x=posx, y=posy}
	self.scale = {x=1,y=1}
	self.rot=0
	self.color={r=255,g=255,b=255,a=255}
	self.col, self.row = col, row
end

function Property.getInterpolated(time, ltime, utime, p1, p2)
	local h = function(a,b)
		return a + (b-a)/(utime - ltime) * (time-ltime)
	end
	local pos = {x=h(p1.pos.x,p2.pos.x), y=h(p1.pos.y,p2.pos.y)}
	local scale = {x=h(p1.scale.x,p2.scale.x), y=h(p1.scale.y,p2.scale.y)}
	local rot = h(p1.rot, p2.rot)
	local color = {
		r=h(p1.color.r, p2.color.r),
		g=h(p1.color.g, p2.color.g),
		b=h(p1.color.b, p2.color.b),
		a=h(p1.color.a, p2.color.a)
	}
	local prop = Property(pos.x, pos.y, p1.col, p1.row)
	prop.scale = scale
	prop.rot = rot
	prop.color = color
	return prop
end

function Property:copy(conv)
	conv = conv or tonumber
	local t = Property(1,1,1,1)
	t.pos.x = conv(self.pos.x)
	t.pos.y = conv(self.pos.y)
	t.scale.x = conv(self.scale.x)
	t.scale.y = conv(self.scale.y)
	t.rot = conv(self.rot)
	t.color = {r=conv(self.color.r), g=conv(self.color.g), b=conv(self.color.b), a=conv(self.color.a)}
	t.row, t.col = conv(self.row), conv(self.col)
	return t
end

return Property
