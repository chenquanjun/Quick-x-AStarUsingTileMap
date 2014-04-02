require "app/basic/extern"
require "app/model/ManageModel"
require "app/view/ManageView"
require "app/delegate/ManageDelegate"

--此处继承CCNode,因为需要维持这个表，但是用object的话需要retian/release
ManageController = class("ManageController", function()
	return CCNode:create()
end)			

ManageController.__index = ManageController
ManageController._view = nil
ManageController._model = nil
ManageController._viewDelegate = nil
ManageController._modelDelegate = nil

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

end

--找不到析构函数。。
--统一用此方法，scene负责通知controller,controller再通知view和model
function ManageController:onRelease()
	print("Controller on release")
	_viewDelegate:removeRefer()
	_modelDelegate:removeRefer()
	_view:onRelease()
	_model:onRelease()
	_view = nil
	_model = nil
	_viewDelegate = nil
	_modelDelegate = nil
end
