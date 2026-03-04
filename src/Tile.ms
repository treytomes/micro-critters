Tile = {}

Tile.fromJson = function(path)
	self = new Tile

	result = json.parse(file.open(path).read)

	for kv in result
		if kv.key[0].startsWith("_") then continue
		if kv.key != "image" then
			self[kv.key] = kv.value
		end if
	end for

	tileSet = AssetFactory.loadTileSet(result.tileSet)

	tileIndex = result.tileIndex
	if tileIndex isa string then tileIndex = code(tileIndex)
	self.image = tileSet.getTile(tileIndex)
	self.width = self.image.width
	self.height = self.image.height

	for y in range(self.image.height - 1)
		for x in range(self.image.width - 1)
			dst_c = self.image.pixel(x, y)
			if dst_c == null or dst_c == "#00000000" then
				if result.hasIndex("backgroundColor") then
					self.image.setPixel x, y, result.backgroundColor
				end if
			else
				if result.hasIndex("foregroundColor") then
					self.image.setPixel x, y, result.foregroundColor
				end if
			end if
		end for
	end for

	return self
end function

return Tile
