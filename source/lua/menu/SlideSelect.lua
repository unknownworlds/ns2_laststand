// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\menu\SlideSelect.lua
//
//    Created by:   Andreas Urwalek (a_urwa@sbox.tugraz.at)
//
// ========= For more inSlideSelectation, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/menu/FormElement.lua")

class 'SlideSelect' (FormElement)

function SlideSelect:Initialize()

    FormElement.Initialize(self)

end

function SlideSelect:GetTagName()
    return "slider"
end