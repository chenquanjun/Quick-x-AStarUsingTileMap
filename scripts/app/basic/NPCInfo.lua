--npc通用信息
NPCInfo = {}
--index
NPCInfo.__index = NPCInfo
-- NPCInfo.__mode = "v" --弱引用
--public
NPCInfo.elfId    = -1
NPCInfo.modelId  = -1
NPCInfo.mapId    = -1
NPCInfo.curState = NPCStateType.Invalid    --NPC主状态
NPCInfo.curFeel  = NPCFeelType.Invalid     --NPC感情类型
NPCInfo.curPay   = NPCPayType.Invalid

NPCInfo.seatType = -1  --座位类型

NPCInfo._productList = nil
NPCInfo._productIndex = 1  --默认指向第一个需求

function NPCInfo:create()
	local ret = {}
	setmetatable(ret, NPCInfo)
	ret:init()
    return ret
end

function NPCInfo:init()
	
end

--设计：npc在座位提出需求，每次需求有一个或多个product，满足一次需求之后可能还有需求
--产品信息使用方法
--1、首先初始化npc时候setProductList(结构：从1开始，每个元素里面包含一个或多个产品id)
--2、获取当前产品getCurProduct，
--3、 再遍历玩家身上的完成物品表，调用isNeedProduct方法判断是否满足npc需求
--4、npc本次需求满足后，进入进食状态，调用nextProduct方法，返回nil退出，否则重复2，3


function NPCInfo:setProductList(productList)
	self._productList = productList
	self._productIndex = 1
end


function NPCInfo:getCurProduct()

	local productVec = self._productList[self._productIndex]

	return productVec
end

function NPCInfo:nextProduct()
	self._productIndex = self._productIndex + 1
	return self:getCurProduct()
end

function NPCInfo:isNeedProduct(elfId)
	local needIndex = -1 --默认没有
	local productVec = self:getCurProduct() --获得当前的productVec

	-- dump(productVec, "product")

	for index, product in ipairs(productVec) do
		local productId = product.elfId
		local state = product.curState 
		if elfId == productId and state == 0 then--elfId相同， 而且未满足需求
			product.curState = 1 --设置成满足

			needIndex = index
			break
		end
	end

	-- dump(productVec, "product")

	return needIndex
end

function NPCInfo:removeFinishProduct(indexVec)
	local productVec = self:getCurProduct() 

    local size = #productVec
    local indexSize = #indexVec

    for i = 1, indexSize do
        local iRevert = indexSize - i + 1

        local index = indexVec[iRevert] --从后面删除

        local product = productVec[index]

        assert(product.curState == 1, "remove error")

        productVec[index] = nil

        for j = index, size do
            productVec[j] = productVec[j + 1]
        end

    end
end

function NPCInfo:isAllProductOK()
	--其实统计产品个数是否为0也可以
	local productVec = self:getCurProduct() --获得当前的productVec

	local isAllOK = true

	for index, product in ipairs(productVec) do

		local state = product.curState 
		if 	state == 0 then--有没满足需求的

			isAllOK = false --设置为false
			break 
		end
	end

	return isAllOK
end

--[[-------------------
	---set  state -----
	---------------------]]

--外部改变npc状态：满足npc需求，赶走npc，进入排队队列等等，使用setxxxx方法
--改变状态后需要调用npcstate方法才能真正执行该状态
function NPCInfo:setSeatStateEating()
	--只有在座位/等待座位请求的npc
	--并且情感状态为普通/愤怒（下个状态）
	-- assert(self.curState == NPCStateType.SeatRequest or self.curState == NPCStateType.WaitSeatRequest, "error state")
	-- assert(self.curFeel == NPCFeelType.Anger or self.curFeel == NPCFeelType.Cancel, "error feel state")

	assert(self:isRequest(), "error state, should be request")

	self.curState = NPCStateType.SeatEating
	self.curFeel = NPCFeelType.Invalid
end

function NPCInfo:setPayStateBegin(isWaitPay)
	if isWaitPay then --等待支付（支付情感控制）
		self.curState = NPCStateType.WaitPay
		self.curPay = NPCPayType.Normal --情感
	else --普通支付（移动）
		self.curState = NPCStateType.NorPayMoving
	end
end

--普通支付状态:npc情感开始变化
function NPCInfo:setPayStateNormal()
	assert(self.curState == NPCStateType.NorPayPrePare, "error state")

	self.curState = NPCStateType.NormalPay
	self.curPay = NPCPayType.Normal
end

--普通支付状态:正在支付
function NPCInfo:setPayStatePaying()
	--玩家在normalpay状态，支付状态为普通或者愤怒（要延后一个状态）
	assert(self.curState == NPCStateType.NormalPay, "error state")
	assert(self.curPay == NPCPayType.Anger or self.curPay == NPCPayType.Cancel, "error pay state")

	self.curPay = NPCPayType.Paying
