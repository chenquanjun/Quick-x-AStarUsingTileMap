PlayerInfo = {}
--index
PlayerInfo.__index = PlayerInfo
--public
PlayerInfo.elfId = -1
PlayerInfo.modelId = -1
PlayerInfo.mapId = -1

function PlayerInfo:create()
	local ret = {}
	setmetatable(ret, PlayerInfo)
	self:init()
    return ret
end

function PlayerInfo:init()
	
end