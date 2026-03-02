fromImage = function(image)
	self = new Animation()
	self.frames = [image]
	self.frameIndex = 0
	self.updateSpeed = 0
	self.lastUpdateTime = 0
	return self
end function

fromImageSet = function(imageSet, updateSpeed)
	self = new Animation()
	self.frames = imageSet
	self.frameIndex = 0
	self.updateSpeed = updateSpeed
	self.lastUpdateTime = 0
	return self
end function

fromJson = function(jsonPath)
	jsonText = file.open(jsonPath).read
	result = json.parse(jsonText)

	updateSpeed = result.updateSpeed
	tiles = []
	for tilePath in result.frames
		tile = AssetFactory.loadTile(tilePath)
		tiles.push tile
	end for

	return self.fromImageSet(tiles, updateSpeed)
end function

update = function(deltaTime)
	self.lastUpdateTime += deltaTime
	if self.lastUpdateTime >= self.updateSpeed then
		self.lastUpdateTime -= self.updateSpeed
		self.frameIndex += 1
		if self.frameIndex >= len(self.frames) then
			self.frameIndex = 0
		end if
	end if
end function

getImage = function
	return self.frames[self.frameIndex]
end function
