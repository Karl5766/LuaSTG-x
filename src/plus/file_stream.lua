-----------------------------------------------------------------------------------
---filestream.lua
---defines interfaces for simple file read and write
---author: CHU
---modifier:
---     Karl, 2021.2.14, renamed the file; changed the naming conventions to match
---     the other parts of the project; removed some assertion checks.
-----------------------------------------------------------------------------------

---@class FileStream
local FileStream = plus.Class()

---@brief 初始化文件流
---@param path string 文件路径
---@param mode string 打开模式
function FileStream:init(path, mode)
    self.file = assert(io.open_u8(path, mode))
end

---@brief 获取文件大小
---@return number 文件大小（字节）
function FileStream:getFileSize()
    local cur = assert(self.file:seek("cur", 0))
    local eof = assert(self.file:seek("end", 0))
    assert(self.file:seek("set", cur))
    return eof - cur
end

---@brief 获取当前读写位置
---@return number 读写位置
function FileStream:getCursorPosition()
    return assert(self.file:seek("cur", 0))
end

---@brief 跳转到位置
---@param offset number 新的位置
---@param base number 基准
function FileStream:seek(base, offset)
    assert(self.file:seek(base, offset))
end

---@brief 关闭文件流
function FileStream:close()
    self.file:flush()
    self.file:close()
    self.file = nil
end

---@brief 立即刷新缓冲区
function FileStream:flush()
    self.file:flush()
end

---@brief 读取一个字节
---@return number 若为文件尾则为nil，否则以number返回所读字节
function FileStream:readByte()
    local b = self.file:read(1)
    if b then
        return string.byte(b)
    else
        return nil
    end
end

---@brief 读取若干个字节
---@param count number 字节数
function FileStream:readBytes(count)
    return self.file:read(count)
end

---@brief 写入一个字节
---@param b number 要写入的字节
function FileStream:writeByte(b)
    assert(type(b) == "number" and b >= 0 and b <= 255, "invalid byte.")
    assert(self.file:write(string.char(b)))
end

---@brief 写入字节数组
---@param data string 要写入的字节
function FileStream:writeBytes(data)
    assert(type(data) == "string", "invalid bytes.")
    assert(self.file:write(data))
end

------------------------------------------------------BinaryReader

---@class plus.BinaryReader
local BinaryReader = plus.Class()
plus.BinaryReader = BinaryReader

function BinaryReader:init(stream)
    assert(type(stream) == "table", "invalid argument type.")
    self.stream = stream
end

---@brief 关闭上行流
function BinaryReader:close()
    self.stream:close()
end

---@brief 获取流
function BinaryReader:getStream()
    return self.stream
end

---@brief 读取一个字符
---@return string 以string返回读取的字符
function BinaryReader:readChar()
    local byte = assert(self.stream:readByte(), "end of stream.")
    return string.char(byte)
end

---@brief 读取一个字节
---@return number 以number返回读取的字节
function BinaryReader:readByte()
    local byte = assert(self.stream:readByte(), "end of stream.")
    return byte
end

---@brief 以小端序读取一个16位带符号整数
---@return number 以number返回读取的整数
function BinaryReader:readShort()
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
function BinaryReader:readUShort()
    local b1, b2 = self:readByte(), self:readByte()
    return b1 + b2 * 0x100
end

---@brief 以小端序读取一个32位带符号整数
---@return number 以number返回读取的整数
function BinaryReader:readInt()
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
function BinaryReader:readUInt()
    local b1, b2, b3, b4 = self:readByte(), self:readByte(), self:readByte(), self:readByte()
    return b1 + b2 * 0x100 + b3 * 0x10000 + b4 * 0x1000000
end

---@brief 以小端序读取一个32位浮点数
---@return number 以number返回读取的浮点数
function BinaryReader:readFloat()
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
function BinaryReader:readString(len)
    return self.stream:readBytes(len)
end

------------------------------------------------------BinaryWriter

---@class plus.BinaryWriter
local BinaryWriter = plus.Class()
plus.BinaryWriter = BinaryWriter

function BinaryWriter:init(stream)
    assert(type(stream) == "table", "invalid argument type.")
    self.stream = stream
end

---@brief 关闭上行流
function BinaryWriter:close()
    self.stream:close()
end

---@brief 获取流
function BinaryWriter:getStream()
    return self.stream
end

---@brief 写入一个字符
---@param c string 要写入的字符
function BinaryWriter:writeChar(c)
    assert(type(c) == "string" and string.len(c) == 1, "invalid argument.")
    self.stream:writeByte(string.byte(c))
