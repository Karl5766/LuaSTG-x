-------------------------------------------------------------------------------------------------
---sequential_file_writer.lua
---desc: defines SequentialFileWriter class, an object of this class can write values of certain
---     types from a given file stream sequentially; by sequential, the object advance the file
---     cursor every time a write function is called
---author: CHU
---modifier:
---     Karl, 2021.3.8, split out BinaryWriter to this file and renamed the class as sequential
---     file writer
-------------------------------------------------------------------------------------------------

---@class SequentialFileWriter
local SequentialFileWriter = LuaClass("SequentialFileWriter")

---@param stream FileStream input file stream
function SequentialFileWriter.__create(stream)
    assert(type(stream) == "table", "invalid argument type.")
    local self = {}
    self.stream = stream
    return self
end

---@brief 关闭上行流
function SequentialFileWriter:close()
    self.stream:close()
end

---@brief 获取流
function SequentialFileWriter:getStream()
    return self.stream
end

---@brief 写入一个字符
---@param c string 要写入的字符
function SequentialFileWriter:writeChar(c)
    assert(type(c) == "string" and string.len(c) == 1, "invalid argument.")
    self.stream:writeByte(string.byte(c))
end

---@brief 写入一个字节
---@param b number 要写入的字节
function SequentialFileWriter:writeByte(b)
    assert(type(b) == "number" and b >= 0 and b <= 255, "invalid argument.")
    self.stream:writeByte(b)
end

---@~chinese 以小端序写入一个32位带符号整数
---
---@~english write 32bit signed integer in little endian order
---@param i number 要写入的整数
function SequentialFileWriter:writeInt(i)
    assert(type(i) == "number" and i >= -2147483648 and i <= 2147483647, "invalid argument.")
    if i < 0 then
        i = (0xFFFFFFFF + i) + 1
    end
    local b1, b2, b3, b4 = i % 0x100, math.floor(i % 0x10000 / 0x100), math.floor(i % 0x1000000 / 0x10000), math.floor(i / 0x1000000)
    local stream = self.stream
    stream:writeByte(b1)
    stream:writeByte(b2)
    stream:writeByte(b3)
    stream:writeByte(b4)
end

---@brief 以小端序写入一个32位无符号整数
---
---write 32bit unsigned integer in little endian order
---@param i number 要写入的整数
function SequentialFileWriter:writeUInt(i)
    assert(type(i) == "number" and i >= 0 and i <= 0xFFFFFFFF, "invalid argument.")
    local b1, b2, b3, b4 = i % 0x100, math.floor(i % 0x10000 / 0x100), math.floor(i % 0x1000000 / 0x10000), math.floor(i / 0x1000000)
    local stream = self.stream
    stream:writeByte(b1)
    stream:writeByte(b2)
    stream:writeByte(b3)
    stream:writeByte(b4)
end

---@~chinese 以小端序写入一个32位浮点数
---
---@~english write 32bit float in little endian order
---@param f number 要写入的浮点数
function SequentialFileWriter:writeFloat(f)
    local stream = self.stream
    if f == 0.0 then
        stream:writeByte(0)
        stream:writeByte(0)
        stream:writeByte(0)
        stream:writeByte(0)
    end

    local sign = 0
    if f < 0.0 then
        sign = 0x80
        f = -f
    end

    local mant, expo = math.frexp(f)
    if mant ~= mant then
        stream:writeByte(0x00)
        stream:writeByte(0x00)
        stream:writeByte(0x88)
        stream:writeByte(0xFF)
    elseif mant == math.huge or expo > 0x80 then
        if sign == 0 then
            stream:writeByte(0x00)
            stream:writeByte(0x00)
            stream:writeByte(0x80)
            stream:writeByte(0x7F)
        else
            stream:writeByte(0x00)
            stream:writeByte(0x00)
            stream:writeByte(0x80)
            stream:writeByte(0xFF)
        end
    elseif (mant == 0.0 and expo == 0) or expo < -0x7E then
        stream:writeByte(0x00)
        stream:writeByte(0x00)
        stream:writeByte(0x00)
        stream:writeByte(sign)
    else
        expo = expo + 0x7E
        mant = (mant * 2.0 - 1.0) * math.ldexp(0.5, 24)
        stream:writeByte(mant % 0x100)
        stream:writeByte(math.floor(mant / 0x100) % 0x100)
        stream:writeByte((expo % 0x2) * 0x80 + math.floor(mant / 0x10000))
        stream:writeByte(sign + math.floor(expo / 0x2))
    end
end

local strlen = string.len

---@brief 写入一个字符串
---@param str string 字符串
---@param is_null_terminate boolean 是否以\0结尾
function SequentialFileWriter:writeString(str, is_null_terminate)
    if is_null_terminate then
        local len = strlen(str)
        if len == 0 or string.byte(str, len) ~= 0 then
            str = str .. "\0"
        end
    end
    if string.len(str) ~= 0 then
        self.stream:writeBytes(str)
    end
end

---@~chinese 写入一个长度任意的字符串
---
---@~english write a variable length string to the file stream
---@param str string the string to write
function SequentialFileWriter:writeVarLengthString(str)
    local string_length = strlen(str)
    self:writeUInt(string_length)
    if string.len(str) ~= 0 then
        self.stream:writeBytes(str)
    end
end

---write the specified float/string fields of a given table to the file stream
---@param sourceTable table the table to read from
---@param floatFields table an array of strings specifying the names of the fields to write as float
---@param stringFields table an array of strings specifying the names of the fields to write as string
function SequentialFileWriter:writeFieldsOfTable(sourceTable, floatFields, stringFields)
    for i = 1, #floatFields do
        local field = floatFields[i]
        self:writeFloat(sourceTable[field])
    end
    for i = 1, #stringFields do
        local field = stringFields[i]
        self:writeVarLengthString(sourceTable[field])
    end
end

-------------------------------------------------------------------------------------------------

local _to_num = { 128, 64, 32, 16, 8, 4, 2, 1 }

---write the given bit array to the file stream
---@param bit_array table an array of bits (boolean true/false) to write to the file
function SequentialFileWriter:writeBitArray(bit_array)
    local n = #bit_array

    -- write the length of bit array
    self:writeUInt(n)

    -- write every 8 bits as a byte
    for i = 1, n, 8 do
        local byte = 0
        for j = 1, 8 do
            local bit = bit_array[i + j - 1]
            if bit then
                byte = byte + _to_num[j]
            end
        end
        self:writeByte(byte)
    end
end

return SequentialFileWriter