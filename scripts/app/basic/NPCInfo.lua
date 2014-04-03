NPCStateType = {
				Invalid                = 1,

				Start                  = 2,            --开始位置
				GoToDoor               = 11,           --移动到门口
				Door                   = 12,            --在门口
				LeaveDoor              = 13,            --离开门口

				FindSeat               = 20,            --尝试寻找座位
				SeatRequest            = 21,            --在座位请求状态 包含子状态NPCFeelType
				SeatEating             = 22,            --在座位吃饭状态
				SeatPay                = 23,            --在座位支付状态 包含子状态NPCFeelType
				SeatPaySuccess         = 24,
				LeaveSeat              = 25,            --离开座位

				FindWaitSeat           = 30,            --寻找等待座位
				WaitSeatRequest        = 31,
				WaitSeatPay            = 32,
				WaitSeatIdle           = 33,            --等于SeatEating
				WaitSeatPaySuccess     = 34,      
				LeaveWaitSeat          = 35,            --离开等待座位
}

NPCFeelType = {
				Invalid   =    1,
				Prepare   =    2,
				Normal    =    3,
				Anger     =    4,
				Cancel    =    5,
}


NPCInfo = {}
NPCInfo.__index = NPCInfo

NPCInfo.npcId = -1
NPCInfo.curMapId = -1
NPCInfo.curState = NPCStateType.Invalid    --NPC主状态
NPCInfo.curFeel  = NPCFeelType.Invalid     --NPC感情类型

function NPCInfo:create(npcId)
	local ret = {}
	setmetatable(ret, NPCInfo)
	self:init(npcId)
    return ret
end

function NPCInfo:init(npcId)
	self.npcId = npcId
end
