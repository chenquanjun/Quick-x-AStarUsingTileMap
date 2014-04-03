require "app/basic/extern"

--此处继承CCNode,因为需要维持这个表，但是用object的话需要retian/release
MapPath = class("MapPath", function()
	return CCNode:create()
end)			

MapPath.__index = MapPath

local _startId = -1--开始Id
local _endId = -1 --结束id
local _pointArr = nil --坐标点

function MapPath:create(startId, endId, pointArr)
	local mapPath = MapPath.new()
	mapPath:init(startId, endId, pointArr)
	return mapPath
end

function MapPath:init(startId, endId, pointArr)
	_startId = startId
	_endId = endId

	local arr = tolua.cast(pointArr, "CCPointArray")
    assert(pointArr ~= nil, "error type")

    local count = arr:count()

    _pointArr = {}

    for i = 1, count do
    	local point = arr:get(i - 1)
    	_pointArr[i] = {}
    	_pointArr[i].x = point.x
    	_pointArr[i].y = point.y
    end
end

function MapPath:getStartId()
	return _startId
end

function MapPath:getEndId()
	return _endId
end

function MapPath:getPointArrCount()
	return table.getn(_pointArr)
end

function MapPath:getPointAtIndex(index)
	--注意index是从1开始的！
	assert(index >= 1 and index <= self:getPointArrCount(), "out of range")
	local pointInArr = _pointArr[index]
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