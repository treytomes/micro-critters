if locals == globals then
    env.importPaths = [
        "/sys/lib",
        "/usr/src",
    ]

	import "DiamondSquareNoise"
    import "json"
	import "mapUtil"
    import "mathUtil"
    import "PerlinNoise"
    import "qa"
end if

World = {}

// ======================================================
// Defines tile colors used by the terrain generator
// ======================================================
World.Tile = {}

// Shallow coastal water
World.Tile.river = color.fromList([0, 80, 160])

// Shallow coastal water
World.Tile.waterShallow = color.fromList([0, 64, 160])

// Deep ocean water
World.Tile.waterDeep = color.fromList([0, 0, 64])

World.Tile.sand   = color.fromList([194, 178, 128])
World.Tile.grass  = color.fromList([34, 180, 34])
World.Tile.rock   = color.fromList([160, 160, 160])
World.Tile.tree   = color.fromList([0, 48, 0])

World.TileIndex = [
    "waterDeep",
    "waterShallow",
    "river",
    "sand",
    "grass",
    "tree",
    "rock"]

WATER_DEEP_INDEX = World.TileIndex.indexOf("waterDeep")
WATER_SHALLOW_INDEX = World.TileIndex.indexOf("waterShallow")
RIVER_INDEX = World.TileIndex.indexOf("river")
SAND_INDEX = World.TileIndex.indexOf("sand")
GRASS_INDEX = World.TileIndex.indexOf("grass")
TREE_INDEX = World.TileIndex.indexOf("tree")
ROCK_INDEX = World.TileIndex.indexOf("rock")

randInt = function(min, max)
    // inclusive min, exclusive max
    return floor(rnd * (max - min)) + min
end function

// ======================================================
// generateOverworld
// Generates an overworld terrain map with elevation,
// water depth, deserts, rivers, and vegetation
// ======================================================
World.generateOverworld = function(w, h, seed)
    rnd(seed)
    self.seed = seed

    // --------------------------------------------------
    // Noise layers
    // --------------------------------------------------
    base1 = DiamondSquareNoise.noise(w, h, 32)
    base2 = DiamondSquareNoise.noise(w, h, 32)

    rock1 = DiamondSquareNoise.noise(w, h, 16)
    rock2 = DiamondSquareNoise.noise(w, h, 16)
    rock3 = DiamondSquareNoise.noise(w, h, 16)

    self.width = w
    self.height = h
    self.tiles = []
    self.elevation = []

    self._generateBase base1, base2, rock1, rock2, rock3
    self._generateShallows
    self._generateRivers
    self._generateCoasts
    self._generateDeserts base1
    self._generateTrees

    return self.tiles
end function

// --------------------------------------------------
// Base elevation + biome classification
// --------------------------------------------------
World._generateBase = function(base1, base2, rock1, rock2, rock3)
    for y in range(0, self.height - 1)
        for x in range(0, self.width - 1)
            i = x + y * self.width

            elev = abs(base1[i] - base2[i]) * 3 - 2

            // Island falloff
            xd = abs(x / (self.width - 1) * 2 - 1)
            yd = abs(y / (self.height - 1) * 2 - 1)
            dist = mathUtil.max(xd, yd) ^ 8
            elev = elev + 1 - dist * 20

            self.elevation.push elev

            // Rock mask
            rockMask = abs(rock1[i] - rock2[i])
            rockMask = abs(rockMask - rock3[i]) * 3 - 2

            if elev < -1.2 then
                self.tiles.push WATER_DEEP_INDEX
            else if elev < -0.5 then
                self.tiles.push WATER_SHALLOW_INDEX
            else if elev > 0.6 and rockMask < -1.5 then
                self.tiles.push ROCK_INDEX
            else
                self.tiles.push GRASS_INDEX
            end if
        end for
    end for
end function

