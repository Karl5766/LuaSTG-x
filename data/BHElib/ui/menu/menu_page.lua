---------------------------------------------------------------------------------------------------
---menu_page.lua
---author: Karl
---date: 2021.5.1
---desc: implements the simple default behaviors of MenuPage objects
---------------------------------------------------------------------------------------------------

local MenuPage = LuaClass("menu.MenuPage")

local InteractiveSelector = require("BHElib.ui.selectors.interactive_selector")
local Prefab = require("core.prefab")

---------------------------------------------------------------------------------------------------

---@param selector InteractiveSelector the selector used in this menu page
function MenuPage.__create(selector)
    local self = {
        selector = selector,
    }
    local Renderer = require("BHElib.ui.renderer_prefab")
    self.renderer = Renderer(LAYER_MENU, self, "ui")

    return self
end

---@param menu_page_array MenuPageArray
function MenuPage:onCascade(menu_page_array)
end

---set the renderer object display layer of the menu page
function MenuPage:setLayer(layer)
    self.renderer.layer = layer
end

function MenuPage:setRenderView(view)
    self.renderer.coordinates_name = view
end

---@param state_const number a constant indicating the state of the selector about transitioning, E.g. IN_FORWARD
function MenuPage:setTransition(state_const)
    self.selector:setTransition(state_const)
end

---set the rate of increase of transition progress per frame
function MenuPage:setTransitionVelocity(transition_velocity)
    self.selector:setTransitionVelocity(transition_velocity)
end

---set the rate of increase of transition progress by frames required to go from completely hidden to shown
function MenuPage:transitionInWithTime(time)
    self.selector:setTransitionInWithTime(time)
end

---set the rate of increase of transition progress by frames required to go from completely shown to hidden
function MenuPage:transitionOutWithTime(time)
    self.selector:setTransitionOutWithTime(time)
end

function MenuPage:resetSelection(is_selecting)
    self.selector:resetSelection(is_selecting)
end

function MenuPage:isInputEnabled()
    return self.selector:isInputEnabled()
end

function MenuPage:continueMenuPage()
    return self.selector:continueMenu()
end

function MenuPage:update(dt)
    self.selector:update(dt)
end

function MenuPage:processInput()
    self.selector:processInput()
end

function MenuPage:render()
    self.selector:render()
end

function MenuPage:cleanup()
    Del(self.renderer)
end

function MenuPage:getChoice()
    return self.selector:getChoice()
end

local MenuConst = require("BHElib.ui.menu.menu_global")
---set a menu page to entering state; can be set on an already entering menu
---@param transition_speed number a positive number indicating the rate of transition per frame
function MenuPage:setPageEnter(is_forward, transition_speed)
    local selector = self.selector
    selector:resetSelection(true)
    if is_forward then
        selector:setTransition(MenuConst.IN_FORWARD)
    else
        selector:setTransition(MenuConst.IN_BACKWARD)
    end
    selector:setTransitionVelocity(transition_speed)
end

---set a menu page to exiting state; can be set on an already exiting menu
---@param transition_speed number a positive number indicating the rate of transition per frame
function MenuPage:setPageExit(is_forward, transition_speed)
    local selector = self.selector
    selector:resetSelection(false)
    if is_forward then
        selector:setTransition(MenuConst.OUT_FORWARD)
    else
        selector:setTransition(MenuConst.OUT_BACKWARD)
    end
    selector:setTransitionVelocity(-transition_speed)
end

return MenuPage