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

function NPCInfo:meetProductNeed()
	if self.curState ==  NPCStateType.SeatRequest then
		self.curState = NPCStateType.SeatEating
		self.curFeel = NPCFeelType.Invalid
	elseif self.curState ==  NPCStateType.WaitSeatRequest then
		self.curState = NPCStateType.WaitSeatIdle
		self.curFeel = NPCFeelType.Invalid
	else
		error("error call")
	end
end

function NPCInfo:enterPayState(isWaitPay)
	if isWaitPay then
		self.curState = NPCStateType.WaitPay
		self.curFeel = NPCFeelType.Normal --情感
	else
		self.curState = NPCStateType.NormalPay
		self.curPay = NPCPayType.Moving --支付情感

	end
end

function NPCInfo:setPayStateNormal()
	assert(self.curState == NPCStateType.NormalPay and self.curPay == NPCPayType.Prepare, "error set")
	self.curPay = NPCPayType.Normal
end

--npc主状态转换
function NPCInfo:npcState()
	local elfId = self.elfId --npcId --NPC的id，具有唯一性
	local totalTime = -1 --回调参数, 若此值为-1则timercontrol不回调，若为0则直接回调，大于0则延迟回调
	local mapId = -1 --npc的目标mapId，若此值为-1则不向view发起寻路命令
	local productVec = nil
	local isEnterPay = false

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
			totalTime = math.random(0.1, 0.2)
			self.curState = NPCStateType.FindSeat

		end,
		--离开门口
		[NPCStateType.LeaveDoor] 				= function()
		stateStr = "L-Door"	
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

			else --寻找外卖座位
				--在开始位置找不到空位怎么处理，继续停留在开始位置等待随机时间？
				totalTime = 0.1
				self.curState = NPCStateType.FindWaitSeat

			end

		end,
		--在座位请求
		[NPCStateType.SeatRequest] 				= function()
		local feelStr = nil
		-- stateStr = "SeatRequest"
			--进入feel状态切换 
			local isWaitSeat = false  --false 表示非外卖座位
			totalTime, productVec, feelStr = self:npcFeelOnRequest(isWaitSeat)

			stateStr = "Req-"..feelStr
		end,
		--在座位吃东西
		[NPCStateType.SeatEating] 				= function()
		
			local productVec = self:nextProduct()
			totalTime = math.random(1, 2)
			if productVec then
				stateStr = "Eat"

				--还有需求
				self.curState = NPCStateType.SeatRequest --状态切换
				self.curFeel = NPCFeelType.Prepare --进入子状态

			else
				stateStr = "Pay"
				--没有需求，进入支付状态
				self.curState = NPCStateType.Pay

				


				--进入支付状态，feel状态进入normal（由于支付是马上执行？）
				-- self.curState = NPCStateType.SeatPay
				-- self.curFeel = NPCFeelType.Normal
			end

		end,
		[NPCStateType.Pay] 							= function()
				isEnterPay = true
				--npc进入支付状态，model把npc交给G_payControl
				--G_payControl决定玩家进入等待支付还是普通支付
				--进入普通支付时，清除npc的时间回调再进入npcState，并加入时间回调
				--进入等待支付，调用npcState，并加入时间回调


				-- local isWaitPay = G_payControl:joinPay(elfId)
				-- totalTime = 0.1

				-- if isWaitPay then --等待支付状态
				-- 	stateStr = "WaitPay"
				-- 	self.curState = NPCStateType.WaitPay
				-- 	self.curFeel = NPCFeelType.Normal --原地感情变化

				-- else --普通支付状态
				-- 	stateStr = "NorPay"
				-- 	self.curState = NPCStateType.NormalPay
				-- 	self.curPay = NPCPayType.Moving --准备进入排队队列
				-- end
		end,
		[NPCStateType.NormalPay] 					= function()
			print("normal pay")
			totalTime, mapId = self:npcPayOnNorPay()
		end,
		[NPCStateType.WaitPay] 						= function()
			print("wait pay")
		end,
		[NPCStateType.LeavePay] 					= function()
		end,
		--在座位支付
		[NPCStateType.SeatPay] 					= function()
		stateStr = "Pay"
			--进入feel状态切换
			local isWaitSeat = false
			totalTime = self:npcFeelOnPay(isWaitSeat)
		end,
		--支付成功
		[NPCStateType.SeatPaySuccess]			= function()
		stateStr = "PayOK"
			totalTime = 1.0
			self.curState = NPCStateType.LeaveSeat
			self.curFeel = NPCFeelType.Invalid
		end,
		--离开座位
		[NPCStateType.LeaveSeat] 				= function()
		stateStr = "L-S"
			-- print("npc leave")
			--离开座位之后回到开始位置然后kill掉?
			G_seatControl:leaveSeat(kMapDataSeat, self.mapId, elfId)
			mapId = G_seatControl:getMapIdOfType(kMapDataStart)

			self.curState = NPCStateType.Release --进入销毁状态
		end,
		--寻找外卖座位
		[NPCStateType.FindWaitSeat] 			= function()
		stateStr = "F-Wait-S"
			mapId = G_seatControl:occupySeat(kMapDataWaitSeat, elfId)

			if mapId > -1 then--占位成功
				--离开门口
				G_seatControl:leaveSeat(kMapDataDoor, self.mapId, elfId)

				self.curState = NPCStateType.WaitSeatRequest --状态切换
				self.curFeel = NPCFeelType.Prepare --进入子状态

			else --寻找外卖座位
				--在开始位置找不到空位怎么处理，继续停留在开始位置等待随机时间？
				stateStr = "L-Door"
				totalTime = 0.1
				self.curState = NPCStateType.LeaveDoor

			end

		end,
		--在外卖座位发起请求
		[NPCStateType.WaitSeatRequest] 			= function()
			--进入feel状态切换
			local isWaitSeat = true  --true 表示外卖座位
			totalTime, productVec, feelStr = self:npcFeelOnRequest(isWaitSeat)

			stateStr = "Req-"..feelStr
		end,
		--在外卖座位支付
		[NPCStateType.WaitSeatPay] 				= function()
		stateStr = "Pay"
			--进入feel状态切换
			local isWaitSeat = true
			totalTime = self:npcFeelOnPay(isWaitSeat)
		end,
		--在外卖座位稍微发呆
		[NPCStateType.WaitSeatIdle] 			= function()
		stateStr = "Idle"
			local productVec = self:nextProduct()
			totalTime = math.random(1, 2)
			if productVec then

				--还有需求
				self.curState = NPCStateType.WaitSeatRequest --状态切换
				self.curFeel = NPCFeelType.Prepare --进入子状态

			else
				--没有需求，进入支付状态

				--进入支付状态，feel状态进入normal（由于支付是马上执行？）
				self.curState = NPCStateType.WaitSeatPay
				self.curFeel = NPCFeelType.Normal
			end
		end,
		--在外卖座位支付成功
		[NPCStateType.WaitSeatPaySuccess] 		= function()
		stateStr = "PayOk"
		    totalTime = 1.0
			self.curState = NPCStateType.LeaveWaitSeat
			self.curFeel = NPCFeelType.Invalid --重置状态
		end,
		--离开外卖座位
		[NPCStateType.LeaveWaitSeat] 			= function()
		stateStr = "L-WaitSeat"
			--离开座位之后回到开始位置然后kill掉?
			G_seatControl:leaveSeat(kMapDataWaitSeat, self.mapId, elfId)
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

	local returnValue      = {}
	returnValue.isRelease  = isRelease
	returnValue.isEnterPay = isEnterPay
	returnValue.totalTime  = totalTime
	returnValue.mapId      = mapId
	returnValue.productVec = productVec
	returnValue.testStateStr = stateStr

	return returnValue
