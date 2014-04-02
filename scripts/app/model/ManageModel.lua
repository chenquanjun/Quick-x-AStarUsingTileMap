require "app/basic/extern"

--此处继承CCNode,因为需要维持这个表，但是用object的话需要retian/release
ManageModel = class("ManageModel", function()
	return CCNode:create()
end)			

--[[-------------------
	---Init Value-----
	---------------------]]

ManageModel.__index = ManageModel

local _delegate = nil --model delegate

local _seatVector = nil --座位数组，保存座位的mapId
local _waitSeatVector = nil 
local _doorVector = nil

local _seatMap = {}  --座位字典
local _waitSeatMap = {} --等待座位字典
local _doorMap = {} --门口字典

--[[-------------------
	---Init Method-----
	---------------------]]

function ManageModel:create()
	local ret = ManageModel.new()
	ret:init()
	return ret
end

function ManageModel:setDelegate(delegate)
	_delegate = delegate
end

function ManageModel:setMapData(seatVec, waitSeatVec, doorVec)

    --记录哪个mapId是座位，等待座位和门口, 下标从1开始
	_seatVector = seatVec
	_waitSeatVector = waitSeatVec
	_doorVector = doorVec

	--初始化
	for i,v in ipairs(_seatVector) 
	do 
		_seatMap[v] = 0 --0表示空, 其他时候表示顾客的id 
	end  

	for i,v in ipairs(_waitSeatVector) 
	do 
		_waitSeatMap[v] = 0 --0表示空, 其他时候表示顾客的id 
	end  

	for i,v in ipairs(_doorVector) 
	do 
		_doorMap[v] = 0 --0表示空, 其他时候表示顾客的id 
	end  	
end

function ManageModel:init()
	print("Model init")
end

function ManageModel:onEnter()
	print("model onEnter")
	if _delegate then
		_delegate:showSprite()
	end
end

function ManageModel:onRelease()
	print("Model on release")
	_delegate = nil

	_seatVector = nil
	_waitSeatVector = nil
	_doorVector = nil

	_seatMap = nil
	_waitSeatMap = nil
	_doorMap = nil
end

--[[-------------------
	---Private method-----
	---------------------]]


--[[-------------------
	---Public method-----
	---------------------]]