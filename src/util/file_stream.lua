-------------------------------------------------------------------------------------------------
---filestream.lua
---defines interfaces for simple file read and write
---author: CHU
---modifier:
---     Karl, 2021.2.14, renamed the file; changed the naming conventions to match
---     the other parts of the project; removed some assertion checks.
-------------------------------------------------------------------------------------------------
---@class FileStream
local FileStream = LuaClass("FileStream")

---@~chinese 初始化文件流
---
---@~english initialize a file stream
---@param path string 文件路径
---@param mode string 打开模式
function FileStream.__create(path, mode)
    local self = {}
    self.file = assert(io.open_u8(path, mode))
    return self
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
---@return string a string consists of the bytes read
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

return FileStream