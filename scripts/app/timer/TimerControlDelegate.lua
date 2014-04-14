TimerControlDelegate = {}
TimerControlDelegate.__index = TimerControlDelegate
TimerControlDelegate._refer = nil --初始化时候包含对view的弱引用，以调用view的方法

--初始化view之后再调用此方法，引用view
function TimerControlDelegate:setRefer(delegate)
	local ret = {}
	setmetatable(ret, TimerControlDelegate)
    ret._refer = delegate --view的引用
    return ret
end
--释放
function TimerControlDelegate:removeRefer()
	print("Timer delegate remove")
	self._refer = nil
end

--test
function TimerControlDelegate:onTimeOver(listenerId)

	if self._refer then
		self._refer:TD_onTimOver(listenerId)
	end
end