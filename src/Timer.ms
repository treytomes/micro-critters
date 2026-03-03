Timer = {}

Timer.make = function(totalTime)
	self = new Timer
	self.totalTime = totalTime
	self.remainingTime = totalTime
	return self
end function

Timer.update = function(deltaTime)
	self.remainingTime -= deltaTime
end function

Timer.reset = function
	self.remainingTime = self.totalTime
end function

Timer.isTriggered = function
	return self.remainingTime <= 0
end function

return Timer
