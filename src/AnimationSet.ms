make = function
	self.animations = {}
	self.currentAnimation = ""
	return self
end function

fromJson = function(path)
	jsonText = file.open(path).read
	result = json.parse(jsonText)
	keys = result.indexes

	set = AnimationSet.make
	
	n = 0
	while n < len(keys)
		key = keys[n]
		set.add key, result[key]
		n += 1
	end while

	set.setCurrent keys[0]
	return set
end function

add = function(name, path)
	self.animations[name] = AssetFactory.loadAnimation(path)
end function

setCurrent = function(name)
	self.currentAnimation = name
end function

getImage = function
	anim = self.animations.values[0]
	if self.animations.hasIndex(self.currentAnimation) then
		anim = self.animations[self.currentAnimation]
	end if
	return anim.getImage
end function
