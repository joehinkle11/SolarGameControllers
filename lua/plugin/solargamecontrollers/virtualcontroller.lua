--
-- virtualcontroller.lua
--

local VirtualController = {}

local JoyStick = require("plugin.solargamecontrollers.joystick")
local Button = require("plugin.solargamecontrollers.button")

function VirtualController.create(id, schema)
	local virtualController = display.newGroup()
	virtualController.id = id
	virtualController.isAwake = false
	if system.getInfo("platform") == "tvos" then
		-- auto awaken the apple remote
		virtualController.isAwake = true
	end

	--
	-- logic for interacting with other things
	--

	local buttonHoveringOn = nil

	--
	-- internal logic
	--

	local hardKeysEnabled = false
	local stickToSide = nil

	local hardKeys = {
		["a"] = "left",
		["left"] = "left",
		["d"] = "right",
		["right"] = "right",
		["w"] = "up",
		["up"] = "up",
		["s"] = "down",
		["down"] = "down",

		["space"] = "a",
		["enter"] = "a",
		["j"] = "a",
		["c"] = "a",
		["k"] = "b",
		["x"] = "b",
		["l"] = "c",
		["z"] = "c",

		-- gamecube controller
		["button2"] = "a",
		["button3"] = "b",
		["button4"] = "c",
		["button1"] = "c",
		-- ["button10"] = "start", -- todo start button support

		-- programmatic use
		["_a"] = "a",
		["_b"] = "b",
		["_c"] = "c",
	}

	-- normal horizontal    : joystick left, buttons right
	-- flipSides horizontal : buttons left,  joystick right
	-- normal vertical      : joystick top,  buttons bottom
	-- flipSides vertical   : buttons top,   joystick bottom
	local space = {l=screenL,r=screenR,t=screenT,b=screenB,m=100}
	local flipSides = false
	local isVertical = false
	local showVirtualGamepad = true
	local divisionPoint = 0
	local bringJoystickBack = nil -- the closer the number gets to 0, the faster back it goes. nil does nothing

	local appleTvMenuMode = "continuous"
	local discreteMovement = nil -- {x=...,y=...} when this is present, it will try to move to the next button
	local continuousMovement = nil -- {x=...,y=...} when this is present, it will try to move to the next button

	local joyStickMenuMovement = nil -- {x=...,y=...} when this is present, it will try to move to the next button

	local menuClick = false
	local menuPush = false
	local abortClick = false
	local backClick = false

    local joyStickA = false
    local joyStickB = false
	local joyStickC = false

	local controlsSizeFactor = .5
	local buttonSize = 187 * controlsSizeFactor

	local elements = {}
	local elementDict = {}

	--
	-- parse schema
	--
	local relativeDependencyValidator = {}
	for i = 1, #schema do
		local element = schema[i]
		local elementView
		-- validation
		if type(element.name) ~= "string" then
			print("ERROR: the element name be included as a string")
			return
		elseif type(element.inputId) ~= "string" then
			print("ERROR: the element inputId be included as a string")
			return
		elseif element.size ~= nil and type(element.size) ~= "number" then
			print("ERROR: the element size is optional, but must be a number")
			return
		end
		-- make it
		if element.type == "direction" then
			elementView = JoyStick.create({
				inputId = element.inputId,
				size = element.size,
				joyStickImages = element.joyStickImages,
				dPadImages = element.dPadImages
			})
			virtualController.joyStick = elementView
			elementView.stickToSide = stickToSide
			elementView:setToDPad()
			-- elementView:setToJoyStick()
			virtualController:insert( elementView )
		elseif element.type == "button" then
			elementView = Button.create({
				inputId = element.inputId,
				size = element.size,
				images = element.images
			})
			virtualController.joyStick = elementView
			elementView.stickToSide = stickToSide
			virtualController:insert( elementView )
		elseif element.type == nil then
			print("ERROR: you must provide a control schema element type")
			return
		else
			print("ERROR: control schema element type "..tostring(element.type).." not supported")
			return
		end
		-- animations
		elementView:setOnShow(element.onShow)
		elementView:setOnHide(element.onHide)
		elementView:setOnPress(element.onPress)
		elementView:setOnRelease(element.onRelease)
		-- positions
		if element.calcAbsolutePosition and element.calcRelativePosition then
			print("ERROR: you can only provide calcAbsolutePosition or calcRelativePosition, but not both")
			return
		elseif element.calcAbsolutePosition then
			if type(element.calcAbsolutePosition) ~= "table" then
				print("ERROR: calcAbsolutePosition must be a table with two numbers for {x, y} on a range of [-1,1] inclusive. For example {1, 1}, would place the button in the bottom right of the screen. Do not include margins, as this is done automatically")
				return
			end
			local x, y = unpack(element.calcAbsolutePosition)
			if type(x) == "number" and type(y) == "number" then
				elementView:setAbsolutePosition(x, y)
			else
				print("ERROR: calcAbsolutePosition must be a table with two numbers for {x, y} on a range of [-1,1] inclusive. For example {1, 1}, would place the button in the bottom right of the screen. Do not include margins, as this is done automatically")
				return
			end
		elseif element.calcRelativePosition then
			if type(element.calcRelativePosition) ~= "table" then
				print("ERROR: calcRelativePosition must be a table. {nameOfOtherElement=String, defaultMargin=Number, direction=Number, playerCanChangeDirection=Bool}")
				return
			end
			local nameOfOtherElement, defaultMargin, direction, playerCanChangeDirection = unpack(element.calcRelativePosition)
			if type(nameOfOtherElement) ~= "string" then
				print("ERROR: calcRelativePosition must be a table. {nameOfOtherElement=String, defaultMargin=Number, direction=Number, playerCanChangeDirection=Bool}. nameOfOtherElement must be a string")
				return
			elseif type(defaultMargin) ~= "number" then
				print("ERROR: calcRelativePosition must be a table. {nameOfOtherElement=String, defaultMargin=Number, direction=Number, playerCanChangeDirection=Bool}. defaultMargin must be a number")
				return
			elseif type(direction) ~= "number" then
				print("ERROR: calcRelativePosition must be a table. {nameOfOtherElement=String, defaultMargin=Number, direction=Number, playerCanChangeDirection=Bool}. direction must be a number")
				return
			elseif type(playerCanChangeDirection) ~= "boolean" then
				print("ERROR: calcRelativePosition must be a table. {nameOfOtherElement=String, defaultMargin=Number, direction=Number, playerCanChangeDirection=Bool}. playerCanChangeDirection must be a boolean")
				return
			end
			if relativeDependencyValidator[nameOfOtherElement] == element.name then
				print("ERROR: "..tostring(nameOfOtherElement).." is dependent on "..tostring(element.name).."'s position, and "..tostring(element.name).." is dependent on "..tostring(nameOfOtherElement).."'s position. Change one of the two to calcAbsolutePosition to avoid this loop")
				return
			end
			-- mark that we are dependent on the other element's position
			relativeDependencyValidator[element.name] = nameOfOtherElement
			elementView:setRelativePosition(nameOfOtherElement, defaultMargin, direction, playerCanChangeDirection)
		end

		-- add it
		if elementView then
			elements[#elements+1] = elementView
			elementDict[element.name] = elementView
		else
			print("ERROR: unknown error creating virtual gamepad from schema")
		end
	end

	-- clean up setup work
	relativeDependencyValidator = nil

	local touchListener = function( event )
		-- if showVirtualGamepad and virtualController.isVisible then
		-- 	local xStart = event.xStart
		-- 	local yStart = event.yStart
		-- 	local isInputForThisController = xStart < space.r and xStart > space.l and yStart < space.b and yStart > space.t
		-- 	if isInputForThisController then
		-- 		local mesaure
		-- 		if isVertical then mesaure = yStart else mesaure = xStart end
		-- 		local forJoyStick = mesaure < divisionPoint -- false for buttons
		-- 		if flipSides then forJoyStick = not forJoyStick end
		-- 		if("moved" == event.phase or "began" == event.phase) then
		-- 			if forJoyStick then
		-- 				joyStick:touch(event)
		-- 			else
		-- 				local x, y = event.x, event.y
		-- 				local distA = (buttonA.x-x)*(buttonA.x-x) + (buttonA.y-y)*(buttonA.y-y)
		-- 				local distB = (buttonB.x-x)*(buttonB.x-x) + (buttonB.y-y)*(buttonB.y-y)
		-- 				local distC = (buttonC.x-x)*(buttonC.x-x) + (buttonC.y-y)*(buttonC.y-y)
		-- 				local minDist = math.min( distA, distB, distC )
		-- 				joyStickA = false
		-- 				joyStickB = false
		-- 				joyStickC = false
		-- 				buttonA.alpha = 1
		-- 				buttonA2.alpha = 0
		-- 				buttonB.alpha = 1
		-- 				buttonB2.alpha = 0
		-- 				buttonC.alpha = 1
		-- 				buttonC2.alpha = 0
		-- 				if distA == minDist then
		-- 					joyStickA = true
		-- 					buttonA.alpha = 0
		-- 					buttonA2.alpha = 1
		-- 				elseif distB == minDist then
		-- 					joyStickB = true
		-- 					buttonB.alpha = 0
		-- 					buttonB2.alpha = 1
		-- 				else
		-- 					joyStickC = true
		-- 					buttonC.alpha = 0
		-- 					buttonC2.alpha = 1
		-- 				end
		-- 			end
		-- 		elseif("ended" == event.phase) then
		-- 			if forJoyStick then
		-- 				joyStick:touch(event)
		-- 			else
		-- 				joyStickA = false
		-- 				joyStickB = false
		-- 				joyStickC = false
		-- 				buttonA.alpha = 1
		-- 				buttonA2.alpha = 0
		-- 				buttonB.alpha = 1
		-- 				buttonB2.alpha = 0
		-- 				buttonC.alpha = 1
		-- 				buttonC2.alpha = 0
		-- 			end
		-- 		end
		-- 	end
		-- end
	end
	Runtime:addEventListener("touch", touchListener)

	local lastAppleX, lastAppleY = 0, 0
	local continuousCountX, continuousCountY = 0, 0
	local continuousThreshold = 8
	local function onAxisEvent( event )
		-- local mFiProfile = (event.device or {}).MFiProfile
		-- if mFiProfile == "microGamepad" then
		-- 	-- Apple TV Remote
		-- 	local value = event.rawValue
		-- 	local minn = event.axis.minValue
		-- 	local maxx = event.axis.maxValue
		-- 	local normalled = ((value - minn) / (maxx - minn) - .5)
		-- 	if event.axis.type == "x" then
		-- 		local delta = (normalled-lastAppleX)*50
		-- 		if math.abs( delta ) > 15 and math.abs(joyStick.joyStick2.x + delta) < 20 then
		-- 			-- snap to 0
		-- 			discreteMovement = {x=joyStick.joyStick2.x, y=(discreteMovement or {}).y}
		-- 			delta = -joyStick.joyStick2.x
		-- 			continuousCountX = 0
		-- 		else
		-- 			continuousCountX = (continuousCountX + delta)*.78
		-- 			if joyStick.joyStick2.x > 0 and delta < 0 then
		-- 				continuousCountX = 0
		-- 			elseif joyStick.joyStick2.x < 0 and delta > 0 then
		-- 				continuousCountX = 0
		-- 			end
		-- 		end
		-- 		joyStick:touch({
		-- 			phase = "moved",
		-- 			x = joyStick.x + joyStick.joyStick2.x + delta,
		-- 			y = nil
		-- 		})
		-- 		lastAppleX = normalled
		-- 	elseif event.axis.type == "y" then
		-- 		local delta = (normalled-lastAppleY)*50
		-- 		if math.abs( delta ) > 15 and math.abs(joyStick.joyStick2.y + delta) < 20 then
		-- 			-- snap to 0
		-- 			discreteMovement = {x=(discreteMovement or {}).y, y=joyStick.joyStick2.y}
		-- 			delta = -joyStick.joyStick2.y
		-- 			continuousCountY = 0
		-- 		else
		-- 			continuousCountY = (continuousCountY + delta)*.78
		-- 			if joyStick.joyStick2.y > 0 and delta < 0 then
		-- 				continuousCountY = 0
		-- 			elseif joyStick.joyStick2.y < 0 and delta > 0 then
		-- 				continuousCountY = 0
		-- 			end
		-- 		end
		-- 		joyStick:touch({
		-- 			phase = "moved",
		-- 			x = nil,
		-- 			y = joyStick.y + joyStick.joyStick2.y + delta
		-- 		})
		-- 		lastAppleY = normalled
		-- 	end
		-- 	if (math.abs(continuousCountX) > continuousThreshold) or (math.abs(continuousCountY) > continuousThreshold) then
		-- 		if math.abs(continuousCountX) > math.abs(continuousCountY) then
		-- 			continuousCountY = 0
		-- 		else
		-- 			continuousCountX = 0
		-- 		end
		-- 		continuousMovement = {x=continuousCountX,y=continuousCountY}
		-- 		continuousCountX = 0
		-- 		continuousCountY = 0
		-- 	end
		-- 	bringJoystickBack = 34
		-- else --if mFiProfile == "gamepad" then
		-- 	-- other controllers
		-- 	local value = event.rawValue
		-- 	local minn = event.axis.minValue
		-- 	local maxx = event.axis.maxValue
		-- 	local normalled = ((value - minn) / (maxx - minn) - .5)*3
		-- 	if event.axis.type == "x" then
		-- 		joyStick:touch({
		-- 			phase = "moved",
		-- 			x = joyStick.x + normalled*30,
		-- 			y = nil
		-- 		})
		-- 	elseif event.axis.type == "y" then
		-- 		joyStick:touch({
		-- 			phase = "moved",
		-- 			x = nil,
		-- 			y = joyStick.y + normalled*30
		-- 		})
		-- 	end
		-- 	local joyStickSpeedX, joyStickSpeedY = joyStick:getControls()
		-- 	local dist = math.abs( joyStickSpeedX*joyStickSpeedX ) + math.abs( joyStickSpeedY*joyStickSpeedY )
		-- 	if dist < 10 then
		-- 		-- this is to end the "wait_for_joystick_centering" state
		-- 		joyStickMenuMovement = nil
		-- 	elseif joyStickMenuMovement == nil and dist > 600 then
		-- 		joyStickMenuMovement = {
		-- 			x = joyStickSpeedX,
		-- 			y = joyStickSpeedY
		-- 		}
		-- 	end
		-- end
    end
	Runtime:addEventListener( "axis", onAxisEvent )
	virtualController.onAxisEvent = onAxisEvent

	-- The Key Event Listener
	local function onKeyEvent( event )
		-- local returnValue = false
		-- local mFiProfile = (event.device or {}).MFiProfile
		-- if mFiProfile == "microGamepad" then
		-- 	-- Apple TV Remote
		-- 	local phase = event.phase
		-- 	local keyName = event.keyName
		-- 	if keyName == "buttonA" or keyName == "buttonZ" then
		-- 		returnValue = true
		-- 		if phase == "up" then
		-- 			if not abortClick and menuPush then
		-- 				menuClick = true
		-- 			end
		-- 			menuPush = false
		-- 			abortClick = false
		-- 			joyStickA = false
		-- 			buttonA.alpha = 1
		-- 			buttonA2.alpha = 0
		-- 		else
		-- 			menuPush = true
		-- 			abortClick = false
		-- 			joyStickA = true
		-- 			buttonA.alpha = 0
		-- 			buttonA2.alpha = 1
		-- 		end
		-- 	elseif keyName == "menu" then
		-- 		returnValue = true
		-- 		if phase == "up" then
		-- 			backClick = true
		-- 			joyStickB = false
		-- 			buttonB.alpha = 1
		-- 			buttonB2.alpha = 0
		-- 		else
		-- 			backClick = false
		-- 			joyStickB = true
		-- 			buttonB.alpha = 0
		-- 			buttonB2.alpha = 1
		-- 		end
		-- 	elseif keyName == "up" then
		-- 		discreteMovement = {x=0,y=-30}
		-- 		continuousMovement = {x=0,y=-30}
		-- 	elseif keyName == "down" then
		-- 		discreteMovement = {x=0,y=30}
		-- 		continuousMovement = {x=0,y=30}
		-- 	elseif keyName == "left" then
		-- 		discreteMovement = {x=-30,y=0}
		-- 		continuousMovement = {x=-30,y=0}
		-- 	elseif keyName == "right" then
		-- 		discreteMovement = {x=30,y=0}
		-- 		continuousMovement = {x=30,y=0}
		-- 	end
		-- elseif hardKeysEnabled then
		-- 	local phase = event.phase
		-- 	local keyName = event.keyName
		-- 	--movement
		-- 	if phase == "down" then
		-- 		if hardKeys[keyName] == "up" then
		-- 			joyStick:hardSet("up")
		-- 			joyStickMenuMovement = {x=0,y=-30}
		-- 			returnValue = true
		-- 		elseif hardKeys[keyName] == "down" then
		-- 			joyStick:hardSet("down")
		-- 			joyStickMenuMovement = {x=0,y=30}
		-- 			returnValue = true
		-- 		end
		-- 		if hardKeys[keyName] == "right" then
		-- 			joyStick:hardSet("right")
		-- 			joyStickMenuMovement = {x=30,y=0}
		-- 			returnValue = true
		-- 		elseif hardKeys[keyName] == "left" then
		-- 			joyStick:hardSet("left")
		-- 			joyStickMenuMovement = {x=-30,y=0}
		-- 			returnValue = true
		-- 		end
		-- 	elseif phase == "up" then
		-- 		if hardKeys[keyName] == "up" then
		-- 			joyStick:reqUnset("up")
		-- 			returnValue = true
		-- 		elseif hardKeys[keyName] == "down" then
		-- 			joyStick:reqUnset("down")
		-- 			returnValue = true
		-- 		end
		-- 		if hardKeys[keyName] == "right" then
		-- 			joyStick:reqUnset("right")
		-- 			returnValue = true
		-- 		elseif hardKeys[keyName] == "left" then
		-- 			joyStick:reqUnset("left")
		-- 			returnValue = true
		-- 		end
		-- 	end
		-- 	if hardKeys[keyName] == "a" then
		-- 		returnValue = true
		-- 		if phase == "up" then
		-- 			if not abortClick and menuPush then
		-- 				menuClick = true
		-- 			end
		-- 			menuPush = false
		-- 			abortClick = false
		-- 			joyStickA = false
		-- 			buttonA.alpha = 1
		-- 			buttonA2.alpha = 0
		-- 		else
		-- 			menuPush = true
		-- 			abortClick = false
		-- 			joyStickA = true
		-- 			buttonA.alpha = 0
		-- 			buttonA2.alpha = 1
		-- 		end
		-- 	end
		-- 	if hardKeys[keyName] == "b" then
		-- 		returnValue = true
		-- 		if phase == "up" then
		-- 			backClick = true
		-- 			joyStickB = false
		-- 			buttonB.alpha = 1
		-- 			buttonB2.alpha = 0
		-- 		else
		-- 			backClick = false
		-- 			joyStickB = true
		-- 			buttonB.alpha = 0
		-- 			buttonB2.alpha = 1
		-- 		end
		-- 	end
		-- 	if hardKeys[keyName] == "c" then
		-- 		returnValue = true
		-- 		if phase == "up" then
		-- 			joyStickC = false
		-- 			buttonC.alpha = 1
		-- 			buttonC2.alpha = 0
		-- 		else
		-- 			joyStickC = true
		-- 			buttonC.alpha = 0
		-- 			buttonC2.alpha = 1
		-- 		end
		-- 	end
		-- end
		-- -- we handled the event, so return true.
		-- -- for default behavior, return false.
		-- return returnValue
	end
	Runtime:addEventListener( "key", onKeyEvent )
	virtualController.onKeyEvent = onKeyEvent

    function virtualController:hide()
        self.isVisible = false
    end

	function virtualController:unhide(_space, _isVertical, _flipSides, _hardKeysEnabled, _stickToSide, _showVirtualGamepad)
		stickToSide = _stickToSide
		showVirtualGamepad = _showVirtualGamepad
		-- joyStick.stickToSide = stickToSide
		hardKeysEnabled = _hardKeysEnabled
		self:arrange( _space, _isVertical, _flipSides )
		self.isVisible = showVirtualGamepad
	end

	function virtualController:arrange( _space, _isVertical, _flipSides )
		space = _space
		isVertical = _isVertical
		flipSides = _flipSides

		-- arrange all absolute positions first
		for i = 1, #elements do
			local element = elements[i]
			if element:getPositionMode() == "absolute" then
				element:arrange(_space, _isVertical, _flipSides)
			end
		end
		-- arrange all relative positions second
		for i = 1, #elements do
			local element = elements[i]
			if element:getPositionMode() == "relative" then
				local otherElementName = element:getNameOfOtherElement()
				local otherElement = elementDict[otherElementName]
				element:arrange(_space, _isVertical, _flipSides, otherElement)
			end
		end


		-- joyStick.isVertical = _isVertical
		
		-- joyStick.flipSides = _flipSides
		-- if isVertical then
		-- 	divisionPoint = (space.t + space.b)*.5
		-- else
		-- 	divisionPoint = (space.l + space.r)*.5
		-- end
		-- if isVertical then
		-- 	local side = stickToSide or (flipSides and "right") or "left"
		-- 	if flipSides then
		-- 		joyStick.y = space.b - space.m*buttonSize*1.5
		-- 		buttonA.y = space.t + space.m*buttonSize*1.5 - (buttonC.height - buttonB.height)*.25
		-- 		buttonB.y = space.t + space.m*buttonSize*1.5 + buttonSize*.8
		-- 		buttonC.y = space.t + space.m*buttonSize*1.5
		-- 	else
		-- 		joyStick.y = space.t + space.m*buttonSize*1.5
		-- 		buttonA.y = space.b - space.m*buttonSize*1.5 + (buttonC.height - buttonB.height)*.25
		-- 		buttonB.y = space.b - space.m*buttonSize*1.5 - buttonSize*.8
		-- 		buttonC.y = space.b - space.m*buttonSize*1.5
		-- 	end
		-- 	if side == "left" then
		-- 		joyStick.x = space.l + space.m*buttonSize
		-- 		buttonA.x = space.l + space.m*buttonSize + buttonSize*.85
		-- 		buttonB.x = space.l + space.m*buttonSize
		-- 		buttonC.x = space.l + space.m*buttonSize
		-- 	elseif side == "right" then
		-- 		joyStick.x = space.r - space.m*buttonSize
		-- 		buttonA.x = space.r - space.m*buttonSize - buttonSize*.85
		-- 		buttonB.x = space.r - space.m*buttonSize
		-- 		buttonC.x = space.r - space.m*buttonSize
		-- 	end
		-- else
		-- 	if flipSides then
		-- 		joyStick.x = space.r - space.m*buttonSize*1.5
		-- 		joyStick.y = space.b - space.m*buttonSize

		-- 		buttonA.x = space.l + space.m*buttonSize*1.5
		-- 		buttonA.y = space.b - space.m*buttonSize - buttonSize*.8
		-- 		buttonB.x = space.l + space.m*buttonSize*1.5 + buttonSize*.85
		-- 		buttonB.y = space.b - space.m*buttonSize + (buttonC.height - buttonB.height)*.25
		-- 		buttonC.x = space.l + space.m*buttonSize*1.5
		-- 		buttonC.y = space.b - space.m*buttonSize
		-- 	else
		-- 		joyStick.x = space.l + space.m*buttonSize*1.5
		-- 		joyStick.y = space.b - space.m*buttonSize

		-- 		buttonA.x = space.r - space.m*buttonSize*1.5
		-- 		buttonA.y = space.b - space.m*buttonSize - buttonSize*.8
		-- 		buttonB.x = space.r - space.m*buttonSize*1.5 - buttonSize*.85
		-- 		buttonB.y = space.b - space.m*buttonSize + (buttonC.height - buttonB.height)*.25
		-- 		buttonC.x = space.r - space.m*buttonSize*1.5
		-- 		buttonC.y = space.b - space.m*buttonSize
		-- 	end
		-- end
		-- buttonA2.x = buttonA.x
		-- buttonA2.y = buttonA.y
		-- buttonB2.x = buttonB.x
		-- buttonB2.y = buttonB.y
		-- buttonC2.x = buttonC.x
		-- buttonC2.y = buttonC.y
	end

	local controlTableMap = {"joyx","joyy","a","b","c"}
    function virtualController:getControlsTable()
		-- max out joystick
		-- local joyStickSpeedX, joyStickSpeedY = joyStick:getControls()
        -- if joyStickSpeedX > 20 then joyStickSpeedX = 30 elseif joyStickSpeedX < -20 then joyStickSpeedX = -30 else joyStickSpeedX = 0 end
        -- if joyStickSpeedY > 20 then joyStickSpeedY = 30 elseif joyStickSpeedY < -20 then joyStickSpeedY = -30 else joyStickSpeedY = 0 end
        return {joyStickSpeedX,joyStickSpeedY,joyStickA,joyStickB,joyStickC}
	end

	function virtualController:setAppleTvMenuMode(isContinuous)
		if isContinuous then
			appleTvMenuMode = "continuous"
		else
			appleTvMenuMode = "discrete"
		end
	end

	local offset3dX, offset3dY = 0, 0
	function virtualController:setHoverButton(buttonData, catchTrajectory)
		if catchTrajectory then
			offset3dX = catchTrajectory.x or offset3dX
			offset3dY = catchTrajectory.y or offset3dY
		end
		if buttonHoveringOn then
			local function putBack(view)
				if view.text then
					transition.to(view, {time=100,
						x = view.restingX,
						y = view.restingY
					})
				end
				transition.to(view, {time=100,
					rotation = view.restingRotation,
					xScale = view.restingXScale,
					yScale = view.restingYScale
				})
				transition.to(view.path, {time=100,
					x1 = (view.restingPath or {}).x1,
					y1 = (view.restingPath or {}).y1,
					x2 = (view.restingPath or {}).x2,
					y2 = (view.restingPath or {}).y2,
					x3 = (view.restingPath or {}).x3,
					y3 = (view.restingPath or {}).y3,
					x4 = (view.restingPath or {}).x4,
					y4 = (view.restingPath or {}).y4
				})
			end
			putBack(buttonHoveringOn.button)
			for i = 1, #buttonHoveringOn.otherViewsToAnimate do
				putBack(buttonHoveringOn.otherViewsToAnimate[i])
			end
		end
		buttonHoveringOn = buttonData
		if buttonData then
			buttonData.button:toFront()
			if buttonData.button.toFrontSubviews then
				for i = 1, #(buttonData.otherViewsToAnimate or {}) do
					if buttonData.otherViewsToAnimate[i] then buttonData.otherViewsToAnimate[i]:toFront() end
				end
			end
			if buttonData.button.leaveAppOnBackWhenSelected then
				system.activate( "controllerUserInteraction" )
			else
				system.deactivate( "controllerUserInteraction" )
			end
		else
			system.deactivate( "controllerUserInteraction" )
		end
	end

	local function checkMenuMovement(movement)
		if type(movement) == "table" then
			abortClick = true
			menuPush = false
			if movement.x ~= nil and movement.y ~= nil then
				-- local nextButton = hub.buttonClosest(buttonHoveringOn.button, {x=movement.x, y=movement.y})
				-- if nextButton then
				-- 	virtualController:setHoverButton(nextButton, {x=movement.x, y=movement.y})
				-- end
				return nil
			else
				movement.x = movement.x or 0
				movement.y = movement.y or 0
			end
		end
		return movement
	end

	function virtualController:verifyMenuSelectionIsValidForScreen()
		local isValid = false
		if buttonHoveringOn then
			if (virtualController.button or {}).isVisible and (virtualController.button or {}).alpha ~= 0 then
				for j = 1, #((buttonHoveringOn.button or {}).validScreenIds or {}) do
					if buttonHoveringOn.button.validScreenIds[j] == hub.screenId then
						isValid = true
						break
					end
				end
			end
		end
		if not isValid then
			self:setHoverButton(nil)
		end
	end

	local function clickButton(buttonData)
		if buttonData.onClick then
			local lockAutoDisable = false
			print("click")
			buttonData.onClick({
				virtualControllerId = virtualController.id,
				phase = "began",
				setNextControllerButtonToSelect = function(button)
					-- local buttonData = hub.buttonDataForButton(button)
					-- virtualController:setHoverButton(buttonData)
				end
			})
			if not lockAutoDisable then
				local isValid = false
				if (virtualController.button or {}).isVisible and (virtualController.button or {}).alpha ~= 0 then
					for j = 1, #((virtualController.button or {}).validScreenIds or {}) do
						if (buttonData or {}).validScreenIds[j] == hub.screenId then
							isValid = true
						end
					end
				end
				if isValid then
					virtualController:setHoverButton(nil)
				end
			end
		end
	end

	local perc1 = .01
	local perc2 = .02
	local ease = .5
	local offsetFactor = 20
	local lastControlsTable = virtualController:getControlsTable()
	local function onEnterFrame(event)
		if bringJoystickBack ~= nil then
			if bringJoystickBack < 0 then
				bringJoystickBack = nil
			else
				if bringJoystickBack >= 0 and bringJoystickBack <= 20 then
					local joyStickSpeedX, joyStickSpeedY = joyStick:getControls()
					local newValueX, newValueY
					if bringJoystickBack == 0 then
						newValueX, newValueY = 0, 0
					else
						newValueX, newValueY = joyStickSpeedX*(bringJoystickBack/100), joyStickSpeedY*(bringJoystickBack/100)
					end
					joyStick:touch({
						phase = "moved",
						x = joyStick.x + joyStickSpeedX * newValueX,
						y = joyStick.y + joyStickSpeedY * newValueY
					})
				end
				bringJoystickBack = bringJoystickBack - 0.5
			end
		end
		if buttonHoveringOn then
			local joyStickSpeedX, joyStickSpeedY = joyStick:getUnclippedControls()
			joyStickSpeedX, joyStickSpeedY = joyStickSpeedX + offset3dX, joyStickSpeedY + offset3dY*3
			offset3dX = offset3dX*.9
			offset3dY = offset3dY*.9

			local expandAmt = 20 + math.sin(event.time*.008)*25
			if menuPush and not abortClick then
				expandAmt = -10
			end

			local function animateView(view)
				if view and view.parent then
					if view.text then
						local x = view.restingX + joyStickSpeedX/30*offsetFactor
						local y = view.restingY + joyStickSpeedY/30*offsetFactor
						view.x = view.x + (x - view.x)*ease
						view.y = view.y + (y - view.y)*ease
					end

					local rotation = view.restingRotation + joyStickSpeedX*.01

					local xScale = view.restingXScale + (math.abs(joyStickSpeedX)*perc1 + math.abs(joyStickSpeedY)*perc2 + expandAmt)/view.restingWidth
					local yScale = view.restingYScale + (math.abs(joyStickSpeedX)*perc1 + math.abs(joyStickSpeedY)*perc2 + expandAmt*(view.restingHeight/view.restingWidth))/view.restingHeight

					local x1 = ((view.restingPath or {}).x1 or 0) + joyStickSpeedX*perc1 + joyStickSpeedY*perc2 - view.restingWidth-expandAmt
					local y1 = ((view.restingPath or {}).y1 or 0) + joyStickSpeedX*perc2 + joyStickSpeedY*perc1 - view.restingHeight-expandAmt

					local x2 = ((view.restingPath or {}).x2 or 0) - joyStickSpeedX*perc1 - joyStickSpeedY*perc2 - view.restingWidth-expandAmt
					local y2 = ((view.restingPath or {}).y2 or 0) - joyStickSpeedX*perc2 - joyStickSpeedY*perc1 + view.restingHeight+expandAmt

					local x3 = ((view.restingPath or {}).x3 or 0) + joyStickSpeedX*perc1 + joyStickSpeedY*perc2 + view.restingWidth+expandAmt
					local y3 = ((view.restingPath or {}).y3 or 0) + joyStickSpeedX*perc2 + joyStickSpeedY*perc1 + view.restingHeight+expandAmt

					local x4 = ((view.restingPath or {}).x4 or 0) - joyStickSpeedX*perc1 - joyStickSpeedY*perc2 + view.restingWidth+expandAmt
					local y4 = ((view.restingPath or {}).y4 or 0) - joyStickSpeedX*perc2 - joyStickSpeedY*perc1 - view.restingHeight-expandAmt


					if view.path == nil then
						view.path.x1 = view.path.x1 + (x1 - view.path.x1)*ease
						view.path.y1 = view.path.y1 + (y1 - view.path.y1)*ease
						view.path.x2 = view.path.x2 + (x2 - view.path.x2)*ease
						view.path.y2 = view.path.y2 + (y2 - view.path.y2)*ease
						view.path.x3 = view.path.x3 + (x3 - view.path.x3)*ease
						view.path.y3 = view.path.y3 + (y3 - view.path.y3)*ease
						view.path.x4 = view.path.x4 + (x4 - view.path.x4)*ease
						view.path.y4 = view.path.y4 + (y4 - view.path.y4)*ease
					else
						view.xScale = view.xScale + (xScale - view.xScale)*ease
						view.yScale = view.yScale + (yScale - view.yScale)*ease
					end
				end
			end
			animateView(buttonHoveringOn.button)
			for i = 1, #buttonHoveringOn.otherViewsToAnimate do
				animateView(buttonHoveringOn.otherViewsToAnimate[i])
			end

			-- if inside a scrollview, scroll automatically to the buttons
			-- print( type(((buttonHoveringOn.button or {}).parent or {})) )
			local searchForScrollView; searchForScrollView = function(view)
				local parent = view.parent
				if parent then
					if type(parent.scrollToPosition) == "function" then
						return parent
					else
						return searchForScrollView(parent)
					end
				end
			end
			local scrollView = searchForScrollView(buttonHoveringOn.button)
			if scrollView then
				-- TODO: horizontal scroll
				local x, y = scrollView:getContentPosition()
				local buttonX, buttonY = buttonHoveringOn.button.x, buttonHoveringOn.button.y
				local newY =  y + (-buttonY + scrollView.height*.5 - y)*.07
				scrollView:scrollToPosition({
					y = newY,
					time = 0
				})
			end

			if menuClick then
				clickButton(buttonHoveringOn)
			elseif backClick then
				local preferreddBackFuncHandledBack = false
				-- if hub.preferreddBackFunc2 then
				-- 	preferreddBackFuncHandledBack = hub.preferreddBackFunc2({
				-- 		currentButtonHoveringOn = buttonHoveringOn or {}
				-- 	})
				-- end
				-- if not preferreddBackFuncHandledBack then
				-- 	if hub.preferreddBackFunc then
				-- 		preferreddBackFuncHandledBack = hub.preferreddBackFunc({
				-- 			currentButtonHoveringOn = buttonHoveringOn or {}
				-- 		})
				-- 	end
				-- end
				-- if not preferreddBackFuncHandledBack then
				-- 	local backBtnData = hub.highestPriorityBackBtn()
				-- 	if backBtnData then
				-- 		clickButton(backBtnData)
				-- 	end
				-- end
			else
				if appleTvMenuMode == "discrete" then
					discreteMovement = checkMenuMovement(discreteMovement)
				elseif appleTvMenuMode == "continuous" then
					continuousMovement = checkMenuMovement(continuousMovement)
				end
				if joyStickMenuMovement ~= nil then
					joyStickMenuMovement = checkMenuMovement(joyStickMenuMovement)
					if joyStickMenuMovement == nil then
						joyStickMenuMovement = "wait_for_joystick_centering"
					end
				end
			end
		end
		menuClick = false
		backClick = false

		-- notify listeners
		local controlsTable = virtualController:getControlsTable()
		for i=1, #controlsTable do
			if controlsTable[i] ~= lastControlsTable[i] then
				print(controlTableMap[i],"changed")
				-- hub.notifyListener(virtualController.id, controlTableMap[i], controlsTable[i])
				-- if not buttonHoveringOn then
				-- 	if hub.screenIsLiveMenu then
				-- 		virtualController.isAwake = true
				-- 		hub.enableControllersForMenus()
				-- 	end
				-- end
			end
		end
		lastControlsTable = controlsTable
	end
	Runtime:addEventListener( "enterFrame", onEnterFrame )

	virtualController.isVisible = false

	function virtualController:destroy()
		Runtime:removeEventListener( "touch", touchListener )
		Runtime:removeEventListener( "key", onKeyEvent )
		Runtime:removeEventListener( "axis", onAxisEvent )
		Runtime:removeEventListener( "enterFrame", onEnterFrame )
		self:removeSelf()
	end
    return virtualController
end


return VirtualController