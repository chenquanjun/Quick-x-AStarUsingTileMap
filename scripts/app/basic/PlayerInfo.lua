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
PlayerInfo.queue   = nil --队列 从1开始增长
PlayerInfo._first   = 0
PlayerInfo._last    = -1

function PlayerInfo:create()
	local ret = {}
	setmetatable(ret, PlayerInfo)
	self:init()
    return ret
end

function PlayerInfo:init()
	self.queue = {}
end


--队列操作
--为了寻找与删除，队列保持增长不删除
function PlayerInfo:at(index)
	local data = self.queue[first]

	return data
end

--队列push，加到队列末尾，如果加入前是空的则返回true（方便直接执行队列）
function PlayerInfo:push(data)

	local last = self._last
	local first = self._first

	-- if first >  last then
	-- 	--队列是空的
	-- end

	self._last = last + 1

	self.queue[self._last] = data

	return self._last --返回指针值

end

--队列pop，弹出顶端数据
function PlayerInfo:pop()
	local data = nil
	local first = self._first
	if first > self._last then
		-- print("empty")
	else
		data = self.queue[first]
		self.queue[first] = nil
		self._first = first + 1
	end

	return data
end

