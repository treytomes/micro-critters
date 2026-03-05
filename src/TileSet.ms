TileSet = {}

TileSet.make = function(image, tileWidth, tileHeight)
	self = new TileSet
	self.image = image
	self.tileWidth = tileWidth
	self.tileHeight = tileHeight
	self.tiles = []
	self.len = floor(self.image.width / self.tileWidth) * floor(self.image.height / self.tileHeight)
	return self
end function

TileSet.fromTiles = function(tiles)
	pd = new PixelDisplay
	pd.clear 

	self = new TileSet
	self.tileWidth = tiles[0].width
	self.tileHeight = tiles[0].height
	self.tiles = []

	width = self.tileWidth * len(tiles)
	height = self.tileHeight
	pd.clear color.black, width, height
	
	x = 0
	for tile in tiles
		img = tile.image
		qa.assert img.width == self.tileWidth and img.height == self.tileHeight, "Tile sizes must match."
		pd.drawImage img, x, 0, self.tileWidth, self.tileHeight

		x += self.tileWidth
	end for
	
	self.image = pd.getImage(0, 0, width, height)
	self.len = floor(self.image.width / self.tileWidth) * floor(self.image.height / self.tileHeight)
	return self
end function

TileSet.fromJson = function(jsonPath)
	qa.assert file.exists(jsonPath), "'" + jsonPath + "' does not exist."
	jsonText = file.open(jsonPath).read
	result = json.parse(jsonText)
	image = AssetFactory.loadImage(result.imagePath)
	return self.make(image, result.tileWidth, result.tileHeight)
end function

TileSet.getTile = function(tileIndex)
	qa.assert tileIndex >= 0 and tileIndex < self.len, "tileIndex {n} out of range({len})".fill({ "n": tileIndex, "len": len(self.len) })
	tilesPerRow = floor(self.image.width / self.tileWidth)
	tileX = (tileIndex % tilesPerRow) * self.tileWidth
	tileY = self.image.height - (floor(tileIndex / tilesPerRow) * self.tileHeight + self.tileHeight)
	return self.image.getImage(tileX, tileY, self.tileWidth, self.tileHeight)
end function

return TileSet
