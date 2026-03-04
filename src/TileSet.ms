TileSet = {}

TileSet.make = function(image, tileWidth, tileHeight)
	self = new TileSet
	self.image = image
	self.tileWidth = tileWidth
	self.tileHeight = tileHeight
	self.tiles = []
	self.len = floor(self.image.width / self.tileWidth) * floor(self.image.height / self.tileHeight)
	return self
end function

TileSet.fromImages = function(images)
	self.tileWidth = images[0].width
	self.tileHeight = images[0].height
	self.tiles = []
	
	self = new TileSet
	self.image = Image.create(self.tileWidth * len(images), self.tileHeight, color.purple)
	
	x = 0
	for img in images
		qa.assert img.width == self.tileWidth and img.height == self.tileHeight, "tile sizes must match"

		for dy in range(0, self.tileHeight - 1)
			for dx in range(0, self.tileWidth - 1)
				c = img.pixel(dx, dy)
				self.image.setPixel x + dx, dy, c
			end for
		end for

		x += self.tileWidth
	end for

	self.len = floor(self.image.width / self.tileWidth) * floor(self.image.height / self.tileHeight)
	return self
end function

TileSet.fromJson = function(jsonPath)
	qa.assert file.exists(jsonPath), "'" + jsonPath + "' does not exist."
	jsonText = file.open(jsonPath).read
	result = json.parse(jsonText)
	image = AssetFactory.loadImage(result.imagePath)
	return self.make(image, result.tileWidth, result.tileHeight)
end function

TileSet.getTile = function(tileIndex)
	qa.assert tileIndex >= 0 and tileIndex < self.len, "tileIndex {n} out of range({len})".fill({ "n": tileIndex, "len": len(self.len) })
	tilesPerRow = floor(self.image.width / self.tileWidth)
	tileX = (tileIndex % tilesPerRow) * self.tileWidth
	tileY = self.image.height - (floor(tileIndex / tilesPerRow) * self.tileHeight + self.tileHeight)
	return self.image.getImage(tileX, tileY, self.tileWidth, self.tileHeight)
end function

return TileSet
