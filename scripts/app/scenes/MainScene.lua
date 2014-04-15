require "app/controller/ManageController"

--local var
local _controller = nil


local MainScene = class("MainScene", function()
    return display.newScene("MainScene")
end)

function MainScene:ctor()
    _controller = ManageController:create()
    self:addChild(_controller)

end

function MainScene:onEnter()
    if device.platform == "android" then
        -- avoid unmeant back
        self:performWithDelay(function()
            -- keypad layer, for android
            local layer = display.newLayer()
            layer:addKeypadEventListener(function(event)
                if event == "back" then app.exit() end
            end)
            self:addChild(layer)

            layer:setKeypadEnabled(true)
        end, 0.5)
    end

    _controller:onEnter()
end

function MainScene:onExit()
    _controller:onRelease()
    _controller = nil
end

return MainScene
