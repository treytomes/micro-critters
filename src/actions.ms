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
		// There's some chance that the entity will transition into an unwalkable position.  Maybe that's okay for now?
        return true
    end if

    // Collision check using chunk metadata bits
    if chunk.blocksMovementAt(tx, ty) then
		// TODO: Some kind of event or notification if the entity bumps into a wall.
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
