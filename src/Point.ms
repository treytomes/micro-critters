Point = {}

Point.make = function(x, y)
	self = new Point
	self.x = x
	self.y = y
	return self
end function

Point.zero = function
	return self.make(0, 0)
end function

Point.unitX = function
	return self.make(1, 0)
end function

Point.unitY = function
	return self.make(0, 1)
end function

Point.str = function
	return "({0},{1})".fill([ self.x, self.y ])
end function

Point.equals = function(other)
	return self.x == other.x and self.y == other.y
end function

Point.multiply = function(n)
	return self.make(n * self.x, n * self.y)
end function

Point.negate = function
	return self.make(-self.x, -self.y)
end function

Point.add = function(pnt)
	return self.make(self.x + pnt.x, self.y + pnt.y)
end function

Point.subtract = function(pnt)
	return self.make(self.x - pnt.x, self.y - pnt.y)
end function

Point.sign = function(pnt)
	return self.make(sign(self.x), sign(self.y))
end function

Point.scale = function(v)
	return self.make(v * self.x, v * self.y)
end function

Point.floor = function
	return self.make(floor(self.x), floor(self.y))
end function

Point.length = function
	return sqrt(self.x * self.x + self.y * self.y)
end function

return Point
