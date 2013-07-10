// ======= Copyright (c) 2003-2013, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Babbler.lua
//
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/ScriptActor.lua")
Script.Load("lua/Mixins/ClientModelMixin.lua")
Script.Load("lua/LiveMixin.lua")
Script.Load("lua/TeamMixin.lua")
Script.Load("lua/MobileTargetMixin.lua")
Script.Load("lua/DamageMixin.lua")
Script.Load("lua/EntityChangeMixin.lua")
Script.Load("lua/OwnerMixin.lua")
Script.Load("lua/TargetCacheMixin.lua")
Script.Load("lua/PathingMixin.lua")
Script.Load("lua/PhysicsGroups.lua")

kBabblerMoveType = enum({ 'None', 'Move', 'Cling', 'Attack', 'Wag' })

class 'Babbler' (ScriptActor)

Babbler.kMapName = "babbler"

Babbler.kModelName = PrecacheAsset("models/alien/babbler/babbler.model")
local kAnimationGraph = PrecacheAsset("models/alien/babbler/babbler.animation_graph")

Babbler.kMass = 15
Babbler.kRadius = .25
Babbler.kLinearDamping = 0
Babbler.kRestitution = .65

local kTargetSearchRange = 12
local kAttackRate = 0.37
local kLifeTime = 60 * 5

local kUpdateMoveInterval = 0.5
local kUpdateAttackInterval = 1
local kMinJumpDistance = 6
local kBabblerRunSpeed = 7
local kVerticalJumpForce = 6
local kMaxJumpForce = 15
local kMinJumpForce = 5
local kTurnSpeed = math.pi

local kBabblerClingDuration = -1

local networkVars =
{
    attacking = "boolean",
    targetId = "entityid",
    ownerId = "entityid",
    clinged = "boolean",
    doesGroundMove = "boolean",
    jumping = "boolean",
    wagging = "boolean",
    creationTime = "time",
    silenced = "boolean",
    // updates every 10 and [] means no compression used (not updates are send in this case)
    m_angles = "interpolated angles (by 10 [], by 10 [], by 10 [])",
    m_origin = "compensated interpolated position (by 0.05 [2 3 5], by 0.05 [2 3 5], by 0.05 [2 3 5])",
}

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ClientModelMixin, networkVars)
AddMixinNetworkVars(LiveMixin, networkVars)
AddMixinNetworkVars(TeamMixin, networkVars)

// shared:

local function CreateHitBox(self)

    if not self.hitBox then
    
        self.hitBox = Shared.CreatePhysicsSphereBody(false, Babbler.kRadius * 2, Babbler.kMass, self:GetCoords() )
        self.hitBox:SetGroup(PhysicsGroup.BabblerGroup)
        self.hitBox:SetCoords(self:GetCoords())
        self.hitBox:SetEntity(self)
        self.hitBox:SetPhysicsType(CollisionObject.Kinematic)
        self.hitBox:SetTriggeringEnabled(true)
        
    end

end

function Babbler:OnCreate()

    ScriptActor.OnCreate(self)

    InitMixin(self, BaseModelMixin)
    InitMixin(self, ClientModelMixin)
    
    InitMixin(self, LiveMixin)
    InitMixin(self, TeamMixin)
    InitMixin(self, DamageMixin)
    
    if Server then
    
        self.targetId = Entity.invalidId
        self.timeLastJump = 0
        self.timeLastAttack = 0
        self.jumpAttempts = 0
        self.silenced = false
        
        InitMixin(self, EntityChangeMixin)
        InitMixin(self, PathingMixin)
        
        self.targetId = Entity.invalidId
        
        self.moveType = kBabblerMoveType.None
        self.clinged = false
        self.attacking = false
        
        self.creationTime = Shared.GetTime()        
        
    elseif Client then
    
        self.oldModelIndex = 0
        self.clientJumping = self.jumping
        self.clientTimeLastAttack = 0
        self.clientClinged = self.clinged
        self.clientAttacking = self.attacking
        
    end
    
