AssetFactory = {}

AssetFactory.assets = {}
AssetFactory.animations = {}

AssetFactory.normalizePath = function(path)
	if path.startsWith(ASSET_ROOT) then
		return path
	end if
	return ASSET_ROOT + path
end function

AssetFactory.loadImage = function(path)
	path = self.normalizePath(path)
	if self.assets.hasIndex(path) then
		return self.assets[path]
	end if

	result = file.loadImage(path)
	self.assets[path] = result
	return result
end function

AssetFactory.loadTileSet = function(path)
	path = self.normalizePath(path)
	if self.assets.hasIndex(path) then
		return self.assets[path]
	end if

	result = TileSet.fromJson(path)
	self.assets[path] = result
	return result
end function

AssetFactory.loadTile = function(path)
	path = self.normalizePath(path)
	if self.assets.hasIndex(path) then
		return self.assets[path]
	end if

	qa.assert(file.exists(path), "'" + path + "' does not exist.")

	result = json.parse(file.open(path).read)
	tileSet = self.loadTileSet(result.tileSet)
	imageTile = tileSet.getTile(result.tileIndex)
	self.assets[path] = imageTile
	return imageTile
end function

AssetFactory.loadAnimation = function(path)
	path = self.normalizePath(path)
	if self.animations.hasIndex(path) then
		return self.animations[path]
	end if

	qa.assert(file.exists(path), "'" + path + "' does not exist.")
	anim = Animation.fromJson(path)
	self.animations[path] = anim
	return anim
end function

AssetFactory.loadAnimationSet = function(path)
	path = self.normalizePath(path)
	if self.assets.hasIndex(path) then
		return self.assets[path]
	end if

	qa.assert(file.exists(path), "'" + path + "' does not exist.")
	set = AnimationSet.fromJson(path)
	self.assets[path] = set
	return set
end function

AssetFactory.updateAnimations = function(deltaTime)
	n = 0
	lst = self.animations.values
	while n < len(lst)
		anim = lst[n]
		anim.update deltaTime
		n += 1
	end while
end function

return AssetFactory
