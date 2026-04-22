-- PreyUI Media Registration
-- This file handles the registration of fonts and textures with LibSharedMedia

local ADDON_PATH = "Interface\\AddOns\\PreyUI\\assets\\"
local LSM = LibStub("LibSharedMedia-3.0")

-- Media types from LibSharedMedia
local MediaType = LSM.MediaType
local FONT = MediaType.FONT
local STATUSBAR = MediaType.STATUSBAR
local BACKGROUND = MediaType.BACKGROUND
local BORDER = MediaType.BORDER

local function RegisterSharedMediaAliases(kind, names, path)
    for _, name in ipairs(names) do
        LSM:Register(kind, name, path)
    end
end

-- Register media synchronously (LSM:Register is lightweight - just table entries)
local preyFontPath = ADDON_PATH .. "Prey.ttf"
RegisterSharedMediaAliases(FONT, { "Prey", "Korivash" }, preyFontPath)

    -- Register Poppins fonts
LSM:Register(FONT, "Poppins Black", ADDON_PATH .. "Poppins-Black.ttf")
LSM:Register(FONT, "Poppins Bold", ADDON_PATH .. "Poppins-Bold.ttf")
LSM:Register(FONT, "Poppins Medium", ADDON_PATH .. "Poppins-Medium.ttf")
LSM:Register(FONT, "Poppins SemiBold", ADDON_PATH .. "Poppins-SemiBold.ttf")

    -- Register Expressway font
LSM:Register(FONT, "Expressway", ADDON_PATH .. "Expressway.TTF")

    -- Register the Prey Logo texture
local logoTexturePath = ADDON_PATH .. "preyLogo.tga"
RegisterSharedMediaAliases(BACKGROUND, { "PreyLogo", "KorivashLogo" }, logoTexturePath)

    -- Register the Prey texture
local preyTexturePath = ADDON_PATH .. "Prey.tga"
RegisterSharedMediaAliases(BACKGROUND, { "Prey", "Korivash" }, preyTexturePath)
RegisterSharedMediaAliases(STATUSBAR, { "Prey", "Korivash" }, preyTexturePath)
RegisterSharedMediaAliases(BORDER, { "Prey", "Korivash" }, preyTexturePath)

    -- Register the Prey Reverse texture
local preyReverseTexturePath = ADDON_PATH .. "Prey_reverse.tga"
RegisterSharedMediaAliases(BACKGROUND, { "Prey Reverse", "Korivash Reverse" }, preyReverseTexturePath)
RegisterSharedMediaAliases(STATUSBAR, { "Prey Reverse", "Korivash Reverse" }, preyReverseTexturePath)
RegisterSharedMediaAliases(BORDER, { "Prey Reverse", "Korivash Reverse" }, preyReverseTexturePath)

    -- Register Square texture
local squareTexturePath = ADDON_PATH .. "Square.tga"
LSM:Register(BACKGROUND, "Square", squareTexturePath)
LSM:Register(STATUSBAR, "Square", squareTexturePath)
LSM:Register(BORDER, "Square", squareTexturePath)

    -- Register Prey v2 texture
local preyV2TexturePath = ADDON_PATH .. "Prey_v2.tga"
RegisterSharedMediaAliases(BACKGROUND, { "Prey v2", "Korivash v2" }, preyV2TexturePath)
RegisterSharedMediaAliases(STATUSBAR, { "Prey v2", "Korivash v2" }, preyV2TexturePath)
RegisterSharedMediaAliases(BORDER, { "Prey v2", "Korivash v2" }, preyV2TexturePath)

    -- Register Prey v2 Reverse texture
local preyV2ReverseTexturePath = ADDON_PATH .. "Prey_v2reverse.tga"
RegisterSharedMediaAliases(BACKGROUND, { "Prey v2 Reverse", "Korivash v2 Reverse" }, preyV2ReverseTexturePath)
RegisterSharedMediaAliases(STATUSBAR, { "Prey v2 Reverse", "Korivash v2 Reverse" }, preyV2ReverseTexturePath)
RegisterSharedMediaAliases(BORDER, { "Prey v2 Reverse", "Korivash v2 Reverse" }, preyV2ReverseTexturePath)

    -- Register Prey v3 texture
local preyV3TexturePath = ADDON_PATH .. "Prey_v3.tga"
RegisterSharedMediaAliases(BACKGROUND, { "Prey v3", "Korivash v3" }, preyV3TexturePath)
RegisterSharedMediaAliases(STATUSBAR, { "Prey v3", "Korivash v3" }, preyV3TexturePath)
RegisterSharedMediaAliases(BORDER, { "Prey v3", "Korivash v3" }, preyV3TexturePath)

    -- Register Prey v3 Inverse texture
local preyV3InverseTexturePath = ADDON_PATH .. "Prey_v3inverse.tga"
RegisterSharedMediaAliases(BACKGROUND, { "Prey v3 Inverse", "Korivash v3 Inverse" }, preyV3InverseTexturePath)
RegisterSharedMediaAliases(STATUSBAR, { "Prey v3 Inverse", "Korivash v3 Inverse" }, preyV3InverseTexturePath)
RegisterSharedMediaAliases(BORDER, { "Prey v3 Inverse", "Korivash v3 Inverse" }, preyV3InverseTexturePath)

    -- Register Prey v4 texture
