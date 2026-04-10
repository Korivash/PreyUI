# PreyUI — Complete Documentation

**Version:** 3.0.12  
**WoW Interface:** 120001 (The War Within / Midnight — Retail)  
**Author:** Korivash  
**License:** GPLv3

---

## Table of Contents

1. [What is PreyUI?](#1-what-is-preyui)
2. [Installation](#2-installation)
3. [First-Time Setup Checklist](#3-first-time-setup-checklist)
4. [Slash Commands](#4-slash-commands)
5. [Options Interface](#5-options-interface)
6. [Module Reference](#6-module-reference)
   - [Unit Frames](#61-unit-frames)
   - [Castbars](#62-castbars)
   - [Action Bars](#63-action-bars)
   - [Minimap](#64-minimap)
   - [Buffs & Debuffs](#65-buffs--debuffs)
   - [Cooldown Manager (NCDM)](#66-cooldown-manager-ncdm)
   - [Mythic+ Timer](#67-mythic-timer)
   - [Mythic+ Tools](#68-mythic-tools)
   - [Combat Text](#69-combat-text)
   - [Combat Timer](#610-combat-timer)
   - [Rotation Assist](#611-rotation-assist)
   - [Custom Trackers](#612-custom-trackers)
   - [Chat Enhancements](#613-chat-enhancements)
   - [Tooltips](#614-tooltips)
   - [Skyriding Vigor Bar](#615-skyriding-vigor-bar)
   - [Brewmaster Stagger Bar](#616-brewmaster-stagger-bar)
   - [Raid Buffs](#617-raid-buffs)
   - [Quick Salvage](#618-quick-salvage)
   - [Quality of Life Automation](#619-quality-of-life-automation)
   - [Data Texts](#620-data-texts)
   - [Reticle / Crosshair](#621-reticle--crosshair)
   - [Anchoring System](#622-anchoring-system)
7. [Blizzard Frame Skinning](#7-blizzard-frame-skinning)
8. [Profile System](#8-profile-system)
9. [Edit Mode Integration](#9-edit-mode-integration)
10. [Keybindings](#10-keybindings)
11. [Performance & Settings](#11-performance--settings)
12. [Localization](#12-localization)
13. [Library Dependencies](#13-library-dependencies)
14. [Troubleshooting](#14-troubleshooting)
15. [FAQ](#15-faq)
16. [Changelog Highlights](#16-changelog-highlights)

---

## 1. What is PreyUI?

PreyUI is a fully modular, all-in-one World of Warcraft UI addon suite designed for high-performance gameplay. It replaces and enhances virtually every element of the default WoW interface:

- **Unit Frames** — player, target, focus, pet, boss frames with health gradients, absorb shields, and aura tracking
- **Action Bars** — complete reskin with proc glows, fade on mouseover, and custom cooldown sweeps
- **Minimap** — reshape, restyle, and add a skyriding vigor bar and data texts
- **Cooldown Manager** — hooks Blizzard's built-in CDM with per-row icon layout control
- **Mythic+ Suite** — timer, keystone tracker, dungeon teleports, affix display
- **Blizzard Skinning** — recolors character frames, loot windows, ESC menu, quest tracker, and more
- **Quality of Life** — auto-repair, auto-sell junk, auto-invite acceptance, and more

Everything is controlled from a single `/prey` interface with a custom GUI. Settings persist across sessions with full profile import/export support.

---

## 2. Installation

### CurseForge / WoWInterface (recommended)
Download and install via your preferred addon manager. The addon will appear in your addon list as **PreyUI**.

### Manual Installation
1. Download the latest release `.zip`
2. Extract so the folder structure is:  
   `World of Warcraft/_retail_/Interface/AddOns/PreyUI/`
3. Ensure `PreyUI.toc` is directly inside that folder
4. Launch WoW and enable the addon in the Character Select screen

> **Required WoW Version:** Interface 120001+. PreyUI will not load on Classic or older retail builds.

---

## 3. First-Time Setup Checklist

When you first load PreyUI, the following message appears in chat as a reminder:

1. **Enable the Cooldown Manager** — Go to `/prey` → `Gameplay Enhancement` and enable the CDM. Without this step, the Essential and Utility cooldown bars are not active.
2. **Action Bars are hidden by default** — Open `/prey` → `Action Bars` tab to configure visibility. Bars fade in on mouseover; use the tab to make them always visible if preferred.
3. **Set CDM icon size to 100%** — In WoW's Edit Mode, set the Essential and Utility CDM bars to 100% icon size for the cleanest layout.
4. **Position CDM bars in Edit Mode** — Drag the CDM rows to your preferred location and click **Save** before closing Edit Mode.

---

## 4. Slash Commands

| Command | Action |
|---------|--------|
| `/prey` | Open the PreyUI options GUI |
| `/preyui` | Alias for `/prey` |
| `/prey debug` | Enable debug mode (reloads UI with extra logging) |
| `/prey editmode` | Toggle unit frame edit / positioning mode |
| `/rl` | Safe reload — queues until out of combat if needed |
| `/kb` | Open LibKeyBound quick keybind mode |
| `/cdm` | Toggle Blizzard's Cooldown Viewer settings panel |
| `/stagger` | Toggle Brewmaster stagger bar unlock (drag to reposition) |

> **Safe Reload (`/rl`):** If you call `/rl` during combat, the reload is queued. When combat ends a confirmation popup appears — click **Reload Now** or **Later**.

---

## 5. Options Interface

Open with `/prey`. The interface uses a left-side navigation rail and a scrollable right-side content area.

### Navigation Tabs

| Tab | Contents |
|-----|----------|
| **General** | UI scale, font, texture, color scheme, dark mode, global toggles |
| **Unit Frames** | Player, target, focus, pet, boss frame settings |
| **Action Bars** | Per-bar visibility, fade settings, icon borders, keybind display |
| **Minimap** | Shape, border, clock, coordinates, skyriding vigor, data texts |
| **Buffs** | Personal buff/debuff bars, raid buff tracker |
| **Cooldown Manager** | NCDM row configuration, icon counts, aspect ratio, glow |
| **Combat** | Combat text, combat timer, rotation assist |
| **M+ Timer** | Layout mode, colors, demo mode |
| **Chat** | URL detection, timestamps, class-color names, edit box style |
| **Tooltips** | Per-context tooltip content (item level, spell ID, etc.) |
| **Trackers** | Custom icon, bar, numeric, and text trackers |
| **QoL** | Auto-repair, auto-sell, auto-accept, fast loot |
| **Skinning** | Per-frame Blizzard reskin toggles and color controls |
| **Gameplay Enhancement** | CDM enable, rotation assist, skyriding, stagger |
| **Performance** | FPS CVar presets, garbage collection, UI scale tools |
| **Profiles** | Export/import profile strings |

---

## 6. Module Reference

### 6.1 Unit Frames

PreyUI creates its own unit frames for: **Player, Target, Target-of-Target, Focus, Focus-Target, Pet, Boss (1–4), and Party**.

#### Key Features
- **Health bars** with gradient, class color, hostility color, or custom RGB options
- **Power bars** supporting all 12 WoW power types (Mana, Rage, Focus, Energy, Runic Power, Maelstrom, Lunar Power, Insanity, and more)
- **Absorb shields** with animated stripe overlay showing over-absorb
- **Portraits** — 2D or 3D, with class icon fallback
- **Name text** with class coloring and max-length truncation
- **Aura display** — configurable buff/debuff icons with numeric timers, stack counts, and debuff type coloring
- **Castbars** integrated directly below each frame (see [Castbars](#62-castbars))
- **Interrupt tracking** — target castbar turns red for interruptible spells
- **Threat indicator** — subtle color shift when pulling threat
- **Edit Mode** — `/prey editmode` unlocks all frames for drag-to-reposition

#### Frame-Specific Settings (per frame)
- Enable / disable
- Width, height, position (X/Y)
- Bar texture and opacity
- Health and background color source (class, hostility, custom)
- Portrait type (2D / 3D / none)
- Power bar display
- Buff / debuff count and filter

#### API Compatibility
PreyUI uses a `UnitHealthPercent` wrapper that handles the WoW 12.0+ (`Midnight`) API change and falls back to manual calculation when needed. `pcall` guards protect against "secret value" arithmetic errors inside instanced content.

---

### 6.2 Castbars

Integrated with unit frames but individually configurable.

- **Player castbar** — shows spell name, icon, cast time, and a pushback indicator
- **Target castbar** — highlights in red when the cast is interruptible
- **Focus castbar** — mirrors target castbar behavior for focus unit
- **Boss castbars** — appear below boss unit frames
- **Empowered spells (Evoker)** — renders stage pips for multi-stage empowered casts
- **Cast queue window** — optional overlay showing the queued next cast

Each castbar supports custom fonts, colors, and border styles from the General settings.

---

### 6.3 Action Bars

PreyUI skins all Blizzard action bars without replacing them, keeping full compatibility with Blizzard's action bar system and Edit Mode.

#### Bars Covered
| Key | Blizzard Frame | Buttons |
|-----|---------------|---------|
| `bar1` | MainMenuBar | 12 |
| `bar2` | MultiBarBottomLeft | 12 |
| `bar3` | MultiBarBottomRight | 12 |
| `bar4` | MultiBarRight | 12 |
| `bar5` | MultiBarLeft | 12 |
| `bar6` | MultiBar5 | 12 |
| `bar7` | MultiBar6 | 12 |
| `bar8` | MultiBar7 | 12 |
| `pet` | PetActionBar | 10 |
| `stance` | StanceBar | 10 |
| `extraActionButton` | ExtraActionBarFrame | 1 |
| `zoneAbility` | ZoneAbilityFrame | 1 |

#### Per-Bar Settings
- Show / hide (with optional always-show or mouseover-fade)
- Mouseover fade in/out time
- Icon border style and color (class color, custom RGB, or none)
- Show / hide keybind text
- Show / hide macro name text
- Cooldown swipe texture

#### Cooldown Swipes
PreyUI replaces the default Blizzard cooldown sweep with custom textures. You can independently control:
- **Buff swipe** (aura cooldowns)
- **GCD swipe** (global cooldown)
- **Spell cooldown swipe** (actual ability cooldowns)

#### Proc Glows
When a spell becomes proc-ready (tracked via `IsSpellOverlayed` / `C_SpellActivationOverlay`), a configurable glow effect fires on that button. Requires LibCustomGlow-1.0 (bundled).

---

### 6.4 Minimap

Full minimap redesign. All changes are applied via hooks so Edit Mode layout still works.

#### Shape Options
- **Circular** (default WoW look, cleanly bordered)
- **Square** (sharp corners with PreyUI border)
- **Rounded Square** (soft corners)

#### Features
- Custom border color and thickness (matches your skin color or custom RGB)
- Background behind the minimap circle/mask
- **Clock** — 12h or 24h with optional date display
- **Coordinates** — player position displayed below the map
- **Zone text** — current zone/subzone name displayed on the minimap
- **Difficulty badge** — M+ keystone level shown as a badge on the minimap

#### Addon Button Organization
Minimap addon buttons (from LibDBIcon-registered addons) are organized by PreyUI into a horizontal row rather than scattered around the circle edge.

---

### 6.5 Buffs & Debuffs

PreyUI manages multiple separate aura display areas:

| Display | Description |
|---------|-------------|
| **Personal Buff Bar** | Your active buffs with duration timers |
| **Personal Debuff Bar** | Debuffs on yourself |
| **Target Debuff Bar** | Debuffs on your target (your own or all) |
| **Raid Buff Tracker** | Missing raid consumables (flask, food, rune, buffs) |

#### Per-Tracker Options
- Enable / disable
- Max icon count
- Icon size
- Sort order (time remaining, type, alphabetical)
- Consolidate/merge duplicate auras
- Show stacks on icon
- Numeric timer display (color-coded: white → yellow → red as duration decreases)

#### Timer Color Coding
| Remaining | Color |
|-----------|-------|
| > 60 sec  | White |
| 30–60 sec | Yellow |
| < 30 sec  | Orange |
| < 10 sec  | Red |

---

### 6.6 Cooldown Manager (NCDM)

PreyUI's **New Cooldown Display Manager** hooks directly into Blizzard's built-in `EssentialCooldownViewer` and `UtilityCooldownViewer` rather than creating a parallel system.

> **Important:** The CDM must be enabled in WoW's Gameplay settings (or via `/prey` → Gameplay Enhancement) before NCDM takes effect.

#### Three Rows

| Row | Blizzard Viewer | Default Contents |
|-----|----------------|-----------------|
| **Essential** | EssentialCooldownViewer | Class burst cooldowns |
| **Utility** | UtilityCooldownViewer | Utility / off-GCD abilities |
| **Defensive** | (Blizzard's third viewer) | Defensive cooldowns |

#### Per-Row Settings
- **Icon count** — max icons displayed per row
- **Aspect ratio** — square (1:1) or rectangle (4:3 wider)
- **Mouseover only** — hide the row until mouse hovers over it
- **Glow on ready** — pulse glow when ability comes off cooldown
- **Charge display** — show charge pips (e.g., "2/3" charges)
- **Layout direction** — left-to-right or right-to-left
- **Custom ability list** — add or remove specific spells from a row

#### How It Works
NCDM uses a secondary scan loop (not a per-frame `OnUpdate`) to detect when cooldown icons change. It applies:
- Custom borders and backgrounds
- Cooldown swipe texture replacements
- Charge count overlays
- Ready-state glow effects

All state is stored in weak-reference tables (`IconState`, `FrameOrderState`) to avoid memory leaks and to prevent tainting Blizzard's secure icon frames.

---

### 6.7 Mythic+ Timer

A fully custom M+ timer with three layout modes.

#### Layout Modes

| Mode | Description |
|------|-------------|
| **Full** | Largest layout; timer, split times (+2/+3), force bar, boss counter, deaths, affixes |
| **Compact** | Reduced size; same information in condensed layout |
| **Sleek** | Minimal — timer, force %, pace indicator on one or two lines |

#### Information Displayed
- **Timer** — elapsed time in `MM:SS` format with color coding (green → yellow → red as time expires)
- **Split lines** — shows the time boundaries for +2 and +3 ratings
- **Enemy Forces** — current / total count and percentage bar
- **Boss objectives** — per-boss checkboxes
- **Deaths** — death counter with time-penalty display (+5 sec each)
- **Affixes** — icon row with affix names on hover
- **Pace indicator** — projected finish time based on current force % progress rate

#### Demo Mode
Use `/prey` → M+ Timer → **Demo Mode** to preview the timer without being in a Mythic+ dungeon.

---

### 6.8 Mythic+ Tools

#### Keystone Tracker
- Displays your current keystone's dungeon and level on the minimap or as a standalone frame
- Announces your keystone in party/raid chat via a button or auto-announce option

#### Dungeon Teleports
One-click teleport buttons appear when a dungeon is available for direct portal.  
- Only accessible if you are the party leader (WoW restricts teleport to leader)
- Automatically filters to the current M+ season's dungeons
- Accessible from the minimap M+ icon or `/prey` → M+ Tools

#### Party Key Tracker
Displays all party members' keystones in a small overlay near the minimap, useful for deciding which key to run.

---

### 6.9 Combat Text

Displays a brief floating text label when entering or leaving combat.

#### Options
- Enable / disable
- Entering combat message text and color
- Leaving combat message text and color
- Display duration (seconds)
- Font, font size, font outline
- Position (X/Y offset from screen center)
- Fade-out animation duration

---

### 6.10 Combat Timer

Tracks how long you have been in combat.

- Starts automatically on `PLAYER_REGEN_DISABLED`
- Resets on `PLAYER_REGEN_ENABLED`
- Displays time as `MM:SS` or `SS.S` depending on duration
- Separate display for boss encounter duration (tracks `ENCOUNTER_START` / `ENCOUNTER_END`)
- Configurable position, font, and color

---

### 6.11 Rotation Assist

Uses Blizzard's `C_AssistedCombat` (Starter Build / Rotation Helper) API to display the currently recommended next ability.

- Shows a single icon frame with the suggested spell
- Displays the keybind for the spell (fetched from your actual bindings)
- Icon dims when the spell is on cooldown or out of range
- Blue tint when out of mana / insufficient resources
- Red tint when target is out of range
- Update frequency: 0.3s in combat, 1.0s out of combat
- Requires that you have Blizzard's Rotation Helper enabled in Gameplay settings

---

### 6.12 Custom Trackers

Create bespoke tracking elements for any aura, cooldown, or resource.

#### Tracker Types

| Type | Description |
|------|-------------|
| **Icon** | Single icon; lights up / dims based on buff/debuff active status |
| **Bar** | Horizontal status bar showing duration or stack count |
| **Numeric** | Number display (stacks, resource amount, percentage) |
| **Text** | Free-form dynamic text with Lua expression support |

#### Trigger Options
- Buff or debuff on self, target, focus, or any party member
- Cooldown ready / active
- Resource above or below a threshold
- Custom Lua condition

#### Visibility Rules
- Always show
- In combat only
- Out of combat only
- Has target only
- In instance / out of instance

---

### 6.13 Chat Enhancements

Applies a glass-style transparent theme to the chat frame and adds utility features.

#### Features
- **URL detection** — detects `http://`, `https://`, and `www.` links and makes them copyable (click to open a copy popup)
- **Timestamps** — prepends `[HH:MM]` to all chat messages
- **Class-colored names** — player names in chat are tinted by their class color
- **Channel abbreviations** — `[Guild]` becomes `[G]`, `[Trade]` becomes `[T]`, `[General]` becomes `[GD]`
- **Chat frame styling** — removes Blizzard's background textures for a minimal look
- **Edit box styling** — custom background and border on the chat input box
- **Copy chat history** — per-frame button to copy recent chat lines to clipboard

#### Supported Chat Events
All standard channels are processed: SAY, YELL, PARTY, RAID, GUILD, OFFICER, WHISPER, BNET WHISPER, INSTANCE, CHANNEL, EMOTE, SYSTEM, AFK, DND, IGNORED.

---

### 6.14 Tooltips

Injects additional information into `GameTooltip` based on the context of what is hovered.

#### Item Tooltips
- Item level (shown prominently at the top)
- Vendor sell price
- Item ID (toggle in options)

#### Player / Unit Tooltips
- Player class and spec
- Guild name
- M+ Rating (when available)
- Realm name (for cross-realm players)

#### Spell Tooltips
- Spell ID
- Cooldown duration
- Cast range (min–max)
- Resource cost

#### NPC Tooltips
- Faction reputation
- NPC classification (Elite, Rare, Boss)

#### Performance Notes
The tooltip module caches the topmost mouse frame for 200ms to avoid repeated `GetMouseFoci()` calls. Taint-sensitive frames (WorldMap, AlertFrames, Quest POIs) are detected and skipped to prevent UI taint.

---

### 6.15 Skyriding Vigor Bar

A custom bar tracking your Skyriding / Dragonriding vigor charges.

#### Visual Elements
- **Continuous bar** — shows charge fill as a smooth progress bar
- **Segment markers** — dividers at each charge boundary (e.g., at 1/3, 2/3 for 3 charges)
- **Recharge overlay** — animated secondary fill showing the incoming charge progress
- **Shadow texture** — subtle drop shadow for depth
- **Flash animation** — brief flash when a charge is gained
- **Speed text** — optional display of current flight speed
- **Second Wind sub-bar** — separate mini-bar and pip display for the Second Wind talent

#### Visibility
- Fades out when grounded for a configurable duration
- Hides when not on a Skyriding mount

#### Smooth Animation
Bar value transitions use linear interpolation (`LERP_SPEED = 8`) for a smooth fill animation rather than snapping to exact values.

---

### 6.16 Brewmaster Stagger Bar

A custom stagger bar exclusively for Brewmaster Monks.

> **Only visible for Monk — Brewmaster Specialization**

#### Visual Elements
- Horizontal status bar with three color zones:
  - **Green** — Light stagger (< yellow threshold)
  - **Yellow** — Moderate stagger (between thresholds)
  - **Red** — Heavy stagger (> red threshold)
- Threshold tick marks at customizable percentages
- Percent text and/or absolute damage value display
- Optional label text ("STAGGER" or custom)
- Critical threshold glow (LibCustomGlow pulse when stagger is critical)

#### Configuration
- Width, height, scale, alpha
- Color per stagger tier (fully custom RGB)
- Yellow threshold % (default 30%)
- Red threshold % (default 60%)
- Critical glow threshold % (default 80%)
- Smooth animation speed
- Show / hide tick marks, tick color and thickness

#### Repositioning
Use `/stagger` to unlock the bar for drag-to-reposition. Position is saved per character.

---

### 6.17 Raid Buffs

Tracks consumable and raid buff status for your group.

| Buff Category | Tracked |
|---------------|---------|
| Flask | Flask of ??? (current tier) |
| Food | Well Fed buff |
| Augment Rune | Augment Rune or Crystalline buff |
| Raid Buffs | Battle Shout, Mark of the Wild, Arcane Intellect, etc. |

- Displays missing buffs as red icons in a small frame near the minimap or unit frames
- Configurable to show your own status only or full group status
- Suppressed outside of group content

---

### 6.18 Quick Salvage

Adds modifier-key salvage buttons to salvageable items in your bags.

- **Disabled by default** — opt-in in `/prey` → QoL
- **Modifier key** — ALT, ALT+CTRL, or ALT+SHIFT (configurable)
- Hovering an eligible bag item while holding the modifier shows a clickable salvage button
- Prevents accidental salvaging without the modifier held

---

### 6.19 Quality of Life Automation

#### Auto-Repair
Automatically repairs your equipment when visiting a merchant with repair capability.

| Setting | Behavior |
|---------|----------|
| `off` | No auto-repair |
| `personal` | Repair using personal gold |
| `guild` | Repair using guild bank funds (falls back to personal if unavailable) |

#### Auto-Sell Junk
Automatically sells all gray-quality (Poor) items when a merchant window opens.

#### Auto Role Accept
Automatically accepts the role check dialog with your current role.

#### Auto-Accept Invites
Automatically accepts group invitations from:

| Setting | Behavior |
|---------|----------|
| `off` | Never auto-accept |
| `all` | Accept from anyone |
| `friends` | Only friends and BattleNet friends |
| `guild` | Only guildmates |
| `both` | Friends and guildmates |

#### Quest Automation
- **Auto-accept quests** — accepts quest dialogs automatically (disabled by default)
- **Auto-turn-in quests** — completes quest turn-in dialogs automatically (disabled by default)
- **Hold Shift to suppress** — holding Shift cancels auto-accept/turn-in when enabled
- **Auto-select single gossip** — automatically picks a gossip option when only one exists

#### Fast Auto Loot
Enables WoW's `autoLootDefault` CVar for instant looting without holding Shift.

#### Auto Combat Log
Automatically starts and stops the combat log when entering/leaving Mythic+ instances. Useful for log-based analysis. Disabled by default.

#### Auto-Delete Confirm
Auto-fills the "DELETE" confirmation text when manually deleting items.

---

### 6.20 Data Texts

A three-slot data text system displayed below the minimap or in a standalone panel.

#### Available Data Sources
| Key | Display |
|-----|---------|
| `time` | Current time (12h or 24h) with optional date |
| `gold` | Current gold with realm total |
| `durability` | Lowest durability item percentage |
| `friends` | Online friends count |
| `guild` | Online guild members count |
| `fps` | Frames per second |
| `latency` | World latency (ms) |
| `memory` | Addon memory usage |
| `zone` | Current zone / subzone |
| `spec` | Current specialization |
| `empty` | Blank slot |

Each slot is individually configured with:
- Data source selection
- Short / long label format
- X/Y offset from the default anchor

---

### 6.21 Reticle / Crosshair

A screen-center crosshair overlay for players who prefer a visual aiming reference.

- Toggle via `/prey` → Gameplay Enhancement → Reticle
- Multiple reticle styles (dot, cross, circle variations)
- Custom color and opacity
- Configurable size

---

### 6.22 Anchoring System

A flexible anchor system that lets you attach any PreyUI frame to another frame with named anchor points.

- Named anchors (e.g., "BelowPlayer", "RightOfMinimap")
- Relative positioning with configurable X/Y offsets
- Visual anchor markers shown during positioning
- Lock / unlock all anchors simultaneously
- Anchor categories for organizational grouping

---

## 7. Blizzard Frame Skinning

PreyUI optionally reskins standard WoW frames to match the PreyUI color palette (dark background, crimson accent by default). Each skin is opt-in or opt-out via `/prey` → Skinning.

| Frame | Setting Key | Default |
|-------|-------------|---------|
| Alert / toast frames (achievement, loot, boss) | `skinAlerts` | ON |
| Character panel (stats, reputation, currency) | `skinCharacterFrame` | ON |
| Inspect frame | `skinInspectFrame` | ON |
| Loot window, roll frames, loot history | `skinLootWindow` | ON |
| Quest / objective tracker | `skinObjectiveTracker` | OFF |
| ESC menu (Game Menu) | `skinGameMenu` | OFF |
| Boss / arena instance frames | `skinInstanceFrames` | OFF |
| Override / vehicle action bar | `skinOverrideActionBar` | OFF |
| Encounter power bar (PlayerPowerBarAlt) | `skinPowerBarAlt` | ON |
| M+ Timer frame | `skinMplusTimer` | ON |

### Skin Color
The skin accent color defaults to PreyUI Crimson (`#D62D38`). You can:
- Use your **class color** as the accent (`skinUseClassColor = true`)
- Set a **custom RGB** accent color

The background color defaults to near-black (`#0D0D0D, 95% opacity`).

---

## 8. Profile System

PreyUI uses **AceDB-3.0** for settings storage. All settings are saved per-profile in `PreyUI_DB` (SavedVariable).

### Profile Scopes
| Scope | Key | Contents |
|-------|-----|----------|
| Profile | `profile` | All addon settings — shared across characters using the same profile |
| Character | `char` | Character-specific data (debug flags) |
| Global | `global` | Account-wide data (profile imports, spec tracker spells) |

### Default Profile
The default profile is named `"Default"` and is shared across all characters unless you create character-specific profiles.

### Export / Import

#### Exporting
1. Open `/prey` → Profiles tab
2. Click **Export Profile**
3. Copy the string starting with `PREY1:...`

#### Importing
1. Open `/prey` → Profiles tab
2. Paste the `PREY1:...` string into the import field
3. Click **Import**

The profile string is compressed (LibDeflate) and base64-encoded for compact sharing. Strings from older PreyUI versions (`KORI1:`) and legacy CDM exports (`CDM1:`) are also accepted.

### Legacy Migration
`backwards.lua` automatically migrates saved variables from previous PreyUI/KoriUI versions:
- Datatext slot architecture (pre-3.0 format)
- Master text color toggles (from legacy `classColorText`)
- Chat edit box table format
- Cooldown swipe v2 (3-toggle system)

---

## 9. Edit Mode Integration

PreyUI respects WoW's built-in **Edit Mode** for frame positioning. In addition, PreyUI provides its own unit frame edit mode.

### Unit Frame Edit Mode
- Activate with `/prey editmode` or via the options GUI
- All unit frames become draggable
- An overlay shows current X/Y coordinates
- Sliders in the options panel sync in real-time during drag
- Click **Save** or close the panel to lock positions

### Blizzard Edit Mode
- CDM bars (Essential, Utility, Defensive) are positioned in Blizzard's Edit Mode
- PreyUI saves the position after Edit Mode closes
- Some PreyUI frames (skyriding bar, stagger bar, combat timer) have their own independent drag-to-move systems and do not use Edit Mode

---

## 10. Keybindings

### Registered Bindings
| Binding | Default | Description |
|---------|---------|-------------|
| `PREYUI_TOGGLE_OPTIONS` | None | Open PreyUI options GUI |

Assign this binding in the WoW Keybindings panel under the **PreyUI** category.

### Quick Keybind Mode
`/kb` opens LibKeyBound, which lets you bind action bar buttons by hovering over them and pressing a key. If LibKeyBound is not available, WoW's Quick Keybind Frame is shown instead.

### Bindings.xml
Custom keybindings are declared in `Bindings.xml` at the addon root. The binding name is set globally as `BINDING_NAME_PREYUI_TOGGLE_OPTIONS`.

---

## 11. Performance & Settings

### UI Scale
PreyUI includes a Perfect Pixel system (`perfectpixel.lua`) that calculates the optimal `UIScale` for your monitor resolution.

| Monitor | Recommended Scale |
|---------|------------------|
| 1080p | ~0.71 |
| 1440p | ~0.64 (default) |
| 4K / 2160p | ~0.43 |

Apply via `/prey` → General → UI Scale, or use the **Auto-Scale** button.

### Eyefinity / Ultrawide Support
Enable `general.eyefinity` for triple-monitor setups or `general.ultrawide` for ultrawide resolutions. This adjusts the scale calculation to use the effective single-monitor width.

### FPS Presets
`/prey` → Performance provides CVar presets (58 CVars) for three performance tiers:

| Preset | Target Use |
|--------|-----------|
| **High Performance** | Raiding / M+ — maximum FPS optimization |
| **Balanced** | General questing with visual quality maintained |
| **Quality** | Cinematic settings for screenshots or RP |

### Garbage Collection
- **Manual GC** — triggers `collectgarbage("collect")` immediately
- **Auto GC** — runs GC every 30 seconds automatically

### Update Frequencies
Understanding how often PreyUI modules update helps with performance expectations:

| Module | Update Method | Frequency |
|--------|--------------|-----------|
| Unit Frames | Event-driven | On UNIT_HEALTH, UNIT_POWER, etc. |
| Castbars | Ticker | ~10 FPS (100ms) |
| Buff/Debuff timers | Ticker | ~10 FPS (100ms) |
| Minimap clock | Ticker | 1 Hz (1s) |
| Minimap coordinates | Ticker (hover) | ~4 Hz (250ms) |
| M+ Timer | Ticker | 10 Hz (100ms) |
| Skyriding bar | OnUpdate with throttle | 20 FPS (50ms) |
| Stagger bar | OnUpdate throttled | ~60 FPS (16ms) with 150ms animation |
| Tooltip mouse cache | Cached | 200ms TTL |
| Rotation Assist | Ticker | 3.3 Hz combat / 1 Hz idle |

---

## 12. Localization

PreyUI ships with translations for 13 locales:

| Code | Language |
|------|----------|
| `enUS` | English (default) |
| `deDE` | German |
| `frFR` | French |
| `esES` | Spanish (Spain) |
| `esMX` | Spanish (Mexico) |
| `ruRU` | Russian |
| `ptBR` | Portuguese (Brazil) |
| `koKR` | Korean |
| `zhCN` | Simplified Chinese |
| `zhTW` | Traditional Chinese |
| `itIT` | Italian |

Localization is handled via **AceLocale-3.0**. Missing translations fall back to `enUS`.

---

## 13. Library Dependencies

All libraries are **bundled** with PreyUI. No external addon dependencies are required.

| Library | Version | Purpose |
|---------|---------|---------|
| LibStub | 1.0 | Library loader |
| AceAddon-3.0 | 3.0 | Addon framework |
| AceDB-3.0 | 3.0 | Profile/settings storage |
| AceEvent-3.0 | 3.0 | Event handling |
| AceConsole-3.0 | 3.0 | Slash commands and print |
| AceLocale-3.0 | 3.0 | Localization |
| AceComm-3.0 | 3.0 | Inter-addon communication (future use) |
| AceSerializer-3.0 | 3.0 | Profile export serialization |
| CallbackHandler-1.0 | 1.0 | Callback infrastructure |
| LibSharedMedia-3.0 | 3.0 | Shared font/texture/sound registry |
| LibCustomGlow-1.0 | 1.0 | Icon and frame glow effects |
| LibKeyBound-1.0 | 1.0 | Quick keybind mode |
| LibDualSpec-1.0 | 1.0 | Spec detection and dual-spec support |
| LibDeflate | — | Profile compression |
| LibOpenRaid | — | Raid unit information |

---

## 14. Troubleshooting

### "PreyUI: GUI not loaded yet. Try again in a moment."
This appears if `/prey` is typed before the addon fully initializes (very early after login). Wait 1–2 seconds and try again.

### Cooldown bars are not showing
1. Open `/prey` → Gameplay Enhancement and ensure **Cooldown Manager** is toggled ON
2. In WoW Game Menu → Interface → Gameplay, ensure **Cooldown Viewer** is enabled
3. Use `/cdm` to open Blizzard's CDM settings and verify your class abilities are configured

### Action bars are invisible
Action bars fade out by default. Move your mouse to the bottom of the screen where bars are positioned. To make them always visible, open `/prey` → Action Bars and disable fade for each bar.

### Frame positions reset after reload
If you moved frames in Blizzard Edit Mode, ensure you clicked **Save** before closing Edit Mode. PreyUI saves CDM positions on Edit Mode exit.

### Stagger bar not showing (Monk only)
Confirm your specialization is set to **Brewmaster** (Spec ID 268). The bar initializes on `PLAYER_SPECIALIZATION_CHANGED` and `PLAYER_ENTERING_WORLD`.

### "Reload queued" but reload never happens
If you typed `/rl` in combat and combat never ended (e.g., you left the instance), the reload popup will still appear the next time you leave combat. You can dismiss it with **Later** if you no longer want to reload.

### Import string fails to decode
- Ensure the string starts with `PREY1:` (or the legacy `KORI1:` / `CDM1:` prefixes)
- Remove any extra spaces before pasting — the import function strips whitespace automatically
- Strings generated by a significantly older PreyUI version may not be compatible if the profile schema changed

### Performance degradation in large raids
Disable features with constant `OnUpdate` activity in crowded content:
- Skyriding bar (not relevant in raids anyway)
- Combat text (high COMBAT_LOG_EVENT_UNFILTERED volume)
- Custom trackers with many watchers

### Taint / "Interface action blocked" errors
PreyUI uses `pcall()` guards and avoids modifying protected frames directly. If you see a taint error mentioning `PreyUI`:
1. Note the specific module or frame mentioned in the error
2. Disable that feature in `/prey` as a workaround
3. Report the issue with the full error text (see [Contributing](#contributing))

---

## 15. FAQ

**Q: Does PreyUI replace oUF, ElvUI, or SUI?**  
A: PreyUI is a standalone suite. It does not require oUF or any other UI framework. It is not compatible with ElvUI running simultaneously (both would skin the same frames).

**Q: Can I use only some features of PreyUI?**  
A: Yes. Almost every module has an enable/disable toggle in `/prey`. You can use only the Minimap module, for example, while keeping default Blizzard unit frames.

**Q: Does PreyUI support Classic WoW?**  
A: No. PreyUI targets Interface 120001+ (Retail: The War Within / Midnight). The API calls used (e.g., `C_Spell`, `C_AssistedCombat`, `C_Container`, `Enum.PowerType`) are not available in Classic.

**Q: My fonts look blurry or pixel-shifted.**  
A: Use `/prey` → General → **Auto-Scale** to set the pixel-perfect UI scale for your resolution. Fonts will be sharp once the scale aligns to whole-pixel boundaries.

**Q: The M+ timer doesn't start automatically.**  
A: The timer listens for the `CHALLENGE_MODE_START` event. Ensure you are in a valid Mythic+ dungeon (not a normal/heroic dungeon). Use the **Demo Mode** button in `/prey` → M+ Timer to test the layout.

**Q: Can I share my settings with a friend?**  
A: Yes. Open `/prey` → Profiles → **Export Profile**, copy the `PREY1:...` string, and send it to your friend. They paste it into `/prey` → Profiles → **Import**.

**Q: The Skyriding bar shows when I'm not riding.**  
A: The bar auto-hides after a configurable idle-on-ground duration. If it persists, check the **Auto-Hide** delay setting in `/prey` → Gameplay Enhancement → Skyriding.

**Q: Will enabling all features impact my FPS?**  
A: PreyUI is designed for performance. In a full raid encounter, the additional CPU overhead versus the default WoW UI is under 1ms per frame in most configurations. The heaviest feature is the Custom Trackers module if you create many watchers. For maximum FPS, use the High Performance preset in `/prey` → Performance.

---

## 16. Changelog Highlights

### v3.0.12 (Current)
- Fixed Blizzard taint from ESC menu button injection
- Fixed alert frame anchor dependency errors on login
- Fixed protected frame taint from extra action / zone ability positioning
- `SafeSetBackdrop` now defers backdrop setup when Midnight secret values are detected
- Improved `compat.lua` shims for WoW 12.0+ `C_Spell` API changes

### v3.0.11
- Rebuilt Unit Frames with Midnight API compatibility (`UnitHealthPercent` wrapper)
- NCDM: migrated icon state tracking to weak-reference tables to prevent memory leaks
- Buff bar: improved hash-based polling with sticky-center debounce
- Skyriding bar: added Second Wind pip display and smooth lerp animation

### v3.0 (Major Rebuild)
- Complete UI rebuilt from PREYCore v1.18 with proper AceDB-3.0 integration
- All branding migrated from KoriUI to PreyUI
- New custom GUI framework replacing AceConfig
- Added profile import/export with LibDeflate compression
- Added Mythic+ timer with three layout modes
- Added Custom Trackers system
- Added Anchoring system

---

## Contributing

Bug reports and feature requests: open an issue at the project repository.

When reporting a bug, please include:
1. Your WoW build (`/run print((select(4,GetBuildInfo())))`)
2. PreyUI version (`/run print(PreyUI.versionString)`)
3. The full error text from the Error Frame or BugSack
4. Steps to reproduce the issue
5. Which modules are enabled

---

*PreyUI is licensed under GPLv3. All Ace3 libraries retain their original licenses (MIT). See individual library headers for details.*
