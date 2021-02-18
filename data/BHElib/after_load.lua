---------------------------------------------------------------------------------------------------
---after_load.lua
---date: 2021.2.17
---desc:
---modifier:
---     Karl, 2021.2.17, moved profiling code up;
---     Karl, 2021.2.18, moved most code to menu_2d_ui
---------------------------------------------------------------------------------------------------

local function loadModules()
    require('BHElib.ui.menu_task')
    require('BHElib.ui.arrange_string')
end
loadModules()