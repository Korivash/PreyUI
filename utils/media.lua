-- PreyUI Media Registration
-- Registers fonts and textures with LibSharedMedia for use across all modules.

local ADDON_PATH = "Interface\\AddOns\\PreyUI\\assets\\"
local LSM = LibStub("LibSharedMedia-3.0")
local FONT      = LSM.MediaType.FONT
local STATUSBAR = LSM.MediaType.STATUSBAR
local BACKGROUND = LSM.MediaType.BACKGROUND
local BORDER    = LSM.MediaType.BORDER

-- Register a list of aliases all pointing to the same path.
local function Alias(kind, names, path)
    for _, name in ipairs(names) do
        LSM:Register(kind, name, path)
    end
end

-- Fonts
LSM:Register(FONT, "Prey",          ADDON_PATH .. "Prey.ttf")
LSM:Register(FONT, "Korivash",      ADDON_PATH .. "Prey.ttf")   -- legacy alias
LSM:Register(FONT, "Poppins Black",    ADDON_PATH .. "Poppins-Black.ttf")
LSM:Register(FONT, "Poppins Bold",     ADDON_PATH .. "Poppins-Bold.ttf")
LSM:Register(FONT, "Poppins Medium",   ADDON_PATH .. "Poppins-Medium.ttf")
LSM:Register(FONT, "Poppins SemiBold", ADDON_PATH .. "Poppins-SemiBold.ttf")
LSM:Register(FONT, "Expressway",    ADDON_PATH .. "Expressway.TTF")

-- Logo texture
Alias(BACKGROUND, { "PreyLogo", "KorivashLogo" }, ADDON_PATH .. "preyLogo.tga")

-- Core bar textures (BACKGROUND + STATUSBAR + BORDER for each variant)
local textures = {
    { names = { "Prey",           "Korivash"           }, file = "Prey.tga"          },
    { names = { "Prey Reverse",   "Korivash Reverse"   }, file = "Prey_reverse.tga"  },
    { names = { "Prey v2",        "Korivash v2"        }, file = "Prey_v2.tga"       },
    { names = { "Prey v2 Reverse","Korivash v2 Reverse"}, file = "Prey_v2reverse.tga"},
    { names = { "Prey v3",        "Korivash v3"        }, file = "Prey_v3.tga"       },
    { names = { "Prey v3 Inverse","Korivash v3 Inverse"}, file = "Prey_v3inverse.tga"},
    { names = { "Prey v4",        "Korivash v4"        }, file = "Prey_v4.tga"       },
    { names = { "Prey v4 Inverse","Korivash v4 Inverse"}, file = "Prey_v4inverse.tga"},
    { names = { "Prey v5",        "Korivash v5"        }, file = "Prey_v5.tga"       },
    { names = { "Prey v5 Inverse","Korivash v5 Inverse"}, file = "Prey_v5_inverse.tga"},
    { names = { "Prey v6",        "Korivash v6"        }, file = "Prey_v6.tga"       },
    { names = { "Prey v6 Inverse","Korivash v6 Inverse"}, file = "Prey_v6inverse.tga"},
}

local squarePath = ADDON_PATH .. "Square.tga"
Alias(BACKGROUND, { "Square" }, squarePath)
Alias(STATUSBAR,  { "Square" }, squarePath)
Alias(BORDER,     { "Square" }, squarePath)

for _, t in ipairs(textures) do
    local path = ADDON_PATH .. t.file
    Alias(BACKGROUND, t.names, path)
    Alias(STATUSBAR,  t.names, path)
    Alias(BORDER,     t.names, path)
end

-- Absorb stripe overlay
Alias(STATUSBAR, { "PREY Stripes", "KORI Stripes" }, ADDON_PATH .. "absorb_stripe")

-- Silent validation on init — prints only on failure.
function PreyUI:CheckMediaRegistration()
    local required = {
        { kind = FONT,       name = "Prey" },
        { kind = BACKGROUND, name = "PreyLogo" },
        { kind = BACKGROUND, name = "Prey" },
        { kind = BACKGROUND, name = "Prey Reverse" },
    }
    local ok = true
    for _, r in ipairs(required) do
        if not LSM:IsValid(r.kind, r.name) then
            if ok then
                ok = false
                PreyUI:Print("|cffef4444Media registration failures:|r")
            end
            PreyUI:Print("  - " .. r.name)
        end
    end
end
