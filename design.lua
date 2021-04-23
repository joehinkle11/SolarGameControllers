

local SolarGameControllers = require "plugin.solargamecontrollers"

SolarGameControllers.addSchema(schemaName, controlSchema)
SolarGameControllers.addSchema("mygamecontroller", {
    {
        type = "direction",
        inputId = "myjoystick", -- this is the id to identifiy this specific input. for joysticks it will generate two input ids, one with "x" and one with "y" appended. So in this example there will be both "myjoystickx" and "myjoysticky" as inputIds that you could listen to
        name = "myjoystick",
        touchGroup = "myjoystickgroup", -- if elements in the schema share the same touchGroup, only one can be pushed at a time, but then you can slide your finger from one button to the other and the library will automatically change which button you are pushing. This helps keep liberal touch boundries which is important to get a touchscreen gamepad feeling responsive. I recommend putting buttons which are close together (like same side of the screen) in the same touch group
        size = 70, -- players will be able to override this, so don't assume this number will be used
        allowValuesOutsideCircle = false, -- because the joystick is a circle, dragging in the bottom right corner will give you pi/4 for x and pi/4 for y. If you would prefer that the values were not clipped to the unit circle, set allowValuesOutsideCircle to true, and you would get 1 for x and 1 for y. I recommend you set this to true
        deadZone = .1, -- Set the deadzone for the joystick. In this example, any value with .1 will be reported as 0. This in effect means you have to move the joystick more than 10% away from the center to make the joystick have a value other than 0
        forceMaxes = false, -- if set to true, any non-zero value will be reported as maxed-out. For example, if x is .5, then you will get 1 reported, and if y is -.36, then -1 will be reported. If a value is in the deadzone (or actually 0), it gets reported as 0
        -- optional images to supply
        joyStickImages = {
            top = "img.png", -- images will be used as "fit-to-scale", so if you provide a 100x50 image, and the size provided above is 70, then it will result in a 70x35 image
            bottom = "img.png",
            topScaleFactor = .5 -- you can provide this to scale down the top image
        },
        dPadImages = { -- all images for the d-pad should point up, and the library will auto rotate them. This way you can reuse the same image
            top = "arrow.png",
            bottom = "arrow.png",
            left = "arrow.png",
            right = "arrow.png"
        },
        -- animate the joystick and dpad here when they show. Their final resting position should be x = 0, y = 0, xScale = 1, yScale = 1 (even for top joystick image), and rotation = 0 (even for each dpad image). Note that the actual position of these images will not make a difference in the hitbox region for their related button/joystick etc.
        onShow = function(joyStickBottom, joyStickTop, dPadTop, dPadBottom, dPadLeft, dPadRight)
            -- example
            joyStickBottom.y = 1000
            transition.to(joyStickBottom, {y = 0})
            dPadBottom.rotation = 45
            transition.to(dPadBottom, {rotation = 0})
        end,
        onHide = function(joyStickBottom, joyStickTop, dPadTop, dPadBottom, dPadLeft, dPadRight)
            -- example
            transition.to(joyStickBottom, {y = 1000})
            transition.to(dPadBottom, {rotation = 45})
            return 500 -- return the time before you wish the whole view to be made invisible
        end,
        --
        -- supply one of two options to position. The results will be modified by the player's custom settings, and a margin will be added (adjustable by the player as well). So assume this is a gamepad without margins
        -- things like lefty mode, margin setting, and even manual adjustments are done automatically
        --
        -- option 1: relative to another element. This will give you the element's final resting place
        --      calcRelativePosition(nameOfOtherElement, defaultMargin, direction, playerCanChangeDirection)
        --      nameOfOtherElement = a string, the name of another element, the same name you provide as "name" above
        --      defaultMargin = a number, and this can be overridedden by the player and its factored in automatically
        --      direction = a number, provide in degrees the direction you want this element to be from the other element. 0 is to the right, 90 is above, 180 is to the left, and 270 is below. And of course you have everything inbetween
        --      playerCanChangeDirection = a bool, if true players can change the direction parameter when changing the control options
        calcRelativePosition = {"myabutton", 10, 135, true}, -- this will position this element left and up from myabutton
        -- option 2: absolute position. Assume no margins are set and give a 0 for centers, 1 for right and bottom and -1 for left and top
        -- option 2 example 1:
        calcAbsolutePosition = {0, 0}, -- this will place the button in the center of the screen. do not include margins, as this is done automatically
        -- option 2 example 2:
        calcAbsolutePosition = {1, 1}, -- this will place the button in the bottom right of the screen. do not include margins, as this is done automatically
        -- option 2 example 3:
        calcAbsolutePosition = {-1, 1},-- this will place the button in the bottom left of the screen. do not include margins, as this is done automatically
        --
        -- optional way to animate your button presses. selectedDPad can be an empty table, or it will be one dPadTop, dPadBottom, dPadLeft or dPadRight depending on the direction selected. The joyX joyY values will be the range [-1,1] inclusive if you want to use those values as part of your animation. Do not set the x and y of the top joystick image, as this is automatic and done immediately before this function call
        --
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
        end,
    },
    {
        type = "button",
        name = "myabutton",
        inputId = "myabutton", -- this is the id to identifiy this specific input
        touchGroup = "mybuttongroup", -- if elements in the schema share the same touchGroup, only one can be pushed at a time, but then you can slide your finger from one button to the other and the library will automatically change which button you are pushing. This helps keep liberal touch boundries which is important to get a touchscreen gamepad feeling responsive. I recommend putting buttons which are close together (like same side of the screen) in the same touch group
        size = 70, -- players will be able to override this, so don't assume this number will be used
        
        images = {
            down = "imgdown.png", -- when button is pushed
            up = "imgup.png" -- when button is not pushed
        },
        --
        -- supply one of two options to position. The results will be modified by the player's custom settings, and a margin will be added (adjustable by the player as well). So assume this is a gamepad without margins
        -- things like lefty mode, margin setting, and even manual adjustments are done automatically
        --
        -- option 1: relative to another element. This will give you the element's final resting place
        --      calcRelativePosition(nameOfOtherElement, defaultMargin, direction)
        --      nameOfOtherElement = a string, the name of another element, the same name you provide as "name" above
        --      defaultMargin = a number, and this can be overridedden by the player and its factored in automatically
        --      direction = a number, provide in degrees the direction you want this element to be from the other element. 0 is to the right, 90 is above, 180 is to the left, and 270 is below. And of course you have everything inbetween
        --      playerCanChageDirection = a bool, if true players can change the direction parameter when changing the control options
        calcRelativePosition = {"anotherbutton", 10, 135, true}, -- this will position this element left and up from myabutton
        -- option 2: absolute position. Assume no margins are set and give a 0 for centers, 1 for right and bottom and -1 for left and top
        -- option 2 example 1:
        calcAbsolutePosition = function()
            return 0, 0 -- this will place the button in the center of the screen. do not include margins, as this is done automatically
        end,
        -- option 2 example 2:
        calcAbsolutePosition = function()
            return 1, 1 -- this will place the button in the bottom right of the screen. do not include margins, as this is done automatically
        end,
        -- option 2 example 3:
        calcAbsolutePosition = function()
            return -1, 1 -- this will place the button in the bottom left of the screen. do not include margins, as this is done automatically
        end,
        --
        -- optional way to animate your button presses
        --
        onPress = function(buttonUp, buttonDown)
            buttonUp.alpha = 0
            buttonDown.alpha = 1
        end,
        onRelease = function(buttonUp, buttonDown)
            buttonUp.alpha = 1
            buttonDown.alpha = 0
        end
    },
    {
        type = "toucharea", -- this is a buttonless area to detect touches
        -- todo
    },
    {
        type = "tilt", -- accelerometer
        -- todo
    }
})

