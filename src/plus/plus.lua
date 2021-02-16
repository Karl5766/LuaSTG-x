---luastg+ 专用强化脚本库
---该脚本库完全独立于lstg的老lua代码
---所有功能函数暴露在全局plus表中
---by CHU

plus         = {}

DoFile("plus/utility.lua")

DoFile("plus/local_directory_interfaces.lua")
DoFile("plus/platforms.lua")

DoFile("plus/file_stream.lua")
