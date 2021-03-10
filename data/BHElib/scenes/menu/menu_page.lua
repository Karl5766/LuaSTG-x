---------------------------------------------------------------------------------------------------
---menu_page.lua
---author: Karl
---date: 2021.3.6
---references: THlib/UI/menu.lua
---desc: implements the MenuPage objects
-------------------------------------------------------------------------------------------------

local _menu_const = {
    font_size           = 0.625,
    line_height         = 24,
    char_width          = 20,
    num_width           = 12.5,
    title_color         = { 255, 255, 255 },
    unfocused_color     = { 128, 128, 128 },
    --unfocused_color={255,255,255},
    focused_color1      = { 255, 255, 255 },
    focused_color2      = { 255, 192, 192 },
    blink_speed         = 7,
    shake_time          = 9,
    shake_speed         = 40,
    shake_range         = 3,
    --符卡练习每页行数
    sc_pr_line_per_page = 12,
    -- 符卡练习每行高度
    sc_pr_line_height   = 22,
    --符卡练习每行宽度
    sc_pr_width         = 320,
    sc_pr_margin        = 8,
    rep_font_size       = 0.6,
    rep_line_height     = 20,
}

local _input = require("BHElib.input.input_and_replay")

-------------------------------------------------------------------------------------------------
---cache functions

local _insert = table.insert

-------------------------------------------------------------------------------------------------
---base object class

---@class MenuPage:Object
MenuPage = Class(Object)

---@param title_text string display title
---@param option_callback table an array of selection callbacks for each option
---@param init_select_index number initial selected option index
function MenuPage:init(title_text, option_callback, init_select_index)
    self.layer = LAYER_MENU
    self.group = GROUP_GHOST
    self.alpha = 1
    self.bound = false

    self.locked = true
    self.hide = true
    self.title_text = title_text
    self.num_options = #option_callback  -- number of options in the menu
    self.option_callback = option_callback
    self.select_index = init_select_index

    -- manually inherit methods
    self.setAcceptInput = MenuPage.setAcceptInput
    self.playSelectSound = MenuPage.playSelectSound
    self.playMoveOptionSound = MenuPage.playMoveOptionSound
    self.moveOption = MenuPage.moveOption
end

---freeze or unfreeze user input
---@param accept_input boolean if true, freeze user input; if false, unfreeze user input
function MenuPage:setAcceptInput(accept_input)
    self.locked = not accept_input
end

function MenuPage:playSelectSound()
    -- PlaySound("sound:select00", 0.3)
end

function MenuPage:playMoveOptionSound()
    -- PlaySound("sound:ok00", 0.3)
end

---move the selected option index by the given difference
---@param index_diff number index difference between the new index and the current index
function MenuPage:moveOption(index_diff)
    local new_index = self.select_index + index_diff

    -- handles boundary condition, warp the index
    self.select_index = (new_index - 1) % self.num_options + 1

    self:playMoveOptionSound()

    self.shake_timer = _menu_const.shake_time
end

RegisterGameClass(MenuPage)

-------------------------------------------------------------------------------------------------

---@class SimpleTextMenuPage:MenuPage
SimpleTextMenuPage = Class(Object)

---@param title string display title
---@param num_options number number of options in the menu
---@param option_content table an array of menu options of the form {option_text, option_callback}
function SimpleTextMenuPage:init(title_text, option_content, init_select_index)
    local text_array = {}
    local callback_array = {}
    for i = 1, #option_content do
        _insert(text_array, option_content[i][1])
        _insert(callback_array, option_content[i][2])
    end

    self.option_text_array = text_array
    self.shake_timer = 0
    self.blink_timer = 0
    MenuPage.init(self, title_text, callback_array, init_select_index)  -- call base class initializer

    -- manually inherit methods
    self.processUserInput = SimpleTextMenuPage.processUserInput
end

---test for and process user input on the menu
function SimpleTextMenuPage:processUserInput()
    -- moving through options
    local index_diff = 0
    if _input.isAnyDeviceKeyDown("up") then
        index_diff = -1
    end
    if _input.isAnyDeviceKeyDown("down") then
        index_diff = 1
    end
    if index_diff ~= 0 then
        self:moveOption(index_diff)
    end

    -- selecting an option
    if _input.isAnyDeviceKeyDown("select") then
        local selected_option_callback = self.option_callback[self.select_index]
        selected_option_callback()
        self:playSelectSound()
    end
end

function SimpleTextMenuPage:frame()
    task.PropagateDo(self)
    self.shake_timer = max(self.shake_timer - 1, 0)

    if self.locked then
        return
    end
    -- below deals with user input

    self:processUserInput()
end

local _menu_painter = require("BHElib.ui.menu_painter")
---draw the menu page
function SimpleTextMenuPage:render()
    _menu_painter.drawTextMenuPage(
            "font:menu",
            self.title_text,
            _menu_const.title_color,
            self.option_text_array,
            _menu_const.unfocused_color,
            _menu_const.focused_color1,
            _menu_const.focused_color2,
            _menu_const.line_height,
            self.select_index,
            self.x,
            self.y,
            self.alpha,
            self.timer,
            _menu_const.blink_speed,
            self.shake_timer,
            _menu_const.shake_range,
            _menu_const.shake_speed,
            {"center"}  -- see resources.lua
    )
end

RegisterGameClass(SimpleTextMenuPage)