WorldAction = {}

WorldAction.make = function(entity, action)
	self = new WorldAction
	self.entity = entity
	self.action = action
	return self
end function

return WorldAction