end

--普通支付状态:支付结束
function NPCInfo:setPayStatePayEnded()
	--主状态:普通支付，支付状态:正在支付
	assert(self.curState == NPCStateType.NormalPay, "error state")
	assert(self.curPay == NPCPayType.Paying, "error pay state")

	self.curState = NPCStateType.LeavePay

	--统计信息
	G_stats:leaveFor(self.elfId, LeaveReason.PayEnded)
end

--赶走npc
function NPCInfo:setSeatStateGetOut()
	--只有在座位/等待座位请求的npc
	--并且情感状态为普通/愤怒（下个状态）
	-- assert(self.curState == NPCStateType.SeatRequest or self.curState == NPCStateType.WaitSeatRequest, "error state")
	-- assert(self.curFeel == NPCFeelType.Anger or self.curFeel == NPCFeelType.Cancel, "error feel state")

	assert(self:isRequest(), "error state, should be request")

	self.curState = NPCStateType.LeaveSeat

	--统计信息
	G_stats:leaveFor(self.elfId, LeaveReason.GetOut)
end

--[[-------------------
	---set change -----
	---------------------]]
--npc主状态转换
function NPCInfo:npcState()
	local elfId = self.elfId --npcId --NPC的id，具有唯一性
	local totalTime = -1 --回调参数, 若此值为-1则timercontrol不回调，若为0则直接回调，大于0则延迟回调
	local mapId = -1 --npc的目标mapId，若此值为-1则不向view发起寻路命令
	local productVec = nil
	local isEnterPay = false
	local isMoveEnd  = false

	local stateStr = nil
	--switch....
	local switchState = {
		--释放
		[NPCStateType.Release]					= function()
			return true --返回,注意此处非npcState方法的返回
		end,
		--开始位置
		[NPCStateType.Start]					= function()
		stateStr = "start"
			totalTime = math.random(0.1, 0.5)
			self.curState = NPCStateType.GoToDoor --状态切换

		end,
		--开始到门口
		[NPCStateType.GoToDoor]					= function()
		stateStr = "ToDoor"
			mapId = G_seatControl:occupySeat(kMapDataDoor, elfId)

			if mapId > -1 then--占位成功
				self.curState = NPCStateType.Door --状态切换

			else --找不到门口空位 
				--在开始位置找不到空位怎么处理，继续停留在开始位置等待随机时间？
				totalTime = 0
				self.curState = NPCStateType.Start

			end
		end,
		--门口位置
		[NPCStateType.Door] 					= function()
		stateStr = "Door"
			--在门口稍微停留再看看有没位置
			totalTime = math.random(0.1, 0.3)
			self.curState = NPCStateType.FindSeat

		end,
		--离开门口
		[NPCStateType.LeaveDoor] 				= function()
		stateStr = "L-Door"	
			--统计信息
			G_stats:leaveFor(self.elfId, LeaveReason.NoSeat)

			--获得开始位置的mapId
			mapId = G_seatControl:getMapIdOfType(kMapDataStart)
			--改变状态
			self.curState = NPCStateType.Start --开始位置
			--清空位置
			G_seatControl:leaveSeat(kMapDataDoor, self.mapId, elfId)

		end,
		--寻找座位
		[NPCStateType.FindSeat] 				= function()
		stateStr = "F-Seat"
			mapId = G_seatControl:occupySeat(kMapDataSeat, elfId)

			if mapId > -1 then--占位成功
				--离开门口
				G_seatControl:leaveSeat(kMapDataDoor, self.mapId, elfId)

				self.curState = NPCStateType.SeatRequest --状态切换
				self.curFeel = NPCFeelType.Prepare --进入子状态

				self.seatType = kMapDataSeat        --保存曾经的座位类型

			else --寻找外卖座位
				--在开始位置找不到空位怎么处理，继续停留在开始位置等待随机时间？
				totalTime = 0.1
				self.curState = NPCStateType.FindWaitSeat

			end

		end,
		--寻找外卖座位
		[NPCStateType.FindWaitSeat] 			= function()
		stateStr = "F-Wait-S"
			mapId = G_seatControl:occupySeat(kMapDataWaitSeat, elfId)

			if mapId > -1 then--占位成功
				--离开门口
				G_seatControl:leaveSeat(kMapDataDoor, self.mapId, elfId)

				self.curState = NPCStateType.SeatRequest --状态切换
				self.curFeel = NPCFeelType.Prepare --进入子状态

				self.seatType = kMapDataWaitSeat      	--曾经的座位类型

			else --寻找外卖座位
				--在开始位置找不到空位怎么处理，继续停留在开始位置等待随机时间？
				stateStr = "L-Door"
				totalTime = 0.1
				self.curState = NPCStateType.LeaveDoor

			end

		end,
		--在座位请求
		[NPCStateType.SeatRequest] 				= function()
		local feelStr = nil
			--进入feel状态切换 

			totalTime, productVec, feelStr = self:npcFeelOnRequest()

			stateStr = "Req-"..feelStr
		end,
		--在座位吃东西/外卖稍微收拾一下
		[NPCStateType.SeatEating] 				= function()
		
			local productVec = self:nextProduct()
			totalTime = math.random(0.5, 0.6)
			if productVec then
				stateStr = "Eat"

				--还有需求
				self.curState = NPCStateType.SeatRequest --状态切换
				self.curFeel = NPCFeelType.Prepare --进入子状态

			else
				stateStr = "Pay"
				--没有需求，进入支付状态
				self.curState = NPCStateType.Pay
			end

		end,
		--进入支付状态
		[NPCStateType.Pay] 							= function()
		stateStr = "Pay"
			isEnterPay = true

		end,
		--普通支付移动
		[NPCStateType.NorPayMoving] 				= function()
		stateStr = "Mov"
			G_seatControl:leaveSeat(self.seatType, self.mapId, self.elfId) --离开座位

		    mapId = G_payControl:getPayPointMapId()
			self.curState = NPCStateType.NorPayMoveEnd
		end,
		--普通支付移动结束
		[NPCStateType.NorPayMoveEnd] 				= function()
		stateStr = "M-End"
		-- 已到达埋单候选位置
		-- 加入队列
			self.curState = NPCStateType.NorPayPrePare --
			isMoveEnd = true
			-- G_payControl:joinNormalPay(self) --加入普通支付
		end,
		--普通支付等待
		[NPCStateType.NorPayPrePare] 			= function()
		stateStr = "Pre"
		-- 	--npc进入指定位置后变成Prepare，然后由支付control统一控制进入normal
		    error("pay control should change it to normal")
		end,
		--普通支付
		[NPCStateType.NormalPay] 					= function()
			-- print("normal pay")
			totalTime, mapId, feelStr = self:npcPayOnNorPay()

			stateStr = "Nor-"..feelStr
		end,
		--等待支付
		[NPCStateType.WaitPay] 						= function()
			-- print("wait pay")
			totalTime, mapId, feelStr = self:npcPayOnWaitPay()
			stateStr = "Wait-"..feelStr
		end,
		--离开支付状态
		[NPCStateType.LeavePay] 					= function()
		stateStr = "L-Pay"
			mapId = G_seatControl:getMapIdOfType(kMapDataStart)

			self.curState = NPCStateType.Release --进入销毁状态
		end,
		--离开座位状态
		[NPCStateType.LeaveSeat] 				= function()
		stateStr = "L-S"
			G_seatControl:leaveSeat(self.seatType, self.mapId, elfId)
			mapId = G_seatControl:getMapIdOfType(kMapDataStart)

			self.curState = NPCStateType.Release --进入销毁状态
		end,

	} --switch end

	local state = self.curState --npc通用状态
	local fSwitch = switchState[state] --switch 方法

	local isRelease = false

	--存在switch（必然存在）
	if fSwitch then
		--执行switch的代码，默认无返回值，若返回true则说明需要释放此NPC
		local result = fSwitch() 
		if result then

			isRelease = true
		end
	else
		error("error state") --没有枚举
		return
	end
	--返回totalTime 和 mapId
	--如果isRelease为true则释放对象
	--如果totalTime小于0，mapId不为0则说明totaltime需要view回调寻路时间来决定
	--否则totalTime小于0是设置错误
	--如果mapId不为-1则移动npc

	local returnValue        = {}
	returnValue.isRelease    = isRelease 	--是否已经释放
	returnValue.isEnterPay   = isEnterPay 	--是否进入支付状态（model交给paycontrol控制）
	returnValue.isMoveEnd    = isMoveEnd 	--是否移动到普通支付候选位置
	returnValue.totalTime    = totalTime 	--总时间
	returnValue.mapId        = mapId     	--移动位置
	returnValue.productVec   = productVec 	--产品数组
	returnValue.testStateStr = stateStr 	--测试状态string

	return returnValue
