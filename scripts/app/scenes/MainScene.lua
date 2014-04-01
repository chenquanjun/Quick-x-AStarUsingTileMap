
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
    do --mapinfo
        _mapInfo = MapInfo:create("map.tmx")
        self:addChild(_mapInfo)
        
    end

    do -- 动作
        local cache = CCSpriteFrameCache:sharedSpriteFrameCache()
        cache:addSpriteFramesWithFile("player1.plist")

        local sprite = CCSprite:createWithSpriteFrameName("player1_0_0.png")
        
        self:addChild(sprite)

        local indexFlag = 1 --执行标志
        local mapPath = _mapInfo:findPath(145, 150) --地图路径类

        local startPoint = mapPath:getPointAtIndex(indexFlag) --第一个点
        local pointNum = mapPath:getPointArrCount()
        
        sprite:setPosition(startPoint)
        print("num:"..pointNum)

        local delay = CCDelayTime:create(0.2) --延迟
        local callfunc = CCCallFunc:create(function()
                            local point = mapPath:getPointAtIndex(indexFlag)
                            indexFlag = indexFlag + 1 --标志增加
                            sprite:setPosition(point) --设置坐标

                            if indexFlag == pointNum then

                                sprite:stopActionByTag(999) --停止
                            end
                            end)
        local sequence = CCSequence:createWithTwoActions(delay, callfunc)
        local action = CCRepeatForever:create(sequence)
        action:setTag(999)
        sprite:runAction(action)
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
