RawFileWriter = {}

SIZEOF_BYTE = 1
SIZEOF_INT = 4  // an integer is usually 4 bytes
SIZEOF_FLOAT = 4

RawFileWriter.make = function
	self = new RawFileWriter
	self.data = []
	self.offset = 0
	return self
end function

RawFileWriter.writeByte = function(value)
	self.data.push [ value, "byte" ]
end function

RawFileWriter.writeInt = function(value)
	self.data.push [ value, "int" ]
end function

RawFileWriter.writeFloat = function(value)
	self.data.push [ value, "float" ]
end function

RawFileWriter.save = function(path)
	// Step 1: Calculate the total size.
	size = 0
	for item in self.data
		type = item[1]
		if type == "byte" then
			size += SIZEOF_BYTE
		else if type == "int" then
			size += SIZEOF_INT
		else if type == "float" then
			size += SIZEOF_FLOAT
		else
			qa.assert false, "Unknown data type: " + type
		end if
	end for

	data = new RawData
	data.resize size

	// Step 2: Write the data to the buffer.
	offset = 0
	for item in self.data
		value = item[0]
		type = item[1]

		if type == "byte" then
			data.setByte offset, value
			offset += SIZEOF_BYTE
		else if type == "int" then
			data.setInt offset, value
			offset += SIZEOF_INT
		else if type == "float" then
			data.setFloat offset, value
			offset += SIZEOF_FLOAT
		else
			qa.assert false, "Unknown data type: " + type
		end if
	end for

	file.saveRaw path, data
end function

return RawFileWriter
