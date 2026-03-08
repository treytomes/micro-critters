// ======================================================
// Tile.ms
// Defines tile colors used by the terrain generator
// ======================================================
Tile = {}

// Shallow coastal water
Tile.river = color.fromList([0, 80, 160])

// Shallow coastal water
Tile.shallowWater = color.fromList([0, 64, 160])

// Deep ocean water
Tile.deepWater = color.fromList([0, 0, 64])

Tile.sand   = color.fromList([194, 178, 128])
Tile.grass  = color.fromList([34, 180, 34])
Tile.rock   = color.fromList([160, 160, 160])
Tile.tree   = color.fromList([0, 48, 0])

// ======================================================
// Random.ms
// Utility random functions
// ======================================================
randInt = function(min, max)
    // inclusive min, exclusive max
    return floor(rnd() * (max - min)) + min
end function

randRange = function(min, max)
    return rnd() * (max - min) + min
end function

// ======================================================
// Noise.ms
// Generates a wrapped diamond-square noise grid
// ======================================================
generateNoise = function(w, h, featureSize)
    values = []
    for i in range(0, w*h-1)
        values.push 0
    end for

    // Seed grid
    for y in range(0, h-1, featureSize)
        for x in range(0, w-1, featureSize)
            values[(x % w) + (y % h) * w] = randRange(-1, 1)
        end for
    end for

    stepSize = featureSize
    scale = 1.0 / w
    scaleMod = 1

    while stepSize > 1
        half = stepSize / 2

        // Diamond step
        for y in range(0, h-1, stepSize)
            for x in range(0, w-1, stepSize)
                a = values[(x % w) + (y % h) * w]
                b = values[((x+stepSize) % w) + (y % h) * w]
                c = values[(x % w) + ((y+stepSize) % h) * w]
                d = values[((x+stepSize) % w) + ((y+stepSize) % h) * w]
                e = (a+b+c+d)/4 + randRange(-1,1)*stepSize*scale
                values[((x+half) % w) + ((y+half) % h) * w] = e
            end for
        end for

		// Square step
		for y in range(0, h-1, stepSize)
			for x in range(0, w-1, stepSize)
				a = values[(x % w) + (y % h) * w]
				b = values[((x+stepSize) % w) + (y % h) * w]
				c = values[(x % w) + ((y+stepSize) % h) * w]
				d = values[((x+half) % w) + ((y+half) % h) * w]
				e = values[((x+half) % w) + ((y-half) % h) * w]
				f = values[((x-half) % w) + ((y+half) % h) * w]

				H = (a + b + d + e)/4 + randRange(-1,1)*stepSize*scale*0.5
				g = (a + c + d + f)/4 + randRange(-1,1)*stepSize*scale*0.5

				values[((x+half) % w) + (y % h) * w] = H
				values[(x % w) + ((y+half) % h) * w] = g
			end for
		end for

        stepSize = half
        scale = scale * (scaleMod + 0.8)
        scaleMod = scaleMod * 0.3
    end while

    return values
end function

// ======================================================
// TopMap.ms
// Generates and validates an overworld terrain map
// ======================================================
if locals == globals then
	import "mapUtil"
    import "mathUtil"
end if

