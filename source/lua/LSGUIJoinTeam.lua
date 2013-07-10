class 'LSGUIJoinTeam' (GUIScript)

Script.Load('lua/SimpleGUI.lua')

local kFont = "fonts/AgencyFB_small.fnt"
local kLargeFont = "fonts/AgencyFB_large.fnt"

local kPromptGap = 34
local kChooseSideGap = 80

local kChooseTeamAtlas = SGMakeAtlas("ui/ChooseTeam.dds", {
    prompt = { 1, 1, 128, 599 },
    marines = { 130, 1, 395, 587 },
    aliens = { 526, 1, 395, 587 }
})


function LSGUIJoinTeam:_AddJoinButton(background, xOffset, teamIndex, region, borderSize, selectedColor, slideDir)

    local notSelectedColor = Color(0, 0, 0, 0.5)
    local width, height = SGGetRegionSize(region)
    
    local buttonFrame = SGAddGraphic(self.menu, background)
    buttonFrame:SetSize(Vector(width + 2*borderSize, height + 2*borderSize, 0))
    buttonFrame:SetAnchor(GUIItem.Left, GUIItem.Top)    
    buttonFrame:SetPosition(Vector(xOffset + slideDir*400, 0, 0))
    buttonFrame:SetColor(Color(0, 0, 0, 0))
    
    local button = SGAddGraphic(self.menu, buttonFrame, region)    
    button:SetAnchor(GUIItem.Left, GUIItem.Top)    
    button:SetPosition(Vector(borderSize, borderSize, 0))
    button:SetInheritsParentAlpha(true)

    function enableButton()
        
        buttonFrame.isMouseOver = false
        buttonFrame.OnMouseEnter = function(item) 
            SGAddPropertyAnim(self.menu, buttonFrame, kSGScale, Vector(1.08, 1.08, 1)) 
            SGAddPropertyAnim(self.menu, buttonFrame, kSGColor, selectedColor) 
        end
        
        buttonFrame.OnMouseExit = function(item) 
            SGAddPropertyAnim(self.menu, buttonFrame, kSGScale, Vector(1, 1, 1)) 
            SGAddPropertyAnim(self.menu, buttonFrame, kSGColor, notSelectedColor)
        end
        
        buttonFrame.OnSendKeyEvent = function(item, key, down)
            if key == InputKey.MouseButton0 and down then
                Client.SendNetworkMessage("JoinTeam", { teamIndex = teamIndex })
            end
        end    
    end

    SGAddPropertyAnim(self.menu, buttonFrame, kSGColor, notSelectedColor, 0.4)
    SGAddPropertyAnim(self.menu, buttonFrame, kSGPosition, Vector(xOffset, 0, 0), 0.8, SGEaseOutBounce, enableButton)
        
    return buttonFrame
 
end


function LSGUIJoinTeam:Initialize()

    self.menu = SGCreateMenu()
    
    local promptWidth, promptHeight = SGGetRegionSize(kChooseTeamAtlas.prompt)
    local marinesWidth, marinesHeight = SGGetRegionSize(kChooseTeamAtlas.marines)
    local borderSize = (promptHeight - marinesHeight) / 2
    local menuWidth = promptWidth + 2*marinesWidth + 4*borderSize + kPromptGap + kChooseSideGap
    local marinesOffset = promptWidth + kPromptGap
    local aliensOffset = marinesOffset + 2*borderSize + marinesWidth + kChooseSideGap
    local marineColor = Color(0, 0, 1, 1)
    local alienColor = Color(1, 0.76, 0.11, 1)
        
    local background = SGAddGraphic(self.menu)
    SGSetSizeAndCenter(background, menuWidth, promptHeight)
    background:SetColor(Color(0, 0, 0, 0))    
    
    local prompt = SGAddGraphic(self.menu, background, kChooseTeamAtlas.prompt)
    prompt:SetAnchor(GUIItem.Left, GUIItem.Top)
    prompt:SetColor(Color(1, 1, 1, 0))
    SGAddPropertyAnim(self.menu, prompt, kSGColor, Color(1, 1, 1, 0.8), 1.5, SGDelay(SGEaseOutCubic, 1.2, 1.5))

    self.marines = self:_AddJoinButton(background, marinesOffset, kTeam1Index, kChooseTeamAtlas.marines, borderSize, marineColor, -1)
    self.aliens = self:_AddJoinButton(background, aliensOffset, kTeam2Index, kChooseTeamAtlas.aliens, borderSize, alienColor, 1)
         
end


function LSGUIJoinTeam:Uninitialize()

    SGDestroyMenu(self.menu)
    self.menu = nil

end


function LSGUIJoinTeam:Update(deltaTime)
    SGUpdateMenu(self.menu, deltaTime)
end

function LSGUIJoinTeam:SendKeyEvent(key, down)
    SGSendKeyEvent(self.menu, key, down)
end

function LSGUIJoinTeam:OnClose()

end
