AnimationSet = {}

AnimationSet.animations = {}
AnimationSet.currentAnimation = ""
AnimationSet.path = ""

AnimationSet.fromJson = function(path)
	jsonText = file.open(path).read
	result = json.parse(jsonText)
	keys = result.indexes

	self = new AnimationSet
	self.path = path
	
	n = 0
	while n < len(keys)
		key = keys[n]
		self.add key, result[key]
		n += 1
	end while

	self.setCurrent keys[0]
	return self
end function

AnimationSet.add = function(name, path)
	self.animations[name] = AssetFactory.loadAnimation(path)
end function

AnimationSet.setCurrent = function(name)
	self.currentAnimation = name
end function

AnimationSet.getImage = function
	anim = self.animations.values[0]
	if self.animations.hasIndex(self.currentAnimation) then
		anim = self.animations[self.currentAnimation]
	end if
	return anim.getImage
end function

return AnimationSet
