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
	--初始化产品
	self:initProduct()

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
	-- addNPCTest() --批量测试
	self:addNPC() --单个测试
	-- self:addNPC() --单个测试

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

	-- self._oneMapIdMap    = nil

	self._npcInfoMap  	= nil
	self._playerInfoMap  = nil

end

--[[-------------------
	---Private method-----
	---------------------]]

function ManageModel:initProduct()
	local productVec = G_mapGeneral:getMapIdVecOfType(kMapDataProduct)
	-- self._mapDataDic[kMapDataProduct]

	for i,mapId in ipairs(productVec) do
		local elfId = self._productIdOffset + i

		local name = "id:"..elfId
		local productType = 1

		local duration = math.random(1, 3)

		local productInfo = {}
			productInfo.duration = duration
			productInfo.type = productType
			productInfo.name = name
			productInfo.mapId = mapId
			productInfo.num = 0
			productInfo.elfId = elfId

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
		local mapId = G_mapGeneral:getMapIdOfType(kMapDataCook)
	
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
		local mapId = G_mapGeneral:getMapIdOfType(kMapDataCashier)
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
		local startMapId = G_mapGeneral:getMapIdOfType(kMapDataStart)
		local modelId = math.random(3, 4)

		local npcInfo = NPCInfo:create()
		npcInfo.curState = NPCStateType.Start --开始位置
		npcInfo.curFeel = NPCFeelType.Invalid
		npcInfo.mapId = startMapId
		npcInfo.elfId = elfId
		npcInfo.modelId = modelId



		do --产品 TEST
			--npc需求结构
			--产品表 (table)
					-- 产品数组 (table)
							-- 产品 (table)
									-- 产品id，产品状态 (int)

			local productList = {
									{
										{elfId = 102, curState = 0},
										{elfId = 102, curState = 0},
										{elfId = 104, curState = 0},
										-- {elfId = 101, curState = 0}
									},
								}

			-- local productList = {}

			-- local totalNum = 6

			-- local productListNum = math.random(1, 1) --1到2个列表

			-- for i = 1, productListNum do
			-- 	local productVec = {}
			-- 	productList[i] = productVec
			-- 	local productNum = math.random(3, 4) --每个列表里面1到3个物品

			-- 	for j = 1, productNum do
	
			-- 		local randomIndex = math.random(1, totalNum)
			-- 		-- print(randomIndex)
			-- 		local flag = 1

			-- 		for index, productInfo in pairs(self._productInfoMap) do
			-- 			-- print("test")
			-- 			if randomIndex == flag then
			-- 				local product = {}
			-- 				product.elfId = productInfo.elfId
			-- 				product.curState = 0 --未满足
			-- 				productVec[j] = product
			-- 				-- print(productElfId)
			-- 				break
			-- 			end

			-- 			flag = flag + 1
			-- 		end

					
			-- 	end
			-- end

			-- dump(productList, "test")

			npcInfo:setProductList(productList)

		end

		self._npcInfoMap[elfId] = npcInfo

		--进入状态控制
		self:npcStateControl(elfId)		 
		
		--通知view添加npc
		local data = {}
		data.elfId = elfId
		data.modelId = modelId
		data.mapId = startMapId
		self._delegate:addNPC(data)
	end
	self._npcTestFlag = self._npcTestFlag + 1



end

--产品冷却完毕
function ManageModel:onCoolDown(elfId)
	local productInfo = self._productInfoMap[elfId]
	assert(productInfo.num == 0, "error") --当前设计最多只有1个，所以此值必为0
	productInfo.num = 1 --增加

	local testPlayerId = 1

	local playerInfo = self._playerInfoMap[testPlayerId]

	if playerInfo.curState == PlayerStateType.WaitProduct and playerInfo.waitProductId == elfId then
		--等待的物品终于完成了
		playerInfo.curState = PlayerStateType.Product --设置原来的数值
		playerInfo.waitProductId = -1
		self:playerQueue(playerInfo)
	end
end

