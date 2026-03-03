TileSet = {}

TileSet.make = function(image, tileWidth, tileHeight)
	self = new TileSet
	self.image = image
	self.tileWidth = tileWidth
	self.tileHeight = tileHeight
	self.tiles = []
	self.len = floor(image.width / tileWidth) * floor(image.height / tileHeight)
	return self
end function

TileSet.fromJson = function(jsonPath)
	qa.assert(file.exists(jsonPath), "'" + jsonPath + "' does not exist.")
	jsonText = file.open(jsonPath).read
	result = json.parse(jsonText)
	image = AssetFactory.loadImage(result.imagePath)
	return self.make(image, result.tileWidth, result.tileHeight)
end function

TileSet.getTile = function(tileIndex)
	qa.assert(tileIndex >= 0 and tileIndex < self.len)
	tilesPerRow = floor(self.image.width / self.tileWidth)
	tileX = (tileIndex % tilesPerRow) * self.tileWidth
	tileY = floor(tileIndex / tilesPerRow) * self.tileHeight
	return self.image.getImage(tileX, tileY, self.tileWidth, self.tileHeight)
end function

return TileSet
