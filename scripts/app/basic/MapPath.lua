--此处继承CCNode,因为需要维持这个表，但是用object的话需要retian/release
MapPath = class("MapPath", function()
	return CCNode:create()
end)			
--index
MapPath.__index = MapPath
MapPath.__mode = "v" --弱引用
--private
MapPath._startId  	= -1--开始Id
MapPath._endId  	= -1 --结束id
MapPath._pointArr  	= nil --坐标点

function MapPath:create(startId, endId, pointArr)
	local mapPath = MapPath.new()
	mapPath:init(startId, endId, pointArr)
	return mapPath
end

function MapPath:init(startId, endId, pointArr)
	self._startId = startId
	self._endId = endId

	local arr = tolua.cast(pointArr, "CCPointArray")
    assert(pointArr ~= nil, "error type")

    local count = arr:count()

    self._pointArr = {}

    for i = 1, count do
    	local point = arr:get(i - 1)
    	self._pointArr[i] = {}
    	self._pointArr[i].x = point.x
    	self._pointArr[i].y = point.y
    end
end

function MapPath:getStartId()
	return self._startId
end

function MapPath:getEndId()
	return self._endId
end

function MapPath:getPointArrCount()
	return table.getn(self._pointArr)
end

function MapPath:getPointAtIndex(index)
	--注意index是从1开始的！
	assert(index >= 1 and index <= self:getPointArrCount(), "out of range")
	local pointInArr = self._pointArr[index]
	local point = ccp(pointInArr.x, pointInArr.y)
	return point
end

function MapPath:getPointArr()
	local pointArr = CCPointArray:create(0)
	local size = self:getPointArrCount()
	for i = 1, size do
		local point = self:getPointAtIndex(i)
		pointArr:add(point)
	end
	return pointArr
end