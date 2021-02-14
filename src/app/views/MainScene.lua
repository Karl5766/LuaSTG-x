---@class MainScene:ViewBase
local MainScene = class("MainScene", cc.load("mvc").ViewBase)

for _, v in ipairs({ 'FocusLoseFunc', 'FocusGainFunc' }) do
    _G[v] = _G[v] or function()
    end
end

local skip_setting
local skip_selection

---Set skip_setting and skip_selection attributes of main scene object.
---@param skip_set boolean whether to skip setting
---@param skip_set boolean whether to skip mod selection
function MainScene.setSkip(skip_set, skip_sel)
    skip_setting, skip_selection = skip_set, skip_sel
end

---Start the one of the two launcher ui or start the game,
---depending on the value of local skip_setting and skip_selection
function MainScene:onEnter()
    if not skip_setting then
        -- launcher 1
        local ok, ret = pcall(require, 'main_scene')
        if not ok then
            require('platform.launcher_ui')()
        end
    elseif not skip_selection then
        -- launcher 2
        local scene = require('app.views.GameScene'):create(nil, setting.mod)
        lstg.loadMod()
        require('platform.launcher2_ui')()
    else
        -- in game
        lstg.loadMod()
        local scene = require('app.views.GameScene'):create(nil, setting.mod)
        scene:showWithScene()
    end
end

return MainScene
