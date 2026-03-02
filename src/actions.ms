Action = {}
Action.cost = 0

Action.canExecute = function(entity)
	return true
end function

Action.execute = function(entity)
end function

// TODO: Add an undo?  Could get interesting, or maybe just hairy.

////////////////////////////////////////////////////////////

MoveAction = new Action
MoveAction.cost = 100

MoveAction.make = function(dx, dy)
	self = new MoveAction
	self.dx = dx
	self.dy = dy
	self.cost = self.cost * sqrt(dx * dx + dy * dy)
	return self
end function

MoveAction.canExecute = function(entity)
	return entity.currentEnergy >= self.cost
end function

MoveAction.execute = function(entity)
	entity.currentState = "moving"
	entity.moveBy self.dx, self.dy
	entity.currentEnergy -= self.cost
end function

move = function(dx, dy)
	return MoveAction.make(dx, dy)
end function
