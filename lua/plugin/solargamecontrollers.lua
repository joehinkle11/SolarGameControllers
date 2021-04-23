local Library = require "CoronaLibrary"

-- Create library
local lib = Library:new{ name='solargamecontrollers', publisherId='io.joehinkle' }

-------------------------------------------------------------------------------
-- BEGIN (Insert your implementation starting here)
-------------------------------------------------------------------------------

-- imports
local SolarWebSockets =  require("plugin.solarwebsockets")
local VirtualController = require("plugin.solargamecontrollers.virtualcontroller")

-- helper functions
local function map(func, tbl)
    local newtbl = {}
    for i,v in pairs(tbl) do
        newtbl[i] = func(v)
    end
    return newtbl
end
local filter = function(t, fn)
	local out = {}
	for _, v in pairs(t) do
		if fn(v) then out[#out+1] = v end
	end
	return out
end

--
-- position info
--
local screenL = -(display.actualContentWidth-display.contentWidth)*.5
local screenR = display.actualContentWidth-(display.actualContentWidth-display.contentWidth)*.5
local screenT = -(display.actualContentHeight-display.contentHeight)*.5 + display.topStatusBarContentHeight
local screenB = display.actualContentHeight-(display.actualContentHeight-display.contentHeight)*.5
local screenW = screenR - screenL
local screenH = screenB - screenT

--
-- private
--
local controlSchemas = {}
local controllersList = {}
local controllersGroup = display.newGroup()
local _idCounter = 0
local gameControllerListener
local controlListeners = {}

--
-- public
--
function lib.addSchema(schemaName, controlSchema)
	controlSchema = controlSchema or {}

	controlSchemas[schemaName] = controlSchema
end

function lib.newController(schemaName, options)
	local controlSchema = controlSchemas[schemaName]
	local options = options or {}
	options.isOnScreen = options.isOnScreen or false
	if controlSchema then
		local controller = VirtualController.create(_idCounter, controlSchema)
		_idCounter = _idCounter + 1
		controllersList[#controllersList + 1] = {
			isOnScreen = options.isOnScreen,
			controller = controller
		}
	else
		print("WARNING: schema "..tostring(schemaName).." does not exist. Try adding it with SolarGameControllers.addSchema("..tostring(schemaName)..",{...}).")
	end
end

function lib.getControlDatas()
	local controls = {}
	for i = 1, #controllersList do
		local controller = controllersList[i].controller
		local controlData = {}
		controlData.id = controller.id
		-- todo get data
		controls[#controls+1] = controlData
	end
	return controls
end

local alwaysHideOnScreenControls = false
function lib.requestToShowOnScreenControls(callback)
	if not alwaysHideOnScreenControls then
		local availableControllers = filter(controllersList, function(controller)
			return controller.isOnScreen
		end)
		local availableControllersIds = map(function(controller)
			return controller.controller.id
		end, availableControllers)

		callback({
			availableControllersIds = availableControllersIds,
			show = function(options)
				options = options or {}
				local controllersIdsToShow = options.controllerIds or {}
				local noAnimation = options.noAnimation or false
				local controllersToShow = {}
				for i = 1, #controllersIdsToShow do
					local controllersId = controllersIdsToShow[i]
					local controller = nil
					for j = 1, #controllersList do
						if controllersList[j].controller.id == controllersId then
							controller = controllersList[j].controller
							break
						end
					end
					controllersToShow[#controllersToShow+1] = controller
				end
				for j = 1, #controllersList do
					controllersList[j].controller:hide()
				end
				for i = 1, #controllersToShow do
					controllersToShow[i]:unhide({t = screenT,b = screenB,l = screenL,r = screenR,m=0}, false, false, true, "left", true)
				end

				controllersGroup.isVisible = true
			end
		})
	end
end

function lib.hideOnScreenControls()
	controllersGroup.isVisible = false
end

function lib.alwaysHideOnScreenControls()
	controllersGroup.isVisible = false
	alwaysHideOnScreenControls = true
end

function lib.addControlListener(controllerId, inputId, callback)
	local controller
	for i = 1, #controllersList do
		if controllersList[i].id == controllerId then
			controller = controllersList[i]
			break
		end
	end
	if controller and type(inputId) == "string" and type(callback) == "function" then
		controlListeners[#controlListeners+1] = {
			controllerId = controllerId,
			input = inputId,
			callback = callback
		}
	end
end

function lib.removeControlListener(callback)
	for i = 1, #controlListeners do
		if controlListeners[i].callback == callback then
			table.remove( controlListeners, i )
			break
		end
	end
end

function lib.onResize(screenTop, screenBottom, screenLeft, screenRight)
	screenL = screenTop
	screenR = screenBottom
	screenT = screenLeft
	screenB = screenRight
	screenW = screenR - screenL
	screenH = screenB - screenT
	controllersGroup.x = screenL
	controllersGroup.y = screenT
end

function lib.editSchemaOptions(schemaName)

end

function lib.init( listener )
	gameControllerListener = listener
end

-------------------------------------------------------------------------------
-- END
-------------------------------------------------------------------------------

-- Return library instance
return lib
