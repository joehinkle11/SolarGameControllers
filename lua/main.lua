--
-- Solar Game Controllers Library Plugin Test Project
--
--
------------------------------------------------------------

-- Load plugin library
local SolarGameControllers = require "plugin.solargamecontrollers"

-------------------------------------------------------------------------------
-- BEGIN (Insert your sample test starting here)
-------------------------------------------------------------------------------

SolarGameControllers.init(function(event)
	if event.name == "input" then
		local controllerId = event.controllerId
		local controllerId = event.controllerId
	end
end)

SolarGameControllers.addSchema("drag",{

})

-------------------------------------------------------------------------------
-- END
-------------------------------------------------------------------------------