end

function Babbler:OnInitialized()

    self:SetModel(Babbler.kModelName, kAnimationGraph)
    
    if Server then

        InitMixin(self, MobileTargetMixin)
        InitMixin(self, TargetCacheMixin)
        
        self.targetSelector = TargetSelector():Init(
                                    self,
                                    kTargetSearchRange, 
                                    true,
                                    { kAlienStaticTargets, kAlienMobileTargets })  
        
        self:UpdateJumpPhysicsBody()
        
        self:AddTimedCallback(Babbler.MoveRandom, kUpdateMoveInterval + math.random())
        self:AddTimedCallback(Babbler.UpdateWag, 0.4)
        self:AddTimedCallback(Babbler.UpdateAttack, kUpdateAttackInterval)
        self:AddTimedCallback(Babbler.TimeUp, kLifeTime)     
        
        self:Jump(Vector(math.random() * 2 - 1, 4, math.random() * 2 - 1))
    
    end
    
end

function Babbler:OnDestroy()

    ScriptActor.OnDestroy(self)
    
    if self.physicsBody then
    
        Shared.DestroyCollisionObject(self.physicsBody)
        self.physicsBody = nil
        
    end
    
    if self.hitBox then
    
        Shared.DestroyCollisionObject(self.hitBox)
        self.hitBox = nil
        
    end
    
    if Client then
    
        local model = self:GetRenderModel()
        if model and self.addedToHiveVision then
            HiveVision_RemoveModel(model)
        end
    
    end

end


function Babbler:GetIsClinged()
    return self.clinged
end

function Babbler:GetTarget()

    local target = self.targetId ~= nil and Shared.GetEntity(self.targetId)
    return target

end

function Babbler:GetIsOnGround()
    return self:GetVelocity():GetLength() < 0.5
end

function Babbler:GetCanBeUsed(player, useSuccessTable)
    useSuccessTable.useSuccess = false    
end

function Babbler:GetVelocity()

    if self.physicsBody then
        return self.physicsBody:GetLinearVelocity()
    end
    return Vector(0, 0, 0)
    
end

// TODO: code assumes that babbler alway belong to team 2 (aliens), need to be fixed when more dynamic teams are done (alien vs. alien?)
local function UpdateRelevancy(self)

    local owner = self:GetOwner()
    local sighted = owner ~= nil and (owner:GetOrigin() - self:GetOrigin()):GetLengthSquared() < 16 and (HasMixin(owner, "LOS") and owner:GetIsSighted())

    local mask = bit.bor(kRelevantToTeam1Unit, kRelevantToTeam2Unit, kRelevantToReadyRoom, kRelevantToTeam2Commander)    
    if sighted then
        mask = bit.bor(mask, kRelevantToTeam1Commander)
    end
    
    self:SetExcludeRelevancyMask( mask )

end

local function UpdateBabbler(self, deltaTime)

    if Server then

        self:UpdateJumpPhysicsBody()    
        self:UpdateJumpPhysics(deltaTime)
        self:UpdateMove(deltaTime)
        self.attacking = self.timeLastAttack + 0.2 > Shared.GetTime()
        self.wagging = self.moveType == kBabblerMoveType.Wag
        
        UpdateRelevancy(self)

    elseif Client then
    
        self:UpdateMoveDirection(deltaTime)
        
        local localPlayerId = Client.GetLocalPlayer() ~= nil and Client.GetLocalPlayer():GetId()
        local model = self:GetRenderModel()
        if model ~= nil and self.ownerId == localPlayerId and not self.addedToHiveVision then
            HiveVision_AddModel(model)
            self.addedToHiveVision = true
        end
    
    end
    
    self.lastVelocity = self:GetVelocity()
    self.lastOrigin = self:GetOrigin()

end

function Babbler:OnUpdatePhysics()
    CreateHitBox(self)
    self.hitBox:SetCoords(self:GetCoords())
