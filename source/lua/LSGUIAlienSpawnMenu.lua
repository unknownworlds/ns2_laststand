class 'LSGUIAlienSpawnMenu' (GUIScript)

Script.Load('lua/SimpleGUI.lua')

local kFont = "fonts/AgencyFB_small.fnt"
local kLargeFont = "fonts/AgencyFB_large.fnt"

local kButtonWidth, kButtonHeight = 909, 192
local kBorderSize = 6
local kPadding = 8

local kAlienColor = Color(1, 0.76, 0.11, 1)

local kAlienTextures = {}
for i = 1, #kAlienDeck do
    table.insert(kAlienTextures, SGMakeRegion(string.format('ui/Lifeforms/Alien%02i.dds', i - 1), kButtonWidth, kButtonHeight))
end


function LSGUIAlienSpawnMenu:_AddChoice(parent)
    
    local slideTime = 0.6
    local maxWaitTime = 0.5
    local index = #self.choices
    local height = kButtonHeight + 2*kBorderSize
    local yOffset = index * (height + kPadding)
    
    local border = SGAddGraphic(self.menu, parent)
    border:SetAnchor(GUIItem.Left, GUIItem.Top)
    border:SetPosition(Vector(-1000, index * (height + kPadding), 0))
    border:SetSize(Vector(kButtonWidth + 2*kBorderSize, height, 0))
    border:SetColor(Color(0, 0, 0, 0))
    
    local button = SGAddGraphic(self.menu,border, kAlienTextures[1])
    button:SetAnchor(GUIItem.Left, GUIItem.Top)
    button:SetPosition(Vector(kBorderSize, kBorderSize, 0))
    button:SetInheritsParentAlpha(true)
    
    local randomDelay = math.random() * maxWaitTime
    local curve = SGDelay(SGEaseOutBounce, randomDelay, randomDelay + slideTime)
    SGAddPropertyAnim(self.menu, border, kSGPosition, Vector(0, yOffset, 0), randomDelay + slideTime, curve) 
    SGAddPropertyAnim(self.menu, border, kSGColor, Color(0, 0, 0, 1), randomDelay + slideTime, curve) 
    
    border.OnMouseEnter = function(item) 
        SGAddPropertyAnim(self.menu, border, kSGScale, Vector(1.05, 1.05, 1)) 
        SGAddPropertyAnim(self.menu, border, kSGColor, kAlienColor) 
    end
    
    border.OnMouseExit = function(item) 
        SGAddPropertyAnim(self.menu, border, kSGScale, Vector(1, 1, 1)) 
        SGAddPropertyAnim(self.menu, border, kSGColor, Color(0, 0, 0, 1))
    end

    border.OnSendKeyEvent = function(item, key, down)
        if key == InputKey.MouseButton0 and down then
            Client.SendNetworkMessage("SpawnAlien", { choice = index + 1 })
        end
    end    
    
    table.insert(self.choices, button)

end

function LSGUIAlienSpawnMenu:Initialize()
    
    self.choices = {}

    self.menu = SGCreateMenu()
    
    local background = SGAddGraphic(self.menu)
    SGSetSizeAndCenter(background, kButtonWidth + 2*kBorderSize, 3*(kButtonHeight + 2*kBorderSize) + 2*kPadding)
    background:SetColor(Color(0, 0, 0, 0))
       
    self:_AddChoice(background)
    self:_AddChoice(background)
    self:_AddChoice(background)
    
 
end


function LSGUIAlienSpawnMenu:Uninitialize()
    
    SGDestroyMenu(self.menu)
    self.menu = nil

end


function LSGUIAlienSpawnMenu:Update(deltaTime)
    SGUpdateMenu(self.menu, deltaTime)
end



function LSGUIAlienSpawnMenu:SendKeyEvent(key, down)    
    SGSendKeyEvent(self.menu, key, down)
end


function LSGUIAlienSpawnMenu:OnClose()

end

function LSGUIAlienSpawnMenu:SetAliens(aliens)
    for i = 1, #self.choices do
        local choice = self.choices[i]
        SGSetTexture(choice, kAlienTextures[aliens[i]])        
    end    
end

