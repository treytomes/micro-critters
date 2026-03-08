// World.ms
// -----------------------------------------------------------------------------
// Generates and visualizes a 256x256 overworld using Perlin noise.
// Intended for tuning overworld appearance before chunk integration.
// -----------------------------------------------------------------------------

if locals == globals then
	env.importPaths = [
		"/sys/lib",
		"/usr/src",
	]

	import "PerlinNoise"
end if

// -----------------------------------------------------------------------------
// World constants
// -----------------------------------------------------------------------------

WORLD_WIDTH  = 256
WORLD_HEIGHT = 256

// -----------------------------------------------------------------------------
// World object
// -----------------------------------------------------------------------------

World = {}

// @property {number} width World width in cells
World.width = WORLD_WIDTH

// @property {number} height World height in cells
World.height = WORLD_HEIGHT

// @property {list} cells Elevation values [0,1]
World.cells = []

// -----------------------------------------------------------------------------
// World generation
// -----------------------------------------------------------------------------

// Generates the overworld elevation map.
World.generate = function
    self.cells = []

    // --- Terrain detail noise ---
    detailScale = 96
    detailOctaves = 5
    detailPersistence = 0.45

    // --- Continent mask noise ---
    continentScale = 256
    continentOctaves = 2
    continentPersistence = 0.5

    // --- Edge ocean parameters ---
    edgeWidth = 24   // tiles forced toward ocean

    totalProgress = self.width * self.height
    progress = 0
    previousPercentage = -1

    for y in range(self.height - 1)
        row = []
        for x in range(self.width - 1)

            // Base terrain detail
            detail = PerlinNoise.fractalNoise(
                x, y,
                detailScale,
                detailOctaves,
                detailPersistence,
                1)

            // Low-frequency continent mask
            continent = PerlinNoise.fractalNoise(
                x + 10000, y + 10000,
                continentScale,
                continentOctaves,
                continentPersistence,
                1)

            // Bias continent mask so average land survives
            continentBias = continent - 0.4

            // Combine signals
            e = detail - continentBias * 0.55

            // --- Hard ocean edges ---
            edgeDist = min([ x, y, self.width - 1 - x, self.height - 1 - y ])
            if edgeDist < edgeWidth then
                edgeFactor = edgeDist / edgeWidth
				e = e - (1 - edgeFactor)
            end if

            // Clamp
            if e < 0 then e = 0
            if e > 1 then e = 1

            row.push e

            // Progress meter
            progress += 1
            percentage = floor((progress / totalProgress) * 100)
            if percentage != previousPercentage and (percentage % 10) == 0 then
                print "Progress: " + percentage
                previousPercentage = percentage
            end if

        end for
        self.cells.push row
    end for
end function

min = function(valueList)
	result = valueList[0]
	for n in range(1, len(valueList) - 1)
		v = valueList[n]
		if v < result then result = v
	end for
	return result
end function

max = function(valueList)
	result = valueList[0]
	for n in range(1, len(valueList) - 1)
		v = valueList[n]
		if v > result then result = v
	end for
	return result
end function

// -----------------------------------------------------------------------------
// Rendering
// -----------------------------------------------------------------------------

// Renders the world to the main PixelDisplay.
World.render = function
    gfx.scale = 2
    w = floor(gfx.width / gfx.scale)
    h = floor(gfx.height / gfx.scale)

    for y in range(self.height - 1)
        for x in range(self.width - 1)

            e = self.cells[y][x]

            // Color bands
            if e < 0.20 then
                // Deep water
                clr = color.fromList([0, 0, 90])

            else if e < 0.30 then
                // Shallow water
                clr = color.fromList([0, 0, 150])

            else if e < 0.36 then
                // Sand
                clr = color.fromList([194, 178, 128])

            else if e < 0.55 then
                // Grassland
                clr = color.fromList([40, 170, 40])

            // else if e < 0.70 then
            //     // Forest
            //     clr = color.fromList([20, 120, 20])

            else if e < 0.7 then
                // Mountains
                c = floor(120 + e * 80)
                clr = color.fromList([c, c, c])

            else
                // Snow
                clr = color.fromList([240, 240, 240])
            end if

            gfx.setPixel x, y, clr
        end for
    end for
end function

// -----------------------------------------------------------------------------
// Demo
// -----------------------------------------------------------------------------

runDemo = function
    text.clear
    print "Generating overworld..."
    World.generate
    print "Rendering overworld..."
    World.render
    print "World generation complete."
end function

if locals == globals then runDemo

return World