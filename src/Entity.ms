make = function
	self = new Entity
	self.currentState = "still"
	self.currentEnergy = 0

	// Race and class attributes applied after construction...?
	self.constitution = 0
	
	self.maxEnergy = 100
	self.animations = person
	self.animations.setCurrent self.currentState
	self.sprite = new Sprite
	self.sprite.image = self.animations.getImage
	self.sprite.x = 0
	self.sprite.y = 0

	// This is where the AI gets stuffed.  Player input is a type of "AI".  Sorry.
	self.behaviors = []

	return self
end function

addToDisplay = function(dsp)
	qa.assert self.sprite != null
	dsp.sprites.push self.sprite
end function

moveTo = function(tx, ty)
	self.sprite.x = tx * self.sprite.image.width
	self.sprite.y = ty * self.sprite.image.height
end function

moveBy = function(dtx, dty)
	self.sprite.x += dtx * self.sprite.image.width
	self.sprite.y += dty * self.sprite.image.height
end function

getTileX = function
	return floor(self.sprite.x / self.sprite.image.width)
end function

getTileY = function
	return floor(self.sprite.y / self.sprite.image.height)
end function

// @returns {WorldAction[]} A list of actions to add to the world queue.
update = function(deltaTime)
	n = 0
	actions = []
	while n < len(self.behaviors)
		b = self.behaviors[n]
		act = b.update(self, deltaTime)
		if act != null then
			actions.push act
		end if
		n += 1
	end while

	self.animations.setCurrent self.currentState
	self.sprite.image = self.animations.getImage
	self.currentEnergy = mathUtil.min(self.maxEnergy, self.currentEnergy + deltaTime * self.constitution * CONSTITUTION_ENERGY_FACTOR)

	return actions
end function
