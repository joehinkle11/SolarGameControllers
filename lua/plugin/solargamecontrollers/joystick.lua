--
-- joyStick.lua
--

local JoyStick = {}

function JoyStick.create(params)
    local joyStick = display.newGroup()
    local params = params or {}
    if type(params.inputId) ~= "string" then
        print("ERROR: an inputId (string) must be specified for a button")
        return
    end
    if type(params.size) ~= "number" then
        print("ERROR: a size must be a number")
        return
    end
    if params.joyStickImages and (type(params.joyStickImages) ~= "table" or type(params.joyStickImages.top) ~= "string" or type(params.joyStickImages.bottom) ~= "string" or (params.joyStickImages.topScaleFactor ~= nil and type(params.joyStickImages.topScaleFactor) ~= "number")) then
        print("ERROR: joyStickImages must be a table for of strings for button paths and an optional topScaleFactor (number), for example {top = \"joysticktop.png\", bottom = \"joystickbottom.png\", topScaleFactor = .85}")
        return
    end
    if params.dPadImages and (type(params.dPadImages) ~= "table" or type(params.dPadImages.up) ~= "string" or type(params.dPadImages.down) ~= "string"  or type(params.dPadImages.left) ~= "string"  or type(params.dPadImages.right) ~= "string" or (params.dPadImages.dPadScaleFactor ~= nil and type(params.dPadImages.dPadScaleFactor) ~= "number") or (params.dPadImages.dPadSpacingFactor ~= nil and type(params.dPadImages.dPadSpacingFactor) ~= "number")) then
        print("ERROR: dPadImages must be a table for of strings for button paths and optional dPadScaleFactor and dPadSpacingFactor (number), for example {up = \"dpadpiecetop.png\", down = \"dpadpiecebottom.png\", left = \"dpadpieceleft.png\", right = \"dpadpieceright.png\", dPadScaleFactor = .5, dPadSpacingFactor = .5}")
        return
    end

    local buttonSize = params.size or 70

    -- animations
    local onShowAnimation
    local onHideAnimation
    local onPressAnimation
    local onReleaseAnimation

    -- position
    local positionMode = "absolute" -- or "relative"
    local absoluteX = 0
    local absoluteY = 0
    local relativeNameOfOtherElement = ""
    local relativeDefaultMargin = 0
    local relativeDirection = 0
    local relativePlayerCanChangeDirection = false

    local joyStickSpeedX = 0
    local joyStickSpeedY = 0
    local unclippedJoyStickSpeedX = 0
    local unclippedJoyStickSpeedY = 0

    joyStick.isVertical = false
    joyStick.flipSides = false
    local showDPad = false

    local joyStickSize = buttonSize
    local dPadSpacingFactor = params.dPadImages.dPadSpacingFactor or .5
    local arrowSize = joyStickSize * (params.dPadImages.dPadScaleFactor or .15)
    -- left
    local leftArrow = display.newGroup()
    if params.dPadImages then
        local image = display.newImage(params.dPadImages.left)
        local maxLength = math.max(image.width,image.height)
        image.xScale = arrowSize/maxLength
        image.yScale = arrowSize/maxLength
        leftArrow.image = image
        leftArrow:insert(image)
    else
        local image = display.newCircle(0,0,arrowSize*.5)
        image:setFillColor(1,.5,.5)
        leftArrow.image = image
        leftArrow:insert(image)
    end
    leftArrow.x = -joyStickSize*dPadSpacingFactor
    leftArrow.rotation = -90
    joyStick:insert(leftArrow)

	-- right
    local rightArrow = display.newGroup()
    if params.dPadImages then
        local image = display.newImage(params.dPadImages.right)
        local maxLength = math.max(image.width,image.height)
        image.xScale = arrowSize/maxLength
        image.yScale = arrowSize/maxLength
        rightArrow.image = image
        rightArrow:insert(image)
    else
        local image = display.newCircle(0,0,arrowSize*.5)
        image:setFillColor(1,.5,.5)
        rightArrow.image = image
        rightArrow:insert(image)
    end
    rightArrow.x = joyStickSize*dPadSpacingFactor
    rightArrow.rotation = 90
    joyStick:insert(rightArrow)

	-- down
    local downArrow = display.newGroup()
    if params.dPadImages then
        local image = display.newImage(params.dPadImages.down)
        local maxLength = math.max(image.width,image.height)
        image.xScale = arrowSize/maxLength
        image.yScale = arrowSize/maxLength
        downArrow.image = image
        downArrow:insert(image)
    else
        local image = display.newCircle(0,0,arrowSize*.5)
        image:setFillColor(1,.5,.5)
        downArrow.image = image
        downArrow:insert(image)
    end
    downArrow.y = joyStickSize*dPadSpacingFactor
    downArrow.rotation = 180
    joyStick:insert(downArrow)

	-- up
    local upArrow = display.newGroup()
    if params.dPadImages then
        local image = display.newImage(params.dPadImages.up)
        local maxLength = math.max(image.width,image.height)
        image.xScale = arrowSize/maxLength
        image.yScale = arrowSize/maxLength
        upArrow.image = image
        upArrow:insert(image)
    else
        local image = display.newCircle(0,0,arrowSize*.5)
        image:setFillColor(1,.5,.5)
        upArrow.image = image
        upArrow:insert(image)
    end
    upArrow.y = -joyStickSize*dPadSpacingFactor
    upArrow.rotation = 0
    joyStick:insert(upArrow)

	-- bottom joystick part
    local joyStick1 = display.newGroup()
    if params.joyStickImages then
        local image = display.newImage(params.joyStickImages.bottom)
        local maxLength = math.max(image.width,image.height)
        image.xScale = joyStickSize/maxLength
        image.yScale = joyStickSize/maxLength
        joyStick1.image = image
        joyStick1:insert(image)
    else
        local image = display.newCircle(0,0,joyStickSize*.5)
        image:setFillColor(1,.5,.5)
        joyStick1.image = image
        joyStick1:insert(image)
    end
	joyStick1.rotation = 0
    joyStick:insert(joyStick1)

    -- top joystick part
    local joyStick2 = display.newGroup()
    if params.joyStickImages then
        local image = display.newImage(params.joyStickImages.top)
        local maxLength = math.max(image.width,image.height)
        image.xScale = (joyStickSize*(params.joyStickImages.topScaleFactor or .85))/maxLength
        image.yScale = (joyStickSize*(params.joyStickImages.topScaleFactor or .85))/maxLength
        joyStick2.image = image
        joyStick2:insert(image)
    else
        local image = display.newCircle(0,0,joyStickSize*.5*(params.joyStickImages.topScaleFactor or .85))
        image:setFillColor(1,.5,.5)
        joyStick2.image = image
        joyStick2:insert(image)
    end
	joyStick2.rotation = 0
    joyStick:insert(joyStick2)


    function joyStick:setToDPad()
        leftArrow.isVisible = true
        rightArrow.isVisible = true
        downArrow.isVisible = true
        upArrow.isVisible = true
        joyStick1.isVisible = false
        joyStick2.isVisible = false
        showDPad = true
    end
    function joyStick:setToJoyStick()
        leftArrow.isVisible = false
        rightArrow.isVisible = false
        downArrow.isVisible = false
        upArrow.isVisible = false
        joyStick1.isVisible = true
        joyStick2.isVisible = true
        showDPad = false
    end

    local dist = joyStickSize*.35
    local distSqrd = dist*dist
    local function setJoyStickVisualPos(x, y)
        if not showDPad then
            if math.abs(y) + math.abs(x) > 0 then
                if (y*y) + (x*x) > distSqrd then
                    local theta = math.atan(y/x)
                    if x < 0 then
                        joyStick2.x = -math.cos(theta)*dist
                        joyStick2.y = -math.sin(theta)*dist
                    else
                        joyStick2.x = math.cos(theta)*dist
                        joyStick2.y = math.sin(theta)*dist
                    end
                else
                    joyStick2.x = x
                    joyStick2.y = y
                end
            else
                joyStick2.x = 0
                joyStick2.y = 0
            end
        end
    end

    function joyStick:touch(event)
        if("moved" == event.phase or "began" == event.phase) then
            local x, y = (event.x or (joyStick2.x+self.x)), (event.y or (joyStick2.y+self.y))
            setJoyStickVisualPos(x - self.x, y - self.y)
            --push or change which button is pushed by sliding
            if x - self.x > 15 then
                rightArrow.alpha = .1
                leftArrow.alpha = 1
                joyStickSpeedX = 30
            elseif x - self.x < -15 then
                rightArrow.alpha = 1
                leftArrow.alpha = .1
                joyStickSpeedX = -30
            else
                rightArrow.alpha = 1
                leftArrow.alpha = 1
                joyStickSpeedX = 0
            end
            --imaginary up or down
            if y - self.y < -15 then
                joyStickSpeedY = -30
                upArrow.alpha = .1
                downArrow.alpha = 1
            elseif y - self.y > 15 then
                joyStickSpeedY = 30
                upArrow.alpha = 1
                downArrow.alpha = .1
            else
                joyStickSpeedY = 0
                upArrow.alpha = 1
                downArrow.alpha = 1
            end
            unclippedJoyStickSpeedX = x - self.x
            unclippedJoyStickSpeedY = y - self.y
        elseif("ended" == event.phase) then
            --put joystick back
            joyStick2.x = 0
            joyStick2.y = 0
            --release
            leftArrow.alpha = 1
            rightArrow.alpha = 1
            upArrow.alpha = 1
            downArrow.alpha = 1
            joyStickSpeedX = 0
            joyStickSpeedY = 0
            unclippedJoyStickSpeedX = 0
            unclippedJoyStickSpeedY = 0
        end
    end

    local hardsPushed = {}
    local function _doHardKeyLogic(withJoyStickFix)
        if not (hardsPushed["left"] or hardsPushed["right"]) then
            joyStickSpeedX = 0
            leftArrow.alpha = 1
            rightArrow.alpha = 1
            joyStick2.x = 0
        elseif hardsPushed["right"] then
            joyStickSpeedX = 30
            leftArrow.alpha = 1
            rightArrow.alpha = .1
            joyStick2.x = dist
        elseif hardsPushed["left"] then
            joyStickSpeedX = -30
            leftArrow.alpha = .1
            rightArrow.alpha = 1
            joyStick2.x = -dist
        end
        if not (hardsPushed["up"] or hardsPushed["down"]) then
            joyStickSpeedY = 0
            upArrow.alpha = 1
            downArrow.alpha = 1
            joyStick2.y = 0
        elseif hardsPushed["down"] then
            joyStickSpeedY = 30
            upArrow.alpha = 1
            downArrow.alpha = .1
            joyStick2.y = dist
        elseif hardsPushed["up"] then
            joyStickSpeedY = -30
            upArrow.alpha = .1
            downArrow.alpha = 1
            joyStick2.y = -dist
        end
        if withJoyStickFix then
            setJoyStickVisualPos(joyStick2.x,joyStick2.y)
        end
    end
    local function undoRotation(key)
        local newKey = key
        if joyStick.isVertical then
            if joyStick.flipSides then
                if key == "up" then newKey = "left"
                elseif key == "down" then newKey = "right"
                elseif key == "left" then newKey = "down"
                elseif key == "right" then newKey = "up" end
            else
                if key == "up" then newKey = "right"
                elseif key == "down" then newKey = "left"
                elseif key == "left" then newKey = "up"
                elseif key == "right" then newKey = "down" end
            end
        end
        return newKey
    end
    function joyStick:hardSet(hardKey)
        hardsPushed[undoRotation(hardKey)] = true
        _doHardKeyLogic(true)
    end

    function joyStick:reqUnset(hardKey)
        hardsPushed[undoRotation(hardKey)] = false
        _doHardKeyLogic(false)
    end

    function joyStick:getControls()
        local x, y = joyStickSpeedX, joyStickSpeedY
        if self.isVertical then
            if self.flipSides then
                local tmp = y
                y = x
				x = -tmp
            else
                local tmp = x
				x = y
				y = -tmp
			end
		end
        return x, y
    end

    function joyStick:getUnclippedControls()
        local x, y = unclippedJoyStickSpeedX, unclippedJoyStickSpeedY
        if self.isVertical then
            if self.flipSides then
                local tmp = y
                y = x
				x = -tmp
            else
                local tmp = x
				x = y
				y = -tmp
			end
		end
        return x, y
    end

    -- animations
    function joyStick:setOnShow(onShow)
        onShowAnimation = onShow or function(joyStickBottom, joyStickTop, dPadTop, dPadBottom, dPadLeft, dPadRight) return 0 end
    end
    function joyStick:setOnHide(onHide)
        onHideAnimation = onHide or function(joyStickBottom, joyStickTop, dPadTop, dPadBottom, dPadLeft, dPadRight) return 0 end
    end

    function joyStick:setOnPress(onPress)
        onPressAnimation = onPress or function(joyStickBottom, joyStickTop, dPadTop, dPadBottom, dPadLeft, dPadRight, selectedDPad, joyX, joyY)
            dPadTop.alpha = 1
            dPadBottom.alpha = 1
            dPadLeft.alpha = 1
            dPadRight.alpha = 1
            selectedDPad.alpha = .5
        end
    end
    function joyStick:setOnRelease(onRelease)
        onReleaseAnimation = onRelease or function(joyStickBottom, joyStickTop, dPadTop, dPadBottom, dPadLeft, dPadRight, selectedDPad, joyX, joyY)
            dPadTop.alpha = 1
            dPadBottom.alpha = 1
            dPadLeft.alpha = 1
            dPadRight.alpha = 1
        end
    end

    -- position
    function joyStick:setAbsolutePosition(x, y)
        positionMode = "absolute"
        absoluteX = x
        absoluteY = y
    end
    function joyStick:setRelativePosition(nameOfOtherElement, defaultMargin, direction, playerCanChangeDirection)
        positionMode = "relative"
        relativeNameOfOtherElement = nameOfOtherElement
        relativeDefaultMargin = defaultMargin
        relativeDirection = direction
        relativePlayerCanChangeDirection = playerCanChangeDirection
    end
    function joyStick:getPositionMode()
        return positionMode
    end
    function joyStick:getNameOfOtherElement()
        return relativeNameOfOtherElement
    end
    function joyStick:arrange(_space, _isVertical, _flipSides, otherElement)
        if positionMode == "absolute" then
            joyStick.x = _space.l + buttonSize*.5 + (absoluteX+1)*.5*(_space.r - _space.l - buttonSize)
            joyStick.y = _space.t + buttonSize*.5 + (absoluteY+1)*.5*(_space.b - _space.t - buttonSize)
        elseif positionMode == "relative" then
            local offsetX = math.cos(math.rad(relativeDirection)) * (otherElement:getSize() + buttonSize)*.5
            local offsetY = math.sin(math.rad(relativeDirection)) * (otherElement:getSize() + buttonSize)*.5
            joyStick.x = otherElement.x + offsetX
            joyStick.y = otherElement.y - offsetY
        end
    end
    function joyStick:getSize()
        return buttonSize
    end

    return joyStick
end



return JoyStick