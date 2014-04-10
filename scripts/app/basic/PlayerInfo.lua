PlayerStateType = {
				Invalid                = 1,

				Idle                   = 2, --空闲状态

				Seat                   = 3, --座位位置
				WaitSeat               = 4, --等待座位位置
				Product                = 5, --产品位置
}

PlayerInfo = {}
--index
PlayerInfo.__index = PlayerInfo
--public
PlayerInfo.elfId   = -1
PlayerInfo.modelId = -1
PlayerInfo.mapId   = -1
PlayerInfo.curState = -1
PlayerInfo._queue   = nil --队列 从1开始增长
PlayerInfo._first   = 0
PlayerInfo._last    = -1

function PlayerInfo:create()
	local ret = {}
	setmetatable(ret, PlayerInfo)
	self:init()
    return ret
end

function PlayerInfo:init()
	self._queue = {}
end


--队列操作
--为了寻找与删除，队列保持增长不删除
function PlayerInfo:atQueue(index)
	local data = self._queue[index]

	return data
end

function PlayerInfo:removeQueue(index)
	local data = self._queue[index]
	--删除原理，player读取队列该数值的时候判断此值是否为true，若true则不执行该队列的命令
	data.isDelete = true --删除
end

--队列push，加到队列末尾，如果加入前是空的则返回true（方便直接执行队列）
function PlayerInfo:pushQueue(data)

	local last = self._last
	local first = self._first

	-- if first >  last then
	-- 	--队列是空的
	-- end

	self._last = last + 1

	self._queue[self._last] = data

	return self._last --返回偏移值

end

--队列pop，弹出顶端数据
function PlayerInfo:popQueue()
	local data = nil
	local first = self._first
	if first > self._last then
		-- print("empty")
	else
		data = self._queue[first]
		-- self._queue[first] = nil --队列完整保存，不用移除
		self._first = first + 1
	end

	return data
end

