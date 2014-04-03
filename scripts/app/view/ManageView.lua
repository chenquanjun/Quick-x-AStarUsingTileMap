require "app/basic/extern"

--此处继承CCNode,因为需要维持这个表，但是用object的话需要retian/release
ManageView = class("ManageView", function()
	return CCNode:create()
end)			

--[[-------------------
    ---Init Value-----
    ---------------------]]

ManageView.__index = ManageView

local _delegate = nil --view delegate
local _mapInfo = nil

local _startMapId = -1
local _npcMap = nil    --存放npcId和npcSprite的对应字典

local _npcLayer = nil --存放NPC的layer

local _timerInterval = -1

local _scheduler = nil

--[[-------------------
    ---Init Method-----
    ---------------------]]

function ManageView:create()
	local ret = ManageView.new()
	ret:init()
	return ret
end

function ManageView:setDelegate(delegate)
    _delegate = delegate
end

function ManageView:setStartMapId(mapId)
    print("startMapId:"..mapId)
    _startMapId = mapId
end

function ManageView:init()
	print("View init")
    _npcMap = {}

    _scheduler = require("framework.scheduler")

	do   --tmx地图 单纯显示用
        local map = CCTMXTiledMap:create("map.tmx")
        self:addChild(map)

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

    do  --精灵
        local cache = CCSpriteFrameCache:sharedSpriteFrameCache()
        cache:addSpriteFramesWithFile("player1.plist")
        cache:addSpriteFramesWithFile("player2.plist")
        cache:addSpriteFramesWithFile("player3.plist")
        cache:addSpriteFramesWithFile("player4.plist")
    end

    do  --npcLayer
        local npcLayer = display.newLayer()
        self:addChild(npcLayer)
        _npcLayer = npcLayer 
    end
end

function ManageView:onRelease()
	print("View on release")
    _delegate = nil
	_mapInfo = nil

    local cache = CCSpriteFrameCache:sharedSpriteFrameCache()
    cache:removeSpriteFramesFromFile("player1.plist")
    cache:removeSpriteFramesFromFile("player2.plist")
    cache:removeSpriteFramesFromFile("player3.plist")
    cache:removeSpriteFramesFromFile("player4.plist")
end

--[[
--------------------------
------Delegate Method------
--MD_前缀代表model delegate---
----------------------------]]
function ManageView:MD_setTimerInterval(interval)
    --view的动作调用间隔需要和timerControl的间隔一致
    --经测试 0.05以上的精度较为理想，小于0.05的话执行间隔不确定
    --具体视乎后面的逻辑设定
    print("interval:"..interval)
    assert(interval >= 0.05, "best interval is larger than 0.05")
    
    _timerInterval = interval
end

function ManageView:MD_showSprite()
    -- self:walkTo(_testSprite, 0.3, 145, 191)
end

function ManageView:MD_addNPC(data)
    local npcId = data.npcId
    local npcType = data.npcType
    
    local startMapId = _startMapId

    local startPoint = _mapInfo:convertIdToPointMid(startMapId)

    local npcSprite = NPCSprite:create("player1_%i_%i.png", npcId)

    npcSprite.nPreMapId = startMapId
    npcSprite.nTargetMapId = startMapId

    npcSprite:setPosition(startPoint)

    _npcLayer:addChild(npcSprite)

    --保存到Map里面
    _npcMap[npcId] = npcSprite 
end

function ManageView:MD_moveNPC(npcId, mapId)
    local npcSprite = _npcMap[npcId]

    local totalTime = -1

    if npcSprite then
        local newPreMapId = npcSprite.nTargetMapId
        local newTargetMapId = mapId
        --更新值
        npcSprite.nPreMapId = newPreMapId  
        npcSprite.nTargetMapId = newTargetMapId

        -- totalTime = self:walkTo(npcSprite, 0.3, newPreMapId, newTargetMapId)

        --test
        totalTime = self:easeWalkTo(npcSprite, 0.2, newPreMapId, newTargetMapId)


    end

    return totalTime
end

--[[
--------------------------
------Private Method------
----------------------------]]

function ManageView:setMapInfo(mapInfo)
	_mapInfo = mapInfo
end

