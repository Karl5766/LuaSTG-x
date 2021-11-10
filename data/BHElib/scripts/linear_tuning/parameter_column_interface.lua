---------------------------------------------------------------------------------------------------
---desc: Describes the interfaces of a parameter column; is only a rough sketch, not accurately
---     describing all interfaces of the object
---------------------------------------------------------------------------------------------------

function M:add(s_next) end                  -- add an object to successor list
function M:spark() end					    -- start chain actions
function M:spark_to(s_next) end				-- start a chain action on the successor
function M:addScript(script) end           -- add a script to be executed each spark
function M:get_chain_name() end		        -- get the chain name