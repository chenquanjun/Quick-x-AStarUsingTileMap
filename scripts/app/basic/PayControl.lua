--支付队列控制（包括等待支付与普通支付）
PayControl = {}
--index
PayControl.__index = PayControl
------------------------
PayControl._norPayQueue        = nil   --普通支付队列
PayControl._waitPayQueue        = nil  --等待支付队列
PayControl._payPointMapId       = -1
PayControl._npcInfoMap          = nil
 
function PayControl:create()
	local ret = {}
	setmetatable(ret, PayControl)
	ret:init()
    return ret
end

function PayControl:init()
	local maxNum = 5
	self._waitPayQueue = PayQueue:create(-1) --等待支付队列无限

	self._norPayQueue  = PayQueue:create(maxNum) --普通支付队列有限

	local payVec = G_seatControl:getMapIdVecOfType(kMapDataPayQueue)
	self._payPointMapId = payVec[maxNum + 1]

	self._npcInfoMap = {}
end

function PayControl:getPayPointMapId()
 	return self._payPointMapId
end

function PayControl:addPayNpc(npcInfo)

end

--加入支付大军
function PayControl:joinPay(elfId)
	--首先检查普通支付队列
	local data = {}
	data.elfId = elfId
	local isFull = self._norPayQueue:isFull()

	local isWaitPay = false

	if isFull then --加入等待支付队列
		self._waitPayQueue:pushQueue(data)
		isWaitPay = true
	else --成功进入普通支付队列
		--但是要等移动到指定位置时候才加入队列
		isWaitPay = false
	end
	return isWaitPay
end

function PayControl:joinNormalPay(npcInfo)
	--已经到达普通支付的等待位置，准备进入队列
	local elfId = npcInfo.elfId

	--获得即将进入的位置

	--转变状态
end

function PayControl:leavePay(elfId)

end

function PayControl:onRelease()
	self._norPayQueue         = nil   
	self._waitPayQueue        = nil  
end








