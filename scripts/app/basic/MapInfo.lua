require"app/basic/extern"
--枚举值 地图信息
kMapDataInvalid   =  0 --无效
kMapDataBlock     = -1 --石头等障碍物
kMapDataRoad      =  1 --路径
kMapDataDoor      =  7 --门口
kMapDataSeat      =  8 --座位
kMapDataWaitSeat  =  9 --等待座位
kMapDataStart     = 10 --开始坐标
kMapDataThing     = 11 --物体
kMapDataServe     = 12 --服务位置
kMapDataProduct   = 13 --产品位置

kActionTagInvalid     = 0 --默认
kActionTagDown       = 1 --下
kActionTagLeft       = 2 --左
kActionTagRight      = 3 --右
kActionTagUp         = 4 --上
kActionTagMove       = 99

kMapKeyOffset     = 100000 --地图路径的保存偏移量 startId * kMapKeyOffset + endId作为key值

--地图信息类
MapInfo = class("MapInfo", function()
	return CCNode:create()
end)

MapInfo.__index  		    	= MapInfo

local _mapMatrix  		   		= nil       --网格，即地图的网格有多少个
local _mapUnit  				= nil       --网格单元大小，每个网格的大小，理论上所有网格的大小都一样
local _mapData  				= nil        --保存地图的信息, 以数组矩阵形式保存, 从左到右，从下到上扩展数值(mapId)，保存kMapDataXXX值
local _mapPathCache  			= nil        --地图缓存
local _mapTypeDataMap  			= nil 		--地图信息类字典(根据mapData分类缓存成字典, 以kMapDataXXX为key值)

--构造方法，继承CCNode
function MapInfo:create(fileName)
	local mapInfo = MapInfo.new()
	mapInfo:init(fileName)
	return mapInfo
end

function MapInfo:init(fileName)
	_mapData = {}
	_mapPathCache = {}
	_mapTypeDataMap = {}

	local map = CCTMXTiledMap:create(fileName)

	--map 网格的大小
	_mapMatrix = map:getMapSize()

	cclog("GridSize: %.0f, %.0f", _mapMatrix.width, _mapMatrix.height)

	--object图层 tmx文件中以object命名的object层
	local group = map:objectGroupNamed("object")
	local objects = group:getObjects()

	do  --网格单元大小
		local firstDict = tolua.cast(objects:objectAtIndex(0), "CCDictionary")
        local keyW = "width"
        local width = (tolua.cast(firstDict:objectForKey(keyW), "CCString")):intValue()
        local keyH = "height"
        local height = (tolua.cast(firstDict:objectForKey(keyH), "CCString")):intValue()
        _mapUnit = CCSize(width, height)

		cclog("PointSize: %.0f, %.0f", width, height)
	end

	do--遍历地图信息并保存下来	    
		local  dict    = nil --字典
	    local  i       = 0   --
	    local  len     = objects:count()

	    local gridWidth = _mapMatrix.width --网格行数目
	    local pointWidth = _mapUnit.width --网格宽度
	    local pointHeight = _mapUnit.height --网格高度

	    for i = 0, len-1, 1 do
	        dict = tolua.cast(objects:objectAtIndex(i), "CCDictionary")

	        if dict == nil then
	            break
	        end

	        local key = "x"
	        local x = (tolua.cast(dict:objectForKey(key), "CCString")):intValue() / pointWidth
	        key = "y"
	        local y = (tolua.cast(dict:objectForKey(key), "CCString")):intValue() / pointHeight
	        key = "objectid"
	        local objectId = (tolua.cast(dict:objectForKey(key), "CCString")):intValue()

	        assert(objectId ~= kMapDataInvalid, "object id not set")
	        --mapId 从左到右，从下到上扩展
	        local mapId = x + y * gridWidth
			_mapData[mapId] = objectId

			-- print("mapId:"..mapId.." "..objectId)

	    end

	end

end

