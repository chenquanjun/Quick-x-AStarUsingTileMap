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
    self._refer = viewRefer --view的引用
    return ret
end
--释放
function ManageModelDelegate:removeRefer()
	print("Model delegate remove")
	self._refer = nil
end

--添加主角
function ManageModelDelegate:addPlayer(data)
	self._refer:MD_addPlayer(data)
end

--添加NPC
function ManageModelDelegate:addNPC(data)
	-- data 结构
	-- npcId    每个npc都有一个唯一对应的NPCId
	-- npcType  不同类型的NPC，view根据相应的type创建NPC
	self._refer:MD_addNPC(data)
end

--移动NPC
function ManageModelDelegate:moveNPC(npcId, mapId)
	local totalTime = self._refer:MD_moveNPC(npcId, mapId)
	return totalTime
end

function ManageModelDelegate:removeNPC(npcId)
	self._refer:MD_removeNPC(npcId)
end