// ======================================================
// generateTopMap
// Generates an overworld terrain map with elevation,
// water depth, deserts, rivers, and vegetation
// ======================================================
// ======================================================
// generateTopMap
// Overworld terrain generator with rivers + polish
// ======================================================
generateTopMap = function(w, h, seed)
    rnd(seed)

    // --------------------------------------------------
    // Noise layers
    // --------------------------------------------------
    base1 = generateNoise(w, h, 32)
    base2 = generateNoise(w, h, 32)

    rock1 = generateNoise(w, h, 16)
    rock2 = generateNoise(w, h, 16)
    rock3 = generateNoise(w, h, 16)

    map = []
    elevation = []

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

            elevation.push elev

            // Rock mask
            rmask = abs(rock1[i] - rock2[i])
            rmask = abs(rmask - rock3[i]) * 3 - 2

            if elev < -1.2 then
                map.push "deepWater"
            else if elev < -0.5 then
                map.push "shallowWater"
            else if elev > 0.6 and rmask < -1.5 then
                map.push "rock"
            else
                map.push "grass"
            end if
        end for
    end for

    // --------------------------------------------------
    // Enforce shallow water along coasts
    // --------------------------------------------------
    for y in range(1, h-2)
        for x in range(1, w-2)
            i = x + y * w
            if map[i] != "deepWater" then continue

            for yy in range(y-1, y+1)
                for xx in range(x-1, x+1)
                    t = map[xx + yy*w]
                    if t == "grass" or t == "rock" then
                        map[i] = "shallowWater"
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
            if map[si] == "river" or (map[si] == "rock" and elevation[si] > 0.8) then break
        end for

        cx = sx
        cy = sy

        for step in range(0, maxRiverLength)
            i = cx + cy * w

            // Stop at sea
            if map[i] == "shallowWater" or map[i] == "deepWater" then break

            // Carve river
            if map[i] == "grass" or map[i] == "sand" then
                map[i] = "river"
            end if

            currentH = elevation[i]
            candidates = []

            // Wander allowance increases on flat land
            wanderAllowance = 0.03
            if currentH < 0.3 then wanderAllowance = 0.08

            for yy in range(cy-1, cy+1)
                for xx in range(cx-1, cx+1)
                    if xx < 0 or yy < 0 or xx >= w or yy >= h then continue
                    if xx == cx and yy == cy then continue

                    ni = xx + yy * w
                    dh = elevation[ni] - currentH

                    // Prefer downhill, allow slight uphill wander
                    if dh <= wanderAllowance then
                        candidates.push [xx, yy, elevation[ni]]
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
            if rnd() < 0.7 then
                choice = candidates[0]
            else
                choice = candidates[randInt(0, candidates.len)]
            end if

            cx = choice[0]
            cy = choice[1]
        end for
    end for

    // // --------------------------------------------------
    // // River widening (lowland only)
    // // --------------------------------------------------
    // for y in range(1, h-2)
    //     for x in range(1, w-2)
    //         i = x + y * w
    //         if map[i] != "river" then continue
    //         if elevation[i] > 0.3 then continue

    //         for yy in range(y-1, y+1)
    //             for xx in range(x-1, x+1)
    //                 j = xx + yy * w
    //                 if map[j] == "grass" then
    //                     map[j] = "river"
    //                 end if
    //             end for
    //         end for
    //     end for
    // end for

    // --------------------------------------------------
    // Sand near water and rivers
    // --------------------------------------------------
    for y in range(1, h-2)
        for x in range(1, w-2)
            i = x + y * w
            if map[i] != "grass" then continue

            for yy in range(y-1, y+1)
                for xx in range(x-1, x+1)
                    t = map[xx + yy*w]
                    if t == "shallowWater" or t == "river" then
                        map[i] = "sand"
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
            if map[i] != "grass" then continue
            if base1[i] < -0.1 then
                map[i] = "sand"
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
            if map[idx] == "grass" then
                map[idx] = "tree"
            end if
        end for
    end for

    return map
end function

// attempt = 0
validateTopMap = function(map, w, h)
    count = {}
    for i in range(0, w*h-1)
        t = map[i]
        if not count.hasIndex(t) then count[t] = 0
        count[t] = count[t] + 1
    end for

	// globals.attempt += 1
	// print "Attempt="+attempt + " count="+count.get("rock", 0)
	// print "Attempt="+attempt + " count="+count.get("sand", 0)
	// print "Attempt="+attempt + " count="+count.get("grass", 0)
	// print "Attempt="+attempt + " count="+count.get("tree", 0)
    if count.get("rock", 0) < 100 then return false
    if count.get("sand", 0) < 100 then return false
    if count.get("grass", 0) < 100 then return false
    if count.get("tree", 0) < 100 then return false

    return true
end function

generateValidatedTopMap = function(w, h, seed)
    while true
        map = generateTopMap(w, h, seed)
        if validateTopMap(map, w, h) then return map
        seed = seed + 1
    end while
end function

drawMap = function(map, w, h)
	gfx.scale = 2
    for y in range(0, h-1)
        for x in range(0, w-1)
            i = x + y * w
            gfx.setPixel x, y, Tile[map[i]]
        end for
    end for
end function

runDemo = function
    w = 256
    h = 256
    seed = rnd * 10000 // floor(time)
    map = generateValidatedTopMap(w, h, seed)
    drawMap(map, w, h)
    print "Terrain generation complete. Seed=" + seed
end function

if locals == globals then runDemo