--npc主状态转换
function ManageModel:npcStateControl(elfId)

	local npcInfo = self._npcInfoMap[elfId]

	if npcInfo then
		local returnValue = npcInfo:npcState() --执行状态方法

		local isRelease = returnValue.isRelease --是否已经释放
		local totalTime = returnValue.totalTime --回调时间
		local mapId = returnValue.mapId --移动目标id
		local productVec = returnValue.productVec --产品数组
		local testStateStr = returnValue.testStateStr

		if isRelease then
			--释放
			self._npcInfoMap[elfId] = nil --释放
			self._delegate:removeNPC(elfId)
		else
			if mapId ~= -1 then
				--mapId存在说明需要自动寻路，totalTime由view控制
				totalTime = self._delegate:moveNPC(elfId, mapId) 
				npcInfo.mapId = mapId --保存目标位置
			end
			self._timer:addTimerListener(elfId, totalTime) --加入时间控制

			if productVec then
				self._delegate:addRequest(elfId, productVec)
			end

			if testStateStr then
				self._delegate:setStateStr(elfId, testStateStr)
			end
		end


	else
		error("error call")
	end
end


--玩家队列分两部分执行，动作与移动
--switch执行的是当前动作
--popQueue是下一个动作的移动部分
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
			local preQueueData = playerInfo:preQueue() --取出上一个队列的数据
			local mapId = preQueueData.originMapId --取出座位id
			local elfId = G_mapGeneral:getSeatInfo(kMapDataSeat, mapId) --取出占座位的npc

			if elfId ~= G_mapGeneral.SEAT_EMPTY  then --座位不为空！
				local npcInfo = self._npcInfoMap[elfId]

				if npcInfo:isRequest() == false then
					return --非请求状态，返回
				end

				--还有满足所有需求后转变npc的状态！！！


				--取出所有已经完成的product信息
				--然后每个和npc的需求比较
				local finishProductVec = self._trayInfo:getFinishProduct()

				-- dump(finishProductVec, "finish")

				local requestIndexVec = {} --需求index vec
				local trayIndexVec = {}    --托盘index vec

				local isProductNeed = false

				for i,v in ipairs(finishProductVec) do
					local productId = v.elfId
					local trayIndex = v.index
					local requestIndex = npcInfo:isNeedProduct(productId)

					if requestIndex > -1 then
						requestIndexVec[#requestIndexVec + 1] = requestIndex
						trayIndexVec[#trayIndexVec + 1] = trayIndex

						isProductNeed = true
					end
				end

				-- dump(requestIndexVec, "req index")
				-- dump(trayIndexVec, "tray index")

				if isProductNeed then
					--删除操作 indexVec 按从小到大的顺序放置，删除时从大到小删除
					--model删除 
					npcInfo:removeFinishProduct(requestIndexVec)
					self._trayInfo:removeProductWithVec(trayIndexVec)  --删除model中托盘物品

					--view删除
					self._delegate:removeRequest(elfId, requestIndexVec) --删除view中npc的需求
					self._delegate:removeProductWithVec(trayIndexVec)--删除view中托盘的物品

				end --if end

				local isAllProductOK = npcInfo:isAllProductOK()

				if isAllProductOK then --所有需求满足，改变npc状态
					
					--删除回调
					self._timer:removeTimerListener(elfId)

					--改变npc状态
					npcInfo:setStateEating()

					--进入下一个状态
					self:npcStateControl(elfId)
				end

			end-- if end
			

		end,
		--3
		[PlayerStateType.WaitSeat]		= function()
			print("at wait seat")
		end,
		--4
		[PlayerStateType.Product]		= function()
			print("at product")
			local preQueueData = playerInfo:preQueue() --取出上一个队列的数据
			assert(preQueueData ~= nil, "error,queue should not nil")

			if preQueueData.isDelete then --先判断是否已经删除
				print("delete")
				return
			end

			local productElfId = preQueueData.elfId --产品id

			local productInfo = self._productInfoMap[productElfId] --产品信息

			local productNum = productInfo.num --产品数目

			--目前设计productNum是只有一个
			if productNum > 0 then --满足需求
				
				 --产品数减1
				productInfo.num = productNum - 1
				--改变面板信息（把面板对应的产品改成complete状态）
				local trayIndex = self._trayInfo:setProductFinish(productElfId)--返回物品在面板的位置

				self._delegate:setProductFinishAtIndex(trayIndex)
				--物品触发冷却
				local duration = productInfo.duration

				self._delegate:coolDownProduct(productElfId, duration)

				self._timer:addTimerListener(productElfId, duration)
				--玩家进入下个状态

			else --不满足需求
				--玩家保持等待状态
				playerInfo.curState = PlayerStateType.WaitProduct
				playerInfo.waitProductId = productElfId --等待id

				--等待产品cooldown回调

				return true --注意此值是fSwitch()的返回值

			end
		end,

		[PlayerStateType.WaitProduct]		= function()
				--在调用playerQueue前应该把此状态改变
				--例如产品完成的回调，检测到玩家是WaitProduct状态，则改变成Product状态
				--以便代码复用
				error("error")
		end,
	} --switch end

	local fSwitch = switchState[state] --switch 方法

	--存在switch（必然存在）
	if fSwitch then
		local result = fSwitch() --执行function

		if result then
			--有回调 目前是玩家在等待状态下有回调
			return 
		end
	else
		error("error state") --没有枚举
		return
	end

	--弹出最上面的数据
	local queueData = playerInfo:popQueue()

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
	queueData.originMapId = mapId
	queueData.state = PlayerStateType.Seat

	local testPlayerId = 1

	local playerInfo = self._playerInfoMap[testPlayerId]

	local queueId = playerInfo:pushQueue(queueData) --动作标志

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
	queueData.originMapId = mapId
	queueData.state = PlayerStateType.WaitSeat

	local testPlayerId = 1

	local playerInfo = self._playerInfoMap[testPlayerId]

	local queueId = playerInfo:pushQueue(queueData)

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
	queueData.originMapId = mapId
	queueData.state = PlayerStateType.Product
	queueData.elfId = elfId

	local testPlayerId = 1

	local playerInfo = self._playerInfoMap[testPlayerId]

	local queueId = playerInfo:pushQueue(queueData)
	print("QUEUE:"..queueId)

	--model保存product信息
	local productIndex, productType = self._trayInfo:addProduct(elfId, queueId)
	--view显示product增加
	self._delegate:addProductAtIndex(productIndex, productType)

	if playerInfo.curState == PlayerStateType.Idle then
		print("idle")
		--当前状态为空闲，直接执行命令
		self:playerQueue(playerInfo)
	end
end

--点击托盘食物回调
function ManageModel:onTrayProductBtn(index)
	--逻辑上删除面板index的值，若产品是未完成的则返回加入产品时候的队列值
	--该队列值是playerInfo动作队列中加入产品动作时候返回的
	local queueId = self._trayInfo:removeProduct(index)

	if queueId then --queueId存在说明物品未完成状态
		
		local testPlayerId = 1

		local playerInfo = self._playerInfoMap[testPlayerId]

		playerInfo:removeQueue(queueId) --删除队列值

		if index == 1 then --此条件仅在等待物品cd且取消的是第一个时候触发
			-- print("remove cd queue")
			--删除第一个队列的值
			--判断玩家是否在等待该产品
			if playerInfo.curState == PlayerStateType.WaitProduct then
				--切换状态，执行下一条命令
				playerInfo.curState = PlayerStateType.Idle --设置空闲状态
				playerInfo.waitProductId = -1
				self:playerQueue(playerInfo)
			end

		end

		
		

	else --物品处于完成阶段

	end

	--删除面板上的值
	self._delegate:removeProductAtIndex(index) 
	
end

--[[-------------------
	---Timer Delegate-----
	---------------------]]
function ManageModel:TD_onTimOver(listenerId)
	if listenerId >= self._npcIdOffset then --npcId回调
	
		--npc状态控制
		self:npcStateControl(listenerId)

	elseif listenerId >= self._productIdOffset then --产品id回调
	
		self:onCoolDown(listenerId)

	else --玩家id回调

		local playerInfo = self._playerInfoMap[listenerId]

		if playerInfo then
			--处理队列
			self:playerQueue(playerInfo)
		end

	end	
end