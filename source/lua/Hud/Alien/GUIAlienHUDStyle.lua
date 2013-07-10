// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIMarineHUDStyle.lua
//
// Created by: Andreas Urwalek (a_urwa@sbox.tugraz.at)
//
// texture names, coordinates and colors used in the marine hud
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

kFogBigTexture = "ui/alien_commander_background.dds"
kFogBigTextureCoords = { 755, 342, 990, 405 }
kFogBigTextureWidth = kFogBigTextureCoords[3] - kFogBigTextureCoords[1]
kFogBigTextureHeight = kFogBigTextureCoords[4] - kFogBigTextureCoords[2]

kFogSmallTexture = "ui/marine_HUD_fogSmall.dds"
kFogSmallCoords = { 0, 0, 314, 96 }
kFogSmallWidth = kFogSmallCoords[3] - kFogSmallCoords[1]
kFogSmallHeight = kFogSmallCoords[4] - kFogSmallCoords[2]

kAlienThemeColor = Color(1, 0.792, 0.227)

kAlienBrightColor = ColorIntToColor(kAlienTeamColor) //Color(1, 0.886, 0.129)
kAlienBrightColorTransparent = Color(kAlienBrightColor.r, kAlienBrightColor.g, kAlienBrightColor.b, 0.5)

kAlienDarkColor = Color(kAlienBrightColor.r * 0.45, kAlienBrightColor.g * 0.45, kAlienBrightColor.b * 0.45, kAlienBrightColor.a)
kAlienDarkColorTransparent = Color(kAlienDarkColor.r, kAlienDarkColor.g, kAlienDarkColor.b, 0.5)

kAlienGreyColor = Color(0.5, 0.5, 0.5, 1)
kAlienGreyColorTransparent = Color(kAlienGreyColor.r, kAlienGreyColor.g, kAlienGreyColor.b, 0.5)
