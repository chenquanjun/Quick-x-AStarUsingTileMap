
GlobalValue = {
    TotalTime =  {
                    index = 1,
                    name  = "总共时间(单位:秒)",
                    value = 90,
                    max   = 999999999,
                    min   = 1,
                 },
    PerWaveTime =  {
                    index = 2,
                    name  = "每波时间(秒)",
                    value = 5,
                    max   = 999999999,
                    min   = 0,
                 },
    PerWaveNum =  {
                    index = 3,
                    name  = "每波顾客人数(个)",
                    value = 3,
                    max   = 999999999,
                    min   = 1,
                 },
    PlayerMoveSpeed =  {
                    index = 4,
                    name  = "玩家移动速度(像素/秒)",
                    value = 500,
                    max   = 1000,
                    min   = 0,
                 },
    NPCMoveSpeed =  {
                    index = 5,
                    name  = "顾客移动速度(像素/秒)",
                    value = 250,
                    max   = 1000,
                    min   = 0,
                 },
    NPCSeatNormal =  {
                    index = 6,
                    name  = "座位普通(秒)",
                    value = 25,
                    max   = 1000,
                    min   = 0,
                 },
    NPCSeatAnger =  {
                    index = 7,
                    name  = "座位愤怒(秒)",
                    value = 20,
                    max   = 1000,
                    min   = 0,
                 },
    NPCWaitSeatNormal =  {
                    index = 8,
                    name  = "外卖普通(秒)",
                    value = 25,
                    max   = 1000,
                    min   = 0,
                 },
    NPCWaitSeatAnger =  {
                    index = 9,
                    name  = "外卖愤怒(秒)",
                    value = 20,
                    max   = 1000,
                    min   = 0,
                 },
    NPCWaitPayNormal =  {
                    index = 10,
                    name  = "等待支付普通(秒)",
                    value = 25,
                    max   = 1000,
                    min   = 0,
                 },
    NPCWaitPayAnger =  {
                    index = 11,
                    name  = "等待支付愤怒(秒)",
                    value = 20,
                    max   = 1000,
                    min   = 0,
                 },
    NPCNorPayNormal =  {
                    index = 12,
                    name  = "支付普通(秒)",
                    value = 25,
                    max   = 1000,
                    min   = 0,
                 },
    NPCNorPayAnger =  {
                    index = 13,
                    name  = "支付愤怒(秒)",
                    value = 20,
                    max   = 1000,
                    min   = 0,
                 },
}


local StartScene = class("StartScene", function()
    return display.newScene("StartScene")
end)

function StartScene:ctor()
    local label = CCLabelTTF:create("开始游戏", "Arial", 50)
    self:addChild(label)
    label:setPosition(ccp(display.right - 250, display.bottom + 50))

    label:setTouchEnabled(true)

    label:addTouchEventListener(function(event, x, y)

        if event == "began" then
            return true -- catch touch event, stop event dispatching
        end

        local touchInSprite = label:getCascadeBoundingBox():containsPoint(CCPoint(x, y))
        if event == "moved" then
            if touchInSprite then

            else

            end
        elseif event == "ended" then
            if touchInSprite then 
                label:setScale(0.9)
                self:transToMain()
            end

        else

        end
    end)


    
    local layer = display.newLayer()
    self:addChild(layer)

    local scrollView = CCScrollView:create()
    local function scrollViewDidScroll()
        print("scrollViewDidScroll")
    end
    local function scrollViewDidZoom()
        print("scrollViewDidZoom")
    end

    -- scrollView:setViewSize(CCSizeMake(display.width / 2,display.height))
    -- scrollView:setPosition(CCPointMake(0, 0))
    -- scrollView:setScale(1.0)
    -- scrollView:ignoreAnchorPointForPosition(true)

    -- scrollView:setContainer(layer)
    -- scrollView:updateInset()

    -- scrollView:setDirection(kCCScrollViewDirectionVertical)
    -- scrollView:setClippingToBounds(true)
    -- scrollView:setBounceable(true)
    -- scrollView:setDelegate()
    -- scrollView:registerScriptHandler(scrollViewDidScroll,CCScrollView.kScrollViewScroll)
    -- scrollView:registerScriptHandler(scrollViewDidZoom,CCScrollView.kScrollViewZoom)

    -- -- scrollView:setTouchEnabled(true)

    -- self:addChild(scrollView)

    local num = 0
    for k,v in pairs(GlobalValue) do
        self:createEidtBox(v, layer)
        num = num + 1
    end

    -- scrollView:setContentSize(CCSize(display.width / 2, 50 * num))
end




function StartScene:createEidtBox(data, layer)

    local editBoxSize = CCSizeMake(100, 40)
    local index = data.index
    local name = data.name
    local value = data.value
    local max = data.max
    local min = data.min
    local function editBoxTextEventHandle(strEventName,pSender)
        local edit = tolua.cast(pSender,"CCEditBox")
        local strFmt
        if strEventName == "began" then
            strFmt = string.format("editBox %p DidBegin !", edit)
            print(strFmt)
        elseif strEventName == "ended" then
            strFmt = string.format("editBox %p DidEnd !", edit)
            print(strFmt)

            local editValueStr = edit:getText()
            local editValue = toint(editValueStr)

            if editValue > min and editValue <= max then
                data.value = editValue
            else
                edit:setText(value)
            end
        elseif strEventName == "return" then
            strFmt = string.format("editBox %p was returned !",edit)



            print(strFmt)
        elseif strEventName == "changed" then

            strFmt = string.format("editBox %p TextChanged, text: %s ", edit, edit:getText())
            print(strFmt)
        end
    end
    local offsetX = self:int(index / 12)
    local offsetY
    if offsetX ~= 0 then
        offsetY = index - offsetX * 12 + 1
    else 
        offsetY = index - offsetX * 12
    end
    
    print(index.." "..offsetX.." "..offsetY)
    -- top
    local point = ccp(display.left + 300 + offsetX * 350, display.top - offsetY * 50)
    local pEditBox = CCEditBox:create(editBoxSize, CCScale9Sprite:create("green_edit.png"))
    pEditBox:setPosition(point)
    pEditBox:setInputMode(kEditBoxInputModePhoneNumber)
    pEditBox:setFontName("Arial")
    pEditBox:setFontSize(25)
    pEditBox:setFontColor(ccc3(255,0,0))
    pEditBox:setPlaceHolder(value) --默认数值
    pEditBox:setPlaceholderFontColor(ccc3(0,0,255))
    pEditBox:setMaxLength(8)
    pEditBox:setReturnType(kKeyboardReturnTypeDone)
    --Handler
    pEditBox:registerScriptEditBoxHandler(editBoxTextEventHandle)
    layer:addChild(pEditBox)

    local label = CCLabelTTF:create(name, "Arial-BoldMT", 20)
    label:setPosition(ccp(display.left + 120 + offsetX * 350, display.top - offsetY * 50))
    layer:addChild(label)

end

function StartScene:transToMain()
    local MainScene = require("app/scenes/MainScene")
    display.replaceScene(MainScene.new())
end

function StartScene:onEnter()
    if device.platform == "android" then
        -- avoid unmeant back
        self:performWithDelay(function()
            -- keypad layer, for android
            local layer = display.newLayer()
            layer:addKeypadEventListener(function(event)
                if event == "back" then app.exit() end
            end)
            self:addChild(layer)

            layer:setKeypadEnabled(true)
        end, 0.5)
    end

end

function StartScene:onExit()

end

function StartScene:int(x) 
    return x>=0 and math.floor(x) or math.ceil(x)
end

return StartScene
