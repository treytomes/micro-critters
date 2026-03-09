RawFileReader = {}

SIZEOF_BYTE = 1
SIZEOF_INT = 4  // an integer is usually 4 bytes
SIZEOF_FLOAT = 4

RawFileReader.read = function(path)
	self = new RawFileReader
	qa.assert file.exists(path), "'{0}' does not exist.".fill([ path ])
	self.data = file.loadRaw(path)
	self.offset = 0
	return self
end function

RawFileReader.readByte = function
	result = self.data.byte(self.offset)
	self.offset += SIZEOF_BYTE
	return result
end function

RawFileReader.readInt = function
	result = self.data.int(self.offset)
	self.offset += SIZEOF_INT
	return result
end function

RawFileReader.readFloat = function
	result = self.data.float(self.offset)
	self.offset += SIZEOF_FLOAT
	return result
end function

return RawFileReader