end

function Babbler:OnUpdate(deltaTime)

    PROFILE("Babbler:OnUpdate")

    ScriptActor.OnUpdate(self, deltaTime)
    
    UpdateBabbler(self, deltaTime)

end

function Babbler:OnProcessMove(input)
    UpdateBabbler(self, input.time)
    
    if Server then
        
        local parent = self:GetParent()
        if parent then
            self:SetOrigin(parent:GetOrigin())
        end
        
    end
    
end

function Babbler:GetPhysicsModelAllowedOverride()
    return false
end

if Server then

    local kEyeOffset = Vector(0, 0.2, 0)
    function Babbler:GetEyePos()
        return self:GetOrigin() + kEyeOffset
    end

    local function GetMoveVelocity(self, targetPos)

        moveVelocity = targetPos - self:GetOrigin()

        local moveSpeedXZ = moveVelocity:GetLengthXZ()

        if moveSpeedXZ > kMaxJumpForce then    
            moveVelocity:Scale(kMaxJumpForce / moveSpeedXZ)        
        elseif moveSpeedXZ < kMinJumpForce then
            moveVelocity:Scale(kMinJumpForce / (moveSpeedXZ + 0.0001) )
        end   
        
        moveVelocity.y = kVerticalJumpForce
        
        return moveVelocity

    end 

    function Babbler:OnEntityChange(oldId)
    
        if oldId == self.targetId then            
            self:SetMoveType(kBabblerMoveType.None)   
            self:Detach()
        end
    
    end
    
    function Babbler:GetTurnSpeedOverride()
        return kTurnSpeed
    end
    
    function Babbler:SetSilenced(silenced)
        self.silenced = silenced
    end
    
    function Babbler:Jump(velocity)

        self:SetGroundMoveType(false)
        if self.physicsBody then
            self.physicsBody:SetCoords(self:GetCoords())
            self.physicsBody:AddImpulse(self:GetOrigin(), velocity)
        end
        self.timeLastJump = Shared.GetTime()
    
    end
    
    function Babbler:Move(targetPos, deltaTime)

        self:SetGroundMoveType(true)

        local prevY = self:GetOrigin().y
        local done = self:MoveToTarget(PhysicsMask.AIMovement, targetPos, kBabblerRunSpeed, deltaTime)
        
        local newOrigin = self:GetOrigin()
        local desiredY = newOrigin.y + Babbler.kRadius
        newOrigin.y = Slerp(prevY, desiredY, deltaTime * 3)
        
        self:SetOrigin(newOrigin)        
        self.targetSelector:AttackerMoved() 
        
        return done
    
    end
    
    local function GetBabblerBall(self)

        for _, ball in ipairs(GetEntitiesForTeamWithinRange("BabblerPheromone", self:GetTeamNumber(), self:GetOrigin(), 20)) do
            
            if ball:GetOwner() == self:GetOwner() and (ball:GetOrigin() - self:GetOrigin()):GetLength() > 4 then
                return ball
            end    
    
        end
    
    end
    
    local function FindSomethingInteresting(self)
    
        PROFILE("Babbler:FindSomethingInteresting")
    
        local origin = self:GetOrigin()
        local searchRange = 7
        local targetPos = nil
        local randomTarget = self:GetOrigin() + Vector(math.random() * 4 - 2, 0, math.random() * 4 - 2) 
        
        if math.random() < 0.2 then        
            targetPos = randomTarget
        else
        
            local babblerBall = GetBabblerBall(self)
            
            if babblerBall then            
                targetPos = babblerBall:GetOrigin()            
            else
            
                local interestingTargets = { }
                table.copy(GetEntitiesWithMixinForTeamWithinRange("Live", self:GetTeamNumber(), origin, searchRange), interestingTargets, true)
                // cysts are very attractive, they remind us of the ball we like to catch!
                table.copy(GetEntitiesForTeamWithinRange("Cyst", self:GetTeamNumber(), origin, searchRange), interestingTargets, true)
            
                local numTargets = #interestingTargets
                if numTargets > 1 then
                    targetPos = interestingTargets[math.random (1, numTargets)]:GetOrigin()
                elseif numTargets == 1 then
                    targetPos = interestingTargets[1]:GetOrigin()
                else
                    targetPos = randomTarget
                end
                
            end    
        
        end
        
        return targetPos
    
    end
    
    function Babbler:UpdateWag()
    
        if self.moveType == kBabblerMoveType.Wag and self:GetIsOnGround() then
    
            local owner = self:GetOwner()            
            local activeWeapon = owner ~= nil and owner:GetActiveWeapon()
            
            if not owner or not activeWeapon or not activeWeapon:isa("BabblerAbility") or activeWeapon:GetRecentlyThrown() or (owner:GetOrigin() - self:GetOrigin()):GetLength() > 6 then
                self:SetMoveType(kBabblerMoveType.None)
            end
        
        end
    
        return self:GetIsAlive()
    
    end
    
    function Babbler:JumpRandom()
        self:Jump(Vector( (math.random() * 3) - 1.5, 3 + math.random() * 2, (math.random() * 3) - 1.5 ))    
    end
    
    function Babbler:MoveRandom()
    
        PROFILE("Babbler:MoveRandom")
    
        if self.moveType == kBabblerMoveType.None and self:GetIsOnGround() then
        
            // check for targets to attack
            local target = self.targetSelector:AcquireTarget()
            local owner = self:GetOwner()
            local activeWeapon = owner ~= nil and owner:GetActiveWeapon()
            
            if target then
                self:SetMoveType(kBabblerMoveType.Attack, target, target:GetOrigin())
                
            elseif owner and activeWeapon and activeWeapon:isa("BabblerAbility") and not activeWeapon:GetRecentlyThrown() and (owner:GetOrigin() - self:GetOrigin()):GetLength() <= 6 then    
                self:SetMoveType(kBabblerMoveType.Wag, owner, owner:GetOrigin())
                
            elseif owner and (self:GetOrigin() - owner:GetOrigin()):GetLength() > 8 then                
                // mama gorge is too far away, hurry back to the warm glowy belly!
                self:SetMoveType(kBabblerMoveType.Move, nil, owner:GetOrigin())
            
            else
            
                // nothing to do, find something "interesting" (maybe glowing)
                local targetPos = FindSomethingInteresting(self)
            
                if targetPos then
                    self:SetMoveType(kBabblerMoveType.Move, nil, targetPos)
                end 
            
            end

            // jump randomly
            if math.random() < 0.6 then
                self:JumpRandom()
            end
        
        end
        
        return self:GetIsAlive() 
        
    end
    
    function Babbler:SetIgnoreOrders(time)
        self.timeOrdersAllowed = Shared.GetTime() + time
    end
    
    local kEyeOffset = Vector(0, 0.3, 0)
    local function GetCanReachTarget(self, target)
    
        local obstacleNormal = Vector(0, 1, 0)
        
        local targetOrigin = HasMixin(target, "Target") and target:GetEngagementPoint() or target:GetOrigin()
        local trace = Shared.TraceRay(self:GetOrigin() + kEyeOffset, targetOrigin, CollisionRep.LOS, PhysicsMask.All, EntityFilterAll())
        
        local canReach = trace.fraction >= 0.9
        if canReach then
            return true, nil
        else
            obstacleNormal = trace.normal
        end
        
        return false, obstacleNormal
    
    end

    // try to jump into the enemy
    function Babbler:UpdateAttack()

        if self.moveType == kBabblerMoveType.Attack and self:GetIsOnGround() then

            local target = self:GetTarget()
            if not target or not target:GetIsAlive() then
            
                self:SetMoveType(kBabblerMoveType.None)
                return self:GetIsAlive()
            
            end
            
            local moveVel = nil
            local canReach, obstacleNormal = GetCanReachTarget(self, target)
            local babblerBall = GetBabblerBall(self)
            
            if babblerBall and babblerBall:GetId() ~= self.lastBabblerBallId then
                
                self.lastBabblerBallId = babblerBall:GetId()
                self:SetMoveType(kBabblerMoveType.Move, nil, babblerBall:GetOrigin())
                self:SetIgnoreOrders(1.5)
                
            elseif canReach then
        
                local moveVelocity = nil
                local targetVelocity = Vector(0,0,0)            
                if target.GetVelocity then
                    // babblers should not jump perfectly, so we don't consider the actual distance
                    targetVelocity = target:GetVelocity()
                end

                local destination = target:GetOrigin()
                if HasMixin(target, "Target") then
                    destination = target:GetEngagementPoint()
                end
                
                moveVel = GetMoveVelocity(self, destination + targetVelocity)
                
                self:Jump(moveVel)
            
            else

                self:SetMoveType(kBabblerMoveType.Move, nil, target:GetOrigin())
                self:SetIgnoreOrders(1.5)
            
            end
            
        end
        
        return self:GetIsAlive() 
        
    end
    
    function Babbler:SetGroundMoveType(isGround)
    
        if isGround ~= self.doesGroundMove then
            
            self.doesGroundMove = isGround
            self:ResetPathing()
            
            if self.doesGroundMove then
                if self.physicsBody then
                    self.physicsBody:SetPhysicsType(CollisionObject.Kinematic)
                end
            else
                // prevents us from getting teleported back when switching to ground move again
                self:ResetPathing()
                if self.physicsBody then
                    self.physicsBody:SetPhysicsType(CollisionObject.Dynamic)
                end
            end
            
        end
    
    end
    
    local function UpdateCling(self, deltaTime, distanceToTarget)
       
        local target = self:GetTarget()
        local success = false
        if target then

            local attachPointOrigin = target:GetFreeBabblerAttachPointOrigin()
            if attachPointOrigin then
            
                success = true
                local moveDir = GetNormalizedVector( attachPointOrigin - self:GetOrigin() )
  
                local distance = (self:GetOrigin() - attachPointOrigin):GetLength()
                local travelDistance = deltaTime * 7
  
                if distance < travelDistance then  
              
                    self.clinged = true  
                    travelDistance = distance

                    target:AttachBabbler(self)
                    
                end
  
                // disable physic simulation
                self:SetGroundMoveType(true)
                self:SetOrigin( self:GetOrigin() + moveDir * travelDistance )
                
            end
            
        end
        
        if not success then
            self:Detach()
        end    
    
    end
    
    local kDetachOffset = Vector(0, 0.3, 0)
    
    function Babbler:Detach()
    
        local target = self:GetTarget()
        self.clinged = false
        
        if target and HasMixin(target, "BabblerCling") then
        
            target:DetachBabbler(self)
            self:SetOrigin(self:GetOrigin() + kDetachOffset)
            self:UpdateJumpPhysicsBody()
            self:SetMoveType(kBabblerMoveType.None)
            self:JumpRandom()
        
        end
    
    end
    
    local function UpdateClingAttached(self)
    
        local target = self:GetTarget()
        if target and target:GetIsAlive() then  
  
            // disable physic simulation, match coords with attach point
            self:SetGroundMoveType(true)
            
        else 
            self:Detach()            
        end 
    
    end
    
    local function UpdateTargetPosition(self)
    
        local target = self:GetTarget()
        if self.moveType == kBabblerMoveType.Cling and target then            
            self.targetPosition = target:GetFreeBabblerAttachPointOrigin()            
        end
    
    end
    
    local function NoObstacleInWay(self, targetPosition)

        local trace = Shared.TraceRay(self:GetOrigin() + kEyeOffset, targetPosition, CollisionRep.LOS, PhysicsMask.All, EntityFilterAll())
        return trace.fraction == 1

    end

    function Babbler:UpdateMove(deltaTime)
    
        PROFILE("Babbler:UpdateMove")
        
        UpdateTargetPosition(self)
        
        if self.clinged then

            UpdateClingAttached(self)
    
        elseif self.moveType == kBabblerMoveType.Move or self.moveType == kBabblerMoveType.Cling then
        
            if self:GetIsOnGround() then
            
                if self.moveType == kBabblerMoveType.Cling and self.targetPosition and (self:GetOrigin() - self.targetPosition):GetLength() < 3 then
                
                    UpdateCling(self, deltaTime, distanceToTarget)
                    success = true
            
                elseif self.timeLastJump + 0.5 < Shared.GetTime() then

                    local targetPosition = self.targetPosition or ( self:GetTarget() and self:GetTarget():GetOrigin())                    
                    if targetPosition then
                    
                        local distance = math.max(0, ((self:GetOrigin() - targetPosition):GetLength() - kMinJumpDistance))
                        local shouldJump = math.random()
                        local jumpProbablity = 0 

                        if distance > 0 then
                            jumpProbablity = distance / 5
                        end

                        local done = false
                        if self.jumpAttempts < 3 and jumpProbablity >= shouldJump and NoObstacleInWay(self, targetPosition) then
                            done = self:Jump(GetMoveVelocity(self, targetPosition))
                            self.jumpAttempts = self.jumpAttempts + 1
                        else
                            done = self:Move(targetPosition, deltaTime)
                        end
                        
                        if done or (self:GetOrigin() - targetPosition):GetLengthXZ() < 0.5 then
                            if self.physicsBody then
                                self.physicsBody:SetCoords(self:GetCoords())
                            end
                            self:SetMoveType(kBabblerMoveType.None)
                        end
                        
                        success = true
                    
                    end
                
                end
                
                if not success then
                    self:SetMoveType(kBabblerMoveType.None)
                end
            
            end

        end
        
        self.jumping = not self:GetIsOnGround()

    end
    
    function Babbler:OnKill()

        self:TriggerEffects("death", {effecthostcoords = Coords.GetTranslation(self:GetOrigin()) })
        DestroyEntity(self)
        
    end
    
    function Babbler:TimeUp()

        self:TriggerEffects("death", {effecthostcoords = Coords.GetTranslation(self:GetOrigin()) })
        DestroyEntity(self)
        
    end
    
    function Babbler:UpdateJumpPhysics(deltaTime)
    
        local velocity = self:GetVelocity()
        local origin = self:GetOrigin()
        
        // simulation is updated only during jumping
        if self.physicsBody and not self.doesGroundMove then

            // If the Babbler has moved outside of the world, destroy it
            local coords = self.physicsBody:GetCoords()
            local origin = coords.origin
            
            local maxDistance = 1000
            
            if origin:GetLengthSquared() > maxDistance * maxDistance then
                Print( "%s moved outside of the playable area, destroying", self:GetClassName() )
                DestroyEntity(self)
            else
                // Update the position/orientation of the entity based on the current
                // position/orientation of the physics object.
                self:SetCoords( coords )
            end
            
            if self.lastVelocity ~= nil then
            
                local delta = velocity - self.lastVelocity
                if delta:GetLengthSquaredXZ() > 0.0001 then
              
                    local endPoint = self.lastOrigin + self.lastVelocity * (deltaTime + Babbler.kRadius * 3)
                    
                    local trace = Shared.TraceCapsule(self.lastOrigin, endPoint, Babbler.kRadius, 0, CollisionRep.Damage, PhysicsMask.Bullets, EntityFilterOne(self))
                    self:ProcessHit(trace.entity, trace.surface)

                end
                
            end
            
            if self.targetSelector then
                self.targetSelector:AttackerMoved()
            end
        
        end
    
    end

    function Babbler:GetSendDeathMessageOverride()
        return false
    end

    function Babbler:SetVelocity(velocity)

        self.desiredVelocity = velocity
        if self.physicsBody then
            self.physicsBody:SetLinearVelocity(velocity)
        end
        self.lastVelocity = velocity
        
    end

    // creates physic object used for jump simulation
    function Babbler:UpdateJumpPhysicsBody()

        if not self.physicsBody and not self.clinged then

            self.physicsBody = Shared.CreatePhysicsSphereBody(true, Babbler.kRadius, Babbler.kMass, self:GetCoords() )
            self.physicsBody:SetGravityEnabled(true)
            self.physicsBody:SetGroup(PhysicsGroup.ProjectileGroup)        
            self.physicsBody:SetGroupFilterMask(PhysicsMask.BabblerMovement)

            self.physicsBody:SetCCDEnabled(false)
            self.physicsBody:SetPhysicsType( CollisionObject.Dynamic )
            self.physicsBody:SetLinearDamping(Babbler.kLinearDamping)
            self.physicsBody:SetRestitution(Babbler.kRestitution)
            
        elseif self.clinged and self.physicsBody then
        
            Shared.DestroyCollisionObject(self.physicsBody)
            self.physicsBody = nil

        end
        
    end

    function Babbler:SetGravityEnabled(state)
        if self.physicsBody then
            self.physicsBody:SetGravityEnabled(state)
        else
            Print("%s:SetGravityEnabled(%s) - Physics body is nil.", self:GetClassName(), tostring(state))
        end
    end  

    local kMoveTypeEffectNames =
    {
        [kBabblerMoveType.Attack] = "babbler_engage",
        [kBabblerMoveType.Wag] = "babbler_wag_begin",
        
    }

    local function OnMoveTypeChanged(self)
        
        local effectName = kMoveTypeEffectNames[self.moveType]
        if effectName then
            self:TriggerEffects(effectName)
        end
        
    end
    
    local function GetIgnoreOrders(self)
        return self.clinged or (self.timeOrdersAllowed and self.timeOrdersAllowed > Shared.GetTime())
    end

    function Babbler:SetMoveType(moveType, target, position, force)

        local targetId = Entity.invalidId
        if target then
            targetId = target:GetId()
        end
        
        if force or ( (moveType ~= self.moveType or targetId ~= self.targetId or self.targetPosition ~= position) and not GetIgnoreOrders(self) ) then

            self.moveType = moveType
            self.targetId = targetId
            self.targetPosition = position
            
            if moveType == kBabblerMoveType.None then
                // makes sure that babbler will fall down when move ends
                self:SetGroundMoveType(false)
            end    

            self.jumpAttempts = 0
            OnMoveTypeChanged(self)
            
            if force then
                self:SetIgnoreOrders(1)
            end
            
        end

    end
        
    function Babbler:ProcessHit(entityHit, surface)

        if entityHit then

            if HasMixin(entityHit, "Live") and HasMixin(entityHit, "Team") and entityHit:GetTeamNumber() ~= self:GetTeamNumber() then
            
                if self.timeLastAttack + kAttackRate < Shared.GetTime() then
                    
                    self.timeLastAttack = Shared.GetTime()
                    
                    local targetOrigin = nil
                    if entityHit.GetEngagementPoint then
                        targetOrigin = entityHit:GetEngagementPoint()
                    else
                        targetOrigin = entityHit:GetOrigin()
                    end
                    
                    //local attackDirection = self:GetOrigin() - targetOrigin
                    //attackDirection:Normalize()
                    
                    self:DoDamage(kBabblerDamage, entityHit, self:GetOrigin(), nil, surface)
                
                end
                
            end
            
        end

    end 
    
    function Babbler:GetShowHitIndicator()
        return true
    end

