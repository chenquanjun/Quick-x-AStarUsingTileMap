ProductStateType = {
				Invalid                = 1,
				NotComplete            = 2,
				Complete               = 3,    

}

--托盘
TrayInfo = {}
--index
TrayInfo.__index = TrayInfo
TrayInfo._maxNum =  5
TrayInfo._productVec = nil

function TrayInfo:create(maxNum)
	local ret = {}
	setmetatable(ret, TrayInfo)
	self:init(maxNum)
    return ret
end

function TrayInfo:init(maxNum)
	if maxNum then
		self._maxNum = maxNum
	end

	self._productVec = {}
end

function TrayInfo:isFull()
	local value = false

	local size = #self._productVec

	if size >= self._maxNum then
		value = true
	end

	return value
end

function TrayInfo:addProduct(elfId, queueId)

	local index = #self._productVec + 1

	assert(index <= self._maxNum, "error") --超出界限，出错

	if self:isFull() then
		return -1, -1
	end

	print("index"..index)

	local product = {}
	product.elfId = elfId
	product.state = ProductStateType.NotComplete
	product.queueId = queueId

	self._productVec[index] = product

	local productType = elfId --test

	return index, productType
end

function TrayInfo:removeProduct(index)
	--tray view 点击index的product
	--区分状态
	--完成的需要删除物品，并向view发送移除index的命令
	--冷却状态需要删除物品，并向view发送移除index的命令，同时还要取消player队列里面的动作

	local product = self._productVec[index]

	if product then
		local queueId = product.queueId

		for i = index, self._maxNum do
			self._productVec[i] = self._productVec[i + 1]
		end

		if product.state == ProductStateType.NotComplete then
			return queueId
		end
	end

end

function TrayInfo:setProductFinish(elfId)
	for index, product in ipairs(self._productVec) do
		if product.elfId == elfId and product.state == ProductStateType.NotComplete then
			product.state = ProductStateType.Complete
			return index
		end
	end
end






