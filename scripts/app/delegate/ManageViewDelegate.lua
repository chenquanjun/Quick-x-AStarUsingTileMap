--view向controller通信，controller再派发给model
ManageViewDelegate = {}
--index
ManageViewDelegate.__index = ManageViewDelegate
--private
ManageViewDelegate._refer = nil --初始化时候包含对controller的弱引用，以调用controller的方法

--初始化controller之后再调用此方法，引用controller
function ManageViewDelegate:setRefer(controllerRefer)
	local ret = {}
	setmetatable(ret, ManageViewDelegate)
    self._refer = controllerRefer --controller的引用
    return ret
end
function ManageViewDelegate:removeRefer()
	print("View delegate remove")
	self._refer = nil
end
--test
function ManageViewDelegate:onShowSprite()
	if self._refer then
		print("on show sprite")
		--controller method
	end
end

function ManageViewDelegate:onProductBtn(elfId)
	self._refer:VD_onProductBtn(elfId)
end