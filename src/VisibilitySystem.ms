// ======================================================
// VisibilitySystem.ms
// High-performance field-of-view + fog-of-war system
// Uses recursive shadow-casting and a 2D visibility buffer.
// ======================================================

// ------------------------------------------------------
// VisibilitySystem
// ------------------------------------------------------
VisibilitySystem = {}

// ------------------------------------------------------
// Octant transforms for shadow-casting
// Each entry: [xx, xy, yx, yy]
// ------------------------------------------------------
VisibilitySystem.octants = [
    [ 1,  0,  0,  1],
    [ 0,  1,  1,  0],
    [-1,  0,  0,  1],
    [ 0, -1,  1,  0],
    [-1,  0,  0, -1],
    [ 0, -1, -1,  0],
    [ 1,  0,  0, -1],
    [ 0,  1, -1,  0]]

// --------------------------------------------------
// Allocate 2D visibility buffer
// --------------------------------------------------
VisibilitySystem.reset = function(chunk, visDisplay)
    self.visibleNow = []
    for y in range(0, chunk.height - 1)
        row = []
        for x in range(0, chunk.width - 1)
            row.push false

            if chunk.hasBeenSeen(x, y) then
                visDisplay.setCell x, y, 0
                visDisplay.setCellTint x, y, "#00000088"
            else
                visDisplay.setCell x, y, 0
                visDisplay.setCellTint x, y, color.black
            end if
        end for
        self.visibleNow.push row
    end for
end function

// ======================================================
// update
// Computes visibility and updates the fog-of-war display.
// ======================================================
VisibilitySystem.update = function(entity, chunk, visDisplay)
    px = entity.getTileX
    py = entity.getTileY
    radius = 8    // entity.rangeOfVision
    radiusSq = radius * radius

    for y in range(0, chunk.height - 1)
        for x in range(0, chunk.width - 1)
            self.visibleNow[y][x] = false
        end for
    end for

    // Player tile is always visible
    self.visibleNow[py][px] = true
    chunk.markSeen px, py

    // --------------------------------------------------
    // Shadow-cast all 8 octants
    // --------------------------------------------------
    for oct in VisibilitySystem.octants
        VisibilitySystem.shadowCast(
            px, py,
            1,
            1.0, 0.0,
            radius,
            radiusSq,
            oct,
            chunk)
    end for

    for y in range(0, chunk.height - 1)
        for x in range(0, chunk.width - 1)
            if self.visibleNow[y][x] then
                chunk.markSeen x, y
            end if
        end for
    end for

    // --------------------------------------------------
    // Rendering pass (bounded to vision box)
    // --------------------------------------------------
    minX = mathUtil.max(0, px - radius - 1)
    maxX = mathUtil.min(chunk.width - 1, px + radius + 1)
    minY = mathUtil.max(0, py - radius - 1)
    maxY = mathUtil.min(chunk.height - 1, py + radius + 1)

    for y in range(minY, maxY)
        for x in range(minX, maxX)
            if self.visibleNow[y][x] then
                visDisplay.setCell x, y, 1
                visDisplay.setCellTint x, y, color.clear
            else if chunk.hasBeenSeen(x, y) then
                visDisplay.setCell x, y, 0
                visDisplay.setCellTint x, y, "#00000088"
            else
                visDisplay.setCell x, y, 0
                visDisplay.setCellTint x, y, color.black
            end if
        end for
    end for
end function

// ======================================================
// shadowCast
// Recursive shadow-casting implementation.
// ======================================================
VisibilitySystem.shadowCast = function(px, py, row, startSlope, endSlope, radius, radiusSq, oct, chunk)
    if startSlope < endSlope then return

    blocked = false
    newStart = startSlope

    for dist in range(row, radius)
        dx = -dist

        while dx <= 0
            dy = -dist

            lSlope = (dx - 0.5) / (dy + 0.5)
            rSlope = (dx + 0.5) / (dy - 0.5)

            if rSlope > startSlope then
                dx += 1
                continue
            end if
            if lSlope < endSlope then
                break
            end if

            tx = px + dx * oct[0] + dy * oct[1]
            ty = py + dx * oct[2] + dy * oct[3]

            if tx >= 0 and ty >= 0 and tx < chunk.width and ty < chunk.height then
                ddx = tx - px
                ddy = ty - py
                if ddx * ddx + ddy * ddy <= radiusSq then
                    self.visibleNow[ty][tx] = true
                end if

                blocks = chunk.blocksVisionAt(tx, ty)
            else
                blocks = true
            end if

            if blocked then
                if blocks then
                    newStart = rSlope
                else
                    blocked = false
                    startSlope = newStart
                end if
            else
                if blocks and dist < radius then
                    blocked = true
                    self.shadowCast(
                        px, py,
                        dist + 1,
                        startSlope,
                        lSlope,
                        radius,
                        radiusSq,
                        oct,
                        chunk)
                    newStart = rSlope
                end if
            end if

            dx += 1
        end while

        if blocked then break
    end for
end function

return VisibilitySystem