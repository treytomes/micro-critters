Action = {}
Action.cost = 0

Action.canExecute = function(entity, chunk)
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

MoveAction.canExecute = function(entity, chunk)
    // Energy check
    if entity.currentEnergy < self.cost then
        return false
    end if

    // Target tile
    tx = entity.getTileX + self.dx
    ty = entity.getTileY + self.dy

    // Bounds check (important, even with chunk transitions)
    if tx < 0 or ty < 0 or tx >= chunk.width or ty >= chunk.height then
        return false
    end if

    // Collision check using chunk metadata bits
    if chunk.blocksMovementAt(tx, ty) then
        return false
    end if

    return true
end function

MoveAction.execute = function(entity)
	entity.currentState = "moving"
	entity.moveBy self.dx, self.dy
	entity.currentEnergy -= self.cost
end function

move = function(dx, dy)
	return MoveAction.make(dx, dy)
end function
