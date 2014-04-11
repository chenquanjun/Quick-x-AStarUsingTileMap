NPCStateType = {
				Invalid                = 1,

				Start                  = 2,            --开始位置
				Release                = 3,            --释放

				GoToDoor               = 11,           --移动到门口
				Door                   = 12,            --在门口
				LeaveDoor              = 13,            --离开门口

				FindSeat               = 20,            --尝试寻找座位
				SeatRequest            = 21,            --在座位请求状态 包含子状态NPCFeelType
				SeatEating             = 22,            --在座位吃饭状态
				SeatPay                = 23,            --在座位支付状态 包含子状态NPCFeelType
				SeatPaySuccess         = 24,
				LeaveSeat              = 25,            --离开座位

				FindWaitSeat           = 30,            --寻找等待座位
				WaitSeatRequest        = 31,
				WaitSeatPay            = 32,
				WaitSeatIdle           = 33,            --等于SeatEating
				WaitSeatPaySuccess     = 34,      
				LeaveWaitSeat          = 35,            --离开等待座位


}

NPCFeelType = {
				Invalid   =    1,
				Prepare   =    2,
				Normal    =    3,
				Anger     =    4,
				Cancel    =    5,
}


NPCInfo = {}
--index
NPCInfo.__index = NPCInfo
--public
NPCInfo.elfId    = -1
NPCInfo.modelId  = -1
NPCInfo.mapId    = -1
NPCInfo.curState = NPCStateType.Invalid    --NPC主状态
NPCInfo.curFeel  = NPCFeelType.Invalid     --NPC感情类型

NPCInfo._productList = nil
NPCInfo._productIndex = 1  --默认指向第一个需求

function NPCInfo:create()
	local ret = {}
	setmetatable(ret, NPCInfo)
	self:init()
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

function NPCInfo:setStateEating()
	self.curState = NPCStateType.SeatEating
	self.curFeel = NPCFeelType.Invalid
end

--npc主状态转换
function NPCInfo:npcState()
	local elfId = self.elfId --npcId --NPC的id，具有唯一性
	local totalTime = -1 --回调参数, 若此值为-1则timercontrol不回调，若为0则直接回调，大于0则延迟回调
	local mapId = -1 --npc的目标mapId，若此值为-1则不向view发起寻路命令
	local productVec = nil

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
			totalTime = math.random(1, 3)
			self.curState = NPCStateType.GoToDoor --状态切换

		end,
		--开始到门口
		[NPCStateType.GoToDoor]					= function()
		stateStr = "GoToDoor"
			mapId = G_mapGeneral:occupySeat(kMapDataDoor, elfId)

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
			totalTime = math.random(0.2, 0.5)
			self.curState = NPCStateType.FindSeat

		end,
		--离开门口
		[NPCStateType.LeaveDoor] 				= function()
		stateStr = "LeaveDoor"	
			--获得开始位置的mapId
			mapId = G_mapGeneral:getMapIdOfType(kMapDataStart)
			--改变状态
			self.curState = NPCStateType.Start --开始位置
			--清空位置
			G_mapGeneral:leaveSeat(kMapDataDoor, self.mapId, elfId)

		end,
		--寻找座位
		[NPCStateType.FindSeat] 				= function()
		stateStr = "FindSeat"
			mapId = G_mapGeneral:occupySeat(kMapDataSeat, elfId)

			if mapId > -1 then--占位成功
				--离开门口
				G_mapGeneral:leaveSeat(kMapDataDoor, self.mapId, elfId)

				self.curState = NPCStateType.SeatRequest --状态切换
				self.curFeel = NPCFeelType.Prepare --进入子状态

			else --寻找外卖座位
				--在开始位置找不到空位怎么处理，继续停留在开始位置等待随机时间？
				totalTime = 0
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

			stateStr = "Request"..feelStr
		end,
		--在座位吃东西
		[NPCStateType.SeatEating] 				= function()
		stateStr = "Eating"
			local productVec = self:nextProduct()

			if productVec then
				--还有需求
				self.curState = NPCStateType.SeatRequest --状态切换
				self.curFeel = NPCFeelType.Prepare --进入子状态

			else
				--没有需求，进入支付状态
				totalTime = math.random(1, 2)

				--进入支付状态，feel状态进入normal（由于支付是马上执行？）
				self.curState = NPCStateType.SeatPay
				self.curFeel = NPCFeelType.Normal
			end

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
		stateStr = "LeaveSeat"
			print("npc leave")
			--离开座位之后回到开始位置然后kill掉?
			G_mapGeneral:leaveSeat(kMapDataSeat, self.mapId, elfId)
			mapId = G_mapGeneral:getMapIdOfType(kMapDataStart)

			self.curState = NPCStateType.Release --进入销毁状态
		end,
		--寻找外卖座位
		[NPCStateType.FindWaitSeat] 			= function()
		stateStr = "FindWaitSeat"
			mapId = G_mapGeneral:occupySeat(kMapDataWaitSeat, elfId)

			if mapId > -1 then--占位成功
				--离开门口
				G_mapGeneral:leaveSeat(kMapDataDoor, self.mapId, elfId)

				self.curState = NPCStateType.WaitSeatRequest --状态切换
				self.curFeel = NPCFeelType.Prepare --进入子状态

			else --寻找外卖座位
				--在开始位置找不到空位怎么处理，继续停留在开始位置等待随机时间？
				totalTime = 0
				self.curState = NPCStateType.LeaveDoor

			end

		end,
		--在外卖座位发起请求
		[NPCStateType.WaitSeatRequest] 			= function()
		stateStr = "Request"
			--进入feel状态切换
			local isWaitSeat = true  --true 表示外卖座位
			totalTime = self:npcFeelOnRequest(isWaitSeat)
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
		    totalTime = math.random(1, 2)
			self.curState = NPCStateType.WaitSeatPay
			self.curFeel = NPCFeelType.Normal
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
		stateStr = "LeaveWaitSeat"
			--离开座位之后回到开始位置然后kill掉?
			G_mapGeneral:leaveSeat(kMapDataWaitSeat, self.mapId, elfId)
			mapId = G_mapGeneral:getMapIdOfType(kMapDataStart)

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
	returnValue.totalTime  = totalTime
	returnValue.mapId      = mapId
	returnValue.productVec = productVec
	returnValue.testStateStr = stateStr

	return returnValue
end

function NPCInfo:isRequest()
	local isRequest = false

	if self.curState ==  NPCStateType.SeatRequest then
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
		testStateStr = "prepare"
			-- print("prepare")
			totalTime = math.random(1, 2)
			self.curFeel = NPCFeelType.Normal
		end,
		--点菜完毕，进入普通等待
		[NPCFeelType.Normal]					= function()
		testStateStr = "Normal"
			print("Normal")
			--点餐
			productVec = self:getCurProduct()

			totalTime = math.random(10, 15)
			self.curFeel = NPCFeelType.Anger
		end,
		--普通等待完毕，进入愤怒状态
		[NPCFeelType.Anger]						= function()
		testStateStr = "Anger"
			-- print("Anger")
			totalTime = math.random(10, 15)
			self.curFeel = NPCFeelType.Cancel
		end,
		--不理客人,客人要走啦
		[NPCFeelType.Cancel] 					= function()
		testStateStr = "Cancel"
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
