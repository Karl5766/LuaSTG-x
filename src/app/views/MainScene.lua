---@class MainScene:ViewBase
local MainScene = class("MainScene", cc.load("mvc").ViewBase)
local director = cc.Director:getInstance()

for _, v in ipairs({ 'FocusLoseFunc', 'FocusGainFunc' }) do
    _G[v] = _G[v] or function()
    end
end

---Start one of the two launcher uis or start the game,
---depending on the value of local skip_setting and skip_selection
function MainScene:onEnter()
    self:runGameScene()
end

---run/switch to the game scene
function MainScene:runGameScene()
    -- in game
    local setting_file_mirror = require("setting.setting_file_mirror")
    local setting_content = setting_file_mirror:getContent()
    local scene = lstg.loadMod(setting_content.mod_info.name, setting_content.sevolume, setting_content.bgmvolume)

    if director:getRunningScene() then
        director:pushScene(scene)
    else
        director:runWithScene(scene)
    end
end

return MainScene