// --------------------------------------------------
// Enforce shallow water along coasts
// --------------------------------------------------
World._generateShallows = function
    for y in range(1, self.height - 2)
        for x in range(1, self.width - 2)
            i = x + y * self.width
            if self.tiles[i] != WATER_DEEP_INDEX then continue

            for yy in range(y - 1, y + 1)
                for xx in range(x - 1, x + 1)
                    t = self.tiles[xx + yy * self.width]
                    if t == GRASS_INDEX or t == ROCK_INDEX then
                        self.tiles[i] = WATER_SHALLOW_INDEX
                    end if
                end for
            end for
        end for
    end for
end function

// --------------------------------------------------
// River generation (downhill with wandering)
// --------------------------------------------------
World._generateRivers = function
    riverCount = floor(self.width * self.height / 6000)
    maxRiverLength = (self.width + self.height) * 1

    for r in range(0, riverCount)
        // Pick a mountain source
        for tries in range(0, 100)
            sx = randInt(0, self.width)
            sy = randInt(0, self.height)
            si = sx + sy * self.width
            if self.tiles[si] == RIVER_INDEX or (self.tiles[si] == ROCK_INDEX and self.elevation[si] > 0.8) then break
        end for

        cx = sx
        cy = sy

        for step in range(0, maxRiverLength)
            i = cx + cy * self.width

            // Stop at sea
            if self.tiles[i] == WATER_SHALLOW_INDEX or self.tiles[i] == WATER_DEEP_INDEX then break

            // Carve river
            if self.tiles[i] == GRASS_INDEX or self.tiles[i] == SAND_INDEX then
                self.tiles[i] = RIVER_INDEX
            end if

            currentH = self.elevation[i]
            candidates = []

            // Wander allowance increases on flat land
            wanderAllowance = 0.03
            if currentH < 0.3 then wanderAllowance = 0.08

            for yy in range(cy-1, cy+1)
                for xx in range(cx-1, cx+1)
                    if xx < 0 or yy < 0 or xx >= self.width or yy >= self.height then continue
                    if xx == cx and yy == cy then continue

                    ni = xx + yy * self.width
                    dh = self.elevation[ni] - currentH

                    // Prefer downhill, allow slight uphill wander
                    if dh <= wanderAllowance then
                        candidates.push [xx, yy, self.elevation[ni]]
                    end if
                end for
            end for

            if candidates.len == 0 then break

            // Sort lowest first
			sortFn = function(a, b)
				return a[2] < b[2]
			end function
            candidates.sort(@sortFn)

            // Strong downhill bias with occasional wandering
            if rnd < 0.7 then
                choice = candidates[0]
            else
                choice = candidates[randInt(0, candidates.len)]
            end if

            cx = choice[0]
            cy = choice[1]
        end for
    end for
end function

// --------------------------------------------------
// Sand near water and rivers
// --------------------------------------------------
World._generateCoasts = function
    for y in range(1, self.height - 2)
        for x in range(1, self.width - 2)
            i = x + y * self.width
            if self.tiles[i] != GRASS_INDEX then continue

            for yy in range(y - 1, y + 1)
                for xx in range(x - 1, x + 1)
                    t = self.tiles[xx + yy * self.width]
                    if t == WATER_SHALLOW_INDEX or t == RIVER_INDEX then
                        self.tiles[i] = SAND_INDEX
                    end if
                end for
            end for
        end for
    end for
end function

// --------------------------------------------------
// Desert expansion (noise-biased)
// --------------------------------------------------
World._generateDeserts = function(base1)
    for y in range(0, self.height - 1)
        for x in range(0, self.width - 1)
            i = x + y * self.width
            if self.tiles[i] != GRASS_INDEX then continue
            if base1[i] < -0.1 then
                self.tiles[i] = SAND_INDEX
            end if
        end for
    end for
end function

// --------------------------------------------------
// Trees (avoid sand and rivers)
// --------------------------------------------------
World._generateTrees = function
    for i in range(0, self.width * self.height / 400)
        x0 = randInt(0, self.width)
        y0 = randInt(0, self.height)

        for j in range(0, 200)
            xx = x0 + randInt(-15, 16)
            yy = y0 + randInt(-15, 16)
            if xx < 0 or yy < 0 or xx >= self.width or yy >= self.height then continue

            idx = xx + yy * self.width
            if self.tiles[idx] == GRASS_INDEX then
                self.tiles[idx] = TREE_INDEX
            end if
        end for
    end for
