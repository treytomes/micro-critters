DiamondSquareNoise = {}

randRange = function(min, max)
    return rnd * (max - min) + min
end function

// ======================================================
// Noise.ms
// Generates a wrapped diamond-square noise grid
// ======================================================
DiamondSquareNoise.noise = function(w, h, featureSize)
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

return DiamondSquareNoise