end

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
function NPCInfo:npcFeelOnRequest(isWaitSeat)
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

			totalTime = math.random(10, 15)
			self.curFeel = NPCFeelType.Anger
		end,
		--普通等待完毕，进入愤怒状态
		[NPCFeelType.Anger]						= function()
		testStateStr = "Ang"
			-- print("Anger")
			totalTime = math.random(10, 15)
			self.curFeel = NPCFeelType.Cancel
		end,
		--不理客人,客人要走啦
		[NPCFeelType.Cancel] 					= function()
		testStateStr = "XX"
			-- print("Cancel")
			totalTime = 0.8 --预留播放动画时间

			self.curFeel = NPCFeelType.Invalid
			if isWaitSeat then
				--外卖座位
				self.curState = NPCStateType.LeaveWaitSeat

			else
				--普通座位
				self.curState = NPCStateType.LeaveSeat
			end
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

--支付状态下状态转换
function NPCInfo:npcFeelOnPay(isWaitSeat)
	local feelType = self.curFeel
	local totalTime = 0

	local switchType = {
		--吃完饭，普通等待埋单
		[NPCFeelType.Normal]					= function()
			totalTime = math.random(1, 3)
			self.curFeel = NPCFeelType.Anger
		end,
		--普通等待完毕，进入愤怒状态
		[NPCFeelType.Anger]						= function()
			totalTime = math.random(1, 3)
			self.curFeel = NPCFeelType.Cancel
		end,
		--不理客人,客人要走啦
		[NPCFeelType.Cancel] 					= function()
			totalTime = 0.8 --预留播放动画时间

			self.curFeel = NPCFeelType.Invalid
			if isWaitSeat then
				--外卖座位
				self.curState = NPCStateType.LeaveWaitSeat

			else
				--普通座位
				self.curState = NPCStateType.LeaveSeat
			end
			
		end,
		[NPCFeelType.Prepare]					= function()
			error("error feel") --支付状态下无准备阶段
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

	return totalTime
end

--normal pay
function NPCInfo:npcPayOnNorPay()
	local payType = self.curPay
	local totalTime = -1
	local mapId = -1

	local switchType = {
		[NPCPayType.Moving]					= function()
		--已到达埋单候选位置
		    mapId = G_payControl:getPayPointMapId()
			self.curPay = NPCPayType.MoveEnd
		end,
		[NPCPayType.MoveEnd]					= function()
			--加入队列
			print("move ended")
			self.curPay = NPCPayType.Prepare --不会有时间回调
			G_payControl:joinNormalPay(self) --加入普通支付
		end,
		[NPCPayType.Prepare]						= function()
			--npc进入指定位置后变成Prepare，然后由支付control统一控制进入normal
		    error("pay control should change it to normal")
		end,

		--吃完饭，普通等待埋单
		[NPCPayType.Normal]					= function()
			totalTime = math.random(1, 3)
			self.curFeel = NPCPayType.Anger
		end,
		--普通等待完毕，进入愤怒状态
		[NPCPayType.Anger]						= function()
			totalTime = math.random(1, 3)
			self.curFeel = NPCPayType.Cancel
		end,
		--不理客人,客人要走啦
		[NPCPayType.Cancel] 					= function()
			G_payControl:leavePay(self.elfId)
		end,

		[NPCPayType.Paying]						= function()

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

	return totalTime, mapId
end
