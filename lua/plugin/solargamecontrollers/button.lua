--
-- button.lua
--

local Button = {}

function Button.create(params)
    local button = display.newGroup()
    local params = params or {}
    if type(params.inputId) ~= "string" then
        print("ERROR: an inputId (string) must be specified for a button")
        return
    end
    if type(params.size) ~= "number" then
        print("ERROR: a size must be a number")
        return
    end
    if params.images and (type(params.images) ~= "table" or type(params.images.up) ~= "string" or type(params.images.down) ~= "string") then
        print("ERROR: images must be a table for of strings for button paths, for example {down = \"buttonadown.png\", up = \"buttonaup.png\"}")
        return
    end

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
    local relativeDefaultMargin = 0 -- todo
    local relativeDirection = 0
    local relativePlayerCanChangeDirection = false-- todo

    local buttonSize = params.size or 70
    local inputId = params.inputId
    local isPushed = false

    -- up button
    local buttonUp = display.newGroup()
    if params.images then
        local image = display.newImage(params.images.up)
        local maxLength = math.max(image.width,image.height)
        image.xScale = buttonSize/maxLength
        image.yScale = buttonSize/maxLength
        buttonUp.image = image
        buttonUp:insert(image)
    else
        local image = display.newCircle(0,0,buttonSize*.5)
        image:setFillColor(1,.5,.5)
        buttonUp.image = image
        buttonUp:insert(image)
    end
    buttonUp.alpha = 1
    button:insert(buttonUp)

    -- down button
    local buttonDown = display.newGroup()
    if params.images then
        local image = display.newImage(params.images.down)
        local maxLength = math.max(image.width,image.height)
        image.xScale = buttonSize/maxLength
        image.yScale = buttonSize/maxLength
        buttonDown.image = image
        buttonDown:insert(image)
    else
        local image = display.newCircle(0,0,buttonSize*.5)
        image:setFillColor(1,.5,.5,.5)
        buttonDown.image = image
        buttonDown:insert(image)
    end
    buttonDown.alpha = 0
    button:insert(buttonDown)

    function button:getControls()
        return {[inputId] = isPushed}
    end


    -- animations
    function button:setOnShow(onShow)
        onShowAnimation = onShow or function(buttonUp, buttonDown) return 0 end
    end
    function button:setOnHide(onHide)
        onHideAnimation = onHide or function(buttonUp, buttonDown) return 0 end
    end

    function button:setOnPress(onPress)
        onPressAnimation = onPress or function(buttonUp, buttonDown)
			transition.cancel(buttonUp)
			transition.cancel(buttonDown)
			transition.to(buttonUp,   {transition = easing.outQuad, alpha = 0, xScale = 1.1, yScale = 1.1, time = 20})
			transition.to(buttonDown, {transition = easing.outQuad, alpha = 1, xScale = 1.1, yScale = 1.1, time = 20})
        end
    end
    function button:setOnRelease(onRelease)
        onReleaseAnimation = onRelease or function(buttonUp, buttonDown)
			transition.cancel(buttonUp)
			transition.cancel(buttonDown)
			transition.to(buttonUp,   {transition = easing.outQuad, alpha = 1, xScale = 1, yScale = 1, time = 20})
			transition.to(buttonDown, {transition = easing.outQuad, alpha = 0, xScale = 1, yScale = 1, time = 20})
        end
    end

    -- position
    function button:setAbsolutePosition(x, y)
        positionMode = "absolute"
        absoluteX = x
        absoluteY = y
    end
    function button:setRelativePosition(nameOfOtherElement, defaultMargin, direction, playerCanChangeDirection)
        positionMode = "relative"
        relativeNameOfOtherElement = nameOfOtherElement
        relativeDefaultMargin = defaultMargin
        relativeDirection = direction
        relativePlayerCanChangeDirection = playerCanChangeDirection
    end
    function button:getPositionMode()
        return positionMode
    end
    function button:getNameOfOtherElement()
        return relativeNameOfOtherElement
    end
    function button:arrange(_space, _isVertical, _flipSides, otherElement)
        if positionMode == "absolute" then
            button.x = _space.l + buttonSize*.5 + (absoluteX+1)*.5*(_space.r - _space.l - buttonSize)
            button.y = _space.t + buttonSize*.5 + (absoluteY+1)*.5*(_space.b - _space.t - buttonSize)
        elseif positionMode == "relative" then
            local offsetX = math.cos(math.rad(relativeDirection)) * (otherElement:getSize() + buttonSize)*.5
            local offsetY = math.sin(math.rad(relativeDirection)) * (otherElement:getSize() + buttonSize)*.5
            button.x = otherElement.x + offsetX
            button.y = otherElement.y - offsetY
        end
    end
    function button:getSize()
        return buttonSize
    end

    return button
end



return Button