end

---@brief 写入一个字节
---@param b number 要写入的字节
function BinaryWriter:writeByte(b)
    assert(type(b) == "number" and b >= 0 and b <= 255, "invalid argument.")
    self.stream:writeByte(b)
end

---@brief 以小端序写入一个16位带符号整数
---@param s number 要写入的整数
function BinaryWriter:writeShort(s)
    assert(type(s) == "number" and s >= -32768 and s <= 32767, "invalid argument.")
    if s < 0 then
        s = (0xFFFF + s) + 1
    end
    local b1, b2 = s % 0x100, math.floor(s / 0x100)
    self.stream:writeByte(b1)
    self.stream:writeByte(b2)
end

---@brief 以小端序写入一个16位无符号整数
---@param s number 要写入的整数
function BinaryWriter:writeUShort(s)
    assert(type(s) == "number" and s >= 0 and s <= 65535, "invalid argument.")
    local b1, b2 = s % 0x100, math.floor(s / 0x100)
    self.stream:writeByte(b1)
    self.stream:writeByte(b2)
end

---@brief 以小端序写入一个32位带符号整数
---@param i number 要写入的整数
function BinaryWriter:writeInt(i)
    assert(type(i) == "number" and i >= -2147483648 and i <= 2147483647, "invalid argument.")
    if i < 0 then
        i = (0xFFFFFFFF + i) + 1
    end
    local b1, b2, b3, b4 = i % 0x100, math.floor(i % 0x10000 / 0x100), math.floor(i % 0x1000000 / 0x10000), math.floor(i / 0x1000000)
    self.stream:writeByte(b1)
    self.stream:writeByte(b2)
    self.stream:writeByte(b3)
    self.stream:writeByte(b4)
end

---@brief 以小端序写入一个32位无符号整数
---@param i number 要写入的整数
function BinaryWriter:writeUInt(i)
    assert(type(i) == "number" and i >= 0 and i <= 0xFFFFFFFF, "invalid argument.")
    local b1, b2, b3, b4 = i % 0x100, math.floor(i % 0x10000 / 0x100), math.floor(i % 0x1000000 / 0x10000), math.floor(i / 0x1000000)
    self.stream:writeByte(b1)
    self.stream:writeByte(b2)
    self.stream:writeByte(b3)
    self.stream:writeByte(b4)
end

---@brief 以小端序写入一个32位浮点数
---@param f number 要写入的浮点数
function BinaryWriter:writeFloat(f)
    if f == 0.0 then
        self.stream:writeByte(0)
        self.stream:writeByte(0)
        self.stream:writeByte(0)
        self.stream:writeByte(0)
    end

    local sign = 0
    if f < 0.0 then
        sign = 0x80
        f = -f
    end

    local mant, expo = math.frexp(f)
    if mant ~= mant then
        self.stream:writeByte(0x00)
        self.stream:writeByte(0x00)
        self.stream:writeByte(0x88)
        self.stream:writeByte(0xFF)
    elseif mant == math.huge or expo > 0x80 then
        if sign == 0 then
            self.stream:writeByte(0x00)
            self.stream:writeByte(0x00)
            self.stream:writeByte(0x80)
            self.stream:writeByte(0x7F)
        else
            self.stream:writeByte(0x00)
            self.stream:writeByte(0x00)
            self.stream:writeByte(0x80)
            self.stream:writeByte(0xFF)
        end
    elseif (mant == 0.0 and expo == 0) or expo < -0x7E then
        self.stream:writeByte(0x00)
        self.stream:writeByte(0x00)
        self.stream:writeByte(0x00)
        self.stream:writeByte(sign)
    else
        expo = expo + 0x7E
        mant = (mant * 2.0 - 1.0) * math.ldexp(0.5, 24)
        self.stream:writeByte(mant % 0x100)
        self.stream:writeByte(math.floor(mant / 0x100) % 0x100)
        self.stream:writeByte((expo % 0x2) * 0x80 + math.floor(mant / 0x10000))
        self.stream:writeByte(sign + math.floor(expo / 0x2))
    end
end

---@brief 写入一个字符串
---@param str string 字符串
---@param is_null_terminate boolean 是否以\0结尾
function BinaryWriter:writeString(str, is_null_terminate)
    if is_null_terminate then
        local len = string.len(str)
        if len == 0 or string.byte(str, len) ~= 0 then
            str = str .. "\0"
        end
    end
    if string.len(s) ~= 0 then
        self.stream:writeBytes(s)
    end
end