SolarGameControllers.editSchemaOptions(schemaName) -- opens up an editor for users to change their preferences. things like margins
SolarGameControllers.editSchemaOptions("mygamecontroller")

SolarGameControllers.create("mygame")

local controlDatas = SolarGameControllers.getControlDatas() -- gives you a list of all the controllers current control datas (which buttons are pushed)
for i = 1, #controlDatas do
    local controlData = controlDatas[i]
    print(controlData.id) -- controller id, int
    print(controlData.joyx) -- x pos on joystick, number
    print(controlData.joyy) -- y pos on joystick, number
    print(controlData.a) -- a button true/false
    print(controlData.b) -- b button true/false
end

SolarGameControllers.requestToShowOnScreenControls(requestCallback) -- use to show when the game starts
SolarGameControllers.requestToShowOnScreenControls(function(event)
    -- here we get our options to show controllers on the screen
    local availableControllersIds = event.availableControllersIds
    -- maybe we only want to show the first two controllers
    local controllerIdsToShow = {availableControllersIds[1], availableControllersIds[2]}
    -- here is the function we call to commit to showing our controllers
    local show = event.show
    -- only proceed to show if we have enough controllers, maybe we want to do a 2-player mode and we need two players
    if #controllerIdsToShow == 2 then
        -- when we call it, we can pass some options
        show({
            controllerIds = controllerIdsToShow,
            noAnimation = false
        })
    end
end)
SolarGameControllers.hideOnScreenControls() -- use to hide when the game ends and you're on a touchscreen menu

SolarGameControllers.alwaysHideOnScreenControls() -- call when you're on a platform without a touchscreen, and you don't want virtual touchpad controllers to ever show

SolarGameControllers.addControlListener(controllerId, inputId, callback)
local myListener = SolarGameControllers.addControlListener(1, "a", function( val, removeListener )
    print("button a on controller 0 is pushed: "..tostring(val))
    removeListener() -- a quick way to clean up
end)
SolarGameControllers.removeControlListener(myListener) -- another way to clean up

SolarGameControllers.onResize(screenTop, screenBottom, screenLeft, screenRight) -- setup the space for on screen controllers
SolarGameControllers.onResize(50, 500, 50, 500)

SolarGameControllers.listenToControllerConnections(function(event)
    if event.name == "connect" then
        local isRemote = event.isRemote -- is true when a connection from is from a controller on a device on the local network
    elseif event.name == "disconnect" then
        local isRemote = event.isRemote -- is true when a connection from is from a controller on a device on the local network
    end
end)

SolarGameControllers.startServer() -- starts a websocket server for other controllers to connect to
SolarGameControllers.stopServer() -- kills the websocket server which will result in all remote controllers disconnecting
SolarGameControllers.allowNewRemoteControllers(validSchemas) -- other devices on the same network can connect as a controller
SolarGameControllers.allowNewRemoteControllers({"mygamecontroller"}) -- you give it a list of schemas for the other controller to choose from. If one is provided, it will be chosen automatically
SolarGameControllers.disallowNewRemoteControllers() -- other devices on the same network cannot connect as a controller