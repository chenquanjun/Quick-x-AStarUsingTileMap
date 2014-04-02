--继承
require "app/basic/extern"
--地图基础信息
require "app/basic/MapPath"
require "app/basic/MapInfo"
--mvc
require "app/model/ManageModel"
require "app/view/ManageView"
--delegate
require "app/delegate/ManageModelDelegate"
require "app/delegate/ManageViewDelegate"

--此处继承CCNode,因为需要维持这个表，但是用object的话需要retian/release
ManageController = class("ManageController", function()
	return CCNode:create()
end)			

ManageController.__index = ManageController

local _view = nil
local _model = nil
local _viewDelegate = nil
local _modelDelegate = nil
local _mapInfo = nil

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
	_view = ManageView:create()
	_model = ManageModel:create()
	self:addChild(_view)
	self:addChild(_model)

	--model delegate 指向view
	_modelDelegate = ManageModelDelegate:setRefer(_view)
	--view delegate 指向controller
	_viewDelegate = ManageViewDelegate:setRefer(self)

	--delegate
	_model:setDelegate(_modelDelegate)
	_view:setDelegate(_viewDelegate)

	--地图信息 controller保存
	_mapInfo = MapInfo:create("map.tmx")
    self:addChild(_mapInfo)

    --view需要用到地图的mapId转换成坐标的方法，所以需要引用mapInfo
    _view:setMapInfo(_mapInfo) 

    --model需要知道门口，座位，等待座位的位置
	local seatVec = _mapInfo:getMapTypeData(kMapDataSeat)
	local waitSeatVec = _mapInfo:getMapTypeData(kMapDataWaitSeat)
	local doorVec = _mapInfo:getMapTypeData(kMapDataDoor)

	_model:setMapData(seatVec, waitSeatVec, doorVec)
end

function ManageController:onEnter()
	_model:onEnter()
end
--统一用此方法，scene负责通知controller,controller再通知view和model
function ManageController:onRelease()
	print("Controller on release")
	_viewDelegate:removeRefer()
	_modelDelegate:removeRefer()
	_view:onRelease()
	_model:onRelease()
	_mapInfo = nil
	_view = nil
	_model = nil
	_viewDelegate = nil
	_modelDelegate = nil
end
