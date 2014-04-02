require "app/basic/extern"

--此处继承CCNode,因为需要维持这个表，但是用object的话需要retian/release
ManageModel = class("ManageModel", function()
	return CCNode:create()
end)			

ManageModel.__index = ManageModel

function ManageModel:create()
	local ret = ManageModel.new()
	ret:init()
	return ret
end

function ManageModel:init()
	print("Model init")
end

function ManageModel:onRelease()
	print("Model on release")
end