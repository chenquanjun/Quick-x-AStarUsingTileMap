--继承
require "app/basic/extern"
--地图基础信息
require "app/basic/MapPath"
require "app/basic/MapInfo"
require "app/basic/MapGeneral"
--mvc
----model
require "app/model/ManageModel"
----view
require "app/view/ManageView"
--delegate
require "app/delegate/ManageModelDelegate"
require "app/delegate/ManageViewDelegate"

--此处继承CCNode,因为需要维持这个表，但是用object的话需要retian/release
ManageController = class("ManageController", function()
	return CCNode:create()
end)	

--[[-------------------
	---Init Value-----
	---------------------]]		

ManageController.__index = ManageController

ManageController._view          = nil
ManageController._model         = nil
ManageController._viewDelegate  = nil
ManageController._modelDelegate = nil
ManageController._mapInfo       = nil

--[[-------------------
	---Init Method-----
	---------------------]]

function ManageController:create()
	local ret = ManageController.new()
	ret:init()
	return ret
end

function ManageController:init()
	print("Controller init")
	--controller被主scene创建
	--controller负责创建model和view，然后再设置相应的delegate
	--为了便于内存控制，controller view 和 model都继承于CCNode，场景离开时交给2dx释放
	self._view = ManageView:create()
	self._model = ManageModel:create()

	self:addChild(self._view)--view
	self:addChild(self._model)--model

	--model delegate 指向view
	self._modelDelegate = ManageModelDelegate:setRefer(self._view)
	--view delegate 指向controller
	self._viewDelegate = ManageViewDelegate:setRefer(self)

	--delegate
	self._model:setDelegate(self._modelDelegate)
	self._view:setDelegate(self._viewDelegate)

	--地图信息 controller保存
	self._mapInfo = MapInfo:create("map.tmx")
    self:addChild(self._mapInfo)

    --view需要用到地图的mapId转换成坐标的方法，所以需要引用mapInfo
    self._view:setMapInfo(self._mapInfo) 


   	--model需要知道门口，座位，等待座位等的位置, 从1开始！！
    local mapDataDic = self._mapInfo:getMapDataDic()

    --全局变量
    G_mapGeneral = MapGeneral:create(mapDataDic)
    G_scheduler = require("framework.scheduler")

    local seatToServeDic = self._mapInfo:getSeatToServeDic()

    -- self._model:setMapDataDic(mapDataDic)
    self._model:setSeatToServeDic(seatToServeDic)

	local seatVec = mapDataDic[kMapDataSeat]
	local waitSeatVec = mapDataDic[kMapDataWaitSeat]
	local productVec = mapDataDic[kMapDataProduct]

	do --初始化按钮
		--座位按钮回调
		self._view:initBtns(seatVec, function(mapId)  
					self._model:onSeatBtn(mapId)
			end)
		self._view:initBtns(waitSeatVec, function(mapId)  
					self._model:onWaitSeatBtn(mapId)
			end)

		-- self._view:initBtns(productVec, function(mapId)  
		-- 			self._model:onProductBtn(mapId)
		-- 	end)
	end

end

function ManageController:onEnter()
	self._model:onEnter()
end
--统一用此方法，scene负责通知controller,controller再通知view和model
function ManageController:onRelease()
	print("Controller on release")
	self._viewDelegate:removeRefer()
	self._modelDelegate:removeRefer()
	self._view:onRelease()
	self._model:onRelease()
	self._mapInfo = nil
	self._view = nil
	self._model = nil
	self._viewDelegate = nil
	self._modelDelegate = nil

	G_mapGeneral = nil
	G_scheduler = nil
end

--[[
--------------------------
------Delegate Method------
----------------------------]]
function ManageController:VD_onProductBtn(elfId)
	self._model:onProductBtn(elfId)
end

function ManageController:VD_onTrayProductBtn(index)
	self._model:onTrayProductBtn(index)
end