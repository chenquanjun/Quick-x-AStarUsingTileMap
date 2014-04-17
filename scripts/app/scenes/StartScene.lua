

local StartScene = class("StartScene", function()
    return display.newScene("StartScene")
end)

function StartScene:ctor()
    local label = CCLabelTTF:create("开始游戏", "Arial", 50)
    self:addChild(label)
    label:setPosition(ccp(display.cx, display.cy))

    label:setTouchEnabled(true)

    label:addTouchEventListener(function(event, x, y)

        if event == "began" then
            return true -- catch touch event, stop event dispatching
        end

        local touchInSprite = label:getCascadeBoundingBox():containsPoint(CCPoint(x, y))
        if event == "moved" then
            if touchInSprite then

            else

            end
        elseif event == "ended" then
            if touchInSprite then 
                self:transToMain()
            end

        else

        end
    end)
end

function StartScene:transToMain()
    local MainScene = require("app/scenes/MainScene")
    display.replaceScene(MainScene.new())
end

function StartScene:onEnter()
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

end

function StartScene:onExit()

end

return StartScene