end

--npc是否在请求状态
function NPCInfo:isRequest()
	local isRequest = false

	if self.curState ==  NPCStateType.SeatRequest or self.curState ==  NPCStateType.WaitSeatRequest then
		if self.curFeel ==  NPCFeelType.Anger or self.curFeel ==  NPCFeelType.Cancel then
			isRequest = true
		end
	end
	return isRequest
end

--请求状态下状态转换
function NPCInfo:npcFeelOnRequest()
	local feelType = self.curFeel
	local totalTime = 0
	local productVec = nil
	local testStateStr = nil

	local switchType = {
		--准备点菜
		[NPCFeelType.Prepare]					= function()
		testStateStr = "Pre"
			-- print("prepare")
			totalTime = math.random(0.1, 0.2)
			self.curFeel = NPCFeelType.Normal
		end,
		--点菜完毕，进入普通等待
		[NPCFeelType.Normal]					= function()
		testStateStr = "Nor"
			-- print("Normal")
			--点餐
			productVec = self:getCurProduct()

			totalTime = math.random(3, 5)
			self.curFeel = NPCFeelType.Anger
		end,
		--普通等待完毕，进入愤怒状态
		[NPCFeelType.Anger]						= function()
		testStateStr = "Ang"
			-- print("Anger")
			totalTime = math.random(3, 5)
			self.curFeel = NPCFeelType.Cancel
		end,
		--不理客人,客人要走啦
		[NPCFeelType.Cancel] 					= function()
		testStateStr = "XX"

			--统计信息
			if self.seatType == kMapDataSeat then --座位
				G_stats:leaveFor(self.elfId, LeaveReason.SeatAnger)

			elseif self.seatType == kMapDataWaitSeat then --等待座位
				G_stats:leaveFor(self.elfId, LeaveReason.WaitSeatAnger)
			end
			
			-- print("Cancel")
			totalTime = 0.8 --预留播放动画时间

			self.curFeel = NPCFeelType.Invalid

			self.curState = NPCStateType.LeaveSeat

		end,
	} --switch end

	local fSwitch = switchType[feelType] --switch 方法

	--存在switch（必然存在）
	if fSwitch then
		local result = fSwitch() --执行function
	else
		error("error state") --没有枚举
		return
	end

	return totalTime, productVec, testStateStr
