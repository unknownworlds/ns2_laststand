// ======= Copyright (c) 2013, Unknown Worlds Entertainment, Inc. All rights reserved. ==========
//
// lua\GUITipVideo.lua
//
// Created by: Steven An (steve@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

gTipVideoUrlPrefix = "file:///ns2/tipvideos/"
Script.Load("lua/GUITipVideo_Data.lua") // Load auto-gen list of tip videos

local kBlankUrl = "temptemp"
local kTipViewURL = "file:///ns2/web/client_game/tipvideo_widget_html5.html"
local kTextureName = "*tip_video_webview_texture"
local kSlideInSecs = 1.0
local kFadeOutSecs = 0.5
local kAfterDeathDelay = 3.5
local kMaxPlaySecs = 7.0    // this is additional to slide-in time
local kWidgetRightMargin = 20
local kTipTextHeight = 50
local kBackgroundAlpha = 0.5
local kVideoPad = 5
local kMaxPlaysPerVideo = 2

// This is how large the web-view should be, in "HTML space."
// Our videos will be 720p, so this should at least by 1280x720 pixels high, also allow 200 pixels for the margins
local webViewWidth = 720
local webViewHeight = 480

local function ToNextTip(player)

    // Try to play the least-played video

    local leastPlays = 0
    local leastPlayedRelevance = 0
    local leastPlayedIndex = -1

    for itip = 1, #gTipVideos do

        local tip = gTipVideos[itip]
        local nplays = Client.GetOptionInteger("tipvids/"..tip.key, 0)

        if tip.teamNumber ~= player:GetTeamNumber() or nplays >= kMaxPlaysPerVideo then
            // never play vids for the other team, and don't play a vid too many times
        else

            // Use relevancy to break ties
            local relevance = 
                ConditionalValue( player:isa(tip.playerClass), 1, 0 )

            //DebugPrint("tip %d nplays %d rel %d", itip, nplays, relevance)

            if (nplays < leastPlays) or (nplays == leastPlays and relevance > leastPlayedRelevance) or leastPlayedIndex == -1 then
                leastPlays = nplays
                leastPlayedIndex = itip
                leastPlayedRelevance = relevance
            end

        end

    end

    if leastPlayedIndex >= 0 then

        local tip = gTipVideos[ leastPlayedIndex ]
        Client.SetOptionInteger("tipvids/"..tip.key, leastPlays+1)
        return tip

    else
        return nil
    end
end

//----------------------------------------
//  
//----------------------------------------
class "GUITipVideo" (GUIScript)

function GUITipVideo:Initialize()

    GUIScript.Initialize(self)
    
    // Compute size/pos
    local webAspect = webViewWidth / webViewHeight
    local wt = Client.GetScreenWidth() * 0.3
    local videoWt = wt - 2*kVideoPad
    local videoHt = videoWt / webAspect
    local ht = videoHt + kTipTextHeight + 2*kVideoPad
    local y = Client.GetScreenHeight()/2.0 - ht/2.0
    
    self.video = GUI.CreateItem()
    self.video:SetColor( Color(1.0,1.0,1.0,1.0) )
    self.video:SetInheritsParentAlpha( true )
    self.video:SetPosition(Vector(kVideoPad, kVideoPad, 0))
    self.video:SetSize( Vector(videoWt, videoHt, 0) )
    self.video:SetTexture( kTextureName )
    self.videoWebView = Client.CreateWebView( webViewWidth, webViewHeight )
    self.videoWebView:SetTargetTexture( kTextureName )

    self.tipText = GUI.CreateItem()
    self.tipText:SetOptionFlag(GUIItem.ManageRender)
    self.tipText:SetInheritsParentAlpha( true )
    self.tipText:SetPosition(Vector(kVideoPad*2, videoHt+3*kVideoPad+5, 0))
    self.tipText:SetTextAlignmentX(GUIItem.Align_Min)
    self.tipText:SetTextAlignmentY(GUIItem.Align_Center)
    self.tipText:SetAnchor( GUIItem.Left, GUIItem.Top )
    self.tipText:SetTextClipped( true, math.floor(wt)-2*kVideoPad, math.floor(kTipTextHeight) )
    self.tipText:SetFontName("fonts/AgencyFB_small.fnt")

    self.background = GUIManager:CreateGraphicItem()
    self.background:SetColor( Color(0.0, 0.0, 0.0, kBackgroundAlpha) )
    self.background:SetPosition(Vector(0, 0, 0))
    self.background:SetSize( Vector(wt, ht, 0) )
    self.background:SetInheritsParentAlpha( true )

    self.widget = GUIManager:CreateGraphicItem()
    self.widget:SetColor( Color(1.0, 1.0, 1.0, 1.0) )
    self.widget:SetPosition(Vector(0, y, 0))
    self.widget:SetSize( Vector(0, 0, 0) )
    self.widget:AddChild(self.background)
    self.widget:AddChild(self.video)
    self.widget:AddChild(self.tipText)
    self.widget:SetIsVisible(false)
    self.widget:SetLayer(kGUILayerTipVideos)

    self.state = "hidden"
    self.videoWebView:SetIsVisible(false)

    // init vars just in case
    self.sinceDeath = 0
    self.sinceHide = 0
    self.tip = nil

end

