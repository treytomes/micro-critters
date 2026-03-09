Chunk = {}

// ======================================================
// Chunk.make
// Builds a chunk directly from world.generateChunk output,
// then applies local elevation + metadata.
// ======================================================
// @param tileSet {map} Tile set definition.
// @param world {World} The world definition to generate from.
// @param worldX {int} Chunk X coordinate in world space.
// @param worldY {int} Chunk Y coordinate in world space.
// @param worldZ {int} World layer / depth.
// @returns Chunk
// ======================================================
Chunk.make = function(tileSet, world, worldX, worldY, worldZ)
    self = new Chunk

    // --- Basic chunk state ---
    self.worldX = worldX
    self.worldY = worldY
    self.worldZ = worldZ
    self.width = CHUNK_WIDTH      // 64
    self.height = CHUNK_HEIGHT    // 64
    self.tileSet = tileSet

    // --- Allocate tile + metadata grids ---
    self.tiles = []
    self.metadata = []
    for y in range(0, self.height - 1)
        tRow = []
        mRow = []
        for x in range(0, self.width - 1)
            tRow.push 0
            mRow.push {}
        end for
        self.tiles.push tRow
        self.metadata.push mRow
    end for

    // --------------------------------------------------
    // Generate chunk tiles from world
    // --------------------------------------------------
    chunkTiles = world.generateChunk(worldX, worldY)

    // --------------------------------------------------
    // Populate chunk tiles + metadata
    // --------------------------------------------------
    for y in range(0, self.height - 1)
        for x in range(0, self.width - 1)
            i = x + y * self.width

            // World tile index → tile name
            tileIndex = chunkTiles[i]
            tileName = World.TileIndex[tileIndex]

            // Set tile
            self.setTile x, y, tileName

            // // ------------------------------------------
            // // Elevation + micro detail (unchanged logic)
            // // ------------------------------------------
            // // Continuous overworld coordinates
            // owFx = worldX * 4 + (x / self.width) * 4
            // owFy = worldY * 4 + (y / self.height) * 4

            // elev = self.sampleWorldElevation(world, owFx, owFy)

            // detail = PerlinNoise.fractalNoise(
            //     (worldX * self.width + x) * 0.25,
            //     (worldY * self.height + y) * 0.25,
            //     32, 3, 0.5, 1)

            // finalHeight = elev + (detail - 0.5) * 0.2

            // // ------------------------------------------
            // // Metadata
            // // ------------------------------------------
            // meta = self.metadata[y][x]
            // meta.height = finalHeight
            // meta.biome = tileName
            // meta.blocksMovement = (finalHeight > 0.8)
            // meta.walkCost = 1 + abs(detail - 0.5)
        end for
    end for

    return self
end function

// ======================================================
// sampleWorldElevation
// Bilinear sampling of overworld elevation.
// ======================================================
Chunk.sampleWorldElevation = function(overworld, fx, fy)
    // Clamp continuous coordinates to valid overworld range
    fx = mathUtil.clamp(fx, 0, overworld.width - 1.001)
    fy = mathUtil.clamp(fy, 0, overworld.height - 1.001)

    x0 = floor(fx)
    y0 = floor(fy)
    x1 = mathUtil.min(x0 + 1, overworld.width - 1)
    y1 = mathUtil.min(y0 + 1, overworld.height - 1)

    sx = fx - x0
    sy = fy - y0

    i00 = x0 + y0 * overworld.width
    i10 = x1 + y0 * overworld.width
    i01 = x0 + y1 * overworld.width
    i11 = x1 + y1 * overworld.width

    e00 = overworld.elevation[i00]
    e10 = overworld.elevation[i10]
    e01 = overworld.elevation[i01]
    e11 = overworld.elevation[i11]

    e0 = e00 * (1 - sx) + e10 * sx
    e1 = e01 * (1 - sx) + e11 * sx
    return e0 * (1 - sy) + e1 * sy
end function

// ======================================================
// applyOverworldTile
// Maps overworld biome tiles to chunk tiles.
// ======================================================
Chunk.applyOverworldTile = function(x, y, owTileName)
    if owTileName == "deepWater" then
        self.setTile x, y, "waterDeep"
    else if owTileName == "shallowWater" then
        self.setTile x, y, "waterShallow"
    else if owTileName == "river" then
        self.setTile x, y, "river"
    else if owTileName == "sand" then
        self.setTile x, y, "sand"
    else if owTileName == "grass" then
        self.setTile x, y, "grass"
    else if owTileName == "tree" then
        self.setTile x, y, "grass"
        self.metadata[y][x].treeBias = 1.0
    else if owTileName == "rock" then
        self.setTile x, y, "wall"
    end if
