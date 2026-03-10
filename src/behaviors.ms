Behavior = {}

Behavior.toSerializable = function
	return {}
end function

Behavior.update = function(entity, deltaTime, chunk)
	return null
end function

PlayerInputBehavior = new Behavior

PlayerInputBehavior.make = function
	self = new PlayerInputBehavior
	self.boredTimer = Timer.make(ENTITY_BORED_TIME)
	return self
end function

PlayerInputBehavior.toSerializable = function
	result = {}
	result.name = "PlayerInputBehavior"
	return result
end function

PlayerInputBehavior.update = function(entity, deltaTime, chunk)
	dx = key.axis("Horizontal")
	dy = key.axis("Vertical")
	if dx == 0 and dy == 0 then
		self.boredTimer.update deltaTime
		if self.boredTimer.isTriggered then
			entity.currentState = "bored"
		else
			entity.currentState = "still"
		end if
	else
		action = actions.move(sign(dx), sign(dy))
		if action.canExecute(entity, chunk) then
			self.boredTimer.reset
			return WorldAction.make(entity, action)
		end if
	end if

	return null
end function

playerInput = function
	return PlayerInputBehavior.make
end function

fromSerializable = function(data)
	if data.name == "PlayerInputBehavior" then
		return playerInput
	end if
	qa.assert false, "Unknown behavior name: " + data.name
end function
