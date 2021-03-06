--托盘view

--此处继承CCNode,因为需要维持这个表，但是用object的话需要retian/release
ManageTrayView = class("ManageTrayView", function()
    local node = display.newNode()
    node:setNodeEventEnabled(true)
    return node
end)			
--index
ManageTrayView.__index  			= ManageTrayView
ManageTrayView._maxNum              = 5 --默认最大5个
ManageTrayView._productVec          = nil         

function ManageTrayView:create(maxNum)
	local ret = ManageTrayView.new()
	ret:init(maxNum)
	return ret
end


function ManageTrayView:init(maxNum)
	if maxNum then
		self._maxNum = maxNum
	end

	self._productVec = {}
end

function ManageTrayView:onEnter()

end

function ManageTrayView:onExit()
	self._productVec = nil
end

function ManageTrayView:addProductAtIndex(index, productType)
	--注意，插入位置应该由model来决定，view不会做自适应
	assert(index > 0 and index <= self._maxNum, "index out of range")

	local sprite = display.newSprite("product_1.jpg")

	local testFlag = (productType - 100) --test

	local label = CCLabelTTF:create(testFlag, "Arial-BoldMT", 60)

	label:setPosition(ccp(50, 50))

	label:setColor(ccc3(0, 0, 255))

	sprite:addChild(label)

	    sprite:setTouchEnabled(true)
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
                	for i,v in ipairs(self._productVec) do
                		if v == sprite then
                			G_viewDelegate:onTrayProductBtn(i)
                			--只接收一次点击
                			sprite:setTouchEnabled(false)
                			return
                		end
                	end
                	
                    
                end

            else

            end
        end)

	sprite:setPosition(ccp(0, - (index + 1) * 50)) --test
	sprite:setScale(0.4) --test
	local fadeInAndMoveTo = CCSpawn:createWithTwoActions(CCFadeIn:create(0.2), CCMoveTo:create(0.2, ccp(0, - index * 50)))
	fadeInAndMoveTo:setTag(99)
	sprite:stopActionByTag(99)
	sprite:runAction(fadeInAndMoveTo)
	-- sprite:runAction() --进入动画

	self:addChild(sprite)

	--view不负责product的释放，需要model调用释放命令
	assert(self._productVec[index] == nil, "should remove first")

	self._productVec[index] = sprite --保存到table
end

function ManageTrayView:removeProductAtIndex(index)
	-- print("remove"..index)

	--删除
	local sprite = self._productVec[index]

	self._productVec[index] = nil

	local sequence = CCSequence:createWithTwoActions(
        											CCSpawn:createWithTwoActions(
						        												CCFadeOut:create(0.2), 
						        												CCMoveBy:create(0.2, ccp(0, 50))
						        												),
													CCRemoveSelf:create(true)
													)
	sequence:setTag(99)
	sprite:stopActionByTag(99)
	sprite:runAction(sequence)

	--移动
	for i = index ,self._maxNum  do
		self._productVec[i] = self._productVec[i + 1]

		sprite = self._productVec[i]

		if sprite then
			local moveTo = CCMoveTo:create(0.2, ccp(0, - i * 50))
			moveTo:setTag(99)
			sprite:stopActionByTag(99)
			sprite:runAction(moveTo)
		else
			self._productVec[i] = self._productVec[i + 1]
			break
		end
		
	end
end

function ManageTrayView:setProductFinishAtIndex(index)
	local sprite = self._productVec[index]
	sprite:setColor(ccc3(255, 0, 255))
end

function ManageTrayView:removeProductWithVec(indexVec)
	local size = #self._productVec
    local indexSize = #indexVec

    local productVec = self._productVec

    productVec[size + 1] = nil
    
    for i = 1, indexSize do
        local iRevert = indexSize - i + 1

        local index = indexVec[iRevert] --从后面删除

        local sequence = CCSequence:createWithTwoActions(
        												CCSpawn:createWithTwoActions(
						        													CCFadeOut:create(0.2), 
						        													CCMoveBy:create(0.2, ccp(0, 50))
						        													),
											        	CCRemoveSelf:create(true)
											        	)

        local sprite = productVec[index]

		sequence:setTag(99)
		sprite:stopActionByTag(99)

        sprite:runAction(sequence)

        productVec[index] = nil

        for j = index, size do
            productVec[j] = productVec[j + 1]
        end

    end

    if indexSize < size then
        for i, product in ipairs(productVec) do
            local sprite = product

            -- local sequence = CCSequence:createWithTwoActions(CCDelayTime:create(0.2), CCMoveTo:create(0.3, ccp(0, - i * 50)))
            local moveTo = CCMoveTo:create(0.3, ccp(0, - i * 50))
            moveTo:setTag(99)
			sprite:stopActionByTag(99)
            sprite:runAction(moveTo)
        end

    end
end





