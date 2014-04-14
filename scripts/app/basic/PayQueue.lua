--收银队列
PayQueue = {}
--index
PayQueue.__index = PayQueue
PayQueue._maxNum =  -1
PayQueue._queueData = nil

--队列系统
--实现功能
--普通队列操作（push，pop）
--队列某元素删除操作（根据elfId）

function PayQueue:create(maxNum)
	local ret = {}
	setmetatable(ret, PayQueue)
	self:init(maxNum)
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

--push
function PayQueue:pushQueue(data)
	local isSuccess = false
	local queueData = self._queueData
	local index = #queueData + 1
	local maxNum = self._maxNum
	index = index + 1
	if maxNum == -1 or index <= maxNum then --无限或者未满，可push

		self._queueData[index] = data

		isSuccess = true
	end

	return isSuccess

end

--
function PayQueue:removeQueue(elfId)
	local queueData = self._queueData
	local isSuccess = false
	local remomveIndex = -1 
	for i, data in ipairs(queueData) do
		if data.elfId == elfId then
			table.remove(queueData, i)
			isSuccess = true

			break
		end
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
	end

	return data
end







