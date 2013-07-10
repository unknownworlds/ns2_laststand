// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\HotkeyMoveMixin.lua    
//    
//    Created by:   Marc Delorme (marc@unknownworlds.com)
//
//    REQUIRE: OverheadMoveMixin
//    Move the player in overhead mode when he use an hot key
//    
// =========== For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/FunctionContracts.lua")
Script.Load("lua/Mixins/OverheadMoveMixin.lua")

HotkeyMoveMixin = CreateMixin( HotkeyMoveMixin )
HotkeyMoveMixin.type = "CommanderMove"

HotkeyMoveMixin.expectedMixin =
{
    OverheadMove = "RTS view movement"
}

HotkeyMoveMixin.expectedCallbacks =
{
	ProcessNumberKeysMove = "Do everything instead of the mixin. TODO. Refactor that!"
}

HotkeyMoveMixin.expectedConstants =
{
}

/**
 * Move player when he press an hotkey.
 * TODO: Need to be refactor. All the code is in commander.
 *       It should be in this mixin.
 */
function HotkeyMoveMixin:UpdateMove(input)
	local position = Vector()

	if self:ProcessNumberKeysMove(input, position) then

		position = self:ConstrainToOverheadPosition(position)
		self:SetOrigin(position)
		
	end
end
AddFunctionContract(HotkeyMoveMixin.UpdateMove, { Arguments = { "Entity", "Move" }, Returns = { } })