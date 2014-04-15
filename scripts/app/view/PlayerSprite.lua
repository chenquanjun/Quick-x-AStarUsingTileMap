--玩家精灵
--此处继承CCNode,因为需要维持这个表，但是用object的话需要retian/release
PlayerSprite = class("PlayerSprite", function()
	return CCNode:create()
end)			
--index
PlayerSprite.__index  			= PlayerSprite
PlayerSprite.__mode = "v" --弱引用

--public
PlayerSprite.nPreMapId      = -1
PlayerSprite.nTargetMapId   = -1
PlayerSprite.handler        = nil       

--private
PlayerSprite._fileName      = nil --文件名
PlayerSprite._sprite        = nil --精灵
PlayerSprite._lastActionTag = nil --最近动作tag
PlayerSprite._elfId         = -1  --用来区分不同NPC，默认为-1


function PlayerSprite:create(fileNameFormat, elfId)
	local ret = PlayerSprite.new()
	ret:init(fileNameFormat, elfId)
	return ret
end

function PlayerSprite:getElfId()
    return self._elfId
end

function PlayerSprite:init(fileNameFormat, elfId)
	self._fileName = fileNameFormat --缓存文件名

    self._elfId = elfId

	self._lastActionTag = kActionTagInvalid

    self:addAnimCache(fileNameFormat)

	self._sprite = CCSprite:createWithSpriteFrameName(string.format(fileNameFormat, 0, 0))

    self._sprite:setAnchorPoint(ccp(0.5, 0))

    self:addChild(self._sprite)

    local layer = CCLayer:create()
    layer:setPosition(ccp(-55, 50))

    self._productLayer = layer
    self:addChild(layer)

    local testLabel = CCLabelTTF:create(elfId, "Arial", 15)
    testLabel:setPosition(ccp(0, 70))
    testLabel:setColor(ccc3(0, 0, 255))

    self:addChild(testLabel)

    self._testStateLabel = testLabel
end

function PlayerSprite:addAnimCache(fileNameFormat)
    --通过动画序列帧的某个缓存来判断是否存在缓存  player1_%i_%i.png0
	local animation = display.getAnimationCache(fileNameFormat..tostring(1))
    
    local cache = CCSpriteFrameCache:sharedSpriteFrameCache()
    --四个动作animation，以fileName + i + 1 作为key保存在缓存里面
	if animation == nil then
		print("add cache:"..fileNameFormat..tostring(1))
		local frameCache = CCSpriteFrameCache:sharedSpriteFrameCache()

		for i = 0, 3 do
			local animFrames = CCArray:create()
			for j = 0, 3 do
				local frame = cache:spriteFrameByName( string.format(fileNameFormat, i, j) )

				animFrames:addObject(frame)
			end

			animation = CCAnimation:createWithSpriteFrames(animFrames, 0.2)
			--此处加1是为了和kActionTagDown/Left/Right/Up枚举对应，方便调用
			local name = fileNameFormat..tostring(i + 1) 

			display.setAnimationCache(name, animation)
		end
	end
end

function PlayerSprite:stopAnim()
	if self._lastActionTag ~= kActionInvalid then
    	self._sprite:stopActionByTag(self._lastActionTag)
    	self._lastActionTag = kActionInvalid
    end
end

--根据移动坐标点的变化来判断播放动画
function PlayerSprite:playAnim(startPoint, endPoint)
    local offsetX = endPoint.x - startPoint.x
    local offsetY = endPoint.y - startPoint.y
    local actionType = kActionTagInvalid     

    local minOffset = 0.01 --若执行帧数过高，此值会比较小
    if offsetY > minOffset then
        actionType = kActionTagUp
    elseif offsetY < -minOffset then
        actionType = kActionTagDown
    elseif offsetX > minOffset then
        actionType = kActionTagRight
    elseif offsetX < -minOffset then
        actionType = kActionTagLeft
    end

    local lastActionTag = self._lastActionTag
    --相同动作直接返回
    if actionType == lastActionTag then
        -- print("return")
    	return
    end

    if lastActionTag ~= kActionInvalid then
    	self._sprite:stopActionByTag(lastActionTag)
    end

    self._lastActionTag = actionType --保存

    local animation = display.getAnimationCache(self._fileName..tostring(actionType))

    if animation then
    	local anim = CCAnimate:create(animation)
    	local action = CCRepeatForever:create(anim)
    	action:setTag(actionType)
    	self._sprite:runAction(action)
 	
    end
end

--sprite: 精灵，speed: 移动一格的速度, startId:开始id，endId:结束id
function PlayerSprite:easeWalkTo(speed, mapPath)
        -- print("WalkTo:"..startId.." "..endId)
        --A星寻路 地图路径

        if mapPath == nil then
            return --没有路径
        end

        local startPoint = mapPath:getPointAtIndex(1) --第一个点
        local pointNum = mapPath:getPointArrCount()

        self:setPosition(startPoint)

        local curTime = 0
        local totalTime = speed * pointNum

        if self.handler then
            -- print("exist")
            G_scheduler.unscheduleGlobal(self.handler)
            self.handler = nil
        end
        --定时器
        self.handler = G_scheduler.scheduleUpdateGlobal(function(dt)
                            curTime = curTime + dt

                            --这个类似动作里面的update的time参数
                            local time = curTime / totalTime

                            local fIndex = (pointNum - 1) * time + 1 --从1开始
                            local index  = self:int(fIndex)

                            if index < pointNum then
                                local curPoint = mapPath:getPointAtIndex(index)
                                -- print(index..":"..curPoint.x..", "..curPoint.y)
                                local nextPoint = mapPath:getPointAtIndex(index + 1)
                                local offset = fIndex - index
                                local x = curPoint.x + (nextPoint.x - curPoint.x) * offset
                                local y = curPoint.y + (nextPoint.y - curPoint.y) * offset
                                curPoint = ccp(x, y) 
                                self:setPosition(curPoint)


                                self:playAnim(curPoint, nextPoint)

                            else --最后一个点
                                local curPoint = mapPath:getPointAtIndex(pointNum)
                                self:setPosition(curPoint)
                                G_scheduler.unscheduleGlobal(self.handler)
                                self.handler = nil
                                self:stopAnim()
                                -- print("move end~")
                            end
        end)

        return totalTime
 
end

function PlayerSprite:int(x) 
    return x>=0 and math.floor(x) or math.ceil(x)
end