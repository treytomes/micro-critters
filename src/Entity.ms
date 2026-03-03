Entity = {}

Entity.make = function(animationSet)
	self = new Entity
	self.currentState = "still"
	self.currentEnergy = 0
	self.maxEnergy = 100

	// Race and class attributes applied after construction...?
	self.constitution = 0
	
	self.animations = animationSet
	self.animations.setCurrent self.currentState
	self.sprite = new Sprite
	self.sprite.image = self.animations.getImage
	self.sprite.x = 0
	self.sprite.y = 0

	// This is where the AI gets stuffed.  Player input is a type of "AI".  Sorry.
	self.behaviors = []

	return self
end function

Entity.toSerializable = function
	result = {}
	result.currentState = self.currentState
	result.currentEnergy = self.currentEnergy
	result.maxEnergy = self.maxEnergy
	result.constitution = self.constitution
	result.animationSet = self.animations.path
	result.tileX = floor(self.sprite.x / self.sprite.image.width)
	result.tileY = floor(self.sprite.y / self.sprite.image.height)

	result.behaviors = []
	n = 0
	while n < len(self.behaviors)
		b = self.behaviors[n]
		result.behaviors.push b.toSerializable
		n += 1
	end while

	return result
end function

Entity.fromSerializable = function(data)
	animationSet = AssetFactory.loadAnimationSet(data.animationSet)
	self = self.make(animationSet)
	self.currentState = data.currentState
	self.currentEnergy = data.currentEnergy
	self.maxEnergy = data.maxEnergy
	self.constitution = data.constitution
	self.moveTo(data.tileX, data.tileY)

	n = 0
	while n < len(data.behaviors)
		b = behaviors.fromSerializable(data.behaviors[n])
		self.behaviors.push b
		n += 1
	end while

	return self
end function

Entity.addToDisplay = function(dsp)
	qa.assert self.sprite != null
	dsp.sprites.push self.sprite
end function

Entity.moveTo = function(tx, ty)
	self.sprite.x = tx * self.sprite.image.width
	self.sprite.y = ty * self.sprite.image.height
end function

Entity.moveBy = function(dtx, dty)
	self.sprite.x += dtx * self.sprite.image.width
	self.sprite.y += dty * self.sprite.image.height
end function

Entity.getTileX = function
	return floor(self.sprite.x / self.sprite.image.width)
end function

Entity.getTileY = function
	return floor(self.sprite.y / self.sprite.image.height)
end function

// @returns {WorldAction[]} A list of actions to add to the world queue.
Entity.update = function(deltaTime)
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

return Entity
