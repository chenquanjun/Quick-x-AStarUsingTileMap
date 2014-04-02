require "app/basic/extern"

TimerEvent = {
	Invalid          = 1,
    Running          = 2,
    Pause            = 3, 
    Stop             = 4,
}

--此处继承CCNode,因为需要维持这个表，但是用object的话需要retian/release
TimerControl = class("TimerControl", function()
return CCNode:create()
end)

TimerControl.__index = TimerControl

local _delegate = nil

local _timerEvent = TimerEvent.Invalid --时间控制器状态

local _nTimePast = 0 --流逝时间

local _timerInterval  =0.1 --每0.1秒执行事件

local _timerActionTag = 99 

local _lstIdsTimerKey = {} --以结束时间为key保存listenerId的vec
local _timerUnitLstIdKey = {} --以listenerId为key保存TimerUnit对象

function TimerControl:create()
	local ret = TimerControl.new()
		ret:init()
	return ret
end

function TimerControl:init()

end

function TimerControl:setDelegate(delegate)
	_delegate = delegate
end

function TimerControl:removeDelegate()
	_delegate = nil
end

--[[-------------------
    ---Timer Method-----
    ---------------------]]

function TimerControl:startTimer()

	if _timerEvent == TimerEvent.Invalid or _timerEvent == TimerEvent.Stop then
		print("start timer")
		_nTimePast = 0
		--停止定时器
		self:stopActionByTag(_timerActionTag)

		local delay = CCDelayTime:create(_timerInterval)
	    local callfunc = CCCallFunc:create(function() self:timerUpdate() end)
	    local sequence = CCSequence:createWithTwoActions(delay, callfunc)
	    local action = CCRepeatForever:create(sequence)

	    action:setTag(_timerActionTag)
	    self:runAction(action)

	    _timerEvent = TimerEvent.Running

	elseif _timerEvent == TimerEvent.Running or _timerEvent == TimerEvent.Pause then
		error("running should stop, pause should resume")
	end



end

function TimerControl:pauseTimer()
	if _timerEvent == TimerEvent.Running then

		self:stopActionByTag(_timerActionTag)

		_timerEvent = TimerEvent.Pause
	else
		error("error call")
	end
end

function TimerControl:resumeTimer()
	if _timerEvent == TimerEvent.Pause then

		local delay = CCDelayTime:create(_timerInterval)
	    local callfunc = CCCallFunc:create(callback)
	    local sequence = CCSequence:createWithTwoActions(delay, callfunc)
	    local action = CCRepeatForever:create(sequence)

	    action:setTag(_timerActionTag)
	    node:runAction(action)

	    _timerEvent = TimerEvent.Running

	else
		error("error call")
	end
end

function TimerControl:stopTimer()
	self:stopActionByTag(_timerActionTag)
	_nTimePast = 0
	_timerEvent = TimerEvent.Stop

	_lstIdsTimerKey = {} 
    _timerUnitLstIdKey = {} 
end

--[[-------------------
    ---update Method-----
    ---------------------]]
function TimerControl:timerUpdate()
	--以时间为key 存放listenerId数组
	local lstIdsVec = _lstIdsTimerKey[_nTimePast]

	if lstIdsVec then
		for i,v in ipairs(lstIdsVec) do 
			
			local listenerId = v

			local timerUnit = _timerUnitLstIdKey[listenerId]

			if timerUnit then
				local endTime = timerUnit.endTime
				if endTime == _nTimePast then
					_delegate:onTimeOver(listenerId)
				end
			end

		end
		_lstIdsTimerKey[_nTimePast] = nil --释放
	end

	_nTimePast = _nTimePast + 1
	print(_nTimePast)
end

--[[-------------------
    ---regist Method-----
    ---------------------]]

function TimerControl:addTimerListener(listenerId, duration)
	--时间换算
	local localDur = self:int(duration / _timerInterval) 

	local endTime = _nTimePast + localDur

	local timerUnit = {}
	timerUnit.startTime = _nTimePast
	timerUnit.endTime = endTime
	timerUnit.listenerId = listenerId

	local lstIdVec = _lstIdsTimerKey[endTime]

	if not lstIdVec then
		lstIdVec = {}
	end

	print("EndTime:"..endTime.." lsdId:".. listenerId)

	local size = table.getn(lstIdVec)
	lstIdVec[size + 1] = listenerId --保存在vector里面

	_lstIdsTimerKey[endTime] = lstIdVec

	_timerUnitLstIdKey[listenerId] = timerUnit

end

function TimerControl:removeTimerListener(listenerId)
	--增加update时候判断的代价换来删除的快捷
	_timerUnitLstIdKey[listenerId] = nil
end

function TimerControl:setListenerSpeed(listenerId, speed)
	local timerUnit = _timerUnitLstIdKey[listenerId]

	if timerUnit then
		local endTime = timerUnit.endTime
		local curTime = _nTimePast

		--过去的不能加速
		if endTime > curTime then
			local newDuration = (endTime - curTime) / speed
			--暂时不知有没问题，待测试
			--此处的duration需要转换成实际的duration
			self:addTimerListener(listenerId, newDuration * _timerInterval)

		end
	end
end

--[[-------------------
    ---private Method-----
    ---------------------]]


function TimerControl:int(x) 
	return x>=0 and math.floor(x) or math.ceil(x)
end
