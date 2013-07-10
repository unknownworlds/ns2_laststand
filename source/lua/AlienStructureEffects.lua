// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\AlienStructureEffects.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
kAlienStructureEffects = 
{
    shift_echo =
    {
        shiftEchoEffects =
        {
            {cinematic = "cinematics/alien/shift/echo_target.cinematic", done = true},
            {sound = "sound/NS2.fev/alien/structures/shift/energize", done = true},
        }    
    },
    
    babbler_hatch =
    {
        babblerEggLandEffects =
        {
            {cinematic = "cinematics/alien/babbler/spawn.cinematic" },
            {sound = "", silenceupgrade = true, done = true},
            {sound = "sound/NS2.fev/alien/drifter/attack", world_space = true, done = true},
        },
    },

    structure_land =
    {
        structureLand =
        {
            // Cinematic doesn't exist.
            //{cinematic = "cinematics/alien/structure_land.cinematic", classname = "Clog", done = true},
            //{cinematic = "cinematics/alien/structure_land.cinematic", done = true},
        },
    },

    construct =
    {
        alienConstruct =
        {
            {sound = "sound/NS2.fev/alien/structures/generic_build", isalien = true, done = true},
        },
    },
    
    hatch =
    {
        recallEffects =
        {
            {sound = "sound/NS2.fev/alien/structures/shift/recall"},
            {cinematic = "cinematics/alien/shift/hatch.cinematic", done = true},
        }    
    },
    
    death =
    {
        alienStructureDeathParticleEffect =
        {        
            // Plays the first effect that evalutes to true
            {cinematic = "cinematics/alien/structures/death_small.cinematic", classname = "Clog", done = true},
            {cinematic = "cinematics/alien/structures/death_hive.cinematic", classname = "Hive", done = true},
            {cinematic = "cinematics/alien/structures/death_large.cinematic", classname = "Whip", done = true},
            
            {cinematic = "cinematics/alien/structures/death_small.cinematic", classname = "Veil", done = true},
            {cinematic = "cinematics/alien/structures/death_small.cinematic", classname = "Shell", done = true},
            {cinematic = "cinematics/alien/structures/death_small.cinematic", classname = "Spur", done = true},
            
            {cinematic = "cinematics/alien/structures/death_small.cinematic", classname = "Crag", done = true},
            {cinematic = "cinematics/alien/structures/death_small.cinematic", classname = "Shade", done = true},
            {cinematic = "cinematics/alien/structures/death_small.cinematic", classname = "Shift", done = true},
            
            {cinematic = "cinematics/alien/structures/death_harvester.cinematic", classname = "Harvester", done = true},
            {cinematic = "cinematics/alien/babbler/death.cinematic", classname = "Babbler", done = true},
            {cinematic = "cinematics/alien/structures/death_small.cinematic", classname = "BabblerEgg", done = true},
            {cinematic = "cinematics/alien/structures/death_small.cinematic", classname = "Cyst", done = true},
            {cinematic = "cinematics/alien/structures/death_small.cinematic", classname = "TunnelEntrance", done = true},
            
            {cinematic = "cinematics/alien/infestationspike/death.cinematic", classname = "BoneWall", done = true},
        },
        
        alienStructureDeathSounds =
        {
            
            {sound = "sound/NS2.fev/alien/structures/harvester_death", classname = "Harvester"},
            {sound = "sound/NS2.fev/alien/structures/hive_death", classname = "Hive"},
            {sound = "sound/NS2.fev/alien/structures/death_grenade", classname = "Structure", doer = "Grenade", isalien = true, done = true},
            {sound = "sound/NS2.fev/alien/structures/death_axe", classname = "Structure", doer = "Axe", isalien = true, done = true},            
            {sound = "sound/NS2.fev/alien/structures/death_small", classname = "Structure", isalien = true, done = true},
            {sound = "sound/NS2.fev/alien/structures/death_small", classname = "Clog", done = true},
            {sound = "sound/NS2.fev/alien/structures/death_small", classname = "Cyst", done = true},
            {sound = "sound/NS2.fev/alien/structures/death_small", classname = "TunnelEntrance", done = true},
            
            {sound = "sound/NS2.fev/alien/structures/death_small", classname = "Veil", done = true},
            {sound = "sound/NS2.fev/alien/structures/death_small", classname = "Shell", done = true},
            {sound = "sound/NS2.fev/alien/structures/death_small", classname = "Spur", done = true},
            
            {sound = "sound/NS2.fev/alien/structures/death_small", classname = "Crag", done = true},
            {sound = "sound/NS2.fev/alien/structures/death_small", classname = "Shade", done = true},
            {sound = "sound/NS2.fev/alien/structures/death_small", classname = "Shift", done = true},
            
            {sound = "sound/NS2.fev/alien/structures/death_small", classname = "Babbler", done = true},
            {sound = "sound/NS2.fev/alien/structures/death_small", classname = "BabblerEgg", done = true},
            
            {sound = "sound/NS2.fev/alien/structures/death_small", classname = "BoneWall", done = true},
            
        },       
    },
    
    enzyme_cloud =
    {
        enzymeCloudEffects =
        {
            // TODO: replace once custom sounds are ready
            {sound = "sound/NS2.fev/alien/structures/generic_spawn_large", world_space = true, done = true},
        }    
    },
    
    drifter_melee_attack =
    {
        drifterMeleeAttackEffects =
        {
            {sound = "sound/NS2.fev/alien/drifter/attack"},
        },
    },
    
    drifter_parasite =
    {
        drifterParasiteEffects = 
        {
            {sound = "sound/NS2.fev/alien/drifter/parasite"},
        },
    },    
    
    drifter_parasite_hit = 
    {
        parasiteHitEffects = 
        {
            {sound = "sound/NS2.fev/alien/skulk/parasite_hit"},
            {player_cinematic = "cinematics/alien/skulk/parasite_hit.cinematic"},
        },
    },
    
    // "sound/NS2.fev/alien/drifter/drift"
    // "sound/NS2.fev/alien/drifter/ordered"
    harvester_collect =
    {
        harvesterCollectEffect =
        {
            {sound = "sound/NS2.fev/alien/structures/harvester_harvested"},
            //{cinematic = "cinematics/alien/harvester/resource_collect.cinematic"},
            {animation = {{.4, "active1"}, {.7, "active2"}}, force = false},
        },
    },
    
    egg_death =
    {
        eggEggDeathEffects =
        {
            {sound = "sound/NS2.fev/alien/structures/egg/death"},
            {cinematic = "cinematics/alien/egg/burst.cinematic"},
        },
    },

    hydra_attack =
    {
        hydraAttackEffects =
        {
            {sound = "sound/NS2.fev/alien/structures/hydra/attack"},
            //{cinematic = "cinematics/alien/hydra/spike_fire.cinematic"},
        },
    },
    
    player_start_gestate =
    {
        playerStartGestateEffects = 
        {
            {private_sound = "sound/NS2.fev/alien/common/gestate"},
        },
    },
    
    player_end_gestate =
    {
        playerStartGestateEffects = 
        {
            {stop_sound = "sound/NS2.fev/alien/common/gestate"},
        },
    },
    
    bone_wall_burst = 
    {
        boneWallBurstEffect =
        {
            {cinematic = "cinematics/alien/infestationspike/burst.cinematic"},
        }
    },
    
    clog_slime =
    {
        clogSlimeEffects =
        {
            {cinematic = "cinematics/alien/gorge/slime_fall.cinematic"},
        } 
    },
    
    hive_login =
    {
        hiveLoginEffects =
        {
            {sound = "sound/NS2.fev/alien/structures/hive_load"}
        },
    },

    hive_logout =
    {
        hiveLogoutEffects =
        {
            {sound = "sound/NS2.fev/alien/structures/hive_exit"}
        },
    },
    
    // Triggers when crag tries to heal entities
    crag_heal =
    {        
        cragTriggerHealEffects = 
        {
            {cinematic = "cinematics/alien/crag/heal.cinematic"}
        },
    },
    
    crag_heal_wave =
    {        
        cragTriggerHealEffects = 
        {
            {cinematic = "cinematics/alien/crag/heal_wave.cinematic"}
        },
    }, 
    
    whip_attack =
    {
        whipAttackEffects =
        {
            {sound = "sound/NS2.fev/alien/structures/whip/hit"},
        },
    },
    
    whip_attack_start =
    {
        whipAttackEffects =
        {
            {sound = "sound/NS2.fev/alien/structures/whip/swing"},
        },
    },
    
    whip_bombard =
    {
        whipBombardEffects =
        {
            // TODO: trigger custom bombard attack sound
            {sound = "sound/NS2.fev/alien/structures/whip/swing"},
        },
    },
    
    whipbomb_hit =
    {
        whipBombHitEffects = 
        {
            // TODO: trigger custom whip bomb hit sound
            {sound = "sound/NS2.fev/alien/gorge/bilebomb_hit"},
            {cinematic = "cinematics/alien/whip/bomb_hit.cinematic", done = true},
        },
    },
    
    whip_trigger_fury =
    {
        whipTriggerFuryEffects = 
        {
            {sound = "sound/NS2.fev/alien/structures/whip/fury"},
            {cinematic = "cinematics/alien/whip/fury.cinematic"},
        },
    },   
    
    //Whip.kMode = enum( {'Rooted', 'Unrooting', 'UnrootedStationary', 'Rooting', 'StartMoving', 'Moving', 'EndMoving'} )
    
    // Played when root finishes
    whip_rooted =
    {
        whipRootedEffects = 
        {
            // Placeholder
            {sound = "sound/NS2.fev/alien/structures/generic_build"},
        },
    },
    
    // Played after unroot finishes
    whip_unrootedstationary =
    {
        whipUnrootedEffects = 
        {
            // Placeholder
            {sound = "sound/NS2.fev/alien/structures/generic_build"},
        },
    },
   
    // "cinematics/alien/shade/blind.cinematic"
    // "cinematics/alien/shade/glow.cinematic"
    // "cinematics/alien/shade/phantasm.cinematic"
    
    // On shade when it triggers cloak ability
    shade_cloak_start =
    {
        {sound = "sound/NS2.fev/alien/structures/shade/cloak_start"},
    },

    create_pheromone =
    {
        createPheromoneEffects =
        {
            // Play different effects for friendlies vs. enemies
            {sound = "sound/NS2.fev/alien/structures/crag/umbra"/*, sameteam = true*/},            
            {cinematic = "cinematics/alien/crag/umbra.cinematic", /*sameteam = true,*/ done = true},
            
            //{sound = "sound/NS2.fev/alien/structures/crag/umbra", sameteam = false, volume = .3, done = true},            
        },
    },    

    death_hallucination =
    {
        deathHallucinationEffect =
        {
            {sound = "sound/NS2.fev/alien/common/frenzy" },
            {cinematic = "cinematics/alien/shade/death_halluzination.cinematic", done = true},         
        },
    },     

    babbler_jump =
    {
        babblerJumpEffect =
        {
            {sound = "", silenceupgrade = true, done = true},
            {sound = "sound/NS2.fev/alien/babbler/jump" },     
        },
    }, 
    
    babbler_engage =
    {
        babblerEngageEffect =
        {
            {sound = "", silenceupgrade = true, done = true},
            {sound = "sound/NS2.fev/alien/babbler/attack_jump" },     
        },
    }, 
    
    babbler_wag_begin =
    {
        babblerWagBeginEffect =
        {
            {sound = "", silenceupgrade = true, done = true},
            {sound = "sound/NS2.fev/alien/babbler/fetch" },     
        },
    }, 
    
    babbler_move =
    {
        babblerIdleEffect =
        {
            {sound = "", silenceupgrade = true, done = true},
            {sound = "sound/NS2.fev/alien/babbler/idle" },     
        },
    }, 
    
    babbler_attack =
    {
        babblerAttackEffect =
        {
            {sound = "", silenceupgrade = true, done = true},
            {sound = "sound/NS2.fev/alien/babbler/attack_jump" },    
        },
    }, 
    
    teleport_start =
    {
        teleportStartEffects =
        {
            {sound = "sound/NS2.fev/alien/structures/deploy_large" },
            {cinematic = "cinematics/alien/shift/teleport_start.cinematic", classname = "Structure", done = true}, 
        },
    }, 
    
    teleport_end =
    {
        teleportEndEffects =
        {
            {sound = "sound/NS2.fev/alien/structures/generic_spawn_large" },
            
            {cinematic = "cinematics/alien/shift/teleport_end.cinematic", done = true},      
        },
    }, 
    
}

GetEffectManager():AddEffectData("AlienStructureEffects", kAlienStructureEffects)
