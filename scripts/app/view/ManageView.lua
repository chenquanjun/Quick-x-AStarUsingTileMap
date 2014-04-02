require "app/basic/extern"

--此处继承CCNode,因为需要维持这个表，但是用object的话需要retian/release
ManageView = class("ManageView", function()
	return CCNode:create()
end)			

ManageView.__index = ManageView

function ManageView:create()
	local ret = ManageView.new()
	ret:init()
	return ret
end

function ManageView:init()
	print("View init")
end

function ManageView:onRelease()
	print("View on release")
end