end

--normal pay
function NPCInfo:npcPayOnWaitPay()
	local payType = self.curPay
	local totalTime = -1
	local mapId = -1
	local testStateStr = nil

	local switchType = {
		--普通等待
		[NPCPayType.Normal]					= function()
		testStateStr = "Nor"
			totalTime = math.random(10, 15)
			self.curPay = NPCPayType.Anger
		end,
		--普通等待完毕，进入愤怒状态
		[NPCPayType.Anger]						= function()
		testStateStr = "Ang"
			totalTime = math.random(10, 15)
			self.curPay = NPCPayType.Cancel
		end,
		--不理客人,客人要走啦
		[NPCPayType.Cancel] 					= function()
		testStateStr = "Can"
			--统计信息
			G_stats:leaveFor(self.elfId, LeaveReason.WaitPayAnger)

			totalTime = 0 
			G_seatControl:leaveSeat(self.seatType, self.mapId, self.elfId) --离开座位
			self.curState = NPCStateType.LeavePay --进入离开状态
			G_payControl:leaveWaitPay(self.elfId) --通知payControl进入离开队列
		end,

		[NPCPayType.Paying]						= function()
		error("wait pay no paying type")
		end,

	} --switch end

	local fSwitch = switchType[payType] --switch 方法

	--存在switch（必然存在）
	if fSwitch then
		local result = fSwitch() --执行function
	else
		error("error state") --没有枚举
		return
	end

	return totalTime, mapId, testStateStr
end

--normal pay
function NPCInfo:npcPayOnNorPay()
	local payType = self.curPay
	local totalTime = -1
	local mapId = -1
	local testStateStr = nil

	local switchType = {
		--普通等待
		[NPCPayType.Normal]					= function()
		testStateStr = "Nor"
			totalTime = math.random(3, 5)
			self.curPay = NPCPayType.Anger
		end,
		--普通等待完毕，进入愤怒状态
		[NPCPayType.Anger]						= function()
		testStateStr = "Ang"
			totalTime = math.random(3, 5)
			self.curPay = NPCPayType.Cancel
		end,
		--不理客人,客人要走啦
		[NPCPayType.Cancel] 					= function()
		testStateStr = "Can"
			--统计信息
			G_stats:leaveFor(self.elfId, LeaveReason.NorPayAnger)

			totalTime = 0 
			self.curState = NPCStateType.LeavePay --进入离开状态
			G_payControl:leavePay(self.elfId) --通知payControl进入离开队列
		end,

		[NPCPayType.Paying]						= function()
		testStateStr = "Paying"
		end,

	} --switch end

	local fSwitch = switchType[payType] --switch 方法

	--存在switch（必然存在）
	if fSwitch then
		local result = fSwitch() --执行function
	else
		error("error state") --没有枚举
		return
	end

	return totalTime, mapId, testStateStr
end
