ASSET_ROOT = "/usr/assets/"

assets = {}
animations = {}

normalizePath = function(path)
	return outer.ASSET_ROOT + path
end function

loadImage = function(path)
	path = normalizePath(path)
	if assets.hasIndex(path) then
		return assets[path]
	end if

	result = file.loadImage(path)
	assets[path] = result
	return result
end function

loadTileSet = function(path)
	path = normalizePath(path)
	if assets.hasIndex(path) then
		return assets[path]
	end if

	result = TileSet.fromJson(path)
	assets[path] = result
	return result
end function

loadTile = function(path)
	path = normalizePath(path)
	if assets.hasIndex(path) then
		return assets[path]
	end if

	qa.assert(file.exists(path), "'" + path + "' does not exist.")

	result = json.parse(file.open(path).read)
	tileSet = loadTileSet(result.tileSet)
	imageTile = tileSet.getTile(result.tileIndex)
	assets[path] = imageTile
	return imageTile
end function

loadAnimation = function(path)
	path = normalizePath(path)
	if animations.hasIndex(path) then
		return animations[path]
	end if

	qa.assert(file.exists(path), "'" + path + "' does not exist.")
	anim = Animation.fromJson(path)
	animations[path] = anim
	return anim
end function

loadAnimationSet = function(path)
	path = normalizePath(path)
	if assets.hasIndex(path) then
		return assets[path]
	end if

	qa.assert(file.exists(path), "'" + path + "' does not exist.")
	set = AnimationSet.fromJson(path)
	assets[path] = set
	return set
end function

updateAnimations = function(deltaTime)
	n = 0
	anims = animations.values
	while n < len(anims)
		anim = anims[n]
		anim.update deltaTime
		n += 1
	end while
end function
