// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIWorldText.lua
//
// Created by: Andreas Urwalek (andi@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'GUIWorldText' (GUIScript)

GUIWorldText.kFont = "fonts/AgencyFB_small.fnt"
GUIWorldText.kYAnim = -30

kCommanderMessageVerticalOffset = GUIScale(90)

local kMinDistanceToCenter = GUIScale(64)

local function CreateMessageItem(self)

    local messageItem = GetGUIManager():CreateTextItem()
    messageItem:SetFontName(GUIWorldText.kFont)
    messageItem:SetTextAlignmentX(GUIItem.Align_Center)
    messageItem:SetTextAlignmentY(GUIItem.Align_Center)
    
    table.insert(self.messages, messageItem)

end

local function RemoveMessageItem(self, messageItem)

    table.removevalue(self.messages, messageItem)
    GUI.DestroyItem(messageItem)

end

function GUIWorldText:Initialize()

    GUIScript.Initialize(self)
    
    self.messages = {}

end

function GUIWorldText:Uninitialize()

    for _, messageItem in ipairs(self.messages) do    
        GUI.DestroyItem(messageItem)    
    end
    
    self.messages = nil
    
end

function GUIWorldText:Update(deltaTime)

    if not self.messages then
        Print("Warning: GUIWorldText script has not been cleaned up properly")
        return
    end
    
    local messages = PlayerUI_GetWorldMessages()    
    local messageDiff = #messages - #self.messages
    
    if messageDiff > 0 then
    
        // add new messages
        for i = 1, math.abs(messageDiff) do        
            CreateMessageItem(self)        
        end    
    
    elseif messageDiff < 0 then
    
        // remove unused messages
        for i = 1, math.abs(messageDiff) do        
            RemoveMessageItem(self, self.messages[1])        
        end
    
    end
    
    local useColor = ConditionalValue(PlayerUI_IsOnMarineTeam(), Color(kMarineTeamColorFloat), Color(kAlienTeamColorFloat))
    
    for index, message in ipairs(messages) do

        // Fetch UI element to update from our current message
        local messageItem = self.messages[index]

        if message.messageType == kWorldTextMessageType.Damage then
            self:UpdateDamageMessage(message, messageItem, useColor, deltaTime)
        else
            self:UpdateRegularMessage(message, messageItem, useColor)
        end
        
    end
    
end

function GUIWorldText:UpdateDamageMessage(message, messageItem, useColor, deltaTime)

    // Updating messages with new numbers shouldn't reset animation - keep it big and faded-in intead of growing
    local animationFraction = message.animationFraction
    if message.minimumAnimationFraction then
        animationFraction = math.max(animationFraction, message.minimumAnimationFraction)
    end
    
    local targetNumStr = string.gsub(message.text, ",", "")
    // Set damage number with commas. If we have a previous number, animate up to new number to portray total damage done.
    local targetNumber = tonumber(targetNumStr)
    
    // Remove commas out of string and convert to a number
    local numberString = string.gsub(messageItem:GetText(), ",", "")
    numberString = string.gsub(numberString, "-", "")
    local currentNumber = tonumber(numberString)
    
    if message.previousNumber ~= nil and type(currentNumber) == "number" then
    
        local newNumber = math.min((currentNumber + kWorldDamageNumberAnimationSpeed*deltaTime), targetNumber)
        messageItem:SetText("-" .. CommaValue(tostring(math.round(newNumber))))
        
    else
        messageItem:SetText("-" .. CommaValue(tostring(math.round(targetNumber))))
    end
    
    local player = Client.GetLocalPlayer()
    local viewCoords = player:GetViewCoords()
    
    // Adjust down a little so it doesn't overlap the reticle
    local inFrontOfPlayer = viewCoords.origin + viewCoords.zAxis * 1 - viewCoords.yAxis * .15
    
    // Blend between just below the crosshair to the actual world point - to make sure you always see the damage feedback!
    local animationScalar = math.sin(animationFraction * math.pi / 2)
    local worldInterpPosition = Vector( inFrontOfPlayer.x + (message.position.x - inFrontOfPlayer.x) * animationScalar, 
                                        inFrontOfPlayer.y + (message.position.y - inFrontOfPlayer.y) * animationScalar, 
                                        inFrontOfPlayer.z + (message.position.z - inFrontOfPlayer.z) * animationScalar)
    
    local direction = GetNormalizedVector(worldInterpPosition - viewCoords.origin)
    local inFront = viewCoords.zAxis:DotProduct(direction) > 0
    messageItem:SetIsVisible(inFront)

    screenPos = Client.WorldToScreen(worldInterpPosition)

    if not self.screenCenter then
        self.screenCenter = Vector(Client.GetScreenWidth()/2, Client.GetScreenHeight()/2, 0)
    end
    
    local toCenter = screenPos - self.screenCenter

    if toCenter:GetLength() < kMinDistanceToCenter then
        screenPos = self.screenCenter + GetNormalizedVectorXY(toCenter) * kMinDistanceToCenter
    end

    messageItem:SetPosition(screenPos)
    
    // Fades to invisible after half the life time
    useColor.a = Clamp(math.cos(animationFraction * math.pi / 2), 0, 1)
    messageItem:SetColor(useColor)

    // Grow and shrink fast, but use distance also
    local baseScale = 1 //50 / message.distance
    local animationScalar = Clamp(math.sin( 2 * animationFraction * math.pi), 0, 1)
    
    // Scale number's up the more damage we do
    local numberScalar = math.min(1 + (targetNumber / 500), 1)
    local scaleFactor = baseScale + animationScalar * 1 * numberScalar
    messageItem:SetScale(Vector(scaleFactor, scaleFactor, scaleFactor))

end

function GUIWorldText:UpdateRegularMessage(message, messageItem, useColor)

    // Animate as rising text
    local animYOffset = message.animationFraction * GUIWorldText.kYAnim    
    local position = Client.WorldToScreen(message.position)
    position.y = position.y + animYOffset
    useColor.a = 1 - message.animationFraction
    
    if message.messageType == kWorldTextMessageType.CommanderError then
        position.y = position.y + kCommanderMessageVerticalOffset
    end

    messageItem:SetText(message.text)
    messageItem:SetPosition(position)
    messageItem:SetColor(useColor)
    
    // Don't display messages that are behind us
    messageItem:SetIsVisible(message.inFront)

end