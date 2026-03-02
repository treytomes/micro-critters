numDice = 1
numSides = 6
modifier = 0

make = function(numDice, numSides, modifier = 0)
	d = new Dice
	d.numDice = numDice
	d.numSides = numSides
	d.modifier = modifier
	return d
end function

zero = function()
	return Dice.make(0, 0)
end function

const = function(value)
	return Dice.make(0, 0, value)
end function

roll = function()
	if self.numDice == 0 then
		return self.modifier
	end if

	sum = 0
	for n in range(self.numDice)
		sum += floor(rnd() * self.numSides) + 1
	end for
	return sum + self.modifier
end function

str = function()
	if features.USE_DICE_NOTATION then
		return self.numDice + "d" + self.numSides + "+" + self.modifier
	else
		return self.min  + "-" + self.max
	end if
end function

min = function()
	return self.numDice + self.modifier
end function

max = function()
	return self.numDice * self.numSides + self.modifier
end function