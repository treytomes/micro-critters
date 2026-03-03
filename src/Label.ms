Label = {}

Label.make = function(text, row, column, width)
	self = new Label
	self.text = text
	self.row = row
	self.column = column
	self.width = width
	return self
end function

Label.draw = function(fillObj)
	text.row = self.row
	text.column = self.column
	print self.text.fill(fillObj).pad(self.width)
end function

return Label
