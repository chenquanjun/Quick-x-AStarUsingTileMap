--座位控制，包括占座离座
SeatControl = {}
--index
SeatControl.__index = SeatControl

SeatControl._mapDataDic				  	= nil

SeatControl._occupySeatDic  				= nil --可以占位的类型均保存在这个字典里面

SeatControl._pointDic   	 		 		= nil --对于单个位置的object，一律保存到这个字典里面，例如开始位置，

SeatControl.SEAT_EMPTY             	    = 0

--经营场景的全局变量，controller负责初始化和回收
--负责管理座位占领和离开

function SeatControl:create(mapDataDic)
	local ret = {}
	setmetatable(ret, SeatControl)
	ret:init(mapDataDic)
    return ret
end

function SeatControl:init(mapDataDic)
	self._mapDataDic = mapDataDic

	self._occupySeatDic = {}

	--多个位置的数组
	self:initMapPointsVec()

	--单个位置
	self:initMapPoint()
end

--单点位置
function SeatControl:initMapPoint()
	local startVec = self._mapDataDic[kMapDataStart]
	local cookVec  = self._mapDataDic[kMapDataCook]
	local cashierVec  = self._mapDataDic[kMapDataCashier]

	local mapIdMap = {}

	mapIdMap[kMapDataStart] = startVec[1]
	mapIdMap[kMapDataCook] = cookVec[1]
	mapIdMap[kMapDataCashier] = cashierVec[1]

	self._pointDic = mapIdMap
end

--多点位置
function SeatControl:initMapPointsVec()

	local seatVec = self._mapDataDic[kMapDataSeat]
	local waitSeatVec = self._mapDataDic[kMapDataWaitSeat]
	local doorVec = self._mapDataDic[kMapDataDoor]
	local payVec = self._mapDataDic[kMapDataPayQueue]

	--初始化字典
	local seatDic = {}
	local waitSeatDic = {}
	local doorDic = {}
	local payDic = {}

	--保存字典到占位字典
	self._occupySeatDic[kMapDataSeat] = seatDic
	self._occupySeatDic[kMapDataWaitSeat] = waitSeatDic 
	self._occupySeatDic[kMapDataDoor] = doorDic 
	self._occupySeatDic[kMapDataPayQueue] = payDic
	
	--初始化
	for i,v in ipairs(seatVec) 
	do 
		seatDic[v] = self.SEAT_EMPTY --0表示空, 其他时候表示顾客的id 
	end  

	for i,v in ipairs(waitSeatVec) 
	do 
		waitSeatDic[v] = self.SEAT_EMPTY --0表示空, 其他时候表示顾客的id 
	end  

	for i,v in ipairs(doorVec) 
	do 
		doorDic[v] = self.SEAT_EMPTY --0表示空, 其他时候表示顾客的id 
	end

	--注意支付队列初始化数组+1为开始排队位置，不作占位使用，用来作移动
	for i,v in ipairs(payVec) 
	do 
		payDic[v] = self.SEAT_EMPTY --0表示空, 其他时候表示顾客的id 
	end  
end

--看看是谁霸占了座位
function SeatControl:getSeatInfo(mapType, mapId)

	local mapDic = self._occupySeatDic[mapType]

	local elfId = mapDic[mapId]

	return elfId
end

--需要占用的类型，占用的npcId
function SeatControl:occupySeat(mapType, elfId)
	-- 占位 
	-- 返回地图id
	local mapId = -1
	--取出类型对应的数组
	local mapVec = self._mapDataDic[mapType]
	--取出字典
	local mapDic = self._occupySeatDic[mapType]
	
	for i,v in ipairs(mapVec) do
				
		local seatState = mapDic[v]

			if seatState == self.SEAT_EMPTY then
				mapId = v --保存id
				mapDic[v] = elfId --霸占位置
			break
		end
	end --for

	return mapId
end

--离开座位，传入地图类型，地图id，之前占领的id
function SeatControl:leaveSeat(mapType, mapId, elfId)
	--取出字典
	local mapDic = self._occupySeatDic[mapType]

	local seatState = mapDic[mapId]

	--两个值应该是相同的，否则出错
	assert(seatState == elfId, "error seat state")

	mapDic[mapId] = self.SEAT_EMPTY
end

function SeatControl:getMapIdOfType(mapType)
	local mapId = self._pointDic[mapType]
	return mapId
end

function SeatControl:getMapIdVecOfType(mapType)
	local vector = self._mapDataDic[mapType]
	return vector
end