--[[-------------------
    -------Require-----
    ---------------------]]
--general 所有常量定义
require "app/basic/ManageGeneral"

--继承2dx对象基类
require "app/basic/extern"

--队列
require "app/basic/PayQueue"

--timer
require "app/timer/GlobalTimer"

--统计模块
require "app/basic/Stats"

--地图基础信息
require "app/basic/MapPath"
require "app/basic/MapInfo"
require "app/basic/SeatControl"
require "app/basic/PayControl"

--信息组件
require "app/basic/NPCInfo"
require "app/basic/PlayerInfo"
require "app/basic/TrayInfo"

--view组件
require "app/view/ManageTrayView"
require "app/view/PlayerSprite"
require "app/view/NPCSprite"

--mvc
----model
require "app/model/ManageModel"
----view
require "app/view/ManageView"
--delegate
require "app/delegate/ManageModelDelegate"
require "app/delegate/ManageViewDelegate"

--controller
--关于全局变量
--所有全局变量均由controller控制生命周期与释放
--命名规范为G_xxx

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
-- ManageController._viewDelegate  = nil
-- ManageController._modelDelegate = nil
ManageController._mapInfo       = nil

ManageController._timerPast     = 0

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
	local modelDelegate = ManageModelDelegate:setRefer(self._view)
	--view delegate 指向controller
	local viewDelegate = ManageViewDelegate:setRefer(self)

	--delegate
	-- self._model:setDelegate(self._modelDelegate)
	-- self._view:setDelegate(self._viewDelegate)

	--地图信息 controller保存
	self._mapInfo = MapInfo:create("map.tmx")
    self:addChild(self._mapInfo)

    --view需要用到地图的mapId转换成坐标的方法，所以需要引用mapInfo
    self._view:setMapInfo(self._mapInfo) 


   	--model需要知道门口，座位，等待座位等的位置, 从1开始！！
    local mapDataDic = self._mapInfo:getMapDataDic()

    do  --全局变量(所有全局变量均由controller控制生命周期与释放)
    	G_modelDelegate = modelDelegate --model delegate
    	G_viewDelegate = viewDelegate  --view delegate

	    G_seatControl = SeatControl:create(mapDataDic)  --座位控制
	    G_scheduler = require("framework.scheduler")    --scheduler
 
	    G_payControl = PayControl:create()              --支付控制

	    G_timer = GlobalTimer:create()                  --全局时间控制
		self:addChild(G_timer)

		G_stats = Stats:create() --统计模块
    end

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

	--启动定时器
	G_timer:startTimer()

	local isOn = true


	do --dump btn
		local pointX = display.right - 50
		local pointY = display.bottom + 50

		local function createDump(name, callback)
			local dumpBtn = CCLabelTTF:create(name, "Arial", 20)
			dumpBtn:setColor(ccc3(255, 0, 0))
			dumpBtn:setPosition(ccp(pointX, pointY))
			pointY = pointY + 30
			self:addChild(dumpBtn, 100)

			dumpBtn:setTouchEnabled(true)
			dumpBtn:setVisible(false)
	        dumpBtn:addTouchEventListener(function(event, x, y)

	            if event == "began" then
	                return true -- catch touch event, stop event dispatching
	            end

	            local touchInSprite = dumpBtn:getCascadeBoundingBox():containsPoint(CCPoint(x, y))
	            if event == "moved" then
	                if touchInSprite then

	                else

	                end
	            elseif event == "ended" then
	                if touchInSprite then 
	                	callback()
	                end

	            else

	            end
	        end)

	        return dumpBtn
		end

		local dumpModelBtn = createDump("model", function ()
			-- self._model:dumpAllData()
			print("dump model")
		end)

		local dumpPayControlBtn = createDump("payControl", function ()

			print("dump pay control")
		end)



		--timer
		self._view:initTimer(function()  
			self._view:toggleTimer(not isOn)

			if isOn then
				-- G_timer:pauseTimer()
				dumpModelBtn:setVisible(true)
				dumpPayControlBtn:setVisible(true)
				CCDirector:sharedDirector():pause()
				
			else 
				-- G_timer:resumeTimer()
				dumpModelBtn:setVisible(false)
				dumpPayControlBtn:setVisible(false)
				CCDirector:sharedDirector():resume()
			end
			isOn = not isOn	


				end)
		
	end
end

function ManageController:onEnter()
	self._model:onEnter()

	self._timerPast = -1 --第一次调用变成0
	self:TD_onTimeOver(ElfIdList.TimerPast)--相当于启动定时器
end
--统一用此方法，scene负责通知controller,controller再通知view和model
function ManageController:onRelease()
	print("Controller on release")
	G_viewDelegate:removeRefer()
	G_modelDelegate:removeRefer()
	self._view:onRelease()
	self._model:onRelease()
	self._mapInfo = nil
	self._view = nil
	self._model = nil
	-- self._viewDelegate = nil

	G_viewDelegate = nil
	G_modelDelegate = nil

	G_seatControl = nil
	G_scheduler = nil
	G_payControl = nil

	G_timer = nil
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

--[[-------------------
	---timer call-----
	---------------------]]
function ManageController:TD_onTimeOver(elfId)
	if elfId == ElfIdList.TimerPast then
		local num = self._timerPast + 1
		self._timerPast = num
		self._view:setTimer(num)
		--不断重复加入
		G_timer:addTimerListener(elfId, 1, self)
	end
end