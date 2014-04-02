--model向view通信
ManageModelDelegate = {}
ManageModelDelegate.__index = ManageModelDelegate
local _refer = nil --初始化时候包含对view的弱引用，以调用view的方法

--初始化view之后再调用此方法，引用view
function ManageModelDelegate:setRefer(viewRefer)
	local ret = {}
	setmetatable(ret, ManageModelDelegate)
    _refer = viewRefer --view的引用
    return ret
end
--释放
function ManageModelDelegate:removeRefer()
	print("Model delegate remove")
	_refer = nil
end

--test
function ManageModelDelegate:showSprite()
	print("show sprite")
	if _refer then
		print("show sprite")
		--view method
		_refer:MD_showSprite()
	end
end