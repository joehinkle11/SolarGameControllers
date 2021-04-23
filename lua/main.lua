------------------------------------------------------------
--
-- Solar Game Controllers Library Plugin Test Project
--
-- Joe Hinkle, 2020
--
------------------------------------------------------------

-- Load plugin library
local SolarGameControllers = require "plugin.solargamecontrollers"
-- local QuickJs = require "plugin.solarquickjs"


local rect = display.newRect(0,0,10,10)
rect:setFillColor(.4,.3,.3)

local rect2 = display.newRect(-1000,200,10000,100)

local QuickJs = require("plugin.quickjs")
local widget = require("widget")
widget.newButton({
    left = 150,
    width = 100,
    top = 50,
    label = "Fullscreen!",
    shape = "rect",
    onRelease = function()
        QuickJs.run {
            js = "window.document.getElementsByTagName('html')[0].requestFullscreen()"
        }
    end,
    fillColor = { default={ 1, 1, 1 }, over={ .2, 0.2, 0.2 } }
})


-- if we are on platforms without touchscreens
-- local isOnDeviceWithTouchScreen = QuickJs.run {
-- 	js = [[
-- 		// source: https://stackoverflow.com/a/4819886/3902590
-- 		var prefixes = ' -webkit- -moz- -o- -ms- '.split(' ');
-- 		var mq = function (query) {
-- 			return window.matchMedia(query).matches;
-- 		}
-- 		if (('ontouchstart' in window) || window.DocumentTouch && document instanceof DocumentTouch) {
-- 			return true;
-- 		}
-- 		var query = ['(', prefixes.join('touch-enabled),('), 'heartz', ')'].join('');
-- 		return mq(query);
-- 	]],
-- 	lua = function()
-- 		if system.getInfo("platform") == "android" or system.getInfo("platform") == "ios" or system.getInfo("platform") == "tvos" then
-- 			return true
-- 		else
-- 			return false
-- 		end
-- 	end
-- }
-- if not isOnDeviceWithTouchScreen then
-- 	SolarGameControllers.alwaysHideOnScreenControls()
-- end

