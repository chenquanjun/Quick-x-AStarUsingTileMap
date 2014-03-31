
require "app/scenes/MapPath"
require "app/scenes/MapInfo"
--local var
local _mapLayer = nil --地图layer
local _mapInfo = nil

local MainScene = class("MainScene", function()
    return display.newScene("MainScene")
end)

function MainScene:ctor()
    ui.newTTFLabel({text = "Hello, World", size = 64, align = ui.TEXT_ALIGN_CENTER})
        :pos(display.cx, display.cy)
        :addTo(self)
    --所有map对象的容器
    _mapLayer = display.newLayer()
    self:addChild(_mapLayer)


    do   --tmx地图
        local map = CCTMXTiledMap:create("map.tmx")
        _mapLayer:addChild(map)

        local  pChildrenArray = map:getChildren()
        local  child = nil
        local  pObject = nil
        local  i = 0
        local  len = pChildrenArray:count()
        for i = 0, len-1, 1 do
            pObject = pChildrenArray:objectAtIndex(i)
            child = tolua.cast(pObject, "CCSpriteBatchNode")

            if child == nil then
                break
            end

            child:getTexture():setAntiAliasTexParameters()
        end
    end
    do
        _mapInfo = MapInfo:create("map.tmx")

        local pointArr = CCPointArray:create(0)
        pointArr:add(ccp(1, 1))
        pointArr:add(ccp(1, 1))
        pointArr:add(ccp(1, 1))
        local mapPath =  MapPath:create(1, 2, pointArr)

        self:addChild(mapPath)

    end

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


end

function MainScene:onExit()
end

return MainScene
