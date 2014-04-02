--view向controller通信，controller再派发给model
ManageViewDelegate = {}
ManageViewDelegate.__index = ManageViewDelegate
local _refer = nil --初始化时候包含对controller的弱引用，以调用controller的方法

--初始化controller之后再调用此方法，引用controller
function ManageViewDelegate:setRefer(controllerRefer)
	local ret = {}
	setmetatable(ret, ManageViewDelegate)
    _refer = controllerRefer --controller的引用
    return ret
end
function ManageViewDelegate:removeRefer()
	print("View delegate remove")
	_refer = nil
end
--test
function ManageViewDelegate:onShowSprite()
	if _refer then
		print("on show sprite")
		--controller method
	end
end