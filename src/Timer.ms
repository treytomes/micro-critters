make = function(totalTime)
	self = new Timer
	self.totalTime = totalTime
	self.remainingTime = totalTime
	return self
end function

update = function(deltaTime)
	self.remainingTime -= deltaTime
end function

reset = function
	self.remainingTime = self.totalTime
end function

isTriggered = function
	return self.remainingTime <= 0
end function
