---------------------------------------------------------------------------------------------------
---delayed_acc_bullet.lua
---author: Karl
---date created: before 2021
---desc: Defines a acceleration controlled, multi-purposes, commonly used bullet type
---------------------------------------------------------------------------------------------------

local Prefab = require("core.prefab")
local Bullet = require("BHElib.units.bullet.bullet_prefab")

local M = Prefab.NewX(Bullet)

---------------------------------------------------------------------------------------------------

local UnitMotion = require("BHElib.scripts.units.unit_motion")

---------------------------------------------------------------------------------------------------
---cache variables and functions

local TaskNew = task.New

---------------------------------------------------------------------------------------------------
---init

-- args will have attributes:
-- *x (number)
-- *y (number)
-- *angle (number)
-- .start_time (number)
-- *bullet_type_name (string)
-- *color_index (number)
-- *controller (AccController)
-- *blink_time (number)
-- .rot (number)
-- .inc_rot (number)
-- *effect_size (number)
-- *destroyable (boolean)
-- .colli_radius (number)
-- .del_time (number) a number specifies frames that need to wait to delete the bullets
-- .del_after (table<number,number,number,number>) the format is l, r, b, t specifying the border rectangle;
-- if any element is nil, they are assumed to be -math.huge for min or math.huge for max
--
-- .rot_controller (AccController)
-- .alt_controller (AccController)
-- .polar_mode (boolean)
-- .chain (see parameter_matrix.lua)

function M:init(args)
	Bullet.init(
			self,
			args.bullet_type_name,
			args.color_index,
			GROUP_ENEMY_BULLET,
			args.blink_time,
			args.effect_size,
			args.destroyable)
	local baseX, baseY = args.x, args.y
    self.x, self.y = baseX, baseY

	self.omiga = args.inc_rot or 0

	local angle = args.angle
    self.rot = args.rot or angle

	self.bound = true

    if args.del_time ~= nil then
        self.bound = false
        CustomTask.del_after(self, args.del_time)
    end
    
    -- delThrough is a list of 4 numbers {xmin, xmax, ymin, ymax}
	if args.del_through then
		self.bound = false
		CustomTask.del_through(self, unpack(args.del_through))
	end
	
	if args.scale then
		self.hscale = args.scale
		self.vscale = args.scale
	end
	
    local layer = args.layer
    local colli_radius = args.colli_radius
	TaskNew(self,function()
        if layer ~= nil then
            self.layer = layer
        end
		if colli_radius ~= nil then
			self.a, self.b = colli_radius, colli_radius
		end
    end)

	if args.chains then
		for _, chain in ipairs(args.chains) do
			chain:sparkAll(self)
		end
	end

	local start_time = args.start_time or 0
	local controller = args.controller
	
	if args.rot_controller == nil then
		if args.navi then self.navi = true end
        
        local alt_controller = args.alt_controller
		if alt_controller ~= nil then
            if args.polar_mode then
                -- polar mode
                if self.navi then
                    self.rot = angle
                end
				UnitMotion.PolarControllerMoveTo(self, alt_controller, controller, angle, start_time)
            else
                -- standard mode
                if self.navi then
                    self.rot = Angle(0, 0, controller:getSpeed(start_time), alt_controller:getSpeed(start_time))
                end
                UnitMotion.XYControllerMoveTo(self, controller, alt_controller, start_time)
            end
		else
			-- fixed angle + distance mode
			UnitMotion.FixedAngleControllerMoveTo(self, controller, angle, start_time)
		end
	else
		-- variable angle + speed mode
        UnitMotion.VariableAngleControllerMoveTo(self, controller, args.rot_controller, angle, start_time, args.navi)
	end
end

function M:fire(dt)
	Bullet.fire(self, dt)
	self.frame_task = true
end

Prefab.Register(M)

return M