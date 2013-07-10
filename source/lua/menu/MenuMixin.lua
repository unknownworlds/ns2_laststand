// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\menu\MenuMixin.lua
//
//    Created by:   Andreas Urwalek (a_urwa@sbox.tugraz.at)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

local kDefaultMenuCursor = "ui/Cursor_MenuDefault.dds"

function HasMenuMixin(script)
    return script._menuMixinEnabled == true
end

function AddMenuMixin(script)

    assert(script ~= nil)

    script.windows = {}
    script.isVisible = false
    script.windowLayer = 0

    script.SetCursor = function(self, cursor)
        self.menuCursor = cursor
    end    

    script.SetIsVisible = function(self, isVisible)

        if self.isVisible ~= isVisible then
        
            local cursor = kDefaultMenuCursor
            if self.menuCursor then
                cursor = self.menuCursor
            end

            MouseTracker_SetIsVisible(isVisible, cursor, false)
            self.isVisible = isVisible
            self.mainWindow:SetIsVisible(isVisible)
            
            // don't bring up all sub windows, but always allow hiding
            for index, window in ipairs(self.windows) do

                if (window:GetInitialVisible() and isVisible) or not isVisible then
                    window:SetIsVisible(isVisible)
                end

            end  
        
        end

    end

    script.GetIsVisible = function(self)
        return self.isVisible
    end

    script.CreateWindow = function(self)

        local window = GetWindowManager():CreateWindow(self, self.windowLayer)
        table.insert(self.windows, window)
        return window

    end

    script.DestroyWindow = function(self, window)

        table.removevalue(self.windows, window)
        GetWindowManager():RemoveWindow(window, self.windowLayer)
        window:Uninitialize()

    end

    script.SetWindowLayer = function(self, windowLayer)
        if self.windowLayer ~= windowLayer and not self.windowLayer == 0 then
            Print("Warning: SetWindowLayer was already called once on this script.")
        end    
    
        self.windowLayer = windowLayer
    end
    
    script.DestroyAllWindows = function(self)
    
        for index, window in ipairs(self.windows) do
            GetWindowManager():RemoveWindow(window, self.windowLayer)
        end
        
        self.windows = {}
    
    end
    
    script._menuMixinEnabled = true

end