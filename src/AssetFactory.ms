AssetFactory = {}

AssetFactory.TYPE_MAP = {}
AssetFactory.TYPE_MAP.Animation = "animations"
AssetFactory.TYPE_MAP.AnimationSet = "animationSets"
AssetFactory.TYPE_MAP.Class = "classes"
AssetFactory.TYPE_MAP.Image = "images"
AssetFactory.TYPE_MAP.Race = "races"
AssetFactory.TYPE_MAP.Tile = "tiles"
AssetFactory.TYPE_MAP.TileSet = "tileSets"

AssetFactory.EXT_MAP = {}
AssetFactory.EXT_MAP.default = "json"
AssetFactory.EXT_MAP.Image = "png"

AssetFactory.assets = {}
AssetFactory.animations = {}

// Normalize the type name to type path.
// If the parameter isn't recognized, it will simply be returned.
//
// @param {string} type The type name or path segment.
// @returns {string} The normalized path segment.
AssetFactory.normalizeType = function(type)
	return AssetFactory.TYPE_MAP.get(type, type)
end function

// Normalize the file extension on a path.
// The default extension will be applied if one does not exist.
//
// @param {string} path The file path.
// @param {string} type The data type.
// @returns {string} The normalized path.
AssetFactory.normalizeExtension = function(path, type)
	if path.contains(".") then return path
	ext = AssetFactory.EXT_MAP.get(type, AssetFactory.EXT_MAP.default)
	return path + "." + ext
end function

// Normalize the asset path.
// Apply the asset root if it's not already there.
// Apply the asset type if it's not already there.
// Apply the asset extension if it's not already there.
// Verify that the path actually exists.
//
// @param {string} path The relative asset path.
// @param {string} type The type name of the asset.
// @returns {string} The complete asset path.
AssetFactory.normalizePath = function(path, type)
	typePath = self.normalizeType(type)

	if not path.startsWith(ASSET_ROOT) then
		if not path.startsWith(type) then
			path = typePath + "/" + path
		end if
		path = ASSET_ROOT + path
	end if

	path = self.normalizeExtension(path, type)
	
	qa.assert(file.exists(path), "'{path}' does not exist.".fill({ "path": path }))
	return path
end function

AssetFactory.loadImage = function(path)
	path = self.normalizePath(path, "Image")
	if self.assets.hasIndex(path) then
		return self.assets[path]
	end if

	result = file.loadImage(path)
	self.assets[path] = result
	return result
end function

AssetFactory.loadTileSet = function(path)
	path = self.normalizePath(path, "TileSet")
	if self.assets.hasIndex(path) then
		return self.assets[path]
	end if

	result = TileSet.fromJson(path)
	self.assets[path] = result
	return result
end function

AssetFactory.loadTile = function(path)
	path = self.normalizePath(path, "Tile")
	if self.assets.hasIndex(path) then
		return self.assets[path]
	end if

	result = Tile.fromJson(path)
	self.assets[path] = result
	return result
end function

AssetFactory.loadAnimation = function(path)
	path = self.normalizePath(path, "Animation")
	if self.animations.hasIndex(path) then
		return self.animations[path]
	end if

	anim = Animation.fromJson(path)
	self.animations[path] = anim
	return anim
end function

AssetFactory.loadAnimationSet = function(path)
	path = self.normalizePath(path, "AnimationSet")
	if self.assets.hasIndex(path) then
		return self.assets[path]
	end if

	set = AnimationSet.fromJson(path)
	self.assets[path] = set
	return set
end function

AssetFactory.loadRace = function(path)
	path = self.normalizePath(path, "Race")
	if self.assets.hasIndex(path) then
		return self.assets[path]
	end if

	result = Race.fromJson(path)
	self.assets[path] = result
	return result
end function

AssetFactory.loadClass = function(path)
	path = self.normalizePath(path, "Class")
	if self.assets.hasIndex(path) then
		return self.assets[path]
	end if

	result = Class.fromJson(path)
	self.assets[path] = result
	return result
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
