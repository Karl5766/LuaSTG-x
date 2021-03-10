-------------------------------------------------------------------------------------------------
---sequential_file_reader.lua
---desc: defines SequentialFileReader class, an object of this class can read values of certain
---     types from a given file stream sequentially; by sequential, the object advance the file
---     cursor every time a read function is called
---author: CHU
---modifier:
---     Karl, 2021.3.8, split out BinaryReader to this file and renamed the class as sequential
---     file reader
-------------------------------------------------------------------------------------------------

---@class SequentialFileReader
local SequentialFileReader = LuaClass()

function SequentialFileReader.__create(stream)
    assert(type(stream) == "table", "invalid argument type.")
    local self = {}
    self.stream = stream
    return self
end

---@brief 关闭上行流
function SequentialFileReader:close()
    self.stream:close()
end

---@brief 获取流
function SequentialFileReader:getStream()
    return self.stream
end

---@brief 读取一个字符
---@return string 以string返回读取的字符
function SequentialFileReader:readChar()
    local byte = assert(self.stream:readByte(), "end of stream reached while attempting to read data from file.")
    return string.char(byte)
end

---@brief 读取一个字节
---@return number 以number返回读取的字节
function SequentialFileReader:readByte()
    local byte = assert(self.stream:readByte(), "end of stream reached while attempting to read data from file.")
    return byte
end

---@brief 以小端序读取一个16位带符号整数
---@return number 以number返回读取的整数
function SequentialFileReader:readShort()
    local b1, b2 = self:readByte(), self:readByte()
    local neg = (b2 >= 0x80)
    if neg then
        return -(0xFFFF - (b1 + b2 * 0x100 - 1))
    else
        return b1 + b2 * 0x100
    end
end

---@brief 以小端序读取一个16位无符号整数
---@return number 以number返回读取的整数
function SequentialFileReader:readUShort()
    local b1, b2 = self:readByte(), self:readByte()
    return b1 + b2 * 0x100
end

---@brief 以小端序读取一个32位带符号整数
---@return number 以number返回读取的整数
function SequentialFileReader:readInt()
    local b1, b2, b3, b4 = self:readByte(), self:readByte(), self:readByte(), self:readByte()
    local neg = (b4 >= 0x80)
    if neg then
        return -(0xFFFFFFFF - (b1 + b2 * 0x100 + b3 * 0x10000 + b4 * 0x1000000 - 1))
    else
        return b1 + b2 * 0x100 + b3 * 0x10000 + b4 * 0x1000000
    end
end

---@brief 以小端序读取一个32位无符号整数
---@return number 以number返回读取的整数
function SequentialFileReader:readUInt()
    local b1, b2, b3, b4 = self:readByte(), self:readByte(), self:readByte(), self:readByte()
    return b1 + b2 * 0x100 + b3 * 0x10000 + b4 * 0x1000000
end

---@brief 以小端序读取一个32位浮点数
---@return number 以number返回读取的浮点数
function SequentialFileReader:readFloat()
    local b1, b2, b3, b4 = self:readByte(), self:readByte(), self:readByte(), self:readByte()
    local sign = (b4 >= 0x80)
    local expo = (b4 % 0x80) * 0x2 + math.floor(b3 / 0x80)
    local mant = ((b3 % 0x80) * 0x100 + b2) * 0x100 + b1

    if sign then
        sign = -1
    else
        sign = 1
    end

    local n

    if mant == 0 and expo == 0 then
        n = sign * 0.0
    elseif expo == 0xFF then
        if mant == 0 then
            n = sign * math.huge
        else
            n = 0.0 / 0.0
        end
    else
        n = sign * math.ldexp(1.0 + mant / 0x800000, expo - 0x7F)
    end

    return n
end

---@brief 读取一个字符串
---@param len number 长度
---@return string 读取的字符串
function SequentialFileReader:readString(len)
    return self.stream:readBytes(len)
end

---read the fields saved by SequentialFileWriter:writeFieldsOfTable back into the give table
---@param t table the table to write to
---@param floatFields table an array of strings specifying the names of the fields to read as float
---@param stringFields table an array of strings specifying the names of the fields to read as string
---@return table the given table t
function SequentialFileReader:readFieldsOfTable(t, floatFields, stringFields)
    for i = 1, #floatFields do
        local field = floatFields[i]
        t[field] = self:readFloat()
    end
    for i = 1, #stringFields do
        local field = stringFields[i]
        -- write the length of the string, followed by the string itself
        local str_length = self:readUInt()
        t[field] = self:readString(str_length)
    end
end

-------------------------------------------------------------------------------------------------

local _to_num = { 128, 64, 32, 16, 8, 4, 2, 1 }
local min = min  -- cache the function

---read a bit array saved by SequentialFileWriter:writeBitArray from the file stream
---@return table an array of bits (boolean true/false) read from the file
function SequentialFileReader:readBitArray()
    -- read the length of bit array
    local n = self:readUInt(n)
    local bit_array = {} -- result array

    -- read every byte as 8 bits
    for i = 1, n, 8 do
        local byte = self:readByte(byte)
        for j = 1, min(8, n - i + 1) do
            local split_num = _to_num[j]
            if byte >= split_num then
                byte = byte - split_num
                bit_array[i + j - 1] = true
            else
                bit_array[i + j - 1] = false
            end
        end
    end
end

return SequentialFileReader