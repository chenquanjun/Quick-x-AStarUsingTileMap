require "app/basic/extern"
require "app/basic/NPCInfo"
require "app/basic/PlayerInfo"
require "app/basic/TrayInfo"
require "app/timer/TimerControl"
require "app/timer/TimerControlDelegate"


--此处继承CCNode,因为需要维持这个表，但是用object的话需要retian/release
ManageModel = class("ManageModel", function()
	return CCNode:create()
end)			

--[[-------------------
	---Init Value-----
	---------------------]]
--index
ManageModel.__index = ManageModel
--private
ManageModel._delegate  			= nil --model delegate
ManageModel._timer  			= nil
ManageModel._timerDelegate  	= nil

--------Map Data-------------
--所有地图信息在mapDataDic保存
ManageModel._mapDataDic         = nil --地图信息字典，保存所有信息，如座位数组，等待座位数组

ManageModel._oneMapIdMap    	= nil --对于单个位置的object，一律保存到这个字典里面，例如开始位置，

ManageModel._seatVector  		= nil --座位数组，保存座位的mapId
ManageModel._waitSeatVector 	= nil --等待
ManageModel._doorVector  		= nil --门口
ManageModel._productVector      = nil

ManageModel._seatMap  			= nil --座位字典
ManageModel._waitSeatMap  		= nil --等待座位字典
ManageModel._doorMap  			= nil --门口字典

ManageModel._seatToServeDic		= nil --座位id与服务id的对应表

---------info map---------
ManageModel._npcInfoMap  		= nil --npc信息（包含id，状态）
ManageModel._playerInfoMap  	= nil --玩家信息
ManageModel._productInfoMap     = nil

-------------------------
ManageModel._trayInfo           = nil --面板信息

-------------------------
ManageModel._productIdOffset	= 100   --100~1000是物品id
ManageModel._npcIdOffset  		= 1000  --1000以后是npcId
ManageModel._npcTestFlag        = 0

--[[-------------------
	---Init Method-----
	---------------------]]

function ManageModel:create()
	local ret = ManageModel.new()
	ret:init()
	return ret
end

function ManageModel:init()
	print("Model init")
	self._seatMap 			= {}  --座位字典
	self._waitSeatMap 		= {} --等待座位字典
	self._doorMap 			= {} --门口字典
	self._npcInfoMap 		= {}
	self._playerInfoMap 	= {}
	self._productInfoMap 	= {}
	self._trayInfo = TrayInfo:create(5)

end

function ManageModel:setDelegate(delegate)
	self._delegate = delegate
end

function ManageModel:setSeatToServeDic(seatToServeDic)
	self._seatToServeDic = seatToServeDic
end

function ManageModel:setMapDataDic(mapDataDic)
	self._mapDataDic = mapDataDic

	--多个位置的数组
	self:initMapPointsVec()

	--单个位置
	self:initMapPoint()
end

--单点位置
function ManageModel:initMapPoint()
	local startVec = self._mapDataDic[kMapDataStart]
	local cookVec  = self._mapDataDic[kMapDataCook]
	local cashierVec  = self._mapDataDic[kMapDataCashier]

	local mapIdMap = {}

	mapIdMap[kMapDataStart] = startVec[1]
	mapIdMap[kMapDataCook] = cookVec[1]
	mapIdMap[kMapDataCashier] = cashierVec[1]

	self._oneMapIdMap = mapIdMap
end

--多点位置
function ManageModel:initMapPointsVec()

	local seatVec = self._mapDataDic[kMapDataSeat]
	local waitSeatVec = self._mapDataDic[kMapDataWaitSeat]
	local doorVec = self._mapDataDic[kMapDataDoor]
	
    --记录哪个mapId是座位，等待座位和门口, 下标从1开始
	self._seatVector = seatVec
	self._waitSeatVector = waitSeatVec
	self._doorVector = doorVec

	--初始化
	for i,v in ipairs(self._seatVector) 
	do 
		self._seatMap[v] = 0 --0表示空, 其他时候表示顾客的id 
	end  

	for i,v in ipairs(self._waitSeatVector) 
	do 
		self._waitSeatMap[v] = 0 --0表示空, 其他时候表示顾客的id 
	end  

	for i,v in ipairs(self._doorVector) 
	do 
		self._doorMap[v] = 0 --0表示空, 其他时候表示顾客的id 
	end  	
