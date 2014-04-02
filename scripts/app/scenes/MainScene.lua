
require "app/model/MapPath"
require "app/model/MapInfo"
require "app/view/NPCSprite"
require "app/controller/ManageController"

--local var
local _controller = nil

local _mapLayer = nil --地图layer
local _mapInfo = nil

local _seatVector = nil
local _waitSeatVector = nil
local _doorVector = nil
local _seatMap = {}  --座位字典
local _waitSeatMap = {} --等待座位字典
local _doorMap = {} --门口字典

local MainScene = class("MainScene", function()
    return display.newScene("MainScene")
end)

function MainScene:ctor()

    _controller = ManageController:create()
    self:addChild(_controller)

    --所有map对象的容器
    _mapLayer = display.newLayer()
    self:addChild(_mapLayer)


    do   --tmx地图 单纯显示用
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

    -- local scheduler = require("framework.scheduler")
    -- handle = scheduler.scheduleUpdateGlobal(function()
    --     self:update()
    -- end)

    do --mapinfo 创建地图信息类
        _mapInfo = MapInfo:create("map.tmx")
        _mapLayer:addChild(_mapInfo) --把内存释放交给2dx

        --记录哪个mapId是座位，等待座位和门口, 下标从1开始
        self._seatVector = _mapInfo:getMapTypeData(kMapDataSeat)
        self._waitSeatVector = _mapInfo:getMapTypeData(kMapDataWaitSeat)
        self._doorVector = _mapInfo:getMapTypeData(kMapDataDoor)


        for i,v in ipairs(self._seatVector) 
        do 
            _seatMap[v] = 0 --0表示空, 其他时候表示顾客的id 
        end  

        for i,v in ipairs(self._waitSeatVector) 
        do 
            _waitSeatMap[v] = 0 --0表示空, 其他时候表示顾客的id 
        end  

        for i,v in ipairs(self._doorVector) 
        do 
            _doorMap[v] = 0 --0表示空, 其他时候表示顾客的id 
        end  
    end

    do  --精灵
        local cache = CCSpriteFrameCache:sharedSpriteFrameCache()
        cache:addSpriteFramesWithFile("player1.plist")
        cache:addSpriteFramesWithFile("player2.plist")
        cache:addSpriteFramesWithFile("player3.plist")
        cache:addSpriteFramesWithFile("player4.plist")

        local testSprite = NPCSprite:create("player1_%i_%i.png")
        _mapLayer:addChild(testSprite)

        self:walkTo(testSprite, 0.3, 145, 191)
    end

    -- self:performWithDelay(function() self:update() end, 1.0)
end

--sprite: 精灵，speed: 移动一格的速度, startId:开始id，endId:结束id
function MainScene:walkTo(pNPCSprite, speed, startId, endId)
        local indexFlag = 0 --执行标志
        local unitDivideNum = 10 --两个格子之间划分成10个坐标点
        local actionTag = kActionTagMove
        --A星寻路 地图路径
        local mapPath = _mapInfo:findPath(startId, endId) --地图路径类

        if mapPath == nil then
            return --没有路径
        end

        local startPoint = mapPath:getPointAtIndex(1) --第一个点
        local pointNum = mapPath:getPointArrCount()
        
        pNPCSprite:setPosition(startPoint)
        pNPCSprite:stopActionByTag(actionTag)
        
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

                                pNPCSprite:playAnim(curPoint, nextPoint) --播放上下左右移动动画

                            elseif index == pointNum then
                                pNPCSprite:stopActionByTag(actionTag) --停止本callFunc
                                pNPCSprite:stopAnim() --停止播放动画
                            end
                            indexFlag = indexFlag + 1 --标志增加

                            pNPCSprite:setPosition(curPoint) --设置坐标

                            end)
        local sequence = CCSequence:createWithTwoActions(delay, callfunc)
        local action = CCRepeatForever:create(sequence)
        action:setTag(actionTag)
        pNPCSprite:runAction(action)

        self:performWithDelay(function() self:update() end, 20.0)
end

function MainScene:update()
    print("callback")
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
    _controller:onRelease()
    _controller = nil
end

return MainScene
