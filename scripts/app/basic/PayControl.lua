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
PayControl._norQueMaxNum     	= -1
 
function PayControl:create()
	local ret = {}
	setmetatable(ret, PayControl)
	ret:init()
    return ret
end

function PayControl:init()
	local maxNum = 5
	self._norQueMaxNum = maxNum
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
	local isWaitPay = self:joinPay(elfId)--返回在普通支付队列(false)还是等待支付队列(true)

	--设置npc状态
	npcInfo:setPayStateBegin(isWaitPay)

	--调用npc信息控制方法
	self:npcStateControl(elfId)

	--此处返回值待修改

end

--加入支付大军
function PayControl:joinPay(elfId)
	--首先检查普通支付队列
	local data = {}
	data.elfId = elfId
	local isFull = self._norPayQueue:isFull() --调用此方法时自增计数

	local isWaitPay = false

	if isFull then --加入等待支付队列
		self._waitPayQueue:pushQueue(data)
		isWaitPay = true

		print("join Wait:"..elfId)
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

	--进入普通队列
	local pushIndex = self._norPayQueue:pushQueue(data)

	--npc支付情感开始变化 normal anger cancel
	npcInfo:setPayStateNormal() --设置状态
	self:npcStateControl(elfId) --开启定时器

	--获得即将进入的位置

	local payVec = G_seatControl:getMapIdVecOfType(kMapDataPayQueue)

	local mapId = payVec[pushIndex] --目的地id

	self:moveToQueuePoint(npcInfo, pushIndex)

end

--根据队列顺序修正npc的位置
--此方法若成功执行到addTimerListener会触发npcMoveEnded方法
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

--离开等待支付队列
function PayControl:leaveWaitPay(elfId)
	--npc进入了愤怒离开状态，离开队列
	print("angerLeaveWaitPay:"..elfId)

	--删除等待支付队列
	self._waitPayQueue:removeQueue(elfId)
end

function PayControl:leavePay(elfId)
	--此处不需要改变npc状态，仅通知payControl该npc离开队列

	--npc进入了愤怒离开状态，离开队列
	print("angerLeavePay:"..elfId)

	--从队列中删除
	self._norPayQueue:removeQueue(elfId)

	--两种情况？
	local state = self._statusDic[elfId] 
	
	if state == 1 then --npc已经在位置上
		self._statusDic[elfId] = 0 --in case

	else --npc还在移动状态 
		G_timer:removeTimerListener(elfId + ElfIdList.PayNpcOffset) --删除移动回调

	end

	--强制修正所有在队列里面的npc位置
	self:adjustQueuePoint()
end

--核心位置修正方法
--强制修正所有在队列里面的npc位置
--同时将等待队列里面的npc加入到普通支付队列
function PayControl:adjustQueuePoint()
	--普通支付队列
	--强制修正其他npc位置
	local queueNum = self._norPayQueue:getQueueNum() --获得队列数目
	for i = 1, queueNum do
		local data = self._norPayQueue:getDataAtIndex(i) --获得队列位置i的数据
		local queElfId = data.elfId

		local queNpcInfo = self._npcInfoMap[queElfId]

		self:moveToQueuePoint(queNpcInfo, i) --移动到指定位置（若在该位置则无效果）
	end

	--等待队列
	local realQueueNum = self._norPayQueue:getRealQueueNum()--注意此处需要使用到真实的队列人数！
	local emptyNum = self._norQueMaxNum - realQueueNum --空位

	for i = 1, emptyNum do
		local data = self._waitPayQueue:popQueue()

		if data == nil then
			--等待队列已空
			break
		end

		local queElfId = data.elfId

		local queNpcInfo = self._npcInfoMap[queElfId]

		print("WaitToNor:"..queElfId)

		--进入支付
		local isWaitPay = self:joinPay(queElfId)

		assert(isWaitPay == false, "should be false")

		--设置npc状态
		queNpcInfo:enterPayState(isWaitPay)

		--调用npc信息控制方法
		self:npcStateControl(queElfId)
	end

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
			local duration = 10.0--收银时间

			--收银开动
			G_timer:addTimerListener(ElfIdList.PayQueCheck, duration, self) --加入时间控制

			--删除定时器
			G_timer:removeTimerListener(elfId)

			--玩家状态改变
			npcInfo:setPayStatePaying()

			G_modelDelegate:setStateStr(elfId, "Paying")

		else --npc在其他位

		end--index if ended
	else 
		print("error:"..elfId)
		error("error elfId")
	end --npcInfo if ended

end

function PayControl:payEnded()
	--第一个npc收银完毕，
	--1、处理第一个npc，删除其所在的队列
	--2、遍历所有在队列里面的npc（第一个已经离开队列），
	--   凡是标记移动状态为1（移动结束）的npc都强制修正为队列位置（已经在该位置的无影响）

	--pop队列
	local data = self._norPayQueue:popQueue()

	local elfId = data.elfId

	local npcInfo = self._npcInfoMap[elfId]

	print("payEnded:"..elfId)
	--标记状态
	self._statusDic[elfId] = 0
	
	--赶走第一个玩家
	npcInfo:setPayStatePayEnded()

	--进入控制
	self:npcStateControl(elfId)

	--强制修正所有在队列里面的npc位置
	self:adjustQueuePoint()
end

--npc主状态转换
function PayControl:npcStateControl(elfId)

	local npcInfo = self._npcInfoMap[elfId]

	if npcInfo then
		local returnValue = npcInfo:npcState() --执行状态方法
		-- dump(returnValue, "value") 
		local isRelease = returnValue.isRelease --是否已经释放
		local totalTime = returnValue.totalTime --回调时间
		local isMoveEnd = returnValue.isMoveEnd
		local mapId = returnValue.mapId --移动目标id

		local testStateStr = returnValue.testStateStr

		if isMoveEnd then
			G_payControl:joinNormalPay(npcInfo) --加入普通支付
			return --忽略
		end


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
		--npc移动到指定位置的回调
		self:npcMoveEnded(listenerId - ElfIdList.PayNpcOffset)--减去偏移

	elseif listenerId >= ElfIdList.NpcOffset then
		--npc状态的回调
		self:npcStateControl(listenerId)
	elseif listenerId == ElfIdList.PayQueCheck then
		self:payEnded() --收银完毕
	end	
end





