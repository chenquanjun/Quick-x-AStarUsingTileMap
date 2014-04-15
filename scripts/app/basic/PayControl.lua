--支付队列控制（包括等待支付与普通支付）
PayControl = {}
--index
PayControl.__index = PayControl
------------------------
PayControl._norPayQueue        = nil   --普通支付队列
PayControl._waitPayQueue        = nil  --等待支付队列
PayControl._payPointMapId       = -1
PayControl._npcInfoMap          = nil
PayControl._statusDic           = nil
 
function PayControl:create()
	local ret = {}
	setmetatable(ret, PayControl)
	ret:init()
    return ret
end

function PayControl:init()
	local maxNum = 5
	self._waitPayQueue = PayQueue:create(-1) --等待支付队列无限

	self._norPayQueue  = PayQueue:create(maxNum) --普通支付队列有限

	local payVec = G_seatControl:getMapIdVecOfType(kMapDataPayQueue)
	self._payPointMapId = payVec[maxNum + 1]

	self._npcInfoMap = {}

	self._statusDic = {}
end

function PayControl:getPayPointMapId()
 	return self._payPointMapId
end

--增加支付的npc
function PayControl:addPayNpc(npcInfo)
	local elfId = npcInfo.elfId
	print("addPay:"..elfId)

	self._npcInfoMap[elfId] = npcInfo

	--进入支付
	local isWaitPay = self:joinPay(elfId)

	--设置npc状态
	npcInfo:enterPayState(isWaitPay)

	--调用npc信息控制方法
	self:npcStateControl(elfId)

end

--加入支付大军
function PayControl:joinPay(elfId)
	--首先检查普通支付队列
	local data = {}
	data.elfId = elfId
	local isFull = self._norPayQueue:isFull()

	local isWaitPay = false

	if isFull then --加入等待支付队列
		self._waitPayQueue:pushQueue(data)
		isWaitPay = true
	else --将进入普通支付队列
		--但是要等移动到指定位置时候才加入队列
		isWaitPay = false
	end
	return isWaitPay
end

--npcinfo方法进入pay的prepare状态时才调用此方法
function PayControl:joinNormalPay(npcInfo)
	--已经到达普通支付的等待位置，准备进入队列
	local elfId = npcInfo.elfId

	local data = {}
	data.elfId = elfId

	--标记状态
	-- self._statusDic[elfId] == 0

	--进入普通队列
	local pushIndex = self._norPayQueue:pushQueue(data)

	npcInfo:setPayStateNormal() --npc支付情感开始变化 normal anger cancel

	--获得即将进入的位置

	local payVec = G_seatControl:getMapIdVecOfType(kMapDataPayQueue)

	local mapId = payVec[pushIndex] --目的地id

	-- local totalTime = G_modelDelegate:moveNPC(elfId, mapId) --移动到指定地方
	-- npcInfo.mapId = mapId --保存mapId

	--注意此处的listenerId需要作偏移处理，防止干扰npcStateControl方法中npc自己状态的改变
	-- G_timer:addTimerListener(elfId + ElfIdList.PayNpcOffset, totalTime, self) --加入时间控制

	--调用npc信息控制方法
	self:npcStateControl(elfId)

	self:moveToQueuePoint(npcInfo, pushIndex)

end

function PayControl:moveToQueuePoint(npcInfo, queueIndex)
	local payVec = G_seatControl:getMapIdVecOfType(kMapDataPayQueue)

	local mapId = payVec[queueIndex] --目的地id

	if npcInfo.mapId ~= mapId then--不在该位置上
		local elfId = npcInfo.elfId
		self._statusDic[elfId] = 0
		local totalTime = G_modelDelegate:moveNPC(elfId, mapId) --移动到指定地方
		npcInfo.mapId = mapId --保存mapId

		--注意此处的listenerId需要作偏移处理，防止干扰npcStateControl方法中npc自己状态的改变
		G_timer:addTimerListener(elfId + ElfIdList.PayNpcOffset, totalTime, self) --加入时间控制
	else --已经在该位置

	end