function MapInfo:findPath(startMapId, endMapId)
	do
		local key = startMapId * kMapKeyOffset + endMapId
		local path = _mapPathCache[key]
		if path ~= nil then
			return path
		end
	end


	do  --排除开始和结束点的不合法情况
		if startMapId == -1 or endMapId == -1 then
			return nil
		end

		local startType = _mapData[startMapId]
		local endType = _mapData[endMapId]

		if startType ==  kMapDataBlock or startType == kMapDataThing then
			return nil
		end

		if endType ==  kMapDataBlock or endType == kMapDataThing then
			return nil
		end
	end

	local vecClose = {} --close表
	local vecOpen = {} --open表

	--其实不需要这个index也可以
	local vecOpenIndex = 1 --open表的index open涉及删除操作
	local vecCloseIndex = 1 --close表的index close表不涉及删除操作

	--链表
	local PointNode = { 
	    parent = PointNode, 
	    nMapId = -1, 
	    nG = -1
	}

	PointNode.nMapId = startMapId
	vecClose[vecCloseIndex] = PointNode
	vecCloseIndex = vecCloseIndex + 1

	local nStep = 0

	while true do
		if nStep >= 100000 then
			break
		end --if

		nStep = nStep + 1

		local pNextNode = vecClose[table.getn(vecClose)]
		-- dump(pNextNode, "pNextNode")
		if pNextNode == nil then
			break;--没有
		end --if

		if pNextNode.nMapId == endMapId then
			break;--目标
		end --if

		for i = 0, 3 do
			local nMapId = self:GetIndexByDir(pNextNode.nMapId, i)
			local bContinue = false

			if nMapID == -1 then
				bContinue = true --等于continue 跳过下面代码继续下个循环，下面的同理
			end

			if bContinue == false then
				local mapType = _mapData[nMapId]

				if mapType == kMapDataSeat or mapType == kMapDataWaitSeat then
				
	                if nMapId ~= endMapId then
	                	bContinue = true --非目的地则排除座位，门口和等待座位
	                end 

	            elseif mapType == kMapDataBlock or mapType == kMapDataThing then
	            	bContinue = true --障碍 物体 排除
				end

				if bContinue == false then
					if self:InTable(nMapId, vecClose) ~= nil then
						bContinue = true --在close表里面
					end

					if bContinue == false then
						local pOpenNode = self:InTable(nMapId, vecOpen)
						if pOpenNode then
							local nNewG = pNextNode.nG + self:GetGByIndex(pNextNode.nMapId, pOpenNode.nMapId)

							if pOpenNode.nG > nNewG then
								pOpenNode.nG = nNewG
								pOpenNode.pParent = pNextNode
							end

							bContinue = true
						end

						if bContinue == false then --新搜索到的格子
							local pNode = {}
							pNode.nMapId = nMapId
							pNode.nG = pNextNode.nG + self:GetGByIndex(pNextNode.nMapId, pNode.nMapId)
							pNode.pParent = pNextNode
							vecOpen[vecOpenIndex] = pNode
							vecOpenIndex = vecOpenIndex + 1

						end
					end


				end


			end
		end --for 循环

		local nMinF = 0xFFFFFF
		pNextNode = nil
        local nNextNodeIndex = 0
        local size = table.getn(vecOpen)

        for i = 1, size do
        	local pNode = vecOpen[i]
        	local bContinue = false
        	if pNode == nil then
        		bContinue = true
        	end

        	if bContinue == false then
        		local nH = self:GetHByIndex(pNode.nMapId, endMapId)
           	    local nF = nH + pNode.nG

           	    if nF < nMinF then
           	  	  nMinF = nF
              	  pNextNode = pNode
              	  nNextNodeIndex = i
           	    end

        	end

        end

        if  nNextNodeIndex <= size then
        	vecClose[vecCloseIndex] = pNextNode
			vecCloseIndex = vecCloseIndex + 1
          
			for i = nNextNodeIndex, size do
				vecOpen[i] = vecOpen[i + 1] --等于将nNextNodeIndex的删除
			end

			vecOpenIndex = vecOpenIndex - 1 --注意删除后要把标志位恢复

        end

	end-- while 循环

	--寻路结束
	local size = table.getn(vecClose)
	local pNode = vecClose[size]

    --坐标点集合数组
	local pointArr = CCPointArray:create(0)

	--此处生成的是逆向坐标点
	while pNode do
		local mapId = pNode.nMapId
		pNode = pNode.pParent

		local point = self:convertIdToPointMid(mapId)

		pointArr:add(point)
	end
     
	local pathRevert = MapPath:create(endMapId, startMapId, pointArr)
	local path = MapPath:create(startMapId, endMapId, pointArr:reverse())

	local keyRevert = endMapId * kMapKeyOffset + startMapId
	local key = startMapId * kMapKeyOffset + endMapId

	_mapPathCache[key] = path
	_mapPathCache[keyRevert] = pathRevert

	--MapPath是自动释放对象，需要addchild
	self:addChild(pathRevert) 
	self:addChild(path)
	-- print("save key:"..key)

	return path
