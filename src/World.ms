if locals == globals then
    env.importPaths = [
        "/sys/lib",
        "/usr/src",
    ]

	import "DiamondSquareNoise"
    import "json"
	import "mapUtil"
    import "mathUtil"
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

    // --------------------------------------------------
    // Base elevation + biome classification
    // --------------------------------------------------
    for y in range(0, h-1)
        for x in range(0, w-1)
            i = x + y * w

            elev = abs(base1[i] - base2[i]) * 3 - 2

            // Island falloff
            xd = abs(x / (w-1) * 2 - 1)
            yd = abs(y / (h-1) * 2 - 1)
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

    // --------------------------------------------------
    // Enforce shallow water along coasts
    // --------------------------------------------------
    for y in range(1, h-2)
        for x in range(1, w-2)
            i = x + y * w
            if self.tiles[i] != WATER_DEEP_INDEX then continue

            for yy in range(y-1, y+1)
                for xx in range(x-1, x+1)
                    t = self.tiles[xx + yy*w]
                    if t == GRASS_INDEX or t == ROCK_INDEX then
                        self.tiles[i] = WATER_SHALLOW_INDEX
                    end if
                end for
            end for
        end for
    end for

    // --------------------------------------------------
    // River generation (downhill with wandering)
    // --------------------------------------------------
    riverCount = floor(w * h / 6000)
    maxRiverLength = (w + h) * 1

    for r in range(0, riverCount)
        // Pick a mountain source
        for tries in range(0, 100)
            sx = randInt(0, w)
            sy = randInt(0, h)
            si = sx + sy * w
            if self.tiles[si] == RIVER_INDEX or (self.tiles[si] == ROCK_INDEX and self.elevation[si] > 0.8) then break
        end for

        cx = sx
        cy = sy

        for step in range(0, maxRiverLength)
            i = cx + cy * w

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
                    if xx < 0 or yy < 0 or xx >= w or yy >= h then continue
                    if xx == cx and yy == cy then continue

                    ni = xx + yy * w
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

    // --------------------------------------------------
    // Sand near water and rivers
    // --------------------------------------------------
    for y in range(1, h-2)
        for x in range(1, w-2)
            i = x + y * w
            if self.tiles[i] != GRASS_INDEX then continue

            for yy in range(y-1, y+1)
                for xx in range(x-1, x+1)
                    t = self.tiles[xx + yy*w]
                    if t == WATER_SHALLOW_INDEX or t == RIVER_INDEX then
                        self.tiles[i] = SAND_INDEX
                    end if
                end for
            end for
        end for
    end for

    // --------------------------------------------------
    // Desert expansion (noise-biased)
    // --------------------------------------------------
    for y in range(0, h-1)
        for x in range(0, w-1)
            i = x + y * w
            if self.tiles[i] != GRASS_INDEX then continue
            if base1[i] < -0.1 then
                self.tiles[i] = SAND_INDEX
            end if
        end for
    end for

    // --------------------------------------------------
    // Trees (avoid sand and rivers)
    // --------------------------------------------------
    for i in range(0, w*h/400)
        x0 = randInt(0, w)
        y0 = randInt(0, h)

        for j in range(0, 200)
            xx = x0 + randInt(-15, 16)
            yy = y0 + randInt(-15, 16)
            if xx < 0 or yy < 0 or xx >= w or yy >= h then continue

            idx = xx + yy * w
            if self.tiles[idx] == GRASS_INDEX then
                self.tiles[idx] = TREE_INDEX
            end if
        end for
    end for

    return self.tiles
end function

World.validateOverworld = function
    count = {}
    for i in range(0, self.width * self.height - 1)
        t = self.tiles[i]
        if not count.hasIndex(t) then count[t] = 0
        count[t] = count[t] + 1
    end for

    if count.get(ROCK_INDEX, 0) < 100 then return false
    if count.get(SAND_INDEX, 0) < 100 then return false
    if count.get(GRASS_INDEX, 0) < 100 then return false
    if count.get(TREE_INDEX, 0) < 100 then return false

    return true
end function

World.make = function(w, h, seed)
    seed = floor(seed)
    self = new World
    while true
        self.generateOverworld(w, h, seed)
        if self.validateOverworld then break
        seed = seed + 1
    end while
    return self
end function

// Generate a minimap image from the tile data.
World.generateMiniMap = function(x, y)
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
    image = self.generateMiniMap(x, y)
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

runDemo = function
    st = time

    w = 256
    h = 256
    seed = rnd * 10000
    globals.world = World.make(w, h, seed)

    world.drawMiniMap 0, 0, 2

    ft = time
    print "Terrain generation complete. Seed=" + seed + ", time=" + (ft - st)
end function

if locals == globals then runDemo

return World
