--所有常量定义
--controller 负责require与释放
--[[-------------------
    -------Map info-----
    ---------------------]]

--枚举值 地图信息
kMapDataInvalid       	=  0 --无效
kMapDataBlock         	= -1 --石头等障碍物
kMapDataRoad          	=  1 --路径
kMapDataCook          	=  2 --厨师位置
kMapDataCashier       	=  3 --收银员位置
kMapDataDoor          	=  7 --门口
kMapDataSeat          	=  8 --座位
kMapDataWaitSeat      	=  9 --等待座位
kMapDataStart         	= 10 --开始坐标
kMapDataThing         	= 11 --物体
kMapDataServe         	= 12 --服务位置
kMapDataProduct       	= 13 --产品位置
kMapDataPayQueue    	= 14 --收银台队列

kActionTagInvalid     	= 0 --默认
kActionTagDown        	= 1 --下
kActionTagLeft        	= 2 --左
kActionTagRight       	= 3 --右
kActionTagUp          	= 4 --上
kActionTagMove        	= 99

kMapKeyOffset         	= 100000 --地图路径的保存偏移量 startId * kMapKeyOffset + endId作为key值

--[[-------------------
    -------id info-----
    ---------------------]]

--确保每个使用到时间调用的元素都有一个唯一的id
ElfIdList = {
	Player     		 = 1,    --玩家id，史迪奇1         --model 
	PayQueCrtl		 = 50,   --支付控制，             --payControl 暂时废弃
	PayQueCheck		 = 51,   --支付队列检测			--payControl
	ProductOffset    = 100,  --100~1000是物品id		--model
	NpcOffset        = 1000, --1000~2000以后是npcId	--model
	PayNpcOffset     = 2000  --2000 + npcId(= 3000 ~ 4000)是支付npc回调
}

--[[-------------------
    -------Player info-----
    ---------------------]]

PlayerStateType = {
				Invalid                = 1,

				Idle                   = 2, --空闲状态

				Seat                   = 3, --座位位置
				WaitSeat               = 4, --等待座位位置
				Product                = 5, --产品位置
				WaitProduct            = 6, --等待产品完成
}

--[[-------------------
    -------NPC info-----
    ---------------------]]

NPCStateType = {
				Invalid                = 1,

				Start                  = 2,            --开始位置
				Release                = 3,            --释放

				GoToDoor               = 11,           --移动到门口
				Door                   = 12,            --在门口
				LeaveDoor              = 13,            --离开门口

				FindSeat               = 20,            --尝试寻找座位
				SeatRequest            = 21,            --在座位请求状态 包含子状态NPCFeelType
				SeatEating             = 22,            --在座位吃饭状态
				LeaveSeat              = 23,            --离开座位

				FindWaitSeat           = 30,            --寻找等待座位

				Pay                    = 40,            --支付
				NorPayMoving           = 41,
				NorPayMoveEnd          = 42,
				NorPayPrePare          = 43,
				NormalPay              = 45, 			--普通支付
				WaitPay                = 46, 			--等待支付
				LeavePay               = 49, 			--离开支付（与LeaveSeat类似）
}

NPCFeelType = {
				Invalid   =    101,
				Prepare   =    102,
				Normal    =    110,
				Anger     =    111,
				Cancel    =    112,
}

--移动到支付的位置，移动结束，准备，等待支付控制进入normal状态
NPCPayType = {
				Invalid   =    201,
				Moving 	  =    202,
				MoveEnd   =    203,
				Prepare   =    204,
				PrepareEnd=    205,
				Normal    =    210,
				Anger     =    211,
				Cancel    =    215,
				Paying    =    216,
}

--[[-------------------
    -------tray info-----
    ---------------------]]

ProductStateType = {
				Invalid                = 1,
				NotComplete            = 2,
				Complete               = 3,    

}