local function Destroy(self)

    self.widget:SetIsVisible(false)
    self.videoWebView:SetIsVisible(false)
    self.videoWebView:LoadUrl(kBlankUrl)

    if self.widget then
        GUI.DestroyItem( self.widget )
        self.widget = nil
    end

    if self.videoWebView then
        Client.DestroyWebView( self.videoWebView )
        self.videoWebView = nil
    end

end

function GUITipVideo:Uninitialize()

    Destroy(self)

end


local function Hide(self)

    self.state = "hiding"
    self.sinceHide = 0.0
    self.tip = nil

end

// Returns true if we must hide the video asap - ie. the player disabled hints, or player is playing the game
local function GetMustHideVideo()

    local isEnabled = Client.GetOptionBoolean("showHints", true)
    local player = Client.GetLocalPlayer()

    return not isEnabled
    or player == nil
    // only hide the vid if the player is CONTROLLING a live player - cuz if they're just spectating a live player, we should be playing!
    or (Client.GetIsControllingPlayer() and player:GetIsAlive())
    or GetGameInfoEntity():GetState() ~= kGameState.Started

end

function GUITipVideo:Update(dt)

    GUIScript.Update(self, dt)

    if not self.videoWebView then
        // did not init successfully
        return
    end
    
    if self.state == "playerIsDead" then

        self.sinceDeath = self.sinceDeath + dt

        if GetMustHideVideo() then
            Hide(self)
        elseif self.sinceDeath > kAfterDeathDelay then

            if self.tip then

                // load the widget page
                self.tip.volume = Client.GetOptionInteger("soundVolume", 50) / 100.0
                self.tip.delaySecs = kSlideInSecs    // don't have the video play until we are done sliding in
                //DebugPrint("encode tip: "..json.encode(self.tip))
                self.videoWebView:LoadUrl(kTipViewURL.."?"..json.encode(self.tip))

                // Setup tip text
                local player = Client.GetLocalPlayer()
                self.tipText:SetText( SubstituteBindStrings(Locale.ResolveString(self.tip.key)) )
                self.tipText:SetColor( kChatTextColor[player:GetTeamType()] )

                self.state = "loadingHtml"

            else
                Hide(self)
            end

        end

    elseif self.state == "loadingHtml" then

        if GetMustHideVideo() then
            Hide(self)
        elseif self.videoWebView:GetUrlLoaded() then

            self.sincePlay = 0.0
            self.state = "playing"

            local color = self.widget:GetColor()
            color.a = 1.0
            self.widget:SetColor( color )
            self.videoWebView:SetIsVisible(true)

        end

    elseif self.state == "playing" then
        // Video is sliding in or playing
   
        if GetMustHideVideo() then
            Hide(self)
        else

            self.sincePlay = self.sincePlay + dt
            local pos = self.widget:GetPosition()

            local widgetWidth = self.background:GetSize().x
            local startX = Client.GetScreenWidth()
            local endX = Client.GetScreenWidth() - widgetWidth - kWidgetRightMargin

            if self.sincePlay < kSlideInSecs then
                local alpha = Easing.outBounce( self.sincePlay, 0.0, 1.0, kSlideInSecs )
                pos.x = (1-alpha)*startX + alpha*endX
            else
                pos.x = endX
            end
            
            self.widget:SetPosition(pos)
            self.widget:SetIsVisible(true)  // set vis here rather than in loadingHtml, to avoid position-related flash

            if self.sincePlay > (kMaxPlaySecs+kSlideInSecs) then
                Hide(self)
            end

        end
        
    elseif self.state == "hiding" then
    
        self.sinceHide = self.sinceHide + dt

        local alpha = 1.0 - math.min( self.sinceHide / kFadeOutSecs, 1.0 )
        local color = self.widget:GetColor()
        color.a = alpha
        self.widget:SetColor( color )
        
        if alpha <= 0.0 then
            self.widget:SetIsVisible(false)
            self.videoWebView:SetIsVisible(false)
            self.videoWebView:LoadUrl(kBlankUrl)
            self.state = "hidden"
        end
        
    elseif self.state == "hidden" then

        // we are hidden, are presumably the player is still dead
        // do not even consider showing again until player respawns

        local player = Client.GetLocalPlayer()

        if player
        and player:GetIsOnPlayingTeam()
        and player:GetIsAlive()
        and Client.GetIsControllingPlayer() then

            self.state = "waitingForPlayerDeath"

        end

    elseif self.state == "waitingForPlayerDeath" then
    
        local player = Client.GetLocalPlayer()
        local isEnabled = Client.GetOptionBoolean("showHints", true)
        local justDied = not player:GetIsAlive() and Client.GetIsControllingPlayer()

        if isEnabled and justDied then

            // player just died
            self.sinceDeath = 0.0
            self.state = "playerIsDead"

            // Decide which tip to play right here, since the player ent will be gone soon
            self.tip = ToNextTip(player)

        end
        
    end
    
end

//Event.Hook("Console_tipvids", function(enabled) gEnabled = enabled == "1" end)
Event.Hook("Console_resettipvids",
        function(enabled)
            for itip = 1, #gTipVideos do

                local tip = gTipVideos[itip]
                Client.SetOptionInteger("tipvids/"..tip.key, 0)

            end
        end)

