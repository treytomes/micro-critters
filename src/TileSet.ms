TileSet = {}

TileSet.make = function(image, tileWidth, tileHeight)
	self = new TileSet
	self.image = image
	self.tileWidth = tileWidth
	self.tileHeight = tileHeight
	self.tiles = []
	self.len = floor(self.image.width / self.tileWidth) * floor(self.image.height / self.tileHeight)
	for n in range(0, self.len - 1)
		self.tiles.push null
	end for
	return self
end function

TileSet.fromTiles = function(tiles)
	self = new TileSet
	self.tileWidth = tiles[0].width
	self.tileHeight = tiles[0].height
	self.tiles = tiles
	self.tileNames = {}
	for n in range(0, len(self.tiles) - 1)
		tile = self.tiles[n]
		name = tile.name
		self.tileNames[name] = n
	end for

	width = self.tileWidth * len(tiles)
	height = self.tileHeight
	pd = new PixelDisplay
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
	if result isa map then
		image = AssetFactory.loadImage(result.imagePath)
		return self.make(image, result.tileWidth, result.tileHeight)
	else if result isa list then
		tiles = []
		for path in result
			t = AssetFactory.loadTile(path)
			tiles.push t
		end for
		return self.fromTiles(tiles)
	else
		qa.assert false, "Unknown file format: " + jsonPath
	end if
end function

TileSet.getTile = function(tileIndex)
	if tileIndex isa number then
		qa.assert tileIndex >= 0 and tileIndex < self.len, "tileIndex {n} out of range({len})".fill({ "n": tileIndex, "len": len(self.len) })
		if self.tiles[tileIndex] == null then
			tilesPerRow = floor(self.image.width / self.tileWidth)
			tileX = (tileIndex % tilesPerRow) * self.tileWidth
			tileY = self.image.height - (floor(tileIndex / tilesPerRow) * self.tileHeight + self.tileHeight)
			self.tiles[tileIndex] = self.image.getImage(tileX, tileY, self.tileWidth, self.tileHeight)
		end if
		return self.tiles[tileIndex]
	else if tileIndex isa string then
		qa.assert self.tileNames.hasIndex(index), "Tile name '" + index + "' is not defined."
		index = self.tileNames[tileIndex]
		tile = self.tiles[index]
		return tile
	else
	end if
end function

return TileSet
