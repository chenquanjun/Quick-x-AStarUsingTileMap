
require("config")
require("framework.init")
require("framework.shortcodes")
require("framework.cc.init")

-- cclog
cclog = function(...)
    print(string.format(...))
end

local MyApp = class("MyApp", cc.mvc.AppBase)

function MyApp:ctor()
    MyApp.super.ctor(self)
end

function MyApp:run()
    CCFileUtils:sharedFileUtils():addSearchPath("res/")
    self:enterScene("StartScene")
end

return MyApp
