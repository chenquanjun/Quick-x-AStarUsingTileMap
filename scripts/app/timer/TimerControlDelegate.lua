TimerControlDelegate = {}
TimerControlDelegate.__index = TimerControlDelegate
local _refer = nil --初始化时候包含对view的弱引用，以调用view的方法

--初始化view之后再调用此方法，引用view
function TimerControlDelegate:setRefer(delegate)
	local ret = {}
	setmetatable(ret, TimerControlDelegate)
    _refer = delegate --view的引用
    return ret
end
--释放
function TimerControlDelegate:removeRefer()
	print("Timer delegate remove")
	_refer = nil
end

--test
function TimerControlDelegate:onTimeOver(listenerId)

	if _refer then
		_refer:TD_onTimOver(listenerId)
	end
end