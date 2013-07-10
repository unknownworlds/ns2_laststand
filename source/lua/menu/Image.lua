// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\menu\Image.lua
//
//    Created by:   Andreas Urwalek (a_urwa@sbox.tugraz.at)
//
// ========= For more inImageation, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/menu/MenuElement.lua")

class 'Image' (MenuElement)

function Image:Initialize()

    MenuElement.Initialize(self)

end

function Image:GetTagName()
    return "image"
end