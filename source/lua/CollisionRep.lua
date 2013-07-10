// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\CollisionReps.lua    
//
// Created by: Dushan Leska (dushan@unknownworlds.com) 
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

CollisionRep = enum
    {
        Default     = Shared.GetCollisionRepId("default"),
        Move        = Shared.GetCollisionRepId("move"),
        Damage      = Shared.GetCollisionRepId("damage"),
        Select      = Shared.GetCollisionRepId("select"),
        LOS         = Shared.GetCollisionRepId("los"),
    }
