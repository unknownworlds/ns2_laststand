// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\menu\Ticker.lua
//
//    Created by:   Marc Delorme (marcdelorme@unknownworlds.com)
//
//    Display message on the main menu (company message, twitter feed, ...)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/menu/MenuElement.lua")
Script.Load("lua/GUIAnimationUtility.lua")

class 'Ticker' (MenuElement)

local function ConvertHtmlCodes(text)

    text = text:gsub('&amp;',  '&')
    text = text:gsub('&quot;', "'")
    text = text:gsub('&lt;',   '<')
    text = text:gsub('&gt;',   '>')
    
    return text

end

local function SetNextText(self)

    self.currentTextIndex = (self.currentTextIndex % #self.tweets) + 1
    
    if not self.tweets[self.currentTextIndex]["retweet_count"] == 0 then
    
        self.retweetCount = self.retweetcount + 1
        
        if self.retweetCount <= #self.tweets then
            SetNextText(self)
        else
            self.animState = "stop"
        end
        
    else
    
        self.currentIndex = 0
        self.currentText = self.tweets[self.currentTextIndex]["text"]
        self.currentText = ConvertHtmlCodes(self.currentText)
        self.retweetCount = 0
        
    end
    
    self:RenderText(self.currentText)
    
end

function Ticker:Initialize()

    MenuElement.Initialize(self)
    
    self.nextLetter = 0.100;
    
    self.animState = 'in'
    self.textAlpha = 0.0
    self.nextTime = 4
    self.currentTextIndex = 0
    
    local params =
    {
        user_id = "NS2",
        screen_name = "NS2"
    }
    
    Shared.SendHTTPRequest("https://api.twitter.com/1/statuses/user_timeline.json", "GET", params, function(response)
        local obj, pos, err = json.decode(response, 1, nil)
        
        if err or obj["errors"] or obj["error"] then
            return
        end
        
        self.tweets = obj
        
        SetNextText(self)
        
        local function OpenTweet()
        
            local id = self.tweets[self.currentTextIndex]["id_str"]
            SetMenuWebView("https://twitter.com/NS2/status/" .. id, Vector(Client.GetScreenWidth() * 0.8, Client.GetScreenHeight() * 0.8, 0))
            
        end
        
        self:AddEventCallbacks({ OnClick = OpenTweet })
        
    end)
    
end

local function UpdateTextAlpha(self)

    for i, f in ipairs(self.fonts) do
        local color = f:GetTextColor()
        color.a = self.textAlpha
        f:SetTextColor( color )
    end

end

local function UpdateFadeIn(self, deltaTime)

    PROFILE("UpdateFadeIn")

    UpdateTextAlpha(self)

    if self.textAlpha > 0.7 then
        self.animState = 'wait'
    end

    self.textAlpha = self.textAlpha + deltaTime
end

local function UpdateFadeOut(self, deltaTime)

    PROFILE("UpdateFadeOut")

    UpdateTextAlpha(self)

    if self.textAlpha < 0 then

        SetNextText(self)

        self.animState = 'in'
        self.textAlpha = 0.0
    end

    self.textAlpha = self.textAlpha - deltaTime
end

function Ticker:Update(deltaTime)

    PROFILE("Ticker:Update")

    if self.tweets == nil then
        return
    end

    if self.animState == 'in' then
        UpdateFadeIn(self, deltaTime)
    elseif self.animState == 'wait' then

        self.nextTime = self.nextTime - 0.5 * deltaTime
        if self.nextTime < 0 then
            self.animState = 'out'
            self.nextTime = 4
        end

    elseif self.animState == 'out' then
        UpdateFadeOut(self, deltaTime)
    end

end

function Ticker:GetTagName()
    return "ticker"
end

function Ticker:RenderText(text)

    PROFILE("Ticker:RenderText")

    self:ClearChildren()

    -- Format the text
    text = text:gsub([[ ?\#[Ff][Bb] ?]], "")

    text = "[ " .. text .. " ]"

    self.texts = {}
    local m, M = text:find("(@[a-zA-z1-9_]*)")
    while  m ~= nil do

        table.insert(self.texts, text:sub(1,m-1) )
        table.insert(self.texts, text:sub(m,M) )
        text = text:sub(M+1)

        m, M = text:find("(@[a-zA-z1-9_]*)")

    end
    
    table.insert(self.texts, text)

    self.fonts = {}
    for i, txt in ipairs(self.texts) do

        table.insert(self.fonts, CreateMenuElement(self, "Font") )
        self.fonts[i]:SetText(txt)

        if i % 2 == 0 then
            self.fonts[i]:AddCSSClass("tweet_name")
        end

        if i > 1 then
            self.fonts[i]:SetLeftOffset( self.fonts[i-1]:GetWidth() )
        end

    end
    
    self:UpdateBackGroundSize()
    UpdateTextAlpha(self)

end

function Ticker:UpdateBackGroundSize()

    local bgSize = Vector(0, 0, 0)
    
    for i, el in ipairs(self.fonts) do

        bgSize.x = bgSize.x + el:GetWidth()    
        bgSize.y = el:GetHeight()

        if i > 1 then
            self.fonts[i]:SetLeftOffset( self.fonts[i-1]:GetWidth() )
        end

    end
    
    self:SetBackgroundSize(bgSize, true)

    self:ReloadCSSClass()

    for i, _ in ipairs(self.fonts) do

        if i > 1 then

            local w = 0
            for k= 1, i-1 do
                w = w + self.fonts[k]:GetWidth()
            end
            self.fonts[i]:SetLeftOffset( w )
        end

    end
    
end

function Ticker:SetBackgroundPosition(posVector, absolute, time, animateFunc, animName, callBack)

    if self.horizontalAlign == GUIItem.Middle then
        posVector.x = - self:GetWidth() / 2
    end

    MenuElement.SetBackgroundPosition(self, posVector, absolute, time, animateFunc, animName, callBack)

end