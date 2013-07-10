kCommonGameSounds =
{ 
    RoundEndMusic = "sound/ls.fev/music/RoundEnd",
}

for i, soundAsset in pairs(kCommonGameSounds) do
    Client.PrecacheLocalSound(soundAsset)
end
