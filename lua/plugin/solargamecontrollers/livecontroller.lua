--
-- livecontroller.lua
--

local LiveController = {}

function LiveController.start()
    system.activate( "multitouch" )
    display.setStatusBar( display.HiddenStatusBar )

    local bg = display.newRect(0,0,0,0)
    bg:setFillColor("red")
    bg.alpha = .12
    hub.subToScreenPositionUpdates(bg, function()
        bg.x = screenCX
        bg.y = screenCYWithSB
        bg.width = screenAW
        bg.height = screenAHWithSB
    end)

    local title = display.newText("Welcome to the livegames.cc Controller!",0,0,nil,38)
    title:setFillColor(1)
    hub.subToScreenPositionUpdates(title, function()
        title.x = screenCX
        title.y = screenT + 20
    end)

    local message = display.newText {
        text = "We are searching for games on your local network. Be sure to connect to the same WiFi network that your system is running on..."
    }
    message:setFillColor(1)
    hub.subToScreenPositionUpdates(message, function()
        message:removeSelf()
        message = display.newText {
            text = "We are searching for games on your local network. Be sure to connect to the same WiFi network that your system is running on...",
            fontSize = 28,
            width = math.min(500,screenAW*.9)
        }
        message.x = title.x
        message.y = title.y + title.height*.5 + message.height*.5 + 5
        message.width = math.min(500,screenAW*.9)
    end)

    --
    -- network logic
    --
    local localController = hub.addLocalController()
    local localControllerId = localController.id
    function sentToGame(data)
        local timestr = "_"..tostring(system.getTimer())
        local payload = data..timestr
        hub.networking.send(payload)
        -- network.request( "http://192.168.0.103:8080/"..payload, "GET", function(event) 
        --     if ( event.isError ) then
        --         print("Network error: " .. tostring(event.response))
        --     else
        --         print("RESPONSE: " .. tostring(event.response))
        --     end
        -- end)
    end
    hub.addControlListener(localControllerId, "a", function(value)
        if value then
            print(sentToGame("A"))
        else
            print(sentToGame("a"))
        end
    end)
    hub.addControlListener(localControllerId, "b", function(value)
        if value then
            print(sentToGame("B"))
        else
            print(sentToGame("b"))
        end
    end)
    hub.addControlListener(localControllerId, "c", function(value)
        if value then
            print(sentToGame("C"))
        else
            print(sentToGame("c"))
        end
    end)
    hub.addControlListener(localControllerId, "joyx", function(value)
        print(sentToGame("x"..value))
    end)
    hub.addControlListener(localControllerId, "joyy", function(value)
        print(sentToGame("y"..value))
    end)
    hub.networking.scan(message)
end

function LiveController.kill()
    -- todo
end

return LiveController