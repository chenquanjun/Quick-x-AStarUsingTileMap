--[[
--------------------------
------Model Delegate------
----------------------------]]
                          
--model向view通信
ManageModelDelegate = {}
ManageModelDelegate.__index = ManageModelDelegate
ManageModelDelegate._refer = nil --初始化时候包含对view的弱引用，以调用view的方法

--初始化view之后再调用此方法，引用view
function ManageModelDelegate:setRefer(viewRefer)
	local ret = {}
	setmetatable(ret, ManageModelDelegate)
    self._refer = viewRefer --view的引用
    return ret
end

--test
function ManageModelDelegate:showSprite(mapId)
	if not _refer then
		print("show sprite")
		--view method
	end
end


--[[
--------------------------
------View Delegate------
----------------------------]]
                          
--view向controller通信，controller再派发给model
ManageViewDelegate = {}
ManageViewDelegate.__index = ManageViewDelegate
ManageViewDelegate._refer = nil --初始化时候包含对controller的弱引用，以调用controller的方法

--初始化controller之后再调用此方法，引用controller
function ManageViewDelegate:setRefer(controllerRefer)
	local ret = {}
	setmetatable(ret, ManageViewDelegate)
    self._refer = controllerRefer --controller的引用
    return ret
end

--test
function ManageViewDelegate:onShowSprite()
	if not _refer then
		print("on show sprite")
		--controller method
	end
end

