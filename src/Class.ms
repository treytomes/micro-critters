Class = {}

Class.fromJson = function(path)
	self = new Race
	jsonText = file.open(path).read
	result = json.parse(jsonText)
	for kv in result
		if kv.key[0].startsWith("_") then continue
		if kv.key != "name" and kv.value isa string then
			self[kv.key] = Dice.parse(kv.value)
		else
			self[kv.key] = kv.value
		end if
	end for
	return self
end function

Class.roll = function
	result = {}
	for kv in self
		if kv.key[0].startsWith("_") then continue
		if kv.value isa Dice then
			result[kv.key] = kv.value.roll
		else
			result[kv.key] = kv.value
		end if
	end for
	return result
end function

Class.apply = function(entity)
	entity.className = self.name

	results = self.roll
	for kv in results
		if kv.key == "name" then continue
		entity[kv.key] += kv.value
	end for

	return entity
end function

return Class
