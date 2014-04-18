--统计模块
Stats = {}
--index
Stats.__index = Stats
Stats._npcInfoDic 				= nil --npc信息字典（加入后不可修改）
Stats._totalNum            = 0

Stats._leaveDic             = nil


function Stats:create()
	local ret = {}
	setmetatable(ret, Stats)
	ret:init()
    return ret
end

function Stats:init()
    self._npcInfoDic  = {} 
 
    self._leaveDic = {}

    for k,v in pairs(LeaveReason) do
    	self._leaveDic[k] = {}
    end

end

function Stats:onRelease()

end

--[[-------------------
	---public method-----
	---------------------]]

--添加npc信息
function Stats:addNPC(data)
	local elfId = data.elfId
	self._totalNum = self._totalNum + 1 --增加数目

	self._npcInfoDic[elfId] = data

	do --总共信息 test

		G_modelDelegate:setStatsReason("TotalIn", self._totalNum)
	end
end

function Stats:addProduct(data)
	-- body
end

--按照顺序存储
function Stats:leaveFor(elfId, leaveReason)

	local reasonStr = nil


	local switchState = {
		--没有位置离开
		[LeaveReason.NoSeat]	 = function()
			reasonStr = "NoSeat"
		end,
		--座位愤怒离开
		[LeaveReason.SeatAnger]	 = function()
			reasonStr = "SeatAnger"
		end,
		--等待座位愤怒离开
		[LeaveReason.WaitSeatAnger]	 = function()
			reasonStr = "WaitSeatAnger"
		end,
		--被赶
		[LeaveReason.GetOut] = function()
			reasonStr = "GetOut"
		end,
		--等待支付愤怒离开
		[LeaveReason.WaitPayAnger] = function()
			reasonStr = "WaitPayAnger"
		end,
		--普通支付愤怒离开
		[LeaveReason.NorPayAnger] = function()
			reasonStr = "NorPayAnger"
		end,
		--正常支付离开
		[LeaveReason.PayEnded] = function()
			reasonStr = "PayEnded"
		end,
	} --switch end

	local fSwitch = switchState[leaveReason] --switch 方法

	--存在switch（必然存在）
	if fSwitch then
		local result = fSwitch() --执行function
	else
		error("error state") --没有枚举
		return
	end

	do --总共信息
		local totalVec = self._leaveDic["TotalLeave"]

		local index = #totalVec + 1

		local data = {}
		data.elfId = elfId
		data.reason = leaveReason

		totalVec[index] = data

		G_modelDelegate:setStatsReason("TotalLeave", index)
	end

	do --单独信息
		local reasonVec = self._leaveDic[reasonStr]
		local index = #reasonVec + 1

		reasonVec[index] = elfId

		G_modelDelegate:setStatsReason(reasonStr, index)
	end

end