end function

World.validateOverworld = function
    // count = {}
    // for i in range(0, self.width * self.height - 1)
    //     t = self.tiles[i]
    //     if not count.hasIndex(t) then count[t] = 0
    //     count[t] = count[t] + 1
    // end for

    // if count.get(ROCK_INDEX, 0) < 100 then return false
    // if count.get(SAND_INDEX, 0) < 100 then return false
    // if count.get(GRASS_INDEX, 0) < 100 then return false
    // if count.get(TREE_INDEX, 0) < 100 then return false

    return true
end function

World.make = function(width, height, seed)
    seed = floor(seed)
    self = new World
    while true
        self.generateOverworld(width, height, seed)
        if self.validateOverworld then break
        seed = seed + 1
    end while
    return self
end function

// Generate a minimap image from the tile data.
World.generateMiniMap = function
    pd = new PixelDisplay
	pd.clear color.black, self.width, self.height
    for y in range(0, self.height - 1)
        for x in range(0, self.width - 1)
            i = x + y * self.width
            tileIndex = self.tiles[i]
            // qa.assert tileIndex isa number, "tileIndex=" + tileIndex
            tileName = World.TileIndex[tileIndex]
            tileColor = World.Tile[tileName]
            pd.setPixel x, y, tileColor
        end for
    end for
    image = pd.getImage(0, 0, self.width, self.height)
    return image
end function

World.drawMiniMap = function(x, y, scale)
    image = self.generateMiniMap
    gfx.drawImage image, x, y, image.width * scale, image.height * scale
end function

World.saveWorld = function
	path = "/usr/world_{seed}.raw".fill(self)
	
    data = new RawData
    SIZEOF_BYTE = 1
    SIZEOF_INT = 4 // an integer is roughly 4 bytes?
    SIZEOF_FLOAT = 4
    data.resize SIZEOF_INT * 4 + len(self.tiles) * SIZEOF_BYTE
    
    offset = 0
    data.setInt offset, self.seed; offset += SIZEOF_INT
    data.setInt offset, self.width; offset += SIZEOF_INT
    data.setInt offset, self.height; offset += SIZEOF_INT
    data.setInt offset, len(self.tiles); offset += SIZEOF_INT
    for n in range(0, len(self.tiles) - 1)
        data.setByte offset, self.tiles[n]
        offset += SIZEOF_BYTE
    end for
    data.setInt offset, len(self.elevation); offset += SIZEOF_INT
    for n in range(0, len(self.elevation) - 1)
        data.setFloat offset, self.elevation[n]
        offset += SIZEOF_FLOAT
    end for

    file.saveRaw path, data

	return path
end function

World.loadWorld = function(path)
    data = file.loadRaw(path)
    SIZEOF_BYTE = 1
    SIZEOF_INT = 4 // an integer is roughly 4 bytes?
    SIZEOF_FLOAT = 4
    offset = 0

    self = new World
    self.seed = data.int(offset); offset += SIZEOF_INT
    self.width = data.int(offset); offset += SIZEOF_INT
    self.height = data.int(offset); offset += SIZEOF_INT
    tilesLen = data.int(offset); offset += SIZEOF_INT
    self.tiles = []
    for n in range(0, tilesLen - 1)
        self.tiles.push data.byte(offset)
        offset += SIZEOF_BYTE
    end for
    elevationsLen = data.int(offset); offset += SIZEOF_INT
    self.elevation = []
    for n in range(0, elevationsLen - 1)
        self.elevation.push data.float(offset)
        offset += SIZEOF_FLOAT
    end for

    return self
end function