--sprite: 精灵，speed: 移动一格的速度, startId:开始id，endId:结束id
--废弃方法
function ManageView:walkTo(npcSprite, speed, startId, endId)
        local indexFlag = 0 --执行标志
        local unitDivideNum = _mapInfo:int(speed / _timerInterval)  --两个格子之间划分成10个坐标点
        local actionTag = kActionTagMove
        --A星寻路 地图路径
        local mapPath = _mapInfo:findPath(startId, endId) --地图路径类

        if mapPath == nil then
            return --没有路径
        end

        local startPoint = mapPath:getPointAtIndex(1) --第一个点
        local pointNum = mapPath:getPointArrCount()
        
        npcSprite:setPosition(startPoint)
        npcSprite:stopActionByTag(actionTag)

        local delay = CCDelayTime:create(speed / unitDivideNum) --延迟
        local callfunc = CCCallFunc:create(function()
            
                            --index 从 1 开始，所以需要 +1
                            local index = _mapInfo:int(indexFlag / unitDivideNum) + 1  
                            -- print("index:"..index)
                            if index < pointNum then
                                
                                --线性化坐标点,
                                local curPoint = mapPath:getPointAtIndex(index)
                                local nextPoint = mapPath:getPointAtIndex(index + 1)
                                local offset = (indexFlag - (index - 1) * unitDivideNum) / unitDivideNum
                                local x = curPoint.x + (nextPoint.x - curPoint.x) * offset
                                local y = curPoint.y + (nextPoint.y - curPoint.y) * offset
                                curPoint = ccp(x, y) 

                                npcSprite:playAnim(curPoint, nextPoint) --播放上下左右移动动画
                                npcSprite:setPosition(curPoint) --设置坐标

                            elseif index == pointNum then
                                local curPoint = mapPath:getPointAtIndex(index)
                                npcSprite:setPosition(curPoint) --设置坐标
                            else
                                npcSprite:stopActionByTag(actionTag) --停止本callFunc
                                npcSprite:stopAnim() --停止播放动画
                                print("move end:"..indexFlag)
                            end
                            indexFlag = indexFlag + 1 --标志增加

                            

                            end)
        local sequence = CCSequence:createWithTwoActions(delay, callfunc)
        local action = CCRepeatForever:create(sequence)
        action:setTag(actionTag)
        npcSprite:runAction(action)

        local totalTime = speed * pointNum
        --model并不知道view中寻路需要多少时间
        --可使用返回时间，或者使用动作完毕回调方法
        return totalTime
end

function ManageView:easeWalkTo(npcSprite, speed, startId, endId)
        print("WalkTo:"..startId.." "..endId)
        --A星寻路 地图路径
        local mapPath = _mapInfo:findPath(startId, endId) --地图路径类

        if mapPath == nil then
            return --没有路径
        end

        local startPoint = mapPath:getPointAtIndex(1) --第一个点
        local pointNum = mapPath:getPointArrCount()

        print("point num:"..pointNum)
        
        npcSprite:setPosition(startPoint)

        local curTime = 0
        local totalTime = speed * pointNum

        

        if npcSprite.handler then
            print("exist")
            _scheduler.unscheduleGlobal(npcSprite.handler)
            npcSprite.handler = nil
        end
        --定时器
        npcSprite.handler = _scheduler.scheduleUpdateGlobal(function(dt)
                            curTime = curTime + dt

                            --这个类似动作里面的update的time参数
                            local time = curTime / totalTime

                            local fIndex = (pointNum - 1) * time + 1 --从1开始
                            local index  = _mapInfo:int(fIndex)

                            if index < pointNum then
                                local curPoint = mapPath:getPointAtIndex(index)
                                -- print(index..":"..curPoint.x..", "..curPoint.y)
                                local nextPoint = mapPath:getPointAtIndex(index + 1)
                                local offset = fIndex - index
                                local x = curPoint.x + (nextPoint.x - curPoint.x) * offset
                                local y = curPoint.y + (nextPoint.y - curPoint.y) * offset
                                curPoint = ccp(x, y) 
                                npcSprite:setPosition(curPoint)


                                npcSprite:playAnim(curPoint, nextPoint)

                            else --最后一个点
                                local curPoint = mapPath:getPointAtIndex(index)
                                npcSprite:setPosition(curPoint)
                                _scheduler.unscheduleGlobal(npcSprite.handler)
                                npcSprite.handler = nil
                                npcSprite:stopAnim()
                                print("move end~")
                            end
        end)

        return totalTime
 
end