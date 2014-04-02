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
local _npcMap = {}    --存放npcId和npcSprite的对应字典

local _npcLayer = nil --存放NPC的layer

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

    if npcSprite then
        local newPreMapId = npcSprite.nTargetMapId
        local newTargetMapId = mapId
        --更新值
        npcSprite.nPreMapId = newPreMapId  
        npcSprite.nTargetMapId = newTargetMapId

        self:walkTo(npcSprite, 0.3, newPreMapId, newTargetMapId)
    end
end

--[[
--------------------------
------Private Method------
----------------------------]]

function ManageView:setMapInfo(mapInfo)
	_mapInfo = mapInfo
end

--sprite: 精灵，speed: 移动一格的速度, startId:开始id，endId:结束id
function ManageView:walkTo(pNPCSprite, speed, startId, endId)
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
end