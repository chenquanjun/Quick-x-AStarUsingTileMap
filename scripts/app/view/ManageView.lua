--主view
--此处继承CCNode,因为需要维持这个表，但是用object的话需要retian/release
ManageView = class("ManageView", function()
    local node = display.newNode()
    node:setNodeEventEnabled(true)
    return node
end)			

--[[-------------------
    ---Init Value-----
    ---------------------]]

ManageView.__index      = ManageView

ManageView._mapInfo     = nil
ManageView._npcMap      = nil    --存放elfId和npcSprite的对应字典
ManageView._playerMap   = nil --存放playerId和精灵的对应字典
ManageView._productMap  = nil
ManageView._npcLayer    = nil --存放NPC的layer
ManageView._playerLayer = nil
ManageView._productLayer= nil
ManageView._btnLayer    = nil
ManageView._trayLayer   = nil
ManageView._timerLabel  = nil
ManageView._testTimerSpr= nil
ManageView._statsReasonMap    = nil
ManageView._statsProductInfoMap = nil

--[[-------------------
    ---Init Method-----
    ---------------------]]

function ManageView:create()
	local ret = ManageView.new()
	ret:init()
	return ret
end

function ManageView:toggleTimer(isOn)
   if isOn then
        self._testTimerSpr:setColor(ccc3(0, 0, 255))
   else
        self._testTimerSpr:setColor(ccc3(255, 0, 0))
   end
end

function ManageView:initTimer(callBack)
    local timerLabel = CCLabelTTF:create("0", "Arial", 40)
    timerLabel:setPosition(ccp(display.cx, display.top - 50))
    timerLabel:setColor(ccc3(0, 0, 255))

    self:addChild(timerLabel)

    self._timerLabel = timerLabel

    --暂停按钮
    local stopBtn = display.newSprite("product.png")
    stopBtn:setPosition(ccp(display.cx - 150, display.top - 50))
    self:addChild(stopBtn)

    self._testTimerSpr = stopBtn
    self:toggleTimer(true)

    stopBtn:setTouchEnabled(true)

    stopBtn:addTouchEventListener(function(event, x, y)

        if event == "began" then
            return true -- catch touch event, stop event dispatching
        end

        local touchInSprite = stopBtn:getCascadeBoundingBox():containsPoint(CCPoint(x, y))
        if event == "moved" then
            if touchInSprite then

            else

            end
        elseif event == "ended" then
            if touchInSprite then 
                callBack() --回调
            end

        else

        end
    end)
end

function ManageView:setTimer(num)
    self._timerLabel:setString(num)
end

function ManageView:initBtns(mapIdVec, callBack)
    local size = self._mapInfo._mapUnit
    local rect = CCRect(0, 0, size.width * 2.5, size.height * 4.5)
    for i,v in ipairs(mapIdVec) do
        local sprite = CCSprite:createWithTexture(nil, rect)
        local point = self._mapInfo:convertIdToPointMid(v) --mapId转换成中点
        sprite:setPosition(ccpAdd(point, ccp(0, size.height * 2.3)))
        sprite:setTouchEnabled(true)
        sprite:setOpacity(0)
        self._btnLayer:addChild(sprite)

        sprite:addTouchEventListener(function(event, x, y)

            if event == "began" then
                return true -- catch touch event, stop event dispatching
            end

            local touchInSprite = sprite:getCascadeBoundingBox():containsPoint(CCPoint(x, y))
            if event == "moved" then
                if touchInSprite then

                else

                end
            elseif event == "ended" then
                if touchInSprite then 
                    callBack(v) --回调
                end

            else

            end
        end)

        
    end
end

