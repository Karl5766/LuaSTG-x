---------------------------------------------------------------------------------------------------
---capture_rate
---author: Karl
---date created: 2021.8.9
---desc: Manages recording capture rates for all the attacks; implements some interfaces for attack
---		card capture rate read/increment; here capture rate refers to the ordered pair of number of
---		captures and number of attempts to a specific attack
---------------------------------------------------------------------------------------------------

---@class CaptureRate
local M = {}

local _save_file_mirror = require("BHElib.unclassified.save_file_mirror")

---------------------------------------------------------------------------------------------------
---cache variables and functions

local pairs = pairs

---------------------------------------------------------------------------------------------------

function M:clear()
	_save_file_mirror:getContent().capture_rate = {}
	_save_file_mirror:syncToFile()
end

---------------------------------------------------------------------------------------------------
---interfaces

local function GetStrListing(difficulty, attack_id, player_id)
	local listing = "-difficulty: "..tostring(difficulty)..
			"\n-attack_id: "..tostring(attack_id)..
			"\n-player_id: "..tostring(player_id)
	return listing
end

local function CheckInputNonNil(difficulty, attack_id, player_id)
	local is_good = difficulty and attack_id and player_id
	if not is_good then
		local report = GetStrListing(difficulty, attack_id, player_id)

		error("Error: Invalid parameters for querying capture rate. \nparameters received: \n"..
				report.."\n")
	end
end

---get capture rate of spell card(s) for a given user; guarantees not modifying the capture rate table
---@param difficulty number difficulty value; if nil, return the sum of all
---@param attack_id string id of the spell; if nil, return the sum of all
---@param player_id string id of the player; if nil, return the sum of all
---@return number,number num_capture, num_attempt
function M:getCaptureRate(difficulty, attack_id, player_id)

	local capture_rate_table = _save_file_mirror:getContent().capture_rate

	if difficulty == nil then
		local total_capture, total_attempt = 0, 0
		for k, v in pairs(capture_rate_table) do
			local num_capture, num_attempt = self:getCaptureRate(v, attack_id, player_id)
			total_capture = total_capture + num_capture
			total_attempt = total_attempt + num_attempt
		end
		return total_capture, total_attempt
	end

	local records = capture_rate_table[difficulty]
	if not records then return 0, 0 end

	if attack_id == nil then
		local total_capture, total_attempt = 0, 0
		for k, v in pairs(records) do
			local num_capture, num_attempt = self:getCaptureRate(difficulty, v, player_id)
			total_capture = total_capture + num_capture
			total_attempt = total_attempt + num_attempt
		end
		return total_capture, total_attempt
	end

	records = records[attack_id]
	if not records then return 0, 0 end

	if player_id == nil then
		local total_capture, total_attempt = 0, 0
		for k, v in pairs(records) do
			local num_capture, num_attempt = self:getCaptureRate(difficulty, attack_id, v)
			total_capture = total_capture + num_capture
			total_attempt = total_attempt + num_attempt
		end
		return total_capture, total_attempt
	else
		local capture_rate = records[player_id]
		if capture_rate then
			assert(capture_rate[1] and capture_rate[2], "Error: Invalid capture rate detected!")
			return capture_rate[1], capture_rate[2]
		else
			return 0, 0
		end
	end
end

---set the capture rate of a spell card for given player and user
---@param difficulty number difficulty value
---@param attack_id string id of the spell
---@param player_id string id of the player
---@param capture_rate table an ordered pair {num_capture, num_attempt}
function M:setCaptureRate(difficulty, attack_id, player_id, capture_rate)
	CheckInputNonNil(difficulty, attack_id, player_id)

	local capture_rate_table = _save_file_mirror:getContent().capture_rate

	local difficulty_table = capture_rate_table[difficulty] or {}
	capture_rate_table[difficulty] = difficulty_table
	local attack_table = difficulty_table[attack_id] or {}
	difficulty_table[attack_id] = attack_table
	attack_table[player_id] = {capture_rate[1], capture_rate[2]}

	_save_file_mirror:syncToFile()
end

---increment the capture number for the attack by 1
function M:incCaptureNum(difficulty, attack_id, player_id)
	CheckInputNonNil(difficulty, attack_id, player_id)
	local num_capture, num_attempt = self:getCaptureRate(difficulty, attack_id, player_id)
	self:setCaptureRate(difficulty, attack_id, player_id, {num_capture + 1, num_attempt})
end

---increment the attempt number for the attack by 1
function M:incAttemptNum(difficulty, attack_id, player_id)
	CheckInputNonNil(difficulty, attack_id, player_id)
	local num_capture, num_attempt = self:getCaptureRate(difficulty, attack_id, player_id)
	self:setCaptureRate(difficulty, attack_id, player_id, {num_capture, num_attempt + 1})
end

return M