// World.generateChunk
// Generates a 64x64 chunk whose detail is subordinate to world terrain intent.
// Rivers are carved as continuous connected polylines (tile-edge based).
World.generateChunk = function(worldX, worldY)
    CHUNK_SIZE = 64
    SUB_DIV = 16
    RIVER_RADIUS = SUB_DIV * 0.6

    chunkTiles = []

    for y in range(0, CHUNK_SIZE - 1)
        for x in range(0, CHUNK_SIZE - 1)

            // --------------------------------------------------
            // Coordinate setup
            // --------------------------------------------------
            px = worldX * SUB_DIV + x
            py = worldY * SUB_DIV + y

            wx = worldX + floor(x / SUB_DIV)
            wy = worldY + floor(y / SUB_DIV)
            wx1 = mathUtil.min(wx + 1, self.width - 1)
            wy1 = mathUtil.min(wy + 1, self.height - 1)

            // --------------------------------------------------
            // World elevation (bilinear)
            // --------------------------------------------------
            e00 = self.elevation[wx  + wy  * self.width]
            e10 = self.elevation[wx1 + wy  * self.width]
            e01 = self.elevation[wx  + wy1 * self.width]
            e11 = self.elevation[wx1 + wy1 * self.width]

            fx = (x % SUB_DIV) / SUB_DIV
            fy = (y % SUB_DIV) / SUB_DIV

            baseElev = e00 * (1 - fx) * (1 - fy) +
                e10 * fx       * (1 - fy) +
                e01 * (1 - fx) * fy +
                e11 * fx       * fy

            roughness = abs(e10 - e00) + abs(e01 - e00)
            detailAmp = mathUtil.clamp(roughness * 0.6, 0.04, 0.18)

            // --------------------------------------------------
            // Noise
            // --------------------------------------------------
            detailNoise = (PerlinNoise.fractalNoise(px, py, 24, 3, 0.4) - 0.5) * 2
            coastNoise  = (PerlinNoise.fractalNoise(px, py, 96, 2, 0.5) - 0.5) * 2
            rockNoise   = (PerlinNoise.fractalNoise(px, py, 32, 3, 0.45) - 0.5) * 2

            elev = baseElev + detailNoise * detailAmp
            coastField = baseElev * 0.9 + coastNoise * 0.5

            // --------------------------------------------------
            // River carving via connected edges
            // --------------------------------------------------
            minDist = 999

            for ry in range(wy - 2, wy + 2)
                for rx in range(wx - 2, wx + 2)
                    if rx < 0 or ry < 0 or rx >= self.width or ry >= self.height then continue
                    if self.tiles[rx + ry * self.width] != RIVER_INDEX then continue

                    cElev = self.elevation[rx + ry * self.width]
                    cx = rx * SUB_DIV + SUB_DIV / 2
                    cy = ry * SUB_DIV + SUB_DIV / 2

                    // For each downstream neighbor, create one edge
                    for ny in range(ry - 1, ry + 1)
                        for nx in range(rx - 1, rx + 1)
                            if nx == rx and ny == ry then continue
                            if nx < 0 or ny < 0 or nx >= self.width or ny >= self.height then continue
                            if self.tiles[nx + ny * self.width] != RIVER_INDEX then continue

                            ni = nx + ny * self.width
                            if self.elevation[ni] >= cElev then continue  // downstream only

                            nxp = nx * SUB_DIV + SUB_DIV / 2
                            nyp = ny * SUB_DIV + SUB_DIV / 2

                            // Segment endpoints
                            sx0 = cx
                            sy0 = cy
                            sx1 = nxp
                            sy1 = nyp

                            vx = sx1 - sx0
                            vy = sy1 - sy0
                            len2 = vx * vx + vy * vy
                            if len2 == 0 then continue

                            // Project pixel onto segment
                            t = ((px - sx0) * vx + (py - sy0) * vy) / len2
                            t = mathUtil.clamp(t, 0, 1)

                            qx = sx0 + vx * t
                            qy = sy0 + vy * t

                            dx = px - qx
                            dy = py - qy
                            dist = sqrt(dx * dx + dy * dy)

                            minDist = mathUtil.min(minDist, dist)
                        end for
                    end for
                end for
            end for

            riverCarve = 0
            if minDist < RIVER_RADIUS then
                t = 1 - minDist / RIVER_RADIUS
                riverCarve = t * t * (3 - 2 * t)
            end if

            if riverCarve > 0 then
                elev -= riverCarve * 0.8
                coastField -= riverCarve * 1.4
            end if

            // Force wet core
            if minDist < SUB_DIV * 0.25 then
                coastField = mathUtil.min(coastField, -0.6)
            end if

            // --------------------------------------------------
            // Tile resolution
            // --------------------------------------------------
            if coastField < -1.2 then
                tile = WATER_DEEP_INDEX
            else if coastField < -0.45 then
                tile = WATER_SHALLOW_INDEX
            else if elev < -0.1 or coastField < -0.4 then
                tile = SAND_INDEX
            else if elev > 0.6 and rockNoise > 0.05 then
                tile = ROCK_INDEX
            else
                if elev > baseElev and roughness < 0.35 and rockNoise < -0.2 then
                    tile = TREE_INDEX
                else if elev < baseElev - 0.025 then
                    tile = SAND_INDEX
                else
                    tile = GRASS_INDEX
                end if
            end if

            chunkTiles.push tile
        end for
    end for

    return chunkTiles