end

-- 地图信息获取方法

function MapInfo:getMapTypeData(type)
	local typeData = _mapTypeDataMap[type]

	if typeData == nil then
		--typeData为type类型信息的数组
		--下标从1开始，内容保存mapId
		typeData = {}
		local index = 1
		local mapData = _mapData --地图信息
		local size = table.getn(mapData)
		for i = 0, size - 1 do
			local objectId = mapData[i]
			if objectId == type then
				typeData[index] = i --其实是mapId
				index = index + 1
			end
		end
		_mapTypeDataMap[type] = typeData
	end

	return typeData
end

-- 坐标地图id转换方法，将点转换成地图id
function MapInfo:convertPointToId(point)
    local mapId = -1;
    --在大地图内, 此处的转换是按照左下角往右扩展，然后再往上扩展形式计算，例如
    -- 8 9 ...
    -- 4 5 6 7
    -- 0 1 2 3
    local rect = CCRect(0, 0, _mapMatrix.width * _mapUnit.width, _mapMatrix.height * _mapUnit.height)
    if rect.containsPoint(point) then
    	        local x = point.x / _mapUnit.width;
        local y = point.y / _mapUnit.height;
        mapId = x + y * _mapMatrix.width;
    end

    return mapId;
end

-- 坐标地图id转换方法，将地图id转换成坐标点（方格左下角点）
function MapInfo:convertIdToPoint(mapId)
    local point = ccp(0, 0)

    local size = table.getn(_mapData)
    if mapId >= 0 and mapId < size then
    	local y = self:int(mapId / _mapMatrix.width)
    	local x = mapId - y * _mapMatrix.width

    	point = ccp(x * _mapUnit.width, y * _mapUnit.height)
    end

    return point;
end

-- 坐标地图id转换方法，将地图id转换成坐标点（方格中点）
function MapInfo:convertIdToPointMid(mapId)
    local point = self:convertIdToPoint(mapId);
    return ccp(point.x + _mapUnit.width * 0.5, point.y + _mapUnit.height * 0.5);
end


--private method
function MapInfo:InTable(nIndex, vector)
	local count = table.getn(vector)

	for i = 1, count do
		local pointNode = vector[i]

		if nIndex == pointNode.nMapId then
			return vector[i]
		end

	end
	return nil
end

function MapInfo:GetIndexByDir(nIndex, nDir)
	--暂时只写了四个方向
	assert(nDir >=0 and nDir <= 4, "out of range")
	local width = _mapMatrix.width
	local height = _mapMatrix.height

	if nIndex < 0 or nIndex >= width * height then
		return -1
	end --if
			    
	local nRow = self:int(nIndex / width);
	local nCol = nIndex % width;

	if nDir == 0 then     --上
		nRow = nRow + 1
	elseif nDir == 1 then --右
		nCol = nCol + 1
	elseif nDir == 2 then --下
		nRow = nRow - 1
	elseif nDir == 3 then --左
		nCol = nCol - 1
	end --if

	if nRow < 0 or nRow >= height or nCol < 0 or nCol >= width then
		return -1
	end --if

	return nRow * width + nCol
end

-- A星寻路 G值
function MapInfo:GetGByIndex(nStartIndex, nEndIndex)
	local width = _mapMatrix.width

	local nStartRow = self:int(nStartIndex / width)
	local nStartCol = nStartIndex % width

	local nEndRow = self:int(nEndIndex / width)
	local nEndCol = nEndIndex % width 

	if nStartRow == nEndRow or nStartCol == nEndCol then
		return 10
	end

	return 14
end

-- A星寻路 H值
function MapInfo:GetHByIndex(nIndex, nEndIndex)
	local width = _mapMatrix.width

	local nRow = self:int(nIndex / width)
	local nCol = nIndex % width

	local nEndRow = self:int(nEndIndex / width)
	local nEndCol = nEndIndex % width 

	local value = (math.abs(nEndRow - nRow) + math.abs(nEndCol - nCol)) * 10

	return value
end

-- 浮点转换成int
function MapInfo:int(x) 
	return x>=0 and math.floor(x) or math.ceil(x)
end