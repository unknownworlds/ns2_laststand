
gAlienSpawn = nil
gMarineSpawn = nil

class 'AlienSpawn' (Entity)
function AlienSpawn:OnCreate()
    Print("alien spawn created")
    gAlienSpawn = self
end

class 'MarineSpawn' (Entity)
function MarineSpawn:OnCreate()
    Print("marine spawn created")
    gMarineSpawn = self
end

Shared.LinkClassToMap("AlienSpawn", "ls_alien_spawn", { })
Shared.LinkClassToMap("MarineSpawn", "ls_marine_spawn", { })
