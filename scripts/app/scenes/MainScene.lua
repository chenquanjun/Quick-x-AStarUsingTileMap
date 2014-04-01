
require "app/scenes/MapPath"
require "app/scenes/MapInfo"
require "app/scenes/NPCSprite"
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
    -- local scheduler = require("framework.scheduler")
    -- handle = scheduler.scheduleUpdateGlobal(function()
    --     self:update()
    -- end)
    do -- 动作
        local cache = CCSpriteFrameCache:sharedSpriteFrameCache()
        cache:addSpriteFramesWithFile("player1.plist")

        local sprite = CCSprite:createWithSpriteFrameName("player1_0_0.png")
        
        self:addChild(sprite)

        self:walkTo(sprite, 0.3, 145, 146)
    end

    do
        local testSprite = NPCSprite:create("player1_%i_%i.png")
        self:addChild(testSprite)
    end


end

function MainScene:playActionAnimByPos(sprite, startPoint, endPoint)
    local offsetX = endPoint.x - startPoint.x
    local offsetY = endPoint.y - startPoint.y
    local actionType = kActionInvalid

    if offsetY > 5 then
        actionType = kActionUp
    elseif offsetY < -5 then
        actionType = kActionDown
    elseif offsetX > 5 then
        actionType = kActionRight
    elseif offsetX < -5 then
        actionType = kActionLeft
    end

    sprite:stopActionByTag(kActionUp)
    sprite:stopActionByTag(kActionDown)
    sprite:stopActionByTag(kActionRight)
    sprite:stopActionByTag(kActionLeft)

    
end

--sprite: 精灵，speed: 移动一格的速度, startId:开始id，endId:结束id
function MainScene:walkTo(sprite, speed, startId, endId)
        local indexFlag = 0 --执行标志
        local unitDivideNum = 10 --两个格子之间划分成10个坐标点
        local actionTag = kActionTagMove
        local mapPath = _mapInfo:findPath(startId, endId) --地图路径类

        if mapPath == nil then
            return --没有路径
        end

        local startPoint = mapPath:getPointAtIndex(1) --第一个点
        local pointNum = mapPath:getPointArrCount()
        
        sprite:setPosition(startPoint)
        sprite:stopActionByTag(actionTag)
        
        local delay = CCDelayTime:create(speed / 10) --延迟
        local callfunc = CCCallFunc:create(function()
                            --index 从 1 开始，所以需要 +1
                            local index = _mapInfo:int(indexFlag / unitDivideNum) + 1  
                            
                            local curPoint = mapPath:getPointAtIndex(index)
                               
                            if index < pointNum then
                                --线性化坐标点,
                                local nextPoint = mapPath:getPointAtIndex(index + 1)
                                local offset = (indexFlag - (index - 1) * unitDivideNum) / unitDivideNum
                                local x = curPoint.x + (nextPoint.x - curPoint.x) * offset
                                local y = curPoint.y + (nextPoint.y - curPoint.y) * offset
                                curPoint = ccp(x, y) 

                            elseif index == pointNum then
                                sprite:stopActionByTag(actionTag) --停止
                            end
                            indexFlag = indexFlag + 1 --标志增加

                            sprite:setPosition(curPoint) --设置坐标

                            end)
        local sequence = CCSequence:createWithTwoActions(delay, callfunc)
        local action = CCRepeatForever:create(sequence)
        action:setTag(actionTag)
        sprite:runAction(action)
end

function MainScene:update()
    -- print("callback")
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
