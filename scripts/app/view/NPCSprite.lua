require "app/basic/extern"

--此处继承CCNode,因为需要维持这个表，但是用object的话需要retian/release
NPCSprite = class("NPCSprite", function()
	return CCNode:create()
end)			

NPCSprite.__index  			= NPCSprite

NPCSprite.nPreMapId      = -1
NPCSprite.nTargetMapId   = -1

local _fileName  		= nil --文件名
local _sprite  			= nil --精灵
local _lastActionTag  	= nil --最近动作tag
local _npcId            = -1  --用来区分不同NPC，默认为-1

function NPCSprite:create(fileNameFormat, npcId)
	local pNPCSprite = NPCSprite.new()
	pNPCSprite:init(fileNameFormat, npcId)
	return pNPCSprite
end

function NPCSprite:init(fileNameFormat, npcId)
	_fileName = fileNameFormat --缓存文件名

    _npcId = npcId

	_lastActionTag = kActionTagInvalid

    self:addAnimCache(fileNameFormat)

	_sprite = CCSprite:createWithSpriteFrameName(string.format(fileNameFormat, 0, 0))

    _sprite:setAnchorPoint(ccp(0.5, 0))

    self:addChild(_sprite)
end

function NPCSprite:addAnimCache(fileNameFormat)
    --通过动画序列帧的某个缓存来判断是否存在缓存  player1_%i_%i.png0
	local animation = display.getAnimationCache(fileNameFormat..tostring(0))
    
    local cache = CCSpriteFrameCache:sharedSpriteFrameCache()
    --四个动作animation，以fileName + i + 1 作为key保存在缓存里面
	if animation == nil then
		print("add cache:"..fileNameFormat..tostring(0))
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
	if _lastActionTag ~= kActionInvalid then
    	_sprite:stopActionByTag(_lastActionTag)
    	_lastActionTag = kActionInvalid
    end
end

function NPCSprite:playAnim(startPoint, endPoint)
    local offsetX = endPoint.x - startPoint.x
    local offsetY = endPoint.y - startPoint.y
    local actionType = kActionTagInvalid     

    if offsetY > 1 then
        actionType = kActionTagUp
    elseif offsetY < -1 then
        actionType = kActionTagDown
    elseif offsetX > 1 then
        actionType = kActionTagRight
    elseif offsetX < -1 then
        actionType = kActionTagLeft
    end

    local lastActionTag = _lastActionTag
    --相同动作直接返回
    if actionType == lastActionTag then
    	return
    end

    if lastActionTag ~= kActionInvalid then
    	_sprite:stopActionByTag(lastActionTag)
    end

    _lastActionTag = actionType --保存

    local animation = display.getAnimationCache(_fileName..tostring(actionType))

    if animation then
    	local anim = CCAnimate:create(animation)
    	local action = CCRepeatForever:create(anim)
    	action:setTag(actionType)
    	_sprite:runAction(action)
 	
    end

    
end
