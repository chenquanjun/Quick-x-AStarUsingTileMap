require "app/basic/extern"
require "app/basic/NPCInfo"
require "app/timer/TimerControl"
require "app/timer/TimerControlDelegate"

--此处继承CCNode,因为需要维持这个表，但是用object的话需要retian/release
ManageModel = class("ManageModel", function()
	return CCNode:create()
end)			

--[[-------------------
	---Init Value-----
	---------------------]]

ManageModel.__index = ManageModel

local _delegate = nil --model delegate
local _timer = nil
local _timerDelegate = nil

local _seatVector = nil --座位数组，保存座位的mapId
local _waitSeatVector = nil 
local _doorVector = nil

local _seatMap = nil  --座位字典
local _waitSeatMap = nil --等待座位字典
local _doorMap = nil --门口字典

local _startMapId = -1

local _npcInfoMap = nil

local _testNPCIdFlag = 10

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
	_seatMap = {}  --座位字典
	_waitSeatMap = {} --等待座位字典
	_doorMap = {} --门口字典
	_npcInfoMap = {}

end

function ManageModel:setDelegate(delegate)
	_delegate = delegate
end

function ManageModel:setStartMapId(mapId)
	_startMapId = mapId
end

function ManageModel:setMapData(seatVec, waitSeatVec, doorVec)

    --记录哪个mapId是座位，等待座位和门口, 下标从1开始
	_seatVector = seatVec
	_waitSeatVector = waitSeatVec
	_doorVector = doorVec

	--初始化
	for i,v in ipairs(_seatVector) 
	do 
		_seatMap[v] = 0 --0表示空, 其他时候表示顾客的id 
	end  

	for i,v in ipairs(_waitSeatVector) 
	do 
		_waitSeatMap[v] = 0 --0表示空, 其他时候表示顾客的id 
	end  

	for i,v in ipairs(_doorVector) 
	do 
		_doorMap[v] = 0 --0表示空, 其他时候表示顾客的id 
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
		_timer = timerControl

		--定时器delegate 将model加入到refer中，以便delegate能回调model的方法
		local timerDelegate = TimerControlDelegate:setRefer(self)
		_timerDelegate = timerDelegate

		timerControl:setDelegate(timerDelegate)

		_delegate:setTimerInterval(timerControl:getTimerInterval())
	end

	--test
	-- for i=1,5 do
		self:addNPC()
	-- end
	
	-- self:moveNPC()

	
	-- _timer:removeTimerListener(1)
	-- _timer:addTimerListener(1, totalTime)
	-- _timer:addTimerListener(1, 0)
	-- _timer:addTimerListener(2, 2.1)
	-- _timer:addTimerListener(3, 2.2)
	-- _timer:addTimerListener(4, 5)
	-- _timer:startTimer()
	-- _timer:setListenerSpeed(1, 1)
	_timer:startTimer()


end

function ManageModel:onRelease()
	print("Model on release")
	_timer:removeDelegate() --timer对delegate的引用
	_timerDelegate:removeRefer() --delegate对model的引用

	_timerDelegate = nil

	_timer = nil

	_delegate = nil

	_seatVector = nil
	_waitSeatVector = nil
	_doorVector = nil

	_seatMap = nil
	_waitSeatMap = nil
	_doorMap = nil
end

--[[-------------------
	---Private method-----
	---------------------]]

--增加NPC
function ManageModel:addNPC()
	
	local npcId = _testNPCIdFlag

	do --init 保存到字典
		local npcInfo = NPCInfo:create(npcId)
		npcInfo.curState = NPCStateType.Start --开始位置
		npcInfo.curFeel = NPCFeelType.Invalid
		npcInfo.mapId = _startMapId
		_npcInfoMap[npcId] = npcInfo

		--进入状态控制
		self:npcState(npcInfo)		 

	end

	do --通知view添加npc
		local data = {}
		data.npcId = npcId
		data.npcType = 1
		_delegate:addNPC(data)
	end

	_testNPCIdFlag = npcId + 1


end

function ManageModel:npcState(npcInfo)
	local npcId = npcInfo.npcId --npcId
	local totalTime = -1 --回调参数
	local mapId = -1 --npc的目标mapId
	--switch....
	local switchState = {
		--释放
		[NPCStateType.Release]					= function()
			print("Release")
			_npcInfoMap[npcId] = nil --释放

			return true --返回nil
		end,
		--开始位置
		[NPCStateType.Start]					= function()
			print("start")
			totalTime = math.random(1, 5)
			npcInfo.curState = NPCStateType.GoToDoor --状态切换

		end,
		--开始到门口
		[NPCStateType.GoToDoor]					= function()
			print("GoToDoor")
			local isFindSeat = false

			for i,v in ipairs(_doorVector) do
				
				local seatState = _doorMap[v]

				if seatState == 0 then
					isFindSeat = true --找到空位
					mapId = v --保存id
					_doorMap[v] = npcId --霸占位置
					npcInfo.curState = NPCStateType.Door --状态切换
					break
				end
			end --for

			--找不到门口空位 
			if not isFindSeat then
				--在开始位置找不到空位怎么处理，继续停留在开始位置等待随机时间？
				npcInfo.curState = NPCStateType.Start
			end

		end,
		--门口位置
		[NPCStateType.Door] 					= function()
			print("Door")
			--在门口稍微停留再看看有没位置
			totalTime = math.random(0.2, 0.5)
			npcInfo.curState = NPCStateType.FindSeat

		end,
		--离开门口
		[NPCStateType.LeaveDoor] 				= function()
			print("LeaveDoor")
			mapId = _startMapId
			npcInfo.curState = NPCStateType.Start --开始位置

			--出现此错误因为npc的mapId没有正确设置
			assert(_doorMap[npcInfo.mapId] == npcId, "error mapid, not in door") 
			_doorMap[npcInfo.mapId] = 0 --清空位置

		end,
		--寻找座位
		[NPCStateType.FindSeat] 				= function()
			print("FindSeat")
			local isFindSeat = false

			for i,v in ipairs(_seatVector) do
				local seatState = _seatMap[v]

				if seatState == 0 then
					isFindSeat = true --找到空位
					mapId = v --保存id

					assert(_doorMap[npcInfo.mapId] == npcId, "error mapid, not in door") 
					assert(_seatMap[v] == 0, "error mapid, not in seat") 

					_doorMap[npcInfo.mapId] = 0 --清空门口位置

					_seatMap[v] = npcId --霸占座位位置
					--进入座位请求状态，feel状态进入prepare
					npcInfo.curState = NPCStateType.SeatRequest --状态切换
					npcInfo.curFeel = NPCFeelType.Prepare --进入子状态
					break
				end
			end

			if not isFindSeat then
				--寻找外卖座位
				npcInfo.curState = NPCStateType.FindWaitSeat
			end

		end,
		--在座位请求
		[NPCStateType.SeatRequest] 				= function()
			print("SeatRequest")
			--进入feel状态切换
			--test,此处应该是进入另外一个方法 未完成
			totalTime = math.random(2, 4)
			npcInfo.curState = NPCStateType.SeatEating
		end,
		--在座位吃东西
		[NPCStateType.SeatEating] 				= function()
			print("SeatEating")
			totalTime = math.random(1, 2)
			--进入支付状态，feel状态进入normal（由于支付是马上执行？）
			npcInfo.curState = NPCStateType.SeatPay
			npcInfo.curFeel = NPCFeelType.Normal
		end,
		--在座位支付
		[NPCStateType.SeatPay] 					= function()
			print("SeatPay")
			--进入feel状态切换
			--test 未完成
			totalTime = math.random(2, 4)
			npcInfo.curState = NPCStateType.LeaveSeat
		end,
		--支付成功
		[NPCStateType.SeatPaySuccess]			= function()
			print("SeatPaySuccess")
			totalTime = 1.0
			npcInfo.curState = NPCStateType.LeaveSeat
			npcInfo.curFeel = NPCFeelType.Invalid
		end,
		--离开座位
		[NPCStateType.LeaveSeat] 				= function()
			print("LeaveSeat")
			--离开座位之后回到开始位置然后kill掉?
			assert(_seatMap[npcInfo.mapId] == npcId, "error")
			_seatMap[npcInfo.mapId] = 0 --设置为空
			mapId = _startMapId

			npcInfo.curState = NPCStateType.Release --进入销毁状态
		end,
		--寻找外卖座位
		[NPCStateType.FindWaitSeat] 			= function()
		    print("FindWaitSeat")
			local isFindSeat = false

			for i,v in ipairs(_waitSeatVector) do
				local seatState = _waitSeatMap[v]

				if seatState == 0 then
					isFindSeat = true --找到空位
					mapId = v --保存id

					assert(_doorMap[npcInfo.mapId] == npcId, "error mapid, not in door") 
					assert(_waitSeatMap[v] == 0, "error mapid, not in wait seat") 

					_doorMap[npcInfo.mapId] = 0 --清空门口位置

					_waitSeatMap[v] = npcId --霸占座位位置
					--进入座位请求状态，feel状态进入prepare
					npcInfo.curState = NPCStateType.WaitSeatRequest --状态切换
					npcInfo.curFeel = NPCFeelType.Prepare --进入子状态
					break
				end
			end

			if not isFindSeat then
				--离开门口
				npcInfo.curState = NPCStateType.LeaveDoor
			end
		end,
		--在外卖座位发起请求
		[NPCStateType.WaitSeatRequest] 			= function()
		    print("WaitSeatRequest")
			--进入feel状态切换
			--test,此处应该是进入另外一个方法 未完成
			totalTime = math.random(2, 4)
			npcInfo.curState = NPCStateType.WaitSeatIdle
		end,
		--在外卖座位支付
		[NPCStateType.WaitSeatPay] 				= function()
		    print("WaitSeatPay")
			--进入feel状态切换
			--test 未完成
			totalTime = math.random(2, 4)
			npcInfo.curState = NPCStateType.LeaveWaitSeat
		end,
		--在外卖座位稍微发呆
		[NPCStateType.WaitSeatIdle] 			= function()
		    print("WaitSeatIdle")

		    totalTime = math.random(1, 2)
			npcInfo.curState = NPCStateType.WaitSeatPay
			npcInfo.curFeel = NPCFeelType.Normal
		end,
		--在外卖座位支付成功
		[NPCStateType.WaitSeatPaySuccess] 		= function()
		    print("WaitSeatPaySuccess")
		    totalTime = 1.0
			npcInfo.curState = NPCStateType.LeaveWaitSeat
			npcInfo.curFeel = NPCFeelType.Invalid --重置状态
		end,
		--离开外卖座位
		[NPCStateType.LeaveWaitSeat] 			= function()
		    print("LeaveWaitSeat")
			--离开座位之后回到开始位置然后kill掉?
			assert(_waitSeatMap[npcInfo.mapId] == npcId, "error")
			_waitSeatMap[npcInfo.mapId] = 0 --设置为空
			mapId = _startMapId

			npcInfo.curState = NPCStateType.Release --进入销毁状态
		end,
	}

	local state = npcInfo.curState --npc通用状态
	local fSwitch = switchState[state] --switch 方法

	if fSwitch then
		local result = fSwitch() --执行switch的代码
		if result then
			--已经释放对象进入此代码段
			return
		end
	else
		error("error state")
		return
	end

	if mapId ~= -1 then
		--说明在switch中改变了值，调用viewdelegate, view会返回寻路花费的时间
		print(npcInfo.mapId)
		print(mapId)
		totalTime = _delegate:moveNPC(npcId, mapId)
		npcInfo.mapId = mapId --保存目标位置
	end

	--注意，totalTime为0导致死循环
	print("id:"..npcId.." totalTIme:"..totalTime)
	_timer:addTimerListener(npcId, totalTime) --加入时间控制


end


--[[-------------------
	---Public method-----
	---------------------]]


--[[-------------------
	---Timer Delegate-----
	---------------------]]
function ManageModel:TD_onTimOver(listenerId)
	print("listenerId is:"..listenerId)

	local npcInfo = _npcInfoMap[listenerId]
	if npcInfo then --回调
		self:npcState(npcInfo)
	end
	
end