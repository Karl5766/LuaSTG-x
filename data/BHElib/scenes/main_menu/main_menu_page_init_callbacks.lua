---------------------------------------------------------------------------------------------------
---main_menu_page_init_callbacks.lua
---author: Karl
---date: 2021.7.7
---desc: implements the callbacks that initializes the main menu menu pages
---------------------------------------------------------------------------------------------------

---@class MainMenuPageInitCallbacks
local _callbacks = {}

---------------------------------------------------------------------------------------------------
---menu page init callbacks

---create a replay saver/loader
local function InitReplayMenuPage(is_saving, menu_manager)
    local ReplayMenuPage = require("BHElib.scenes.main_menu.replay_menu_page")
    return ReplayMenuPage(1, is_saving, menu_manager.replay_folder_path, 10, 3)
end

---create a replay saver menu page
---@param menu_manager MainMenuManager
function _callbacks.ReplaySaver(menu_manager)
    return InitReplayMenuPage(true, menu_manager)
end

---create a replay loader menu page
---@param menu_manager MainMenuManager
function _callbacks.ReplayLoader(menu_manager)
    return InitReplayMenuPage(false, menu_manager)
end

---create a title menu page
---@param menu_manager MainMenuManager
function _callbacks.Title(menu_manager)
    local TitleMenuPage = require("BHElib.scenes.main_menu.title_menu_page")
    return TitleMenuPage(1, menu_manager.temp_replay_path)
end

return _callbacks