function ManageView:init()
	print("View init")
    self._npcMap = {}
    self._playerMap = {}
    self._productMap = {}

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
        self._npcLayer = npcLayer 
    end

    do  --playerLayer
        local playerLayer = display.newLayer()
        self:addChild(playerLayer, 10)
        self._playerLayer = playerLayer 
    end

    do  --productLayer
        local productLayer = display.newLayer()
        self:addChild(productLayer)
        self._productLayer = productLayer     
    end


    do  --btnLayer
        local btnLayer = display.newLayer()
        self:addChild(btnLayer)
        self._btnLayer = btnLayer 
    end

    do --tray 托盘
        local trayNum = GlobalValue.TrayNum.value
        local trayView = ManageTrayView:create(trayNum)
        trayView:setPosition(ccp(display.left + 40, display.top - 50))

        self:addChild(trayView)
        self._trayLayer = trayView
    end

    do --统计
        self._statsReasonMap = {}
        self._statsProductInfoMap = {}

        local statsLayer = display.newLayer()
        self:addChild(statsLayer, 100)
        statsLayer:setPosition(ccp(display.right - 250, display.top))

        local offsetY = 0

        for k,v in pairs(LeaveReason) do

            offsetY = offsetY + 1
            local infoLabel = CCLabelTTF:create(k..":0", "Arial", 15)

            infoLabel:setColor(ccc3(0, 0, 255))

            infoLabel:setPosition(ccp(0, - 20 * offsetY))

            statsLayer:addChild(infoLabel)

            self._statsReasonMap[k] = infoLabel
        end

        --产品个数
        -- local productVec = G_seatControl:getMapIdVecOfType(kMapDataProduct)

        local productNum = GlobalValue.ProductNum.value

        offsetY = 0
        for i = 1, productNum do
            offsetY = offsetY + 1

            local elfId = ElfIdList.ProductOffset + i --产品id

            local infoLabel = CCLabelTTF:create("product"..(elfId - 100)..":0", "Arial", 15)

            infoLabel:setColor(ccc3(0, 0, 255))

            infoLabel:setPosition(ccp(150, - 20 * offsetY))

            statsLayer:addChild(infoLabel)

            self._statsProductInfoMap[elfId] = infoLabel
        end
    end
end

function ManageView:onEnter()

end

function ManageView:onExit()
    print("View on release")
    -- self._trayLayer:onRelease()

    self._mapInfo = nil

    local cache = CCSpriteFrameCache:sharedSpriteFrameCache()
    cache:removeSpriteFramesFromFile("player1.plist")
    cache:removeSpriteFramesFromFile("player2.plist")
    cache:removeSpriteFramesFromFile("player3.plist")
    cache:removeSpriteFramesFromFile("player4.plist")
end

-- function ManageView:onRelease()

-- end

--[[
--------------------------
------Delegate Method------
--MD_前缀代表model delegate---
----------------------------]]
function ManageView:MD_setStatsReason(leaveReason, num)
    local label = self._statsReasonMap[leaveReason]
    label:setString(leaveReason..":"..num)
end

function ManageView:setStatsProductInfo(productId, num)
    local label = self._statsProductInfoMap[productId]
    label:setString("product"..(productId - 100)..":"..num)
end

function ManageView:MD_addProduct(data)
        local elfId = data.elfId
        local name = data.name
        local productType = data.type
        local mapId = data.mapId

        local point = self._mapInfo:convertIdToPointMid(mapId)

        local size = self._mapInfo._mapUnit
        local rect = CCRect(0, 0, size.width * 2, size.height * 2)

        local label = CCLabelTTF:create(name, "Arial-BoldMT", 30)

        local progressBar = CCProgressTimer:create(display.newSprite("product.png"))

        progressBar:setType(kCCProgressTimerTypeRadial)
        progressBar:setPercentage(0)    

        local sprite = CCSprite:createWithTexture(nil, rect)

        sprite:setTouchEnabled(true)

        label:setAnchorPoint(ccp(0.5, - 0.7))
        label:setColor(ccc3(255, 0, 0))
        
        -- sprite:setOpacity(100)

        sprite:setPosition(point)
        label:setPosition(point)
        progressBar:setPosition(point)

        
        self._productLayer:addChild(sprite)
        self._productLayer:addChild(progressBar)
        self._productLayer:addChild(label)

        self._productMap[elfId] = progressBar

        sprite:addTouchEventListener(function(event, x, y)

            if event == "began" then
                return true -- catch touch event, stop event dispatching
            end

            local touchInSprite = sprite:getCascadeBoundingBox():containsPoint(CCPoint(x, y))
            if event == "moved" then
                if touchInSprite then

                else

                end
            elseif event == "ended" then
                if touchInSprite then 
                    --回调
                   G_viewDelegate:onProductBtn(elfId)
                end

            else

            end
        end)
end

function ManageView:MD_addPlayer(data)
    local elfId = data.elfId

    local modelId = data.modelId

    local startMapId = data.mapId

    local startPoint = self._mapInfo:convertIdToPointMid(startMapId)

    local fileName = "player1_%i_%i.png"

    if modelId == 1 then
        fileName = "player1_%i_%i.png"
    elseif modelId == 2 then
        fileName = "player2_%i_%i.png"
    elseif modelId == 3 then
        fileName = "player3_%i_%i.png"
    elseif modelId == 4 then
        fileName = "player4_%i_%i.png"
    end

    local npcSprite = PlayerSprite:create(fileName, elfId)

    npcSprite.nPreMapId = startMapId
    npcSprite.nTargetMapId = startMapId

    npcSprite:setPosition(startPoint)

    self._playerLayer:addChild(npcSprite)

    --保存到Map里面
    self._playerMap[elfId] = npcSprite 

    -- if elfId == 1 then
    --     --test
    --     local productVec = {}

    --     for i=1,5 do
    --         local product1 = {}
    --         productVec[i] = product1
    --         product1.elfId = i
    --     end

    --     npcSprite:addRequest(productVec)

    --     local removeList = {}
    --     removeList[1] = 2
    --     removeList[2] = 3
    --     removeList[3] = 5
    --     -- removeList[4] = 4
    --     -- removeList[5] = 5

    --     npcSprite:removeRequest(removeList)
    -- end




