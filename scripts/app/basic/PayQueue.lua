--队列（支付专用）
PayQueue = {}
--index
PayQueue.__index = PayQueue
PayQueue._maxNum =  -1
PayQueue._queueData = nil
PayQueue._targetNum = 0

--支付队列系统
--实现功能
--普通队列操作（push，pop）
--队列某元素删除操作（根据elfId）

function PayQueue:create(maxNum)
	local ret = {}
	setmetatable(ret, PayQueue)
	ret:init(maxNum)
    return ret
end

function PayQueue:init(maxNum)
	if maxNum then
		self._maxNum = maxNum
	end

	self._queueData = {}
end

function PayQueue:onRelease()
	self._elfIdDic = nil
	self._queueData = nil
end

--功能：判断队列是否为空，若为空则_targetNum加1，返回结果
--删除队列时候自减去
function PayQueue:isFull()
	local isFull = true

	if self._targetNum < self._maxNum then
		self:addTargetNum(1)
		isFull = false
	end

	return isFull
end

function PayQueue:addTargetNum(num)
	self._targetNum = self._targetNum + num
end

--获得实际队列数目，包括移动到普通支付队列的npc
function PayQueue:getRealQueueNum()
	local num = self._targetNum
	return num
end
--获得队列数目，表示在普通支付队列中npc数目
function PayQueue:getQueueNum()
	local num = #self._queueData
	return num
end

function PayQueue:getDataAtIndex(index)
	local queueData = self._queueData
	local data = queueData[index]
	return data
end

function PayQueue:getQueueIndex(elfId)
	local queueData = self._queueData
	local index = -1

	for i, data in ipairs(queueData) do
		if data.elfId == elfId then
			index = i
			break
		end
	end

	return index	
end

--push
function PayQueue:pushQueue(data)
	local pushIndex = -1
	local queueData = self._queueData
	local index = #queueData + 1
	local maxNum = self._maxNum
	-- index = index + 1
	if maxNum == -1 or index <= maxNum then --无限或者未满，可push

		self._queueData[index] = data

		pushIndex = index
	end

	return pushIndex

end

--
function PayQueue:removeQueue(elfId)
	local queueData = self._queueData

	local index = self:getQueueIndex(elfId)

	local isSuccess = false

	if index > -1 then
		table.remove(queueData, index)

		self:addTargetNum(-1) --减1

		isSuccess = true	
	end
	return isSuccess

end

function PayQueue:popQueue()
	local queueData = self._queueData
	local queueNum = #queueData
	local data = nil

	if queueNum > 0 then
		data = self._queueData[1] 
		table.remove(queueData, 1)

		self:addTargetNum(-1)
		-- dump(queueData, "queueData")
	end

	return data
end