end function

// Chunk.toSerializable = function
// 	result = {}
// 	result.worldX = self.worldX
// 	result.worldY = self.worldY
// 	result.worldZ = self.worldZ

// 	result.width = self.width
// 	result.height = self.height

// 	result.tiles = self.tiles
// 	result.metadata = self.metadata

// 	return result
// end function

// Chunk.fromSerializable = function(tileSet, data)
//     self = new Chunk

//     self.worldX = data.worldX
//     self.worldY = data.worldY
//     self.worldZ = data.worldZ
    
//     self.width = data.width
//     self.height = data.height

//     self.tileSet = tileSet

//     self.tiles = data.tiles
//     self.metadata = data.metadata
//     return self
// end function

Chunk.saveChunk = function
	// path = "/usr/chunk_{worldX}_{worldY}_{worldZ}.json".fill(self)
    // data = self.toSerializable
	// file.writeLines path, json.toJSON(data)

    writer = RawFileWriter.make
    writer.writeInt self.worldX
    writer.writeInt self.worldY
    writer.writeInt self.worldZ
    writer.writeInt self.width
    writer.writeInt self.height

    for y in range(0, self.height - 1)
        for x in range(0, self.width - 1)
            writer.writeInt self.tiles[y][x]
        end for
    end for

    for y in range(0, self.height - 1)
        for x in range(0, self.width - 1)
            writer.writeInt self.metadata[y][x]
        end for
    end for
    
    path = "/usr/chunk_{worldX}_{worldY}_{worldZ}.raw".fill(self)
    writer.save path

    return path
end function

Chunk.loadChunk = function(tileSet, worldX, worldY, worldZ)
	// path = "/usr/chunk_{0}_{1}_{2}.json".fill([ worldX, worldY, worldZ ])
    // qa.assert file.exists(path), "'" + path +"' does not exist."
    // jsonText = file.open(path).read
	// result = json.parse(jsonText)
    // return self.fromSerializable(tileSet, result)

	path = "/usr/chunk_{0}_{1}_{2}.raw".fill([ worldX, worldY, worldZ ])
    qa.assert file.exists(path), "'" + path +"' does not exist."
    reader = RawFileReader.read(path)

    self = new Chunk

    // --- Basic chunk state ---
    self.worldX = reader.readInt
    self.worldY = reader.readInt
    self.worldZ = reader.readInt
    self.width = reader.readInt
    self.height = reader.readInt
    self.tileSet = tileSet

    // --- Allocate tile + metadata grids ---
    self.tiles = []
    self.metadata = []
    for y in range(0, self.height - 1)
        tRow = []
        mRow = []
        for x in range(0, self.width - 1)
            tRow.push 0
            mRow.push {}
        end for
        self.tiles.push tRow
        self.metadata.push mRow
    end for

    // Load the tiles.
    for y in range(0, self.height - 1)
        for x in range(0, self.width - 1)
            self.tiles[y][x] = reader.readInt
        end for
    end for

    // Load the metadata.
    for y in range(0, self.height - 1)
        for x in range(0, self.width - 1)
            self.metadata[y][x] = reader.readInt
        end for
    end for
    
    return self
end function

Chunk.render = function(tileDisplay)
	tileDisplay.tileSet = self.tileSet.image
	tileDisplay.tileSetTileSize = [self.tileSet.tileWidth, self.tileSet.tileHeight]  // size of each tile in the image
	tileDisplay.cellSize = tileDisplay.tileSetTileSize
	tileDisplay.extent = [self.width, self.height]

	for y in range(0, self.height - 1)
		for x in range(0, self.width - 1)
			tileDisplay.setCell x, y, self.tiles[y][x]
		end for
	end for
end function

Chunk.setTile = function(x, y, tileName)
    // qa.assert self.tileSet.tileNames.hasIndex(tileName), "this: " + self.tileSet.tileNames
	tile = self.tileSet.tileNames[tileName]
	metadata = self.getMetadata(tileName)
	self.tiles[y][x] = tile
	self.metadata[y][x] = metadata
end function

Chunk.getTile = function(tileName)
	for t in self.tileSet.tiles
		if t.metadata.name == tileName then return t
	end for
	qa.assert false, "Tile '" + tileName + "' is not defined."
end function

Chunk.getMetadata = function(tileName)
	return 0
end function

return Chunk
