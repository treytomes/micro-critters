// PerlinNoise.ms
// -----------------------------------------------------------------------------
// Deterministic 2D Perlin noise using a permutation-table algorithm.
// Port of Ken Perlin's reference implementation adapted for MiniScript.
// Output range: [0, 1]
// -----------------------------------------------------------------------------

// PerlinNoise namespace.
PerlinNoise = {}

// -----------------------------------------------------------------------------
// Initialization
// -----------------------------------------------------------------------------

// @property {list<int>} basePerm
// Base permutation table defined by Ken Perlin.
// This table must remain constant for deterministic noise.
PerlinNoise.basePerm = [
    151,160,137,91,90,15,131,13,201,95,96,53,194,233,7,225,
    140,36,103,30,69,142,8,99,37,240,21,10,23,190,6,148,
    247,120,234,75,0,26,197,62,94,252,219,203,117,35,11,32,
    57,177,33,88,237,149,56,87,174,20,125,136,171,168,68,175,
    74,165,71,134,139,48,27,166,77,146,158,231,83,111,229,122,
    60,211,133,230,220,105,92,41,55,46,245,40,244,102,143,54,
    65,25,63,161,1,216,80,73,209,76,132,187,208,89,18,169,
    200,196,135,130,116,188,159,86,164,100,109,198,173,186,3,64,
    52,217,226,250,124,123,5,202,38,147,118,126,255,82,85,212,
    207,206,59,227,47,16,58,17,182,189,28,42,223,183,170,213,
    119,248,152,2,44,154,163,70,221,153,101,155,167,43,172,9,
    129,22,39,253,19,98,108,110,79,113,224,232,178,185,112,104,
    218,246,97,228,251,34,242,193,238,210,144,12,191,179,162,241,
    81,51,145,235,249,14,239,107,49,192,214,31,181,199,106,157,
    184,84,204,176,115,121,50,45,127,4,150,254,138,236,205,93,
    222,114,67,29,24,72,243,141,128,195,78,66,215,61,156,180]

// @property {list<int>} perm
// Doubled permutation table (512 entries) to avoid index wrapping.
PerlinNoise.perm = PerlinNoise.basePerm + PerlinNoise.basePerm

// -----------------------------------------------------------------------------
// Helpers
// -----------------------------------------------------------------------------

// Fade curve used to smooth interpolation.
// Implements 6t^5 − 15t^4 + 10t^3.
//
// @param {number} t Value in range [0, 1].
// @returns {number} Smoothed interpolation value.
PerlinNoise.fade = function(t)
    return t * t * t * (t * (t * 6 - 15) + 10)
end function

// Linear interpolation between two values.
//
// @param {number} t Interpolation factor [0, 1].
// @param {number} a Start value.
// @param {number} b End value.
// @returns {number} Interpolated result.
PerlinNoise.lerp = function(t, a, b)
    return a + t * (b - a)
end function

// Gradient dot-product function.
// Selects one of four gradient directions based on hashed value.
//
// @param {int} hash Hashed permutation value.
// @param {number} x X offset within grid cell.
// @param {number} y Y offset within grid cell.
// @returns {number} Gradient dot product.
PerlinNoise.grad = function(hash, x, y)
    h = bitAnd(hash, 3)   // 4 gradient directions
    if h == 0 then return  x + y
    if h == 1 then return -x + y
    if h == 2 then return  x - y
    return -x - y
end function

// -----------------------------------------------------------------------------
// 2D Perlin Noise
// -----------------------------------------------------------------------------

// Computes 2D Perlin noise at the given coordinates.
//
// @param {number} x X coordinate (continuous).
// @param {number} y Y coordinate (continuous).
// @returns {number} Noise value in range [0, 1].
PerlinNoise.noise = function(x, y)
    X = bitAnd(floor(x), 255)
    Y = bitAnd(floor(y), 255)

    x -= floor(x)
    y -= floor(y)

    u = self.fade(x)
    v = self.fade(y)

    A  = self.perm[X] + Y
    AA = self.perm[A]
    AB = self.perm[A + 1]
    B  = self.perm[X + 1] + Y
    BA = self.perm[B]
    BB = self.perm[B + 1]

    n = self.lerp(v,
        self.lerp(u,
            self.grad(self.perm[AA], x, y),
            self.grad(self.perm[BA], x - 1, y)),
        self.lerp(u,
            self.grad(self.perm[AB], x, y - 1),
            self.grad(self.perm[BB], x - 1, y - 1)))

    // Normalize from [-1,1] to [0,1]
    return (n + 1) / 2
end function

// Computes fractal (octave) Perlin noise at a point.
//
// @param x {number} X coordinate
// @param y {number} Y coordinate
// @param scale {number} Base scale (larger = smoother)
// @param octaves {int} Number of octaves
// @param persistence {number} Amplitude falloff per octave
// @param amplitude {number} Overall output multiplier (default 1)
// @param xOffset {number} X offset (for scrolling/animation)
// @param yOffset {number} Y offset (for scrolling/animation)
// @returns {number} Noise value in [0, amplitude]
PerlinNoise.fractalNoise = function(x, y, scale, octaves, persistence, amplitude = 1, xOffset = 0, yOffset = 0)
    total = 0
    amp = 1
    freq = 1
    maxAmp = 0

    for o in range(octaves - 1)
        n = PerlinNoise.noise(
            (x + xOffset) / scale * freq,
            (y + yOffset) / scale * freq)
        total += n * amp
        maxAmp += amp
        amp *= persistence
        freq *= 2
    end for

    return (total / maxAmp) * amplitude
end function

// -----------------------------------------------------------------------------
// Demo
// -----------------------------------------------------------------------------

runDemo = function
    text.clear

    gfx.scale = 3
    w = floor(gfx.width / gfx.scale)
    h = floor(gfx.height / gfx.scale)
    pd = gfx

    // Terrain parameters
    scale = 16
    octaves = 4
    persistence = 0.25
    amplitude = 1

    for y in range(h - 1)
        for x in range(w - 1)
            n = PerlinNoise.fractalNoise(x, y, scale, octaves, persistence, amplitude)

            if n < 0.35 then
                clr = color.fromList([0, 0, floor(100 + n * 120)])
            else if n < 0.5 then
                clr = color.fromList([194, 178, 128])
            else if n < 0.75 then
                clr = color.fromList([34, floor(150 + n * 60), 34])
            else
                c = floor(200 + n * 55)
                clr = color.fromList([c, c, c])
            end if

            pd.setPixel x, y, clr
        end for
    end for

    print "Fractal Perlin terrain demo complete."
end function

if locals == globals then runDemo

return PerlinNoise