elseif Client then

    function Babbler:OnAdjustModelCoords(modelCoords)

        if not self:GetIsClinged() and self.moveDirection then
            modelCoords = Coords.GetLookIn(modelCoords.origin, self.moveDirection)
            modelCoords.origin.y = modelCoords.origin.y - Babbler.kRadius
        end
    
        return modelCoords
    
    end
    
    function Babbler:UpdateMoveDirection(deltaTime)

        if self.clientClinged ~= self.clinged then
        
            //self:TriggerEffects("babbler_cling")
            self.clientClinged = clinged
        
        end

        if self.clientJumping ~= self.jumping and self.jumping then
            self:TriggerEffects("babbler_jump") 
        end

        if self.clientAttacking ~= self.attacking and self.attacking then
            self:TriggerEffects("babbler_attack")
        end
        
        if self.clientGroundMove ~= self.doesGroundMove and self.doesGroundMove then
            self:TriggerEffects("babbler_move")
        end
        
        self.clientGroundMove = self.doesGroundMove
        
        if self.lastOrigin then
        
            if not self.moveDirection then
                self.moveDirection = Vector(0, 0, 0)
            end
            
            local moveDirection = GetNormalizedVectorXZ(self:GetOrigin() - self.lastOrigin)
            
            local target = self:GetTarget()
            if target then
                local targetPosition = target:GetOrigin()
                moveDirection = GetNormalizedVectorXZ(targetPosition - self:GetOrigin())
            end
            
            // smooth out turning of babblers
            self.moveDirection = self.moveDirection + moveDirection * deltaTime * (moveDirection - self.moveDirection):GetLength() * 5
            self.moveDirection:Normalize()
            
            if deltaTime > 0 then
                self.clientVelocity = (self:GetOrigin() - self.lastOrigin) / deltaTime
            end
            
        end
        
        self.clientJumping = self.jumping
        self.clientAttacking = self.attacking
        self.clientTimeLastAttack = self.timeLastAttack 

        
    end
    
    function Babbler:OnUpdateAnimationInput(modelMixin)
    
        PROFILE("Babbler:OnUpdateAnimationInput")
    
        local move = "idle"
        if self.jumping then
            move = "jump"
        elseif self.doesGroundMove then
            move = "run"
        elseif self.wagging then
            move = "wag"
        end
        
        modelMixin:SetAnimationInput("move", move)
        modelMixin:SetAnimationInput("attacking", self.attacking)

    end
    
    function Babbler:OnUpdatePoseParameters()
    
        PROFILE("Babbler:OnUpdateAnimationInput")
    
        local moveSpeed = 0
        local moveYaw = 0
        
        if self.clientVelocity then    

            local coords = self:GetCoords()
            local moveDirection = ConditionalValue(self.clientVelocity:GetLengthXZ() > 0, GetNormalizedVectorXZ(self.clientVelocity), self.moveDirection)
            local x = Math.DotProduct(coords.xAxis, moveDirection)
            local z = Math.DotProduct(coords.zAxis, moveDirection)
            
            moveYaw = Math.Wrap(Math.Degrees( math.atan2(z,x) ), -180, 180) + 180
            moveSpeed = Clamp(self.clientVelocity:GetLength() / kBabblerRunSpeed, 0, 1)
        
        end
        
        self:SetPoseParam("move_speed", moveSpeed)
        self:SetPoseParam("move_yaw", moveYaw)
        
    end
    
    // hide babblers which are clinged on the local player to not obscure their view
    function Babbler:OnGetIsVisible(visibleTable, viewerTeamNumber)
        
        local parent = self:GetParent()
        if parent and (parent == Client.GetLocalPlayer() or (HasMixin(parent, "Cloakable") and parent:GetIsCloaked()) ) then
            visibleTable.Visible = false
        end
    
    end

end

function Babbler:GetEffectParams(tableParams)
    tableParams[kEffectFilterSilenceUpgrade] = self.silenced
end

function Babbler:GetDeathIconIndex()
    return kDeathMessageIcon.Babbler
end

Shared.LinkClassToMap("Babbler", Babbler.kMapName, networkVars, true)