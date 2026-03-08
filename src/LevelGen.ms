// ======================================================
// Tile.ms
// Defines tile colors used by the terrain generator
// ======================================================
Tile = {}
Tile.water  = color.fromList([0, 0, 128])
Tile.sand   = color.fromList([194, 178, 128])
Tile.grass  = color.fromList([34, 180, 34])
Tile.rock   = color.fromList([160, 160, 160])
Tile.tree   = color.fromList([0, 48, 0])
// Tile.stairs = color.fromList([255, 255, 255])

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

generateTopMap = function(w, h, seed)
    rnd(seed)

    // Base noise
    noise1 = generateNoise(w, h, 32)
    noise2 = generateNoise(w, h, 32)

    // Rock mask noise
    mnoise1 = generateNoise(w, h, 16)
    mnoise2 = generateNoise(w, h, 16)
    mnoise3 = generateNoise(w, h, 16)

    map = []

    // Base terrain
    for y in range(0, h-1)
        for x in range(0, w-1)
            i = x + y * w

            val = abs(noise1[i] - noise2[i]) * 3 - 2

            mval = abs(mnoise1[i] - mnoise2[i])
            mval = abs(mval - mnoise3[i]) * 3 - 2

            xd = abs(x / (w-1) * 2 - 1)
            yd = abs(y / (h-1) * 2 - 1)
            dist = mathUtil.max(xd, yd)
            dist = dist^8

            val = val + 1 - dist * 20

            if val < -0.5 then
                map.push "water"
            else if val > 0.5 and mval < -1.5 then
                map.push "rock"
            else
                map.push "grass"
            end if
        end for
    end for

	// ------------------------------------------------------
	// Sand generation (beaches + deserts)
	// ------------------------------------------------------

	// 1) Coastal sand: grass adjacent to water becomes sand
	for y in range(1, h-2)
		for x in range(1, w-2)
			i = x + y * w
			if map[i] != "grass" then continue

			isCoastal = false
			for yy in range(y-1, y+1)
				for xx in range(x-1, x+1)
					if map[xx + yy*w] == "water" then
						isCoastal = true
					end if
				end for
			end for

			if isCoastal then
				map[i] = "sand"
			end if
		end for
	end for

	// 2) Desert seeds (higher density than original Java)
	desertSeeds = floor(w * h / 400)

	for i in range(0, desertSeeds)
		xs = randInt(0, w)
		ys = randInt(0, h)

		for j in range(0, 100)
			xx = xs + randInt(-12, 13)
			yy = ys + randInt(-12, 13)

			if xx >= 0 and yy >= 0 and xx < w and yy < h then
				idx = xx + yy * w
				if map[idx] == "grass" then
					map[idx] = "sand"
				end if
			end if
		end for
	end for

	// 3) Noise-based sand expansion (smooths deserts)
	for y in range(0, h-1)
		for x in range(0, w-1)
			i = x + y * w

			// Only convert grass
			if map[i] != "grass" then continue

			// Use existing base noise to bias sand
			if noise1[i] < -0.1 then
				map[i] = "sand"
			end if
		end for
	end for

    // Trees
    for i in range(0, w*h/400)
        x = randInt(0, w)
        y = randInt(0, h)
        for j in range(0, 200)
            xx = x + randInt(-15, 16)
            yy = y + randInt(-15, 16)
            if xx >= 0 and yy >= 0 and xx < w and yy < h then
                idx = xx + yy * w
                if map[idx] == "grass" then map[idx] = "tree"
            end if
        end for
    end for

    // // Stairs (must be surrounded by rock)
    // count = 0
    // for i in range(0, w*h/100)
    //     x = randInt(1, w-1)
    //     y = randInt(1, h-1)
    //     ok = true
    //     for yy in range(y-1, y+1)
    //         for xx in range(x-1, x+1)
    //             if map[xx + yy*w] != "rock" then ok = false
    //         end for
    //     end for
    //     if ok then
    //         map[x + y*w] = "stairs"
    //         count = count + 1
    //         if count == 4 then break
    //     end if
    // end for

    return map
end function

attempt = 0
validateTopMap = function(map, w, h)
    count = {}
    for i in range(0, w*h-1)
        t = map[i]
        if not count.hasIndex(t) then count[t] = 0
        count[t] = count[t] + 1
    end for

	globals.attempt += 1
	print "Attempt="+attempt + " count="+count.get("rock", 0)
	print "Attempt="+attempt + " count="+count.get("sand", 0)
	print "Attempt="+attempt + " count="+count.get("grass", 0)
	print "Attempt="+attempt + " count="+count.get("tree", 0)
	// print "Attempt="+attempt + " count="+count.get("stairs", 0)
    if count.get("rock", 0) < 100 then return false
    if count.get("sand", 0) < 100 then return false
    if count.get("grass", 0) < 100 then return false
    if count.get("tree", 0) < 100 then return false
    // if count.get("stairs", 0) < 2 then return false

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
	gfx.scale = 4
    for y in range(0, h-1)
        for x in range(0, w-1)
            i = x + y * w
            gfx.setPixel x, y, Tile[map[i]]
        end for
    end for
end function

runDemo = function
    w = 128
    h = 128
    seed = floor(time)
    map = generateValidatedTopMap(w, h, seed)
    drawMap(map, w, h)
    print "Terrain generation complete. Seed=" + seed
end function

if locals == globals then runDemo