local preyV4TexturePath = ADDON_PATH .. "Prey_v4.tga"
RegisterSharedMediaAliases(BACKGROUND, { "Prey v4", "Korivash v4" }, preyV4TexturePath)
RegisterSharedMediaAliases(STATUSBAR, { "Prey v4", "Korivash v4" }, preyV4TexturePath)
RegisterSharedMediaAliases(BORDER, { "Prey v4", "Korivash v4" }, preyV4TexturePath)

    -- Register Prey v4 Inverse texture
local preyV4InverseTexturePath = ADDON_PATH .. "Prey_v4inverse.tga"
RegisterSharedMediaAliases(BACKGROUND, { "Prey v4 Inverse", "Korivash v4 Inverse" }, preyV4InverseTexturePath)
RegisterSharedMediaAliases(STATUSBAR, { "Prey v4 Inverse", "Korivash v4 Inverse" }, preyV4InverseTexturePath)
RegisterSharedMediaAliases(BORDER, { "Prey v4 Inverse", "Korivash v4 Inverse" }, preyV4InverseTexturePath)

    -- Register Prey v5 texture
local preyV5TexturePath = ADDON_PATH .. "Prey_v5.tga"
RegisterSharedMediaAliases(BACKGROUND, { "Prey v5", "Korivash v5" }, preyV5TexturePath)
RegisterSharedMediaAliases(STATUSBAR, { "Prey v5", "Korivash v5" }, preyV5TexturePath)
RegisterSharedMediaAliases(BORDER, { "Prey v5", "Korivash v5" }, preyV5TexturePath)

    -- Register Prey v5 Inverse texture
local preyV5InverseTexturePath = ADDON_PATH .. "Prey_v5_inverse.tga"
RegisterSharedMediaAliases(BACKGROUND, { "Prey v5 Inverse", "Korivash v5 Inverse" }, preyV5InverseTexturePath)
RegisterSharedMediaAliases(STATUSBAR, { "Prey v5 Inverse", "Korivash v5 Inverse" }, preyV5InverseTexturePath)
RegisterSharedMediaAliases(BORDER, { "Prey v5 Inverse", "Korivash v5 Inverse" }, preyV5InverseTexturePath)

    -- Register Prey v6 texture
local preyV6TexturePath = ADDON_PATH .. "Prey_v6.tga"
RegisterSharedMediaAliases(BACKGROUND, { "Prey v6", "Korivash v6" }, preyV6TexturePath)
RegisterSharedMediaAliases(STATUSBAR, { "Prey v6", "Korivash v6" }, preyV6TexturePath)
RegisterSharedMediaAliases(BORDER, { "Prey v6", "Korivash v6" }, preyV6TexturePath)

    -- Register Prey v6 Inverse texture
local preyV6InverseTexturePath = ADDON_PATH .. "Prey_v6inverse.tga"
RegisterSharedMediaAliases(BACKGROUND, { "Prey v6 Inverse", "Korivash v6 Inverse" }, preyV6InverseTexturePath)
RegisterSharedMediaAliases(STATUSBAR, { "Prey v6 Inverse", "Korivash v6 Inverse" }, preyV6InverseTexturePath)
RegisterSharedMediaAliases(BORDER, { "Prey v6 Inverse", "Korivash v6 Inverse" }, preyV6InverseTexturePath)

    -- Register PREY Stripes texture (for absorb shield overlays)
local absorbStripeTexturePath = ADDON_PATH .. "absorb_stripe"
RegisterSharedMediaAliases(STATUSBAR, { "PREY Stripes", "KORI Stripes" }, absorbStripeTexturePath)

-- Function to check if our media is registered
function PreyUI:CheckMediaRegistration()
    local preyFontRegistered = LSM:IsValid(FONT, "Prey")
    local logoTextureRegistered = LSM:IsValid(BACKGROUND, "PreyLogo")
    local preyTextureRegistered = LSM:IsValid(BACKGROUND, "Prey")
    local preyReverseTextureRegistered = LSM:IsValid(BACKGROUND, "Prey Reverse")
    
    -- Silent check - only print if there's a failure
    if not (preyFontRegistered and logoTextureRegistered and preyTextureRegistered and preyReverseTextureRegistered) then
        PreyUI:Print("Media registration failed:")
        if not preyFontRegistered then PreyUI:Print("- Prey font not registered") end
        if not logoTextureRegistered then PreyUI:Print("- PreyLogo texture not registered") end
        if not preyTextureRegistered then PreyUI:Print("- Prey texture not registered") end
        if not preyReverseTextureRegistered then PreyUI:Print("- Prey Reverse texture not registered") end
    end
end

-- Register any additional fonts or textures here
-- Example:
-- LSM:Register(FONT, "MyCustomFont", "Interface\\AddOns\\PreyUI\\assets\\mycustomfont.ttf")
-- LSM:Register(STATUSBAR, "MyCustomTexture", "Interface\\AddOns\\PreyUI\\assets\\mycustomtexture.tga") 