end function

// generateChunkImage
// Builds a minimap image from a 64x64 chunk tile array.
generateChunkImage = function(chunkTiles)
    pd = new PixelDisplay
    pd.clear color.black, 64, 64

    for y in range(0, 63)
        for x in range(0, 63)
            i = x + y * 64
            tileIndex = chunkTiles[i]
            tileName = World.TileIndex[tileIndex]
            tileColor = World.Tile[tileName]
            pd.setPixel x, y, tileColor
        end for
    end for

    return pd.getImage(0, 0, 64, 64)
end function

runDemo = function
    st = time

    w = 256
    h = 256
    seed = 0 // rnd * 10000
    globals.world = World.make(w, h, seed)
    text.clear

    scale = 1.5
    gfx.clear
    miniMap = world.generateMiniMap
    gfx.drawImage miniMap, 0, 0, miniMap.width * scale, miniMap.height * scale
    // TODO: generate the chunk, then the chunk minimap, then draw the chunk minimap to the right of the world minimap.

    chunkScale = 4

    cursorX = 88
    cursorY = 76

    chunkTiles = world.generateChunk(cursorX, cursorY)
    chunkImage = generateChunkImage(chunkTiles)

    gfx.drawImage chunkImage,
        miniMap.width * scale + 10,
        0,
        chunkImage.width * scale * 4,
        chunkImage.height * scale * 4
    
    text.row = 25
    text.column = 0
    print "x=" + cursorX + ",y=" + cursorY + "    "
 
    isBlinking = false
    while not key.pressed("escape")
        dx = key.axis("Horizontal")
        dy = key.axis("Vertical")
        cursorX += sign(dx) * chunkScale
        cursorY += sign(dy) * chunkScale
        if cursorX < 0 then cursorX = 0
        if cursorY < 0 then cursorY = 0
        if cursorX >= 256 then cursorX = 256
        if cursorY >= 256 then cursorY = 256

        if dx != 0 or dy != 0 then
            gfx.drawImage miniMap, 0, 0, miniMap.width * scale, miniMap.height * scale

            chunkTiles = world.generateChunk(cursorX, cursorY)
            chunkImage = generateChunkImage(chunkTiles)

            gfx.drawImage chunkImage,
                miniMap.width * scale + 10,
                0,
                chunkImage.width * scale * 4,
                chunkImage.height * scale * 4
            
            text.row = 25
            text.column = 0
            print "x=" + cursorX + ",y=" + cursorY + "    "
        end if

        left = (cursorX * scale - scale * chunkScale / 2)
        bottom = (cursorY * scale - scale * chunkScale / 2)
        width = scale * 2 * chunkScale
        height = scale * 2 * chunkScale
        isBlinking = floor(time) % 2
        if isBlinking then
            gfx.drawRect left, bottom, width, height, color.red
        else
            gfx.drawRect left, bottom, width, height, color.yellow
        end if

        wait 1 / 30
    end while

    ft = time
    // print "Terrain generation complete. Seed=" + seed + ", time=" + (ft - st)
end function

if locals == globals then runDemo

return World