-- setup or gamepad schema
SolarGameControllers.addSchema("example_gamepad", {
    {
        type = "direction",
        inputId = "joystick",
        name = "joystick",
        touchGroup = "joystickgroup",
        size = 70,
        allowValuesOutsideCircle = false,
        deadZone = .1,
        forceMaxes = false,
        joyStickImages = {
            top = "joystick.png",
            bottom = "joystick.png",
            topScaleFactor = .7
        },
        dPadImages = {
            up = "dpadpiece.png",
            down = "dpadpiece.png",
            left = "dpadpiece.png",
			right = "dpadpiece.png",
			dPadSpacingFactor = .3,
			dPadScaleFactor = .5
        },
        onShow = function(joyStickBottom, joyStickTop, dPadTop, dPadBottom, dPadLeft, dPadRight)
			joyStickBottom.y = 200
			joyStickTop.y = 200
			dPadTop.y = 200
			dPadBottom.y = 200
			dPadLeft.y = 200
			dPadRight.y = 200
			transition.to(joyStickBottom, {delay = 0,  transition = easing.outQuad, y = 0, time = 250})
			transition.to(joyStickTop,    {delay = 10, transition = easing.outQuad, y = 0, time = 250})
			transition.to(dPadTop,        {delay = 20, transition = easing.outQuad, y = 0, time = 250})
			transition.to(dPadBottom,     {delay = 30, transition = easing.outQuad, y = 0, time = 250})
			transition.to(dPadLeft,       {delay = 40, transition = easing.outQuad, y = 0, time = 250})
			transition.to(dPadRight,      {delay = 50, transition = easing.outQuad, y = 0, time = 250})
			return 300
        end,
        onHide = function(joyStickBottom, joyStickTop, dPadTop, dPadBottom, dPadLeft, dPadRight)
			transition.to(joyStickBottom, {delay = 0,  transition = easing.outQuad, y = 200, time = 250})
			transition.to(joyStickTop, 	  {delay = 10, transition = easing.outQuad, y = 200, time = 250})
			transition.to(dPadTop,        {delay = 20, transition = easing.outQuad, y = 200, time = 250})
			transition.to(dPadBottom,     {delay = 30, transition = easing.outQuad, y = 200, time = 250})
			transition.to(dPadLeft,       {delay = 40, transition = easing.outQuad, y = 200, time = 250})
			transition.to(dPadRight,      {delay = 50, transition = easing.outQuad, y = 200, time = 250})
			return 300
        end,
        calcAbsolutePosition = {-1, 1},
        onPress = function(joyStickBottom, joyStickTop, dPadTop, dPadBottom, dPadLeft, dPadRight, selectedDPad, joyX, joyY)
            dPadTop.alpha = 1
            dPadBottom.alpha = 1
            dPadLeft.alpha = 1
            dPadRight.alpha = 1
            selectedDPad.alpha = .5
        end,
        onRelease = function(joyStickBottom, joyStickTop, dPadTop, dPadBottom, dPadLeft, dPadRight)
            dPadTop.alpha = 1
            dPadBottom.alpha = 1
            dPadLeft.alpha = 1
            dPadRight.alpha = 1
        end
    },
    {
        type = "button",
        name = "abutton",
        inputId = "a",
        touchGroup = "buttongroup",
        size = 70,
        images = {
            down = "buttona.png",
            up = "buttona.png"
        },
		calcAbsolutePosition = {1, 1},
		onShow = function(buttonUp, buttonDown)
			buttonUp.y = 200
			buttonDown.y = 200
			transition.to(buttonUp,   {delay = 60, transition = easing.outQuad, y = 0, time = 250})
			transition.to(buttonDown, {delay = 70, transition = easing.outQuad, y = 0, time = 250})
			return 320
		end,
		onHide = function(buttonUp, buttonDown)
			transition.to(buttonUp,   {delay = 60, transition = easing.outQuad, y = 200, time = 250})
			transition.to(buttonDown, {delay = 70, transition = easing.outQuad, y = 200, time = 250})
			return 320
		end,
        onPress = function(buttonUp, buttonDown)
			transition.cancel(buttonUp)
			transition.cancel(buttonDown)
			transition.to(buttonUp,   {transition = easing.outQuad, alpha = 0, xScale = 1.1, yScale = 1.1, time = 20})
			transition.to(buttonDown, {transition = easing.outQuad, alpha = 1, xScale = 1.1, yScale = 1.1, time = 20})
        end,
		onRelease = function(buttonUp, buttonDown)
			transition.cancel(buttonUp)
			transition.cancel(buttonDown)
			transition.to(buttonUp,   {transition = easing.outQuad, alpha = 1, xScale = 1, yScale = 1, time = 20})
			transition.to(buttonDown, {transition = easing.outQuad, alpha = 0, xScale = 1, yScale = 1, time = 20})
        end
    },
    {
        type = "button",
        name = "bbutton",
        inputId = "b",
        touchGroup = "buttongroup",
        size = 50,
        images = {
            down = "buttonb.png",
            up = "buttonb.png"
        },
        calcRelativePosition = {"abutton", 10, 180, true},
		onShow = function(buttonUp, buttonDown)
			buttonUp.y = 200
			buttonDown.y = 200
			transition.to(buttonUp,   {delay = 60, transition = easing.outQuad, y = 0, time = 250})
			transition.to(buttonDown, {delay = 70, transition = easing.outQuad, y = 0, time = 250})
			return 320
		end,
		onHide = function(buttonUp, buttonDown)
			transition.to(buttonUp,   {delay = 60, transition = easing.outQuad, y = 200, time = 250})
			transition.to(buttonDown, {delay = 70, transition = easing.outQuad, y = 200, time = 250})
			return 320
		end,
        onPress = function(buttonUp, buttonDown)
			transition.cancel(buttonUp)
			transition.cancel(buttonDown)
			transition.to(buttonUp,   {transition = easing.outQuad, alpha = 0, xScale = 1.1, yScale = 1.1, time = 20})
			transition.to(buttonDown, {transition = easing.outQuad, alpha = 1, xScale = 1.1, yScale = 1.1, time = 20})
        end,
		onRelease = function(buttonUp, buttonDown)
			transition.cancel(buttonUp)
			transition.cancel(buttonDown)
			transition.to(buttonUp,   {transition = easing.outQuad, alpha = 1, xScale = 1, yScale = 1, time = 20})
			transition.to(buttonDown, {transition = easing.outQuad, alpha = 0, xScale = 1, yScale = 1, time = 20})
        end
    },
})

-- make the player 1 controller
SolarGameControllers.newController("example_gamepad", {
	isOnScreen = true
})

-- show the controller
SolarGameControllers.requestToShowOnScreenControls(function(event)
	-- here we get our options to show controllers on the screen
    local availableControllersIds = event.availableControllersIds
    -- maybe we only want to show the first two controllers
    local controllerIdsToShow = {availableControllersIds[1], availableControllersIds[2]}
    -- here is the function we call to commit to showing our controllers
    local show = event.show
    -- only proceed to show if we have enough controllers, maybe we want to do a 2-player mode and we need two players
    -- if #controllerIdsToShow == 2 then
		-- when we call it, we can pass some options
        show({
            controllerIds = controllerIdsToShow,
            noAnimation = false
        })
    -- end
end)

local margin = 20
-- Called when the app's view has been resized
local function onResize( event )
	local screenL = -(display.actualContentWidth-display.contentWidth)*.5
	local screenR = display.actualContentWidth-(display.actualContentWidth-display.contentWidth)*.5
	local screenT = -(display.actualContentHeight-display.contentHeight)*.5 + display.topStatusBarContentHeight
	local screenB = display.actualContentHeight-(display.actualContentHeight-display.contentHeight)*.5
	local screenW = screenR - screenL
	local screenH = screenB - screenT
	rect.x = (screenL + screenR)*.5
	rect.y = (screenT + screenB)*.5
	rect.width = screenW - margin
	rect.height = screenH - margin
end
onResize()
 
-- Add the "resize" event listener
Runtime:addEventListener( "resize", onResize )