end

function ManageModel:onEnter()
	print("model onEnter")

	do --初始化定时器	

	--关于定时器
	--model负责维护timer及其delegate的生命周期
	--model直接调用timer的时间方法
	--timer到时间后调用delegate
	--delegate再回调model

		local timerControl = TimerControl:create()
		self:addChild(timerControl)
		self._timer = timerControl

		--定时器delegate 将model加入到refer中，以便delegate能回调model的方法
		local timerDelegate = TimerControlDelegate:setRefer(self)
		self._timerDelegate = timerDelegate

		timerControl:setDelegate(timerDelegate)

		-- self._delegate:setTimerInterval(timerControl:getTimerInterval())
	end
	--test
	local function performWithDelay(node, callback, delay)
	    local delay = CCDelayTime:create(delay)
	    local callfunc = CCCallFunc:create(callback)
	    local sequence = CCSequence:createWithTwoActions(delay, callfunc)
	    node:runAction(sequence)
	    return sequence
	end

	--批量循环增加测试
	local function addNPCTest()
		performWithDelay(self, function() 
			for i=1,6 do
			self:addNPC()
			end
			addNPCTest()
		end, math.random(1, 8))
	end

	self:addPlayer()
	addNPCTest() --批量测试
	-- self:addNPC() --单个测试

	self:initProduct()


	self._timer:startTimer()


end

function ManageModel:onRelease()
	print("Model on release")
	self._timer:removeDelegate() --timer对delegate的引用
	self._timerDelegate:removeRefer() --delegate对model的引用

	self._timerDelegate = nil

	self._timer = nil

	self._delegate = nil

	self._seatVector = nil
	self._waitSeatVector = nil
	self._doorVector = nil

	self._seatMap = nil
	self._waitSeatMap = nil
	self._doorMap = nil

	self._oneMapIdMap    = nil

	self._npcInfoMap  	= nil
	self._playerInfoMap  = nil

end

--[[-------------------
	---Private method-----
	---------------------]]

function ManageModel:initProduct()
	local productVec = self._mapDataDic[kMapDataProduct]

	for i,mapId in ipairs(productVec) do
		local elfId = self._productIdOffset + i

		local name = "id:"..elfId
		local productType = 1

		local duration = math.random(3, 5)

		local productInfo = {}
		productInfo.duration = duration
		productInfo.type = productType
		productInfo.name = name
		productInfo.mapId = mapId
		productInfo.num = 0
		self._productInfoMap[elfId] = productInfo
		--view初始化信息
		local data = {}
		data.elfId = elfId
		data.name = name
		data.type = productType
		data.mapId = mapId

		self._delegate:addProduct(data)

		--定时器 test
		self._delegate:coolDownProduct(elfId, duration)

		self._timer:addTimerListener(elfId, duration)
	end

end

function ManageModel:addPlayer()
	do --init 保存到字典
		local elfId = 1
		local mapId = self._oneMapIdMap[kMapDataCook]
	
		local playerInfo = PlayerInfo:create()
		playerInfo.mapId = mapId
		playerInfo.elfId = elfId
		playerInfo.curState = PlayerStateType.Idle

		self._playerInfoMap[elfId] = playerInfo
		
		--通知view添加玩家
		local data = {}
		data.elfId = elfId
		data.modelId = 1
		data.mapId = mapId
		self._delegate:addPlayer(data)
	end

	do --init 保存到字典
		local elfId = 2
		local mapId = self._oneMapIdMap[kMapDataCashier]
		print("mapId"..mapId)

		local playerInfo = PlayerInfo:create()
		playerInfo.mapId = mapId
		playerInfo.elfId = elfId

		self._playerInfoMap[elfId] = playerInfo
		
		--通知view添加玩家
		local data = {}
		data.elfId = elfId
		data.modelId = 2
		data.mapId = mapId
		self._delegate:addPlayer(data)
	end
end

