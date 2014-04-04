require "app/basic/extern"

--此处继承CCNode,因为需要维持这个表，但是用object的话需要retian/release
NPCSprite = class("NPCSprite", function()
	return CCNode:create()
end)			
--index
NPCSprite.__index  			= NPCSprite

--public
NPCSprite.nPreMapId      = -1
NPCSprite.nTargetMapId   = -1
NPCSprite.handler        = nil       

--private
NPCSprite._fileName  	= nil --文件名
NPCSprite._sprite  		= nil --精灵
NPCSprite._lastActionTag  	= nil --最近动作tag
NPCSprite._npcId            = -1  --用来区分不同NPC，默认为-1

function NPCSprite:create(fileNameFormat, npcId)
	local pNPCSprite = NPCSprite.new()
	pNPCSprite:init(fileNameFormat, npcId)
	return pNPCSprite
end

function NPCSprite:getNPCId()
    return self._npcId
end

function NPCSprite:init(fileNameFormat, npcId)
	self._fileName = fileNameFormat --缓存文件名

    self._npcId = npcId

	self._lastActionTag = kActionTagInvalid

    self:addAnimCache(fileNameFormat)

	self._sprite = CCSprite:createWithSpriteFrameName(string.format(fileNameFormat, 0, 0))

    self._sprite:setAnchorPoint(ccp(0.5, 0))

    self:addChild(self._sprite)
end

function NPCSprite:addAnimCache(fileNameFormat)
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

function NPCSprite:stopAnim()
	if self._lastActionTag ~= kActionInvalid then
    	self._sprite:stopActionByTag(self._lastActionTag)
    	self._lastActionTag = kActionInvalid
    end
end

--根据移动坐标点的变化来判断播放动画
function NPCSprite:playAnim(startPoint, endPoint)
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
