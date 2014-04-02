require "app/basic/extern"
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

	--关于定时器
	--model负责维护timer及其delegate的生命周期
	--model直接调用timer的时间方法
	--timer到时间后调用delegate
	--delegate再回调model

	--定时器
	local timerControl = TimerControl:create()
	self:addChild(timerControl)
	_timer = timerControl

	--定时器delegate 将model加入到refer中，以便delegate能回调model的方法
	local timerDelegate = TimerControlDelegate:setRefer(self)
	_timerDelegate = timerDelegate

	timerControl:setDelegate(timerDelegate)
end

function ManageModel:setDelegate(delegate)
	_delegate = delegate
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
	--test
	self:addNPC()
	self:moveNPC()

	_timer:addTimerListener(1, 3)
	-- _timer:addTimerListener(1, 2.1)
	-- _timer:addTimerListener(3, 0.02)
	_timer:startTimer()
	_timer:setListenerSpeed(1, 1)
	-- _timer:startTimer()
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
	

	local data = {}

	data.npcId = 1
	data.npcType = 1

	_delegate:addNPC(data)

end

--移动NPC
function ManageModel:moveNPC()
	_delegate:moveNPC(1, _doorVector[1])
end

--[[-------------------
	---Public method-----
	---------------------]]


--[[-------------------
	---Timer Delegate-----
	---------------------]]
function ManageModel:TD_onTimOver(listenerId)
	print("listenerId is:"..listenerId)
end