--增加NPC
function ManageModel:addNPC()
	
	local elfId = self._npcIdOffset + self._npcTestFlag

	do --init 保存到字典
		local startMapId = self._oneMapIdMap[kMapDataStart]
		local modelId = math.random(3, 4)

		local npcInfo = NPCInfo:create()
		npcInfo.curState = NPCStateType.Start --开始位置
		npcInfo.curFeel = NPCFeelType.Invalid
		npcInfo.mapId = startMapId
		npcInfo.elfId = elfId
		npcInfo.modelId = modelId
		self._npcInfoMap[elfId] = npcInfo

		--进入状态控制
		self:npcState(npcInfo)		 
		
		--通知view添加npc
		local data = {}
		data.elfId = elfId
		data.modelId = modelId
		data.mapId = startMapId
		self._delegate:addNPC(data)
	end
	self._npcTestFlag = self._npcTestFlag + 1



end

function ManageModel:onCoolDown(elfId)
	local productInfo = self._productInfoMap[elfId]
	assert(productInfo.num == 0, "error") --当前设计最多只有1个，所以此值必为0
	productInfo.num = 1 --增加
end

function ManageModel:npcState(npcInfo)
	local elfId = npcInfo.elfId --npcId --NPC的id，具有唯一性
	local totalTime = -1 --回调参数, 若此值为-1则timercontrol不回调，若为0则直接回调，大于0则延迟回调
	local mapId = -1 --npc的目标mapId，若此值为-1则不向view发起寻路命令
	--switch....
	local switchState = {
		--释放
		[NPCStateType.Release]					= function()
			-- print("Release")
			self._npcInfoMap[elfId] = nil --释放

			return true --返回,注意此处非npcState方法的返回
		end,
		--开始位置
		[NPCStateType.Start]					= function()
			-- print("start")
			totalTime = math.random(1, 5)
			npcInfo.curState = NPCStateType.GoToDoor --状态切换

		end,
		--开始到门口
		[NPCStateType.GoToDoor]					= function()
			--print("GoToDoor")
			local isFindSeat = false

			for i,v in ipairs(self._doorVector) do
				
				local seatState = self._doorMap[v]

				if seatState == 0 then
					isFindSeat = true --找到空位
					mapId = v --保存id
					self._doorMap[v] = elfId --霸占位置
					npcInfo.curState = NPCStateType.Door --状态切换
					break
				end
			end --for

			--找不到门口空位 
			if not isFindSeat then
				--在开始位置找不到空位怎么处理，继续停留在开始位置等待随机时间？
				totalTime = 0
				npcInfo.curState = NPCStateType.Start
			end

		end,
		--门口位置
		[NPCStateType.Door] 					= function()
			--print("Door")
			--在门口稍微停留再看看有没位置
			totalTime = math.random(0.2, 0.5)
			npcInfo.curState = NPCStateType.FindSeat

		end,
		--离开门口
		[NPCStateType.LeaveDoor] 				= function()
			--print("LeaveDoor")
			mapId = self._oneMapIdMap[kMapDataStart]
			npcInfo.curState = NPCStateType.Start --开始位置

			--出现此错误因为npc的mapId没有正确设置
			assert(self._doorMap[npcInfo.mapId] == elfId, "error mapid, not in door") 
			self._doorMap[npcInfo.mapId] = 0 --清空位置

		end,
		--寻找座位
		[NPCStateType.FindSeat] 				= function()
			--print("FindSeat")
			local isFindSeat = false

			for i,v in ipairs(self._seatVector) do
				local seatState = self._seatMap[v]

				if seatState == 0 then
					isFindSeat = true --找到空位
					mapId = v --保存id

					assert(self._doorMap[npcInfo.mapId] == elfId, "error mapid, not in door") 
					assert(self._seatMap[v] == 0, "error mapid, not in seat") 

					self._doorMap[npcInfo.mapId] = 0 --清空门口位置

					self._seatMap[v] = elfId --霸占座位位置
					--进入座位请求状态，feel状态进入prepare
					npcInfo.curState = NPCStateType.SeatRequest --状态切换
					npcInfo.curFeel = NPCFeelType.Prepare --进入子状态
					break
				end
			end

			if not isFindSeat then
				--寻找外卖座位
				totalTime = 0
				npcInfo.curState = NPCStateType.FindWaitSeat
			end

		end,
		--在座位请求
		[NPCStateType.SeatRequest] 				= function()
			--print("SeatRequest")
			--进入feel状态切换
			local isWaitSeat = false  --false 表示非外卖座位
			totalTime = self:npcFeelOnRequest(npcInfo, isWaitSeat)
		end,
		--在座位吃东西
		[NPCStateType.SeatEating] 				= function()
			--print("SeatEating")
			totalTime = math.random(1, 2)
			--进入支付状态，feel状态进入normal（由于支付是马上执行？）
			npcInfo.curState = NPCStateType.SeatPay
			npcInfo.curFeel = NPCFeelType.Normal
		end,
		--在座位支付
		[NPCStateType.SeatPay] 					= function()
			--print("SeatPay")
			--进入feel状态切换
			local isWaitSeat = false
			totalTime = self:npcFeelOnPay(npcInfo, isWaitSeat)
		end,
		--支付成功
		[NPCStateType.SeatPaySuccess]			= function()
			--print("SeatPaySuccess")
			totalTime = 1.0
			npcInfo.curState = NPCStateType.LeaveSeat
			npcInfo.curFeel = NPCFeelType.Invalid
		end,
		--离开座位
		[NPCStateType.LeaveSeat] 				= function()
			--print("LeaveSeat")
			--离开座位之后回到开始位置然后kill掉?
			assert(self._seatMap[npcInfo.mapId] == elfId, "error")
			self._seatMap[npcInfo.mapId] = 0 --设置为空
			mapId = self._oneMapIdMap[kMapDataStart]

			npcInfo.curState = NPCStateType.Release --进入销毁状态
		end,
		--寻找外卖座位
		[NPCStateType.FindWaitSeat] 			= function()
		    --print("FindWaitSeat")
			local isFindSeat = false

			for i,v in ipairs(self._waitSeatVector) do
				local seatState = self._waitSeatMap[v]

				if seatState == 0 then
					isFindSeat = true --找到空位
					mapId = v --保存id

					assert(self._doorMap[npcInfo.mapId] == elfId, "error mapid, not in door") 
					assert(self._waitSeatMap[v] == 0, "error mapid, not in wait seat") 

					self._doorMap[npcInfo.mapId] = 0 --清空门口位置

					self._waitSeatMap[v] = elfId --霸占座位位置
					--进入座位请求状态，feel状态进入prepare
					npcInfo.curState = NPCStateType.WaitSeatRequest --状态切换
					npcInfo.curFeel = NPCFeelType.Prepare --进入子状态
					break
				end
			end

			if not isFindSeat then
				--离开门口
				totalTime = 0
				npcInfo.curState = NPCStateType.LeaveDoor
			end
		end,
		--在外卖座位发起请求
		[NPCStateType.WaitSeatRequest] 			= function()
		    --print("WaitSeatRequest")
			--进入feel状态切换
			local isWaitSeat = true  --true 表示外卖座位
			totalTime = self:npcFeelOnRequest(npcInfo, isWaitSeat)
		end,
		--在外卖座位支付
		[NPCStateType.WaitSeatPay] 				= function()
		    --print("WaitSeatPay")
			--进入feel状态切换
			local isWaitSeat = true
			totalTime = self:npcFeelOnPay(npcInfo, isWaitSeat)
		end,
		--在外卖座位稍微发呆
		[NPCStateType.WaitSeatIdle] 			= function()
		    --print("WaitSeatIdle")

		    totalTime = math.random(1, 2)
			npcInfo.curState = NPCStateType.WaitSeatPay
			npcInfo.curFeel = NPCFeelType.Normal
		end,
		--在外卖座位支付成功
		[NPCStateType.WaitSeatPaySuccess] 		= function()
		    --print("WaitSeatPaySuccess")
		    totalTime = 1.0
			npcInfo.curState = NPCStateType.LeaveWaitSeat
			npcInfo.curFeel = NPCFeelType.Invalid --重置状态
		end,
		--离开外卖座位
		[NPCStateType.LeaveWaitSeat] 			= function()
		    --print("LeaveWaitSeat")
			--离开座位之后回到开始位置然后kill掉?
			assert(self._waitSeatMap[npcInfo.mapId] == elfId, "error")
			self._waitSeatMap[npcInfo.mapId] = 0 --设置为空
			mapId = self._oneMapIdMap[kMapDataStart]

			npcInfo.curState = NPCStateType.Release --进入销毁状态
		end,
	} --switch end

	local state = npcInfo.curState --npc通用状态
	local fSwitch = switchState[state] --switch 方法

	--存在switch（必然存在）
	if fSwitch then
		--执行switch的代码，默认无返回值，若返回true则说明需要释放此NPC
		local result = fSwitch() 
		if result then
			--已经释放对象进入此代码段
			self._delegate:removeNPC(elfId)
			return
		end
	else
		error("error state") --没有枚举
		return
	end

	if mapId ~= -1 then
		--说明在switch中改变了值，调用viewdelegate, view会返回寻路花费的时间
		totalTime = self._delegate:moveNPC(elfId, mapId)
		npcInfo.mapId = mapId --保存目标位置
	end

	--注意，对于同一个id，小心totalTime总为为0导致死循环，因为0的时候直接回调此方法
	--print("id:"..npcId.." totalTIme:"..totalTime)
	self._timer:addTimerListener(elfId, totalTime) --加入时间控制

