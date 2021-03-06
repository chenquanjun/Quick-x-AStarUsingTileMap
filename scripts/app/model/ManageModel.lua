--此处继承CCNode,因为需要维持这个表，但是用object的话需要retian/release
ManageModel = class("ManageModel", function()
    local node = display.newNode()
    node:setNodeEventEnabled(true)
    return node
end)	

--[[-------------------
	---Init Value-----
	---------------------]]
--index
ManageModel.__index = ManageModel
--private
ManageModel._seatToServeDic		= nil --座位id与服务id的对应表

---------info map---------
ManageModel._npcInfoMap  		= nil --npc信息（包含id，状态）
ManageModel._playerInfoMap  	= nil --玩家信息
ManageModel._productInfoMap     = nil

-------------------------
ManageModel._trayInfo           = nil --面板信息

ManageModel._lightMap           = nil --闪光信息

-------------------------
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
	self._lightMap          = {}
	local trayNum = GlobalValue.TrayNum.value
	self._trayInfo = TrayInfo:create(trayNum)

end

function ManageModel:setSeatToServeDic(seatToServeDic)
	self._seatToServeDic = seatToServeDic
end

function ManageModel:onEnter()
	print("model onEnter")

	--初始化产品
	self:initProduct()

	--初始化普通座位，外卖座位闪光
	local seatVec = G_seatControl:getMapIdVecOfType(kMapDataSeat)
	for i,v in ipairs(seatVec) do
		self._lightMap[v] = 0
	end
	local waitSeatVec = G_seatControl:getMapIdVecOfType(kMapDataWaitSeat)
	for i,v in ipairs(waitSeatVec) do
		self._lightMap[v] = 0
	end

	--test
	local function performWithDelay(node, callback, delay)
	    local delay = CCDelayTime:create(delay)
	    local callfunc = CCCallFunc:create(callback)
	    local sequence = CCSequence:createWithTwoActions(delay, callfunc)
	    node:runAction(sequence)
	    return sequence
	end

	self:addPlayer()

	local perWaveNum = GlobalValue.PerWaveNum.value
	local perWaveTime = GlobalValue.PerWaveTime.value

	-- print("perWaveNum"..perWaveNum)

	--批量循环增加测试
	-- local function addNPCTest()
	-- 	performWithDelay(self, function() 
	-- 		for i=1, perWaveNum do
	-- 		self:addNPC()
	-- 		end
	-- 		addNPCTest()
	-- 	end, perWaveTime)
	-- end

	-- local function addSimpleNPCTest()
	-- 	performWithDelay(self, function() 
	-- 		for i=101 ,106 do
	-- 			local productList = {
	-- 									{
	-- 										{elfId = i, curState = 0},
	-- 									},
	-- 								}

	-- 			self:addNPC(productList) --单个测试	
	-- 		end
	-- 		addSimpleNPCTest()
	-- 	end, math.random(5, 10))
	-- end

	for i=1, perWaveNum do
		self:addNPC()
	end
	--npc波数控制
	G_timer:addTimerListener(ElfIdList.NPCWave, perWaveTime, self)
	
	-- addNPCTest() --批量测试
	-- addSimpleNPCTest() --批量单个测试

end

function ManageModel:onExit()
	print("Model on release")

	self._seatVector = nil
	self._waitSeatVector = nil
	self._doorVector = nil

	self._seatMap = nil
	self._waitSeatMap = nil
	self._doorMap = nil

	self._npcInfoMap  	= nil
	self._playerInfoMap  = nil
end

--[[-------------------
	---Private method-----
	---------------------]]

function ManageModel:initProduct()
	local productVec = G_seatControl:getMapIdVecOfType(kMapDataProduct)
	-- self._mapDataDic[kMapDataProduct]

	for i,mapId in ipairs(productVec) do
		if i > GlobalValue.ProductNum.value then
			break
		end

		local elfId = ElfIdList.ProductOffset + i

		local name = "id:"..(elfId - 100)
		local productType = 1

		local duration = GlobalValue.ProductCD.value / 1000--math.random(0.5, 0.5)

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

		G_modelDelegate:addProduct(data)

		--选择闪光对应id
		self._lightMap[mapId] = 0 

		--定时器 test
		G_modelDelegate:coolDownProduct(elfId, duration)

		G_timer:addTimerListener(elfId, duration, self)
	end

end

