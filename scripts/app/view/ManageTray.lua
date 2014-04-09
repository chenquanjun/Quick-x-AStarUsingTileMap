--托盘
require "app/basic/extern"

--此处继承CCNode,因为需要维持这个表，但是用object的话需要retian/release
ManageTray = class("ManageTray", function()
	return CCNode:create()
end)			
--index
ManageTray.__index  			= ManageTray
ManageTray._delegate      		= nil --view delegate
ManageTray._maxNum              = 5 --默认最大5个
ManageTray._productVec          = nil         

function ManageTray:create(maxNum)
	local ret = ManageTray.new()
	ret:init(maxNum)
	return ret
end


function ManageTray:init(maxNum)
	if maxNum then
		self._maxNum = maxNum
	end

	self._productVec = {}
end

function ManageTray:setDelegate(delegate)
    self._delegate = delegate
end

function ManageTray:onRelease()
	self._delegate = nil
	self._productVec = nil
end

function ManageTray:addProductAtIndex(productType, index)
	assert(index > 0 and index <= self._maxNum, "index out of range")

	local sprite = display.newSprite("product_1.jpg")

	sprite:setPosition(ccp(0, - index * 50))
	sprite:setScale(0.4)

	sprite:runAction(CCFadeIn:create(0.2))

	self:addChild(sprite)

	self._productVec[index] = sprite
end

function ManageTray:removeProductAtIndex(index)
	local sprite = self._productVec[index]

	self._productVec[index] = nil

	local sequence = CCSequence:createWithTwoActions(
					CCFadeOut:create(0.2), 
					CCRemoveSelf:create(true)
					)

	sprite:runAction(sequence)

	for i = index + 1,self._maxNum  do
		sprite = self._productVec[i]
		sprite:runAction(CCMoveBy:create(0.3, ccp(0, 50)))
	end
end

function ManageTray:setProductFinishAtIndex(index)
	local sprite = self._productVec[index]
	sprite:setColor(ccc3(255, 0, 0))
end





