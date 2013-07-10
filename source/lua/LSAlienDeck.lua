/*

Class IDs
=========

 - kTechId.Skulk
 - kTechId.Gorge
 - kTechId.Lerk
 - kTechId.Fade
 - kTechId.Onos
 
Ability IDs
===========

 - kTechId.Bite             (Skulk)
 - kTechId.Parasite         (Skulk)
 - kTechId.Leap             (Skulk)
 - kTechId.Xenocide         (Skulk)
 - kTechId.Spit             (Gorge)
 - kTechId.BuildAbility     (Gorge)
 - kTechId.Spray            (Gorge)
 - kTechId.BileBomb         (Gorge)
 - kTechId.BabblerAbility   (Gorge)
 - kTechId.Swipe            (Fade)
 - kTechId.Blink            (Fade)
 - kTechId.Vortex           (Fade)
 - kTechId.Gore             (Onos)
 - kTechId.Stomp            (Onos)
 - kTechId.LerkBite         (Lerk)
 - kTechId.Spores           (Lerk)
 - kTechId.Umbra            (Lerk)
 
 - kTechId.Carapace
 - kTechId.Regeneration
 - kTechId.Silence
 - kTechId.Camouflage
 - kTechId.Celerity
 - kTechId.Adrenaline

*/

kAlienDeck = {

    { name = 'Skulk',               start = 0,      minWeight = 1000,   maxWeight = 100,   class = kTechId.Skulk,           abilities = { kTechId.Bite } },
    { name = 'Leaping Skulk',       start = 0,      minWeight = 100,    maxWeight = 100,   class = kTechId.Skulk,           abilities = { kTechId.Bite, kTechId.Leap } },
    { name = 'Hardened Skulk',      start = 0,      minWeight = 100,    maxWeight = 100,   class = kTechId.Skulk,           abilities = { kTechId.Bite, kTechId.Carapace } },
    { name = 'Infiltrator Skulk',   start = 0,      minWeight = 100,    maxWeight = 100,   class = kTechId.Skulk,           abilities = { kTechId.Camouflage, kTechId.Bite } },
	{ name = 'Scouting Skulk',		start = 0,      minWeight = 100,    maxWeight = 100,   class = kTechId.Skulk,			abilities = { kTechId.Bite, kTechId.Parasite } },
	{ name = 'Detonation Skulk',	start = 0,      minWeight = 100,    maxWeight = 100,   class = kTechId.Skulk,			abilities = { kTechId.Bite, kTechId.Xenocide} },

    { name = 'Gorge',      			start = 0,      minWeight = 100,    maxWeight = 100,   class = kTechId.Gorge,           abilities = { kTechId.Heal, kTechId.Spit } },
    { name = 'Swarm Gorge',         start = 0,      minWeight = 100,    maxWeight = 100,   class = kTechId.Gorge,           abilities = { kTechId.Heal, kTechId.BabblerAbility, kTechId.Spit, kTechId.BuildAbility } },
    { name = 'Bomber Gorge',        start = 0,      minWeight = 100,    maxWeight = 100,   class = kTechId.Gorge,           abilities = { kTechId.Heal, kTechId.BileBomb, kTechId.Spit } },

    { name = 'Lerk',       			start = 0.25,   minWeight = 0,      maxWeight = 100,   class = kTechId.Lerk,            abilities = { kTechId.LerkBite } },
    { name = 'Speedy Lerk',         start = 0.25,   minWeight = 0,      maxWeight = 100,   class = kTechId.Lerk,            abilities = { kTechId.LerkBite, kTechId.Celerity } },
    { name = 'Gassy Lerk',          start = 0.25,   minWeight = 0,      maxWeight = 100,   class = kTechId.Lerk,            abilities = { kTechId.LerkBite, kTechId.Spores } },

    { name = 'Fade',                start = 0.5,    minWeight = 0,      maxWeight = 100,   class = kTechId.Fade,            abilities = { kTechId.Swipe } },    
    { name = 'Ninja Fade',          start = 0.5,    minWeight = 0,      maxWeight = 100,   class = kTechId.Fade,            abilities = { kTechId.Swipe, kTechId.Silence } },
    { name = 'Mutant Fade',         start = 0.5,    minWeight = 0,      maxWeight = 100,   class = kTechId.Fade,            abilities = { kTechId.Swipe, kTechId.Regeneration } },
    
    { name = 'Onos',                start = 0.75,   minWeight = 0,      maxWeight = 100,   class = kTechId.Onos,            abilities = { kTechId.Gore } },
    { name = 'Raging Onos',         start = 0.75,   minWeight = 0,      maxWeight = 100,   class = kTechId.Onos,            abilities = { kTechId.Gore, kTechId.Stomp } },
    { name = 'Rabid Onos',          start = 0.75,   minWeight = 0,      maxWeight = 100,   class = kTechId.Onos,            abilities = { kTechId.Gore, kTechId.Adrenaline } },
}