function ManageModel:addPlayer()
	do --init 保存到字典
		local elfId = ElfIdList.Player     		
		local mapId = G_seatControl:getMapIdOfType(kMapDataCook)
	
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
		G_modelDelegate:addPlayer(data)
	end

	--废弃
	do --init 保存到字典
		local elfId = 2
		local mapId = G_seatControl:getMapIdOfType(kMapDataCashier)
		-- print("mapId"..mapId)

		local playerInfo = PlayerInfo:create()
		playerInfo.mapId = mapId
		playerInfo.elfId = elfId

		self._playerInfoMap[elfId] = playerInfo
		
		--通知view添加玩家
		local data = {}
		data.elfId = elfId
		data.modelId = 2
		data.mapId = mapId
		G_modelDelegate:addPlayer(data)
	end
end

--增加NPC

function ManageModel:addNPC(productList)

	local elfId = ElfIdList.NpcOffset + self._npcTestFlag

	do --init 保存到字典
		local startMapId = G_seatControl:getMapIdOfType(kMapDataStart)
		local modelId = math.random(3, 4)

		local npcInfo = NPCInfo:create()
		npcInfo.curState = NPCStateType.Start --开始位置
		npcInfo.curFeel = NPCFeelType.Invalid
		npcInfo.mapId = startMapId
		npcInfo.elfId = elfId
		npcInfo.modelId = modelId


		if productList == nil then
			do --产品 TEST
				--npc需求结构
				--产品表 (table)
						-- 产品数组 (table)
								-- 产品 (table)
										-- 产品id，产品状态 (int)

				-- local productList = {
				-- 						{
				-- 							{elfId = 106, curState = 0},
				-- 							{elfId = 105, curState = 0},
				-- 							{elfId = 101, curState = 0},
				-- 							{elfId = 106, curState = 0}
				-- 						},
				-- 					}

				productList = {}

				local totalNum = 6

				local productListNum = math.random(1, 1) --1到2个列表

				for i = 1, productListNum do
					local productVec = {}
					productList[i] = productVec
					local productNum = math.random(1, 3) --每个列表里面1到3个物品

					for j = 1, productNum do
		
						local randomIndex = math.random(1, totalNum)
						-- print(randomIndex)
						local flag = 1

						for index, productInfo in pairs(self._productInfoMap) do
							-- print("test")
							if randomIndex == flag then
								local product = {}
								product.elfId = productInfo.elfId
								product.curState = 0 --未满足
								productVec[j] = product
								-- print(productElfId)
								break
							end

							flag = flag + 1
						end

						
					end
				end



			end
		end

		-- dump(productList, "test")

		npcInfo:setProductList(productList)



		self._npcInfoMap[elfId] = npcInfo

		--进入状态控制
		self:npcStateControl(elfId)		 
		
		--通知view添加npc
		local data = {}
		data.elfId = elfId
		data.modelId = modelId
		data.mapId = startMapId
		G_modelDelegate:addNPC(data)

		do--统计信息

			local productVec = {}

			local data = {}
			data.elfId = elfId
			data.productVec = productVec
			

			local index = 1

			for i, productTable in ipairs(productList) do
				for j,product in ipairs(productTable) do
					local productId = product.elfId
					productVec[index] = productId
					index = index + 1
				end
			end

			G_stats:addNPC(data)
		end

		
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
		local isEnterPay = returnValue.isEnterPay --转交给支付模块控制
		local totalTime = returnValue.totalTime --回调时间
		local mapId = returnValue.mapId --移动目标id
		local productVec = returnValue.productVec --产品数组
		local testStateStr = returnValue.testStateStr

		if isEnterPay then --新模块
			--转交给支付控制模块
			G_payControl:addPayNpc(npcInfo)

			--model不再持有此npc信息，释放
			self._npcInfoMap[elfId] = nil --释放

			return
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