end

function PayControl:leavePay(elfId)
	--npc进入了愤怒离开状态，离开队列
end

function PayControl:onRelease()
	self._norPayQueue         = nil   
	self._waitPayQueue        = nil  
end

function PayControl:npcMoveEnded(elfId)
	local npcInfo = self._npcInfoMap[elfId]

	if npcInfo then--npc到达指定位置
		
		assert(self._statusDic[elfId] == 0, "error") --移动之前应该改变标志

		self._statusDic[elfId] = 1 --标记为到达指定位置

		local queueIndex = self._norPayQueue:getQueueIndex(elfId)

		if queueIndex == 1 then --npc在第一位
			local duration = 3.0--收银时间

			--收银开动
			G_timer:addTimerListener(ElfIdList.PayQueCheck, duration, self) --加入时间控制

			--删除定时器
			G_timer:removeTimerListener(elfId)

			--玩家状态改变
			npcInfo:setPayStatePaying()

		else --npc在其他位

		end--index if ended
	else 
		error("error elfId")
	end --npcInfo if ended

end

function PayControl:payEnded()
	--收银完毕

	--pop队列
	local data = self._norPayQueue:popQueue()

	local elfId = data.elfId

	local npcInfo = self._npcInfoMap[elfId]

	--标记状态
	self._statusDic[elfId] = 0
	
	--赶走第一个玩家
	npcInfo:setPayStatePayEnded()

	--进入控制
	self:npcStateControl(elfId)
	
	--移动队列（从1开始移动，仅移动标记为1的npc，遇到标记为0的玩家则break）
	local queueNum = self._norPayQueue:getQueueNum()
	for i = 1, queueNum do
		local data = self._norPayQueue:queueDataAtIndex(i)
		local queElfId = data.elfId
		local status = self._statusDic[queElfId] --1表示已经移动完毕

		if status == 1 then
			self:moveToQueuePoint(npcInfo, queueIndex) --移动到指定位置（若在该位置则无效果）

		else --0的忽略不计

		end
	end


	--等待支付队列的玩家进入普通支付队列
end

--npc主状态转换
function PayControl:npcStateControl(elfId)

	local npcInfo = self._npcInfoMap[elfId]

	if npcInfo then
		local returnValue = npcInfo:npcState() --执行状态方法
		dump(returnValue, "value") 
		local isRelease = returnValue.isRelease --是否已经释放
		local totalTime = returnValue.totalTime --回调时间
		local mapId = returnValue.mapId --移动目标id

		local testStateStr = returnValue.testStateStr


		if isRelease then-- 废弃
			--释放
			self._npcInfoMap[elfId] = nil --释放
			G_modelDelegate:removeNPC(elfId)
		else
			if mapId ~= -1 then
				--mapId存在说明需要自动寻路，totalTime由view控制
				totalTime = G_modelDelegate:moveNPC(elfId, mapId) 
				npcInfo.mapId = mapId --保存目标位置
			end
			
			G_timer:addTimerListener(elfId, totalTime, self) --加入时间控制

			if productVec then
				G_modelDelegate:addRequest(elfId, productVec)
			end


		end

		if testStateStr then
				G_modelDelegate:setStateStr(elfId, testStateStr)
		end


	else
		error("error call")
	end
end


function PayControl:TD_onTimeOver(listenerId)
	if listenerId >= ElfIdList.NpcOffset + ElfIdList.PayNpcOffset then --npcId回调
		self:npcMoveEnded(listenerId - ElfIdList.PayNpcOffset)--减去偏移
	elseif listenerId >= ElfIdList.NpcOffset then
		--todo
		self:npcStateControl(listenerId)
	elseif listenerId == ElfIdList.PayQueCheck then
		self:payEnded() --收银完毕
	end	
end





