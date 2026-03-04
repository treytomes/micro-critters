Chunk = {}

Chunk.make = function(worldX, worldY, worldZ)
	self = new Chunk
	
	self.worldX = worldX
	self.worldY = worldY
	self.worldZ = worldZ

	self.width = CHUNK_WIDTH
	self.height = CHUNK_HEIGHT

	self.tileSet = {}

	self.tiles = []
	self.metadata = []
	for y in range(0, self.height - 1)
		t_row = []
		m_row = []
		for x in range(0, self.width - 1)
			t_row.push 0
			m_row.push {}
		end for
		self.tiles.push t_row
		self.metadata.push m_row
	end for

	// Build a simple map.

	for y in range(0, self.height - 1)
		for x in range(0, self.width - 1)
			self.setTile x, y, "floor"
		end for
	end for
	for y in range(0, self.height - 1)
		self.setTile 0, y, "wall"
		self.setTile self.width - 1, y, "wall"
	end for
	for x in range(0, self.width - 1)
		self.setTile x, 0, "wall"
		self.setTile x, self.height - 1, "wall"
	end for

	return self
end function

Chunk.render = function(tileDisplay)
	tileSet = TileSet.fromTiles(self.tileSet.values)
	tileDisplay.tileSet = tileSet.image
	tileDisplay.tileSetTileSize = [tileSet.tileWidth, tileSet.tileHeight]  // size of each tile in the image
	tileDisplay.cellSize = tileDisplay.tileSetTileSize
	tileDisplay.extent = [self.width, self.height]

	for y in range(0, self.height - 1)
		for x in range(0, self.width - 1)
			tileDisplay.setCell x, y, self.tiles[y][x]
		end for
	end for
end function

Chunk.setTile = function(x, y, tileName)
	tile = self.loadTile(tileName)
	metadata = self.getMetadata(tileName)
	self.tiles[y][x] = tile
	self.metadata[y][x] = metadata
end function

Chunk.loadTile = function(tileName)
	if not self.tileSet.hasIndex(tileName) then
		tile = AssetFactory.loadTile(tileName)
		self.tileSet[tileName] = tile
	end if
	return self.tileSet.indexes.indexOf(tileName)
end function

Chunk.getMetadata = function(tileName)
	result = {}
	data = self.loadTile(tileName)
	for kv in data
		if kv.key[0].startsWith("_") then continue
		if kv.key != "image" and not kv.key.contains("Color") then
			result[kv.key] = Dice.parse(kv.value)
		else
			result[kv.key] = kv.value
		end if
	end for
end function

return Chunk