--玩家去到座位时候调用此方法（仅当座位上存在npc）
function ManageModel:playerOnSeat(npcInfo)
	if npcInfo == nil then
		return --防止离开model进入支付等待列表的npc
	end

	local elfId = npcInfo.elfId

	if npcInfo:isRequest() == false then
		return --非请求状态，返回
	end

	--取出所有已经完成的product信息
	--然后每个和npc的需求比较
	local finishProductVec = self._trayInfo:getFinishProduct()

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

	--满足需求
	if isProductNeed then
		--删除操作 indexVec 按从小到大的顺序放置，删除时从大到小删除

		table.sort(requestIndexVec) --将请求列表的序号排序（因为托盘的物品不一定按照npc的需求来排序，所以此处需要排序）
		--model删除 
		npcInfo:removeFinishProduct(requestIndexVec)
		self._trayInfo:removeProductWithVec(trayIndexVec)  --删除model中托盘物品

		--view删除
		G_modelDelegate:removeRequest(elfId, requestIndexVec) --删除view中npc的需求
		G_modelDelegate:removeProductWithVec(trayIndexVec)--删除view中托盘的物品

		-- local deleteNum = #requestIndexVec

		local addNum = self:refreshTrayProduct() --补充托盘

		-- assert(#requestIndexVec == addNum, "error num")

	else --没有一个产品满足npc（赶走npc）
		print("get out:"..elfId)
		--前面已经判断npc是否在请求状态，此处不用判断（实际上方法内部有assert判断）
		npcInfo:setSeatStateGetOut()

		--进入下一个状态
		self:npcStateControl(elfId)
		return
	end --if end

	local isAllProductOK = npcInfo:isAllProductOK()

	if isAllProductOK then --所有需求满足，改变npc状态
		
		--删除回调
		G_timer:removeTimerListener(elfId)

		--改变npc状态
		npcInfo:setSeatStateEating()

		--进入下一个状态
		self:npcStateControl(elfId)
	end

end

--补充托盘
function ManageModel:refreshTrayProduct()

	local emptyNum = self._trayInfo:getEmptyNum()

	if emptyNum > 0 then
		local testPlayerId = 1

		local playerInfo = self._playerInfoMap[testPlayerId] --npcinfo

		--删除多少个就加入多少个（如果队列后面有移动到产品的命令）
		local playerQueNum = playerInfo:getCurQueueNum()
		local playerQueIndex = playerInfo:getCurQueueIndex()

		local addNum = 0

		for i = 1, playerQueNum do
			local index = playerQueIndex + i - 1
			local queueData = playerInfo:atQueue(index)
			--产品信息
			if queueData.state == PlayerStateType.Product and queueData.isAddTray == false then
				--找到了
				queueData.isAddTray = true --标记

				local productId = queueData.elfId
				local queueId = index
				--model保存product信息
				local productIndex, productType = self._trayInfo:addProduct(productId, queueId)
				--view显示product增加
				G_modelDelegate:addProductAtIndex(productIndex, productType)

				addNum = addNum + 1

				if addNum == emptyNum then
					break --增加的和删除的相同了
				end
			end
		end
	end

	return emptyNum
	
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
		    -- print("at seat")
			local preQueueData = playerInfo:preQueue() --取出上一个队列的数据
			local mapId = preQueueData.originMapId --取出座位id
			local elfId = G_seatControl:getSeatInfo(kMapDataSeat, mapId) --取出占座位的npc



			if preQueueData.IsUnselectLight then
				--todo
			else
				self:addSelectLight(mapId, -1)--闪光次数减1
				preQueueData.IsUnselectLight = true
			end

			-- self:addSelectLight(mapId, -1)--闪光次数减1

			if elfId == ElfIdList.Rubbish then --清理垃圾
				G_seatControl:leaveSeat(kMapDataSeat, mapId, elfId)

			elseif elfId ~= G_seatControl.SEAT_EMPTY  then --座位不为空！
				local npcInfo = self._npcInfoMap[elfId]
				--处理需求

				self:playerOnSeat(npcInfo)

			end-- if end
		
		end,
		--3
		[PlayerStateType.WaitSeat]		= function()
			-- print("at wait seat")
			local preQueueData = playerInfo:preQueue() --取出上一个队列的数据
			local mapId = preQueueData.originMapId --取出座位id

			if preQueueData.IsUnselectLight then
				--todo
			else
				self:addSelectLight(mapId, -1)--闪光次数减1
				preQueueData.IsUnselectLight = true
			end

			-- self:addSelectLight(mapId, -1)--闪光次数减1

			local elfId = G_seatControl:getSeatInfo(kMapDataWaitSeat, mapId) --取出占座位的npc

			if elfId == ElfIdList.Rubbish then --清理垃圾
				G_seatControl:leaveSeat(kMapDataWaitSeat, mapId, elfId)

			elseif elfId ~= G_seatControl.SEAT_EMPTY  then --座位不为空！
				local npcInfo = self._npcInfoMap[elfId]
				--处理需求
				self:playerOnSeat(npcInfo)

			end-- if end	
		end,
		--4
		[PlayerStateType.Product]		= function()
			-- print("at product")
			local preQueueData = playerInfo:preQueue() --取出上一个队列的数据
			assert(preQueueData ~= nil, "error,queue should not nil")

			local mapId = preQueueData.originMapId

			-- self:addSelectLight(mapId, -1)--闪光次数减1

			if preQueueData.IsUnselectLight then
				--todo
			else
				self:addSelectLight(mapId, -1)--闪光次数减1
				preQueueData.IsUnselectLight = true
			end

			if preQueueData.isDelete then --先判断是否已经删除
				-- print("delete")
				return
			end

			if not preQueueData.isAddTray then
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

				G_modelDelegate:setProductFinishAtIndex(trayIndex)
				--物品触发冷却
				local duration = productInfo.duration

				G_modelDelegate:coolDownProduct(productElfId, duration)

				G_timer:addTimerListener(productElfId, duration, self)
				--玩家进入下个状态



			else --不满足需求
				--玩家保持等待状态
				playerInfo.curState = PlayerStateType.WaitProduct
				playerInfo.waitProductId = productElfId --等待id

				--等待产品cooldown回调

				-- self:addSelectLight(mapId, 1)--闪光次数减1

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

	--稍微延迟执行

	local function performWithDelay(node, callback, delay)
	    local delay = CCDelayTime:create(delay)
	    local callfunc = CCCallFunc:create(callback)
	    local sequence = CCSequence:createWithTwoActions(delay, callfunc)

	    -- if node:getActionByTag(1024) then
	    	-- print("stop multi call")
	    -- end
	    node:stopActionByTag(1024) --此处需要stop，防止多次调用
	    sequence:setTag(1024)

	    -- if node:getNumberOfRunningActions() > 1 then
	    	--  print(node:stopActionByTag(1024)) 
	    	-- assert(node:stopActionByTag(1024) ~= nil, "error multi")
	    -- end

	    node:runAction(sequence)
	    return sequence
	end

	--稍微停顿
	performWithDelay(self, function ()
		--弹出最上面的数据
		local queueData = playerInfo:popQueue()

		if queueData then
			local isDelete = queueData.isDelete
			-- --是否已经取消，若取消则执行下一个队列

			if isDelete then
				-- if playerInfo.curState == PlayerStateType.Product then
					-- self:addSelectLight(queueData.originMapId, -1)--闪光次数减1
				-- end

				if queueData.IsUnselectLight then
				--todo
				else
					self:addSelectLight(mapId, -1)--闪光次数减1
					queueData.IsUnselectLight = true
				end

				playerInfo.curState = PlayerStateType.Idle --空闲状态
				self:playerQueue(playerInfo)
				return
			end
			--当前数据, 执行逻辑
			local mapId = queueData.mapId

			playerInfo.curState = queueData.state --保存状态

			local totalTime = G_modelDelegate:movePlayer(elfId, mapId)

			G_timer:addTimerListener(elfId, totalTime, self) --加入时间控制

		else --不存在
			playerInfo.curState = PlayerStateType.Idle --空闲状态
		end	
	end, 0.2)


end


--[[---------------------
	---Public method-----
	----V->C->M----------]]
--点击座位事件
function ManageModel:onSeatBtn(mapId)
	-- print("on seat btn:"..mapId)
	--这里应该按照地图对应的座位/位置发生的事件派发给对应的player，然后等待回调

	self:addSelectLight(mapId, 1)--闪光次数加1

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

	self:addSelectLight(mapId, 1)--闪光次数加1

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
	--填队列结构
	local productInfo = self._productInfoMap[elfId]
	local mapId = productInfo.mapId

	self:addSelectLight(mapId, 1)--闪光次数加1

	local serveId = self._seatToServeDic[mapId]

	local queueData = {}
	queueData.mapId = serveId
	queueData.originMapId = mapId
	queueData.state = PlayerStateType.Product
	queueData.elfId = elfId

	local testPlayerId = 1

	local playerInfo = self._playerInfoMap[testPlayerId]

	local queueId = playerInfo:pushQueue(queueData)
	-- print("QUEUE:"..queueId)

	local isFull = self._trayInfo:isFull()

	if isFull then
		queueData.isAddTray = false
		-- print("product full")
		--满了只加入到队列里面

	else
		queueData.isAddTray = true
		--model保存product信息
		local productIndex, productType = self._trayInfo:addProduct(elfId, queueId)
		--view显示product增加
		G_modelDelegate:addProductAtIndex(productIndex, productType)
	
	end


	if playerInfo.curState == PlayerStateType.Idle then
		-- print("idle")
		--当前状态为空闲，直接执行命令
		self:playerQueue(playerInfo)
	end
end

--点击托盘食物回调
function ManageModel:onTrayProductBtn(index)
	--逻辑上删除面板index的值，若产品是未完成的则返回加入产品时候的队列值
	--该队列值是playerInfo动作队列中加入产品动作时候返回的	

	local productId = self._trayInfo:productIdAtIndex(index)

	local queueId = self._trayInfo:removeProduct(index)

	if queueId then --queueId存在说明物品未完成状态

		local testPlayerId = 1

		local playerInfo = self._playerInfoMap[testPlayerId]

		--删除闪光
		
		local productInfo = self._productInfoMap[productId]
		local mapId = productInfo.mapId
		

		local curQueueData = playerInfo:atQueue(queueId)

		if curQueueData.IsUnselectLight then
			--todo
		else
			self:addSelectLight(mapId, -1)--闪光次数减1
			curQueueData.IsUnselectLight = true
		end

		playerInfo:removeQueue(queueId) --删除队列值

		if index == 1 then --此条件仅在等待物品cd且取消的是第一个时候触发
			-- print("remove cd queue")
			--删除第一个队列的值
			--判断玩家是否在等待该产品
			if playerInfo.curState == PlayerStateType.WaitProduct then

				-- local productInfo = self._productInfoMap[playerInfo.waitProductId]
				-- local mapId = productInfo.mapId

				-- self:addSelectLight(mapId, -1)--闪光次数减1

				--切换状态，执行下一条命令
				playerInfo.curState = PlayerStateType.Idle --设置空闲状态
				playerInfo.waitProductId = -1
				self:playerQueue(playerInfo)


			end

		end
	else --物品处于完成阶段

	end

	--删除面板上的值
	G_modelDelegate:removeProductAtIndex(index) 

	self:refreshTrayProduct() --补充托盘
	
end


function ManageModel:addSelectLight(mapId, num)
	local originNum = self._lightMap[mapId]
	local newNum = originNum + num
	print("add"..mapId.." "..originNum.." "..newNum)

	if originNum == 0 and newNum == 1 then
		G_modelDelegate:selectLight(mapId, true)
		-- print("light:"..mapId.."light")		

	elseif originNum == 1 and newNum == 0 then
		G_modelDelegate:selectLight(mapId, false)
		-- print("light:"..mapId.."dark")	
	end

	self._lightMap[mapId] = newNum

	-- dump(self._lightMap, "light")

end

--[[-------------------
	---timer call-----
	---------------------]]
function ManageModel:TD_onTimeOver(elfId)
	if elfId >= ElfIdList.NpcOffset then
		self:npcStateControl(elfId)

	elseif elfId >= ElfIdList.ProductOffset then
		self:onCoolDown(elfId) --产品冷却回调

	elseif elfId == ElfIdList.NPCWave then --npc波数控制

		local perWaveNum = GlobalValue.PerWaveNum.value
		local perWaveTime = GlobalValue.PerWaveTime.value


		for i=1, perWaveNum do
		self:addNPC()
		end

		--npc波数控制
		G_timer:addTimerListener(ElfIdList.NPCWave, perWaveTime, self)

	else
		local testPlayerId = 1

		local playerInfo = self._playerInfoMap[testPlayerId]

		if playerInfo then
			self:playerQueue(playerInfo)
		end
	end
end

--[[-------------------
	---dump  data-----
	---------------------]]
function ManageModel:dumpAllData()
	-- local function serialize(obj)
	--       local lua = ""
	--       local t = type(obj)
	--       if t == "number" then
	--           lua = lua .. obj
	--       elseif t == "boolean" then
	--           lua = lua .. tostring(obj)
	--       elseif t == "string" then
	--           lua = lua .. string.format("%q", obj)
	--       elseif t == "table" then
	--           lua = lua .. "{\n"
	--           for k, v in pairs(obj) do
	--               lua = lua .. "[" .. serialize(k) .. "]=" .. serialize(v) .. ",\n"
	--           end
	--           local metatable = getmetatable(obj)
	--           if metatable ~= nil and type(metatable.__index) == "table" then
	--               for k, v in pairs(metatable.__index) do
	--                   lua = lua .. "[" .. serialize(k) .. "]=" .. serialize(v) .. ",\n"
	--               end
	--           end
	--           lua = lua .. "}"
	--       elseif t == "nil" then
	--           return nil
	--       elseif t == "function" then
	--       	  lua = lua .. "function"--跳过function
	--       else
	--           error("can not serialize a " .. t .. " type.")
	--       end
	--       return lua
	--   end

	dump(self._npcInfoMap , "npcInfo")
	dump(self._playerInfoMap , "playernfo")
	dump(self._productInfoMap , "productInfo")
	-- dump(self._trayInfo , "trayInfo")

	-- print(serialize(self._npcInfoMap)) 
end