end

function ManageView:MD_addNPC(data)
    local elfId = data.elfId
    local modelId = data.modelId

    local mapId = data.mapId

    local startPoint = self._mapInfo:convertIdToPointMid(mapId)

    local fileName = "player1_%i_%i.png"

    if modelId == 1 then
        fileName = "player1_%i_%i.png"
    elseif modelId == 2 then
        fileName = "player2_%i_%i.png"
    elseif modelId == 3 then
        fileName = "player3_%i_%i.png"
    elseif modelId == 4 then
        fileName = "player4_%i_%i.png"
    end

    local npcSprite = NPCSprite:create(fileName, elfId)

    npcSprite.nPreMapId    = mapId
    npcSprite.nTargetMapId = mapId

    npcSprite:setPosition(startPoint)

    self._npcLayer:addChild(npcSprite)

    --保存到Map里面
    self._npcMap[elfId] = npcSprite 
end

function ManageView:MD_moveNPC(elfId, mapId)
    local npcSprite = self._npcMap[elfId]

    local totalTime = -1

    if npcSprite then

        local newPreMapId = npcSprite.nTargetMapId
        local newTargetMapId = mapId
        --更新值
        npcSprite.nPreMapId = newPreMapId  
        npcSprite.nTargetMapId = newTargetMapId

        local mapPath = self._mapInfo:findPath(newPreMapId, newTargetMapId) --地图路径类

        local speed = 50 / GlobalValue.NPCMoveSpeed.value
        totalTime = npcSprite:easeWalkTo(speed, mapPath)
    end

    return totalTime
end

function ManageView:MD_movePlayer(elfId, mapId)
    local playerSprite = self._playerMap[elfId]

    local totalTime = -1

    if playerSprite then
        local point = ccp(playerSprite:getPositionX(), playerSprite:getPositionY())
        local newPreMapId = self._mapInfo:convertPointToId(point) --转换成当前id
        local newTargetMapId = mapId
        --更新值
        playerSprite.nPreMapId = newPreMapId
        playerSprite.nTargetMapId = newTargetMapId

        local mapPath = self._mapInfo:findPath(newPreMapId, newTargetMapId) --地图路径类

        local speed = 50 / GlobalValue.PlayerMoveSpeed.value
        totalTime = playerSprite:easeWalkTo(speed, mapPath)
    end

    return totalTime
end

function ManageView:addRequest(elfId, productVec)
    local npcSprite = self._npcMap[elfId]

    if npcSprite then

        npcSprite:addRequest(productVec)

    end
end

function ManageView:MD_removeRequest(elfId, indexVec)
    local npcSprite = self._npcMap[elfId]

    if npcSprite then
        npcSprite:removeRequest(indexVec)
    end
end

function ManageView:MD_coolDownProduct(elfId, duration)
    local progressBar = self._productMap[elfId]
    progressBar:stopAllActions()
    progressBar:runAction(CCProgressFromTo:create(duration, 0, 100))
end

function ManageView:MD_removeNPC(elfId)
    local npcSprite = self._npcMap[elfId]

    if npcSprite then
        self._npcMap[elfId] = nil
        
        npcSprite:removeFromParentAndCleanup(true)

    end
end

function ManageView:MD_setStateStr(elfId, stateStr)
    local npcSprite = self._npcMap[elfId]

    if npcSprite then
        npcSprite:setStateStr(stateStr)

    else

    end
end

--[[
------------------------------
--------Delegate Method-------
----------Tray Method---------
------------------------------]]


function ManageView:MD_addProductAtIndex(index, productType)
    self._trayLayer:addProductAtIndex(index, productType)
end

function ManageView:MD_removeProductAtIndex(index)
    self._trayLayer:removeProductAtIndex(index)
end

function ManageView:MD_setProductFinishAtIndex(index)
    self._trayLayer:setProductFinishAtIndex(index)
end

function ManageView:MD_removeProductWithVec(indexVec)
    self._trayLayer:removeProductWithVec(indexVec)
end
--[[
--------------------------
------Private Method------
----------------------------]]
function ManageView:setMapInfo(mapInfo)
	self._mapInfo = mapInfo
end

