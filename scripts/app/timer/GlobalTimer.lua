require "app/basic/extern"

TimerEvent = {
	Invalid          = 1,
    Running          = 2,
    Pause            = 3, 
    Stop             = 4,
}
--最小单位为0.1f
--对于同一个listenerid，只有最后一次的定时有效

--此处继承CCNode,因为需要维持这个表，但是用object的话需要retian/release
GlobalTimer = class("GlobalTimer", function()
return CCNode:create()
end)

GlobalTimer.__index            = GlobalTimer
GlobalTimer._delegate          = nil
GlobalTimer._timerEvent        = TimerEvent.Invalid --时间控制器状态
GlobalTimer._nTimePast         = 0 --流逝时间
GlobalTimer._timerInterval     = 0.05 --每0.1秒执行事件
GlobalTimer._timerActionTag    = 99 
GlobalTimer._lstIdsTimerKey    = nil --以结束时间为key保存listenerId的vec
GlobalTimer._timerUnitLstIdKey = nil --以listenerId为key保存TimerUnit对象

--[[-------------------
    ---init Method-----
    ---------------------]]

function GlobalTimer:create()
	local ret = GlobalTimer.new()
		ret:init()
	return ret
end

function GlobalTimer:init()
    self._lstIdsTimerKey = {} --以结束时间为key保存listenerId的vec
    self._timerUnitLstIdKey = {} --以listenerId为key保存TimerUnit对象
end

--[[-------------------
    ---Timer Method-----
    ---------------------]]

function GlobalTimer:startTimer()

	if self._timerEvent == TimerEvent.Invalid or self._timerEvent == TimerEvent.Stop then
		print("start timer")
		self._nTimePast = 0
		--停止定时器
		self:stopActionByTag(self._timerActionTag)

		local delay = CCDelayTime:create(self._timerInterval)
	    local callfunc = CCCallFunc:create(function() self:timerUpdate() end)
	    local sequence = CCSequence:createWithTwoActions(delay, callfunc)
	    local action = CCRepeatForever:create(sequence)

	    action:setTag(self._timerActionTag)
	    self:runAction(action)

	    self._timerEvent = TimerEvent.Running

	elseif self._timerEvent == TimerEvent.Running or self._timerEvent == TimerEvent.Pause then
		error("running should stop, pause should resume")
	end



end

function GlobalTimer:pauseTimer()
	if self._timerEvent == TimerEvent.Running then
		print("pause timer")
		self:stopActionByTag(self._timerActionTag)

		self._timerEvent = TimerEvent.Pause
	else
		error("error call")
	end
end

function GlobalTimer:resumeTimer()
	if self._timerEvent == TimerEvent.Pause then
		print("resume timer")
		local delay = CCDelayTime:create(self._timerInterval)
	    local callfunc = CCCallFunc:create(function() self:timerUpdate() end)
	    local sequence = CCSequence:createWithTwoActions(delay, callfunc)
	    local action = CCRepeatForever:create(sequence)

	    action:setTag(self._timerActionTag)
	    self:runAction(action)

	    self._timerEvent = TimerEvent.Running

	else
		error("error call")
	end
end

function GlobalTimer:stopTimer()
	print("stop timer")
	self:stopActionByTag(self._timerActionTag)
	self._nTimePast = 0
	self._timerEvent = TimerEvent.Stop

	self._lstIdsTimerKey = {} 
    self._timerUnitLstIdKey = {} 
end

--[[-------------------
    ---update Method-----
    ---------------------]]
function GlobalTimer:timerUpdate()
	--以时间为key 存放listenerId数组
	local lstIdsVec = self._lstIdsTimerKey[self._nTimePast]

	if lstIdsVec then
		for i,v in ipairs(lstIdsVec) do 
			
			local listenerId = v

			local timerUnit = self._timerUnitLstIdKey[listenerId]

			if timerUnit then
				local endTime = timerUnit.endTime
				if endTime == self._nTimePast then
					timerUnit.delegate:TD_onTimOver(listenerId)
				end
			end

		end
		self._lstIdsTimerKey[self._nTimePast] = nil --释放
	end

	self._nTimePast = self._nTimePast + 1
end

--[[-------------------
    ---regist Method-----
    ---------------------]]

function GlobalTimer:addTimerListener(listenerId, duration, delegate)
	if duration < 0 then
		return --小于0 直接返回
	end
	--时间换算
	local localDur = self:int(duration / self._timerInterval) 

	if localDur == 0 then
		--对于时间为0先清空map对应的数据，然后直接回调
		--防止同一个id在同一帧里面多次addTimer造成bug
		self._timerUnitLstIdKey[listenerId] = nil
		self._delegate:onTimeOver(listenerId)
		return
	end

	local endTime = self._nTimePast + localDur

	local timerUnit = {}
	timerUnit.startTime = self._nTimePast
	timerUnit.endTime = endTime
	timerUnit.listenerId = listenerId
	timerUnit.delegate = delegate

	local lstIdVec = self._lstIdsTimerKey[endTime] --endTime时间点的listenerId列表（可能一个，可能存在多个，也可能是空）

	if not lstIdVec then
		--vec 不存在
		lstIdVec = {}

	else --对于同一个id在相同时间添加多次的话会造成多次回调
		for i,v in ipairs(lstIdVec) do
			if v ==  listenerId then
				print("same id")
				return --排除
			end
		end
	end

	-- print("EndTime:"..endTime.." lsdId:".. listenerId)

	local size = table.getn(lstIdVec)
	lstIdVec[size + 1] = listenerId --保存在vector里面

	self._lstIdsTimerKey[endTime] = lstIdVec

	self._timerUnitLstIdKey[listenerId] = timerUnit

end

function GlobalTimer:removeTimerListener(listenerId)
	--增加update时候判断的代价换来删除的快捷
	self._timerUnitLstIdKey[listenerId] = nil
end

function GlobalTimer:setListenerSpeed(listenerId, speed)
	local timerUnit = self._timerUnitLstIdKey[listenerId]

	if timerUnit then
		local endTime = timerUnit.endTime
		local curTime = self._nTimePast

		--过去的不能加速
		if endTime > curTime then
			local newDuration = (endTime - curTime) / speed
			--暂时不知有没问题，待测试
			--此处的duration需要转换成实际的duration
			self:addTimerListener(listenerId, newDuration * self._timerInterval, timerUnit.delegate)

		end
	end
end

function GlobalTimer:getListenerRemainTime(listenerId)
	local remainTime = -1
	local timerUnit = self._timerUnitLstIdKey[listenerId]  
	if timerUnit then
		local endTime  = timerUnit.endTime
		local curTime = self._nTimePast

		if endTime > curTime then
			remainTime = (endTime - curTime) * self._timerInterval
		end
	end

	return remainTime
end

--[[-------------------
    ---private Method-----
    ---------------------]]


function GlobalTimer:int(x) 
	return x>=0 and math.floor(x) or math.ceil(x)
end
