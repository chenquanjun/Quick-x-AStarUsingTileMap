--model向view通信
ManageModelDelegate = {}
--index
ManageModelDelegate.__index = ManageModelDelegate
--private
ManageModelDelegate._refer = nil --初始化时候包含对view的弱引用，以调用view的方法

--初始化view之后再调用此方法，引用view
function ManageModelDelegate:setRefer(viewRefer)
	local ret = {}
	setmetatable(ret, ManageModelDelegate)
    ret._refer = viewRefer --view的引用
    return ret
end
--释放
function ManageModelDelegate:removeRefer()
	print("Model delegate remove")
	self._refer = nil
end

function ManageModelDelegate:setStatsReason(leaveReason, num)
	self._refer:MD_setStatsReason(leaveReason, num)
end

--添加产品
function ManageModelDelegate:addProduct(data)
	self._refer:MD_addProduct(data)
end

--添加主角
function ManageModelDelegate:addPlayer(data)
	self._refer:MD_addPlayer(data)
end

--添加NPC
function ManageModelDelegate:addNPC(data)
	-- data 结构
	-- elfId   每个npc都有一个唯一对应的elfId
	-- modelId  不同类型的NPC，view根据相应的type创建NPC
	self._refer:MD_addNPC(data)
end

--移动NPC
function ManageModelDelegate:moveNPC(elfId, mapId)
	local totalTime = self._refer:MD_moveNPC(elfId, mapId)
	return totalTime
end

--移动player
function ManageModelDelegate:movePlayer(elfId, mapId)	
	local totalTime = self._refer:MD_movePlayer(elfId, mapId)
	return totalTime
end

function ManageModelDelegate:coolDownProduct(elfId, duration)
	self._refer:MD_coolDownProduct(elfId, duration)
end

function ManageModelDelegate:removeNPC(elfId)
	self._refer:MD_removeNPC(elfId)
end

function ManageModelDelegate:setStateStr(elfId, stateStr)
	self._refer:MD_setStateStr(elfId, stateStr)
end

--请求
function ManageModelDelegate:addRequest(elfId, productVec)
	self._refer:addRequest(elfId, productVec)
end

--删除请求
function ManageModelDelegate:removeRequest(elfId, indexVec)
	self._refer:MD_removeRequest(elfId, indexVec)
end

--tray method
function ManageModelDelegate:addProductAtIndex(index, productType)
    self._refer:MD_addProductAtIndex(index, productType)
end

function ManageModelDelegate:removeProductAtIndex(index)
    self._refer:MD_removeProductAtIndex(index)
end

function ManageModelDelegate:removeProductWithVec(indexVec)
	self._refer:MD_removeProductWithVec(indexVec)
end

function ManageModelDelegate:setProductFinishAtIndex(index)
    self._refer:MD_setProductFinishAtIndex(index)
end