end

--请求状态下状态转换
function ManageModel:npcFeelOnRequest(npcInfo, isWaitSeat)
	local feelType = npcInfo.curFeel
	local totalTime = 0

	local switchType = {
		--准备点菜
		[NPCFeelType.Prepare]					= function()
			-- print("prepare")
			totalTime = math.random(1, 3)
			npcInfo.curFeel = NPCFeelType.Normal
		end,
		--点菜完毕，进入普通等待
		[NPCFeelType.Normal]					= function()
			-- print("Normal")
			totalTime = math.random(1, 3)
			npcInfo.curFeel = NPCFeelType.Anger
		end,
		--普通等待完毕，进入愤怒状态
		[NPCFeelType.Anger]						= function()
			-- print("Anger")
			totalTime = math.random(1, 3)
			npcInfo.curFeel = NPCFeelType.Cancel
		end,
		--不理客人,客人要走啦
		[NPCFeelType.Cancel] 					= function()
			-- print("Cancel")
			totalTime = 0.8 --预留播放动画时间

			npcInfo.curFeel = NPCFeelType.Invalid
			if isWaitSeat then
				--外卖座位
				npcInfo.curState = NPCStateType.LeaveWaitSeat

			else
				--普通座位
				npcInfo.curState = NPCStateType.LeaveSeat
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

	return totalTime
end

--支付状态下状态转换
function ManageModel:npcFeelOnPay(npcInfo, isWaitSeat)
	local feelType = npcInfo.curFeel
	local totalTime = 0

	local switchType = {
		--吃完饭，普通等待埋单
		[NPCFeelType.Normal]					= function()
			totalTime = math.random(1, 3)
			npcInfo.curFeel = NPCFeelType.Anger
		end,
		--普通等待完毕，进入愤怒状态
		[NPCFeelType.Anger]						= function()
			totalTime = math.random(1, 3)
			npcInfo.curFeel = NPCFeelType.Cancel
		end,
		--不理客人,客人要走啦
		[NPCFeelType.Cancel] 					= function()
			totalTime = 0.8 --预留播放动画时间

			npcInfo.curFeel = NPCFeelType.Invalid
			if isWaitSeat then
				--外卖座位
				npcInfo.curState = NPCStateType.LeaveWaitSeat

			else
				--普通座位
				npcInfo.curState = NPCStateType.LeaveSeat
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

function ManageModel:playerQueue(playerInfo)
	--处理当前位置的数据
	local state = playerInfo.curState
	local elfId = playerInfo.elfId

	local switchState = {
		[PlayerStateType.Idle]	 		= function()

		end,
		--2
		[PlayerStateType.Seat]	 		= function()
			print("at seat")
		end,
		--3
		[PlayerStateType.WaitSeat]		= function()
			print("at wait seat")
		end,
		--4
		[PlayerStateType.Product]		= function()
			print("at product")
		end,
	} --switch end

	local fSwitch = switchState[state] --switch 方法

	--存在switch（必然存在）
	if fSwitch then
		local result = fSwitch() --执行function
	else
		error("error state") --没有枚举
		return
	end

	--弹出最上面的数据
	local queueData = playerInfo:pop()

	if queueData then
		local isDelete = queueData.isDelete
		--是否已经取消，若取消则执行下一个队列
		if isDelete then
			playerInfo.curState = PlayerStateType.Idle --空闲状态
			self:playerQueue(playerInfo)
			return
		end

		--当前数据, 执行逻辑
		local mapId = queueData.mapId

		playerInfo.curState = queueData.state --保存状态

		local totalTime = self._delegate:movePlayer(elfId, mapId)

		self._timer:addTimerListener(elfId, totalTime) --加入时间控制

	else --不存在
		playerInfo.curState = PlayerStateType.Idle --空闲状态
	end
end


--[[---------------------
	---Public method-----
	----V->C->M----------]]
--点击座位事件
function ManageModel:onSeatBtn(mapId)
	-- print("on seat btn:"..mapId)
	--这里应该按照地图对应的座位/位置发生的事件派发给对应的player，然后等待回调

	--填队列结构
	local serveId = self._seatToServeDic[mapId]

	local queueData = {}
	queueData.mapId = serveId
	queueData.state = PlayerStateType.Seat

	local testPlayerId = 1

	local playerInfo = self._playerInfoMap[testPlayerId]

	local queueId = playerInfo:push(queueData) --动作标志

	if playerInfo.curState == PlayerStateType.Idle then
		--当前队列为空，直接执行命令
		self:playerQueue(playerInfo)
	end
end

--点击外卖座位事件
function ManageModel:onWaitSeatBtn(mapId)
	-- print("on wait seat btn:"..mapId)

	--填队列结构
	local serveId = self._seatToServeDic[mapId]

	local queueData = {}
	queueData.mapId = serveId
	queueData.state = PlayerStateType.WaitSeat

	local testPlayerId = 1

	local playerInfo = self._playerInfoMap[testPlayerId]

	local queueId = playerInfo:push(queueData)

	if playerInfo.curState == PlayerStateType.Idle then
		--当前队列为空，直接执行命令
		self:playerQueue(playerInfo)
	end
end

--点击产品事件
function ManageModel:onProductBtn(elfId)
	-- print("on product btn:"..elfId)

	local isFull = self._trayInfo:isFull()

	if isFull then
		print("product full")
		return
	end


	--填队列结构
	local productInfo = self._productInfoMap[elfId]
	local mapId = productInfo.mapId

	local serveId = self._seatToServeDic[mapId]

	local queueData = {}
	queueData.mapId = serveId
	queueData.state = PlayerStateType.Product
	queueData.elfId = elfId

	local testPlayerId = 1

	local playerInfo = self._playerInfoMap[testPlayerId]

	local queueId = playerInfo:push(queueData)

	local productIndex, productType = self._trayInfo:addProduct(elfId, queueId)

	self._delegate:addProductAtIndex(productIndex, productType)

	if playerInfo.curState == PlayerStateType.Idle then
		--当前状态为空闲，直接执行命令
		self:playerQueue(playerInfo)
	end
end

function ManageModel:onTrayProductBtn(index)

	local queueId = self._trayInfo:removeProduct(index)

	print(queueId)

	if queueId then
		self._delegate:removeProductAtIndex(index)
	end
	
end

--[[-------------------
	---Timer Delegate-----
	---------------------]]
function ManageModel:TD_onTimOver(listenerId)
	if listenerId >= self._npcIdOffset then
	--npcId回调
		local npcInfo = self._npcInfoMap[listenerId]
		if npcInfo then --回调
			--print("id:"..npcInfo.elfId)
			self:npcState(npcInfo)

			return
		end

	elseif listenerId >= self._productIdOffset then
	--产品id回调
		self:onCoolDown(listenerId)
	else

	--玩家id回调
		local playerInfo = self._playerInfoMap[listenerId]

		if playerInfo then
			--处理队列
			self:playerQueue(playerInfo)
		end

	end	
end