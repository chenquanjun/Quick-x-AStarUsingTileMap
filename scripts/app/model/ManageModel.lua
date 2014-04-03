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

local _seatMap = {}  --座位字典
local _waitSeatMap = {} --等待座位字典
local _doorMap = {} --门口字典

local _startMapId = -1

local _npcInfoMap = {}

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
	self:addNPC()
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
		npcInfo.curMapId = _startMapId
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

--移动NPC
-- function ManageModel:moveNPC(npcId, mapId)
-- 	local totalTime = _delegate:moveNPC(npcId, mapId)
-- 	print("id:"..npcId.." totalTIme:"..totalTime)
-- 	_timer:addTimerListener(npcId, totalTime)
-- end

function ManageModel:npcState(npcInfo)
	local npcId = npcInfo.npcId --npcId
	local totalTime = 0 --回调参数
	local mapId = -1 --npc的目标mapId
	--switch....
	local switchState = {
		[NPCStateType.Start]					= function()
			print("start")
			totalTime = math.random(1, 10)
			npcInfo.curState = NPCStateType.GoToDoor --状态切换
		end,

		[NPCStateType.GoToDoor]					= function()
			print("GoToDoor")

		end,

		[NPCStateType.Door] 					= function()
			print("Door")

		end,

		[NPCStateType.LeaveDoor] 				= function()
			print("LeaveDoor")

		end,

		[NPCStateType.FindSeat] 				= function()
			print("FindSeat")

		end,

		[NPCStateType.SeatRequest] 				= function()
			print("SeatRequest")

		end,

		[NPCStateType.SeatEating] 				= function()
			print("SeatEating")

		end,

		[NPCStateType.SeatPay] 					= function()
			print("SeatPay")

		end,

		[NPCStateType.SeatPaySuccess]			= function()
			print("SeatPaySuccess")

		end,

		[NPCStateType.LeaveSeat] 				= function()
			print("LeaveSeat")

		end,

		[NPCStateType.FindWaitSeat] 			= function()
		    print("FindWaitSeat")

		end,

		[NPCStateType.WaitSeatRequest] 			= function()
		    print("WaitSeatRequest")

		end,

		[NPCStateType.WaitSeatPay] 				= function()
		    print("WaitSeatPay")

		end,

		[NPCStateType.WaitSeatIdle] 			= function()
		    print("WaitSeatIdle")

		end,

		[NPCStateType.WaitSeatPaySuccess] 		= function()
		    print("WaitSeatPaySuccess")

		end,

		[NPCStateType.LeaveWaitSeat] 			= function()
		    print("LeaveWaitSeat")

		end,
	}
	
	local state = npcInfo.curState --npc通用状态
	local fSwitch = switchState[state] --switch 方法

	if fSwitch then
		fSwitch() --执行switch
	else
		error("state error")
	end

	if mapId ~= -1 then
		--说明在switch中改变了值，调用viewdelegate
		totalTime = _delegate:moveNPC(npcId, mapId)
	end


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