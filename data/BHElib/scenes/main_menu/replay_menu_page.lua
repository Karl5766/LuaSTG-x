---------------------------------------------------------------------------------------------------
---replay_menu_page.lua
---author: Karl
---date: 2021.5.11
---desc: implements replay player and replay saver
---------------------------------------------------------------------------------------------------

local MenuPage = require("BHElib.ui.menu.menu_page")

---@class ReplayMenuPage:MenuPage
local M = LuaClass("menu.ReplayMenuPage", MenuPage)

local MultiPageMenuSelector = require("BHElib.ui.selectors.multi_page_menu_selector")
local ShakeEffListingSelector = require("BHElib.ui.selectors.shake_eff_listing_selector")
local MenuConst = require("BHElib.ui.menu.menu_global")
local Coordinates = require("BHElib.unclassified.coordinates_and_screen")
local FS = require("file_system")

---------------------------------------------------------------------------------------------------
---cache variables and functions

local Vec2 = math.vec2
local Vec4 = math.vec4
local Selectable = ShakeEffListingSelector.Selectable

---------------------------------------------------------------------------------------------------
---name formatting parameters

local STR_REPLAY_PREFIX = "Default_"
local STR_REPLAY_SUFFIX = ".Replay"  -- credit to Trackmania replay suffix, hard to come up with a suffix better than ".rpy" myself

---------------------------------------------------------------------------------------------------

local function CreateSaveSelectable(display_text, full_path, i)
    local selectable = Selectable(display_text, {
        {MenuConst.CHOICE_SPECIFY, "replay_path_for_write", full_path},
        {MenuConst.CHOICE_CASCADE},  -- let title page do the saving job
    })
    return selectable
end

---scan through all replay files in the directory, create an array of options with index specified by the replay file;
---for empty slots, those elements in the array with corresponding index will be filled with empty selectable
---@param max_index number maximum number of items; must be multiple of mod_num
---@param mod_num number number of items must be divisible by mod_num
---@return table, number an array of all selectables and the size of the array
local function CreateAllSelectable(is_saving, replay_file_directory, max_index, mod_num, empty_room_num)
    local size = empty_room_num
    local ret = {}

    local files = FS.getBriefOfFilesInDirectory(replay_file_directory)
    for i = 1, #files do

        local file = files[i]
        local file_name = file.name  -- contains the suffix part
        if file.isDirectory == false and string.sub(file_name, -#STR_REPLAY_SUFFIX, -1)== STR_REPLAY_SUFFIX
                and string.sub(file_name, 1, #STR_REPLAY_PREFIX) == STR_REPLAY_PREFIX then

            local number_str = string.sub(file_name, #STR_REPLAY_PREFIX + 1, -#STR_REPLAY_SUFFIX - 1)
            local number = tonumber(number_str)
            if number and number <= max_index then

                local selectable
                if is_saving then
                    selectable = CreateSaveSelectable(file_name, replay_file_directory.."/"..file_name, number)
                else
                    selectable = Selectable(file_name, {
                        {MenuConst.CHOICE_SPECIFY, "replay_path_for_read", replay_file_directory.."/"..file_name},
                        {MenuConst.CHOICE_EXIT}  -- let stage scene do the loading job
                    })
                end
                ret[number] = selectable
                size = max(number, size) + empty_room_num
            end
        end
    end

    size = math.ceil(size / mod_num) * mod_num
    size = min(size, max_index)

    -- fill out the empty slots
    for i = 1, size do
        if ret[i] == nil then
            if is_saving then
                ret[i] = CreateSaveSelectable(
                        "--- empty ---",
                        replay_file_directory.."/"..STR_REPLAY_PREFIX..tostring(i)..STR_REPLAY_SUFFIX,
                        i
                )
            else
                ret[i] = Selectable("--- empty ---", nil)
            end
        end
    end

    return ret, size
end

local function ReplayMenuProcessInput(self)
    ---@type InputManager
    local input = self.selection_input

    if input:isAnyDeviceKeyJustChanged("escape", false, true) then
        self:exit()
    else
        MultiPageMenuSelector.processInput(self)
    end
end

---@param init_focused_index number initial position index of focused selectable
function M.__create(
        init_focused_index,
        is_saving,
        replay_file_directory,
        num_selectable_in_page,
        num_pages
)
    -- create simple menu selector

    local width = Coordinates.getResolution()
    local ui_scale = Coordinates.getUIScale()
    width = width / ui_scale  -- convert to "ui" coordinates

    local center_x, center_y = Coordinates.getScreenCenterInUI()

    local title = "Replay"
    if is_saving then
        title = "Save Replay"
    end
    local max_replay_num = num_pages * num_selectable_in_page
    local selectable_array, size = CreateAllSelectable(is_saving, replay_file_directory, max_replay_num, num_selectable_in_page, 10)
    local selector = MultiPageMenuSelector.shortInit(
            init_focused_index,
            1,
            width * 0.7,
            Vec2(center_x, center_y),
            selectable_array,
            title,
            num_selectable_in_page,
            size / num_selectable_in_page,
            180,
            0
    )
    selector.processInput = ReplayMenuProcessInput
    local self = MenuPage.__create(selector)
    self.replay_file_directory = replay_file_directory
    self.is_saving = is_saving

    return self
end

return M