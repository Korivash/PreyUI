# PreyUI - Feature Documentation

Complete guide to all features and modules in PreyUI.

----

## Table of Contents

1. [Action Bars](#action-bars)
2. [Unit Frames](#unit-frames)
3. [Castbars](#castbars)
4. [Minimap](#minimap)
5. [Buff & Debuff System](#buff--debuff-system)
6. [Cooldown Manager](#cooldown-manager)
7. [Mythic+ Features](#mythic-features)
8. [Combat Enhancements](#combat-enhancements)
9. [Custom Trackers](#custom-trackers)
10. [Chat System](#chat-system)
11. [Tooltips](#tooltips)
12. [Quality of Life](#quality-of-life)
13. [Anchoring System](#anchoring-system)
14. [Performance Tools](#performance-tools)

---

## Action Bars

Complete action bar replacement with modern styling and extensive customization.

### Features

#### Visual Customization
- **Icon Borders**: Apply custom borders to action bar buttons
  - Border colors: Class-colored, custom RGB, or disabled
  - Border thickness adjustments
  - Proc glow effects on ability ready

- **Cooldown Display**
  - Custom cooldown swipe textures
  - Numeric cooldown timers
  - OmniCC integration support
  - Cooldown effects (spiral, radial, etc.)

- **Button Styling**
  - Custom button background textures
  - Highlight effects on mouseover
  - Pushed/checked state visuals
  - Macro text and keybind display options

#### Visibility Controls
- **Mouseover Fade**
  - Fade action bars when not in use
  - Adjustable fade opacity (0-100%)
  - Fade speed customization
  - Combat visibility override

- **Per-Bar Controls**
  - Action Bar 1-8 individual visibility
  - Pet action bar show/hide
  - Stance/form bar controls
  - Extra action button positioning

#### Keybind System
- **Quick Keybind Mode** (`/kb`)
  - Hover over buttons to bind keys
  - Mousewheel support via LibKeyBound
  - Visual feedback during binding
  - Save/cancel options

- **Display Options**
  - Show/hide keybind text on buttons
  - Keybind text size and font
  - Abbreviate modifier keys (`Ctrl`, `C`)

### Configuration Path
`/prey` -> **Actionbars** tab

### Technical Details
- **Module**: `prey_actionbars.lua`
- **Dependencies**: LibKeyBound-1.0
- **Hooks**: Blizzard Action Bar system
- **Performance**: Minimal impact, event-driven updates

---

## Unit Frames

Modern unit frame system with extensive customization for player, target, focus, and party frames.

### Player Frame

#### Health Bar
- **Color Options**
  - Class-colored health bars
  - Custom RGB color selection
  - Gradient health (full -> empty)
  - Dark mode background

- **Display Options**
  - Health value format (percent, current, max, combined)
  - Font selection from LibSharedMedia
  - Text size and positioning
  - Absorb shield visualization with stripe effects

#### Power Bar
- **Power Types Supported**
  - Mana, rage, focus, energy, runic power
  - Class-specific: combo points, holy power, chi, soul shards, arcane charges
  - Alternative power (raid mechanics)

- **Customization**
  - Power color by type or custom
  - Separate or attached to health bar
  - Size and width adjustments

#### Advanced Features
- **Portrait Display**
  - 2D or 3D portrait
  - Position: left, right, overlay
  - Size customization

- **Buffs/Debuffs**
  - Show player buffs on frame
  - Filter by type (magic, disease, curse, poison)
  - Size and position adjustments
  - Timer overlays

### Target Frame

All player frame options plus:
- **Threat Indicator**
  - Glow when you have aggro
  - Color-coded threat level

- **Interrupt Indicator**
  - Highlight when target is casting interruptible spell
  - Integration with castbar

### Focus Frame

- Smaller, more compact version of target frame
- Same customization options
- Ideal for arena/PvP focus targets

### Party Frames

- **Layout Options**
  - Horizontal or vertical growth
  - Spacing adjustments
  - Number of visible frames (1-5)

- **Display Mode**
  - Compact: Small frames for healing
  - Standard: Medium size for general use
  - Large: Big frames for detailed tracking

- **Group Features**
  - Role icons (tank, healer, DPS)
  - Range fading for out-of-range members
  - Debuff highlighting on frames

### Configuration Path
`/prey` -> **Unit Frames** section  
`/prey editmode` for positioning

### Technical Details
- **Module**: `prey_unitframes.lua`
- **Update Rate**: Event-driven (`UNIT_HEALTH`, `UNIT_POWER`, etc.)
- **Memory**: Frames created on demand, pooled for efficiency
- **Edit Mode**: Drag-and-drop repositioning with save states

---

## Castbars

Advanced castbar system for player, target, and focus with interrupt tracking.

### Features

#### Player Castbar
- **Cast Information**
  - Spell name and rank
  - Cast time remaining (numeric)
  - Channel tick information
  - Empowered spell stages (for evoker)

- **Visual Elements**
  - Spell icon (left, right, or hidden)
  - Cast bar color customization
  - Separate channel bar color
  - Shield indicator for uninterruptible casts

- **Pushback Tracking**
  - Visual indication of cast delay from damage
  - Numeric display of added cast time
  - Color change on pushback

#### Target Castbar
- **Interrupt Highlighting**
  - Bright color when cast is interruptible
  - Shield icon for immune/shielded casts
  - Fades when target finishes cast

- **Cast Success/Failure**
  - Visual feedback on successful casts
  - Fade out animation
  - Reset on interrupt

#### Focus Castbar
- Same features as target castbar
- Useful for tracking additional targets in PvP/PvE

### Position & Sizing
- **Anchor Points**: Attach to unit frames or custom positions
- **Width/Height**: Fully adjustable dimensions
- **Icon Size**: Independent icon sizing
- **Text Options**: Font, size, alignment

### Configuration Path
`/prey` -> **Castbars** section

### Technical Details
- **Module**: `prey_castbar.lua`
- **Events**: `UNIT_SPELLCAST_START`, `UNIT_SPELLCAST_STOP`, `UNIT_SPELLCAST_INTERRUPTED`, etc.
- **Latency**: Includes spell queue window visualization

---

## Minimap

Modern minimap redesign with clean button organization and enhanced features.

### Visual Options

#### Shape & Style
- **Shapes**: Circular, square, rounded square
- **Border**: Custom border texture and color
- **Background**: Opacity and color adjustments
- **Size**: Scalable from 100-300px

#### Zone & Time Display
- **Zone Text**
  - Current zone name above minimap
  - Font and size customization
  - Mouseover fade option

- **Clock/Calendar**
  - 12/24 hour format
  - Date display (optional)
  - Tooltip with calendar info

### Button Organization

#### Auto-Tracking
- Automatically captures minimap buttons from other addons
- Organizes in clean grid or circular pattern
- Mouseover reveal option

#### Manual Control
- Drag buttons to reposition
- Hide specific buttons
- Adjust button spacing

### Tracking Features

#### Skyriding Vigor (Dragonriding)
- Vigor bar around minimap edge
- Charge indicators
- Cooldown timers
- Color customization

#### Difficulty Badge
- Dungeon/raid difficulty icon
- Mythic keystone level display
- Scalable size

### Configuration Path
`/prey` -> **Minimap** section

### Technical Details
- **Module**: `preycore_minimap.lua`
- **Hooks**: Minimap button creation hooks
- **Performance**: Button organization is one-time on login, minimal runtime cost

---

## Buff & Debuff System

Comprehensive buff and debuff tracking with customizable bars.

### Buff Bar

#### Personal Buffs
- **Display Options**
  - Icon size: 20-60px
  - Rows and icons per row
  - Growth direction (right/left, up/down)

- **Filtering**
  - Show all buffs or whitelist only
  - Hide specific buffs (blacklist)
  - Consolidate similar buffs
  - Weapon enchant separate tracking

- **Timer Display**
  - Numeric timers on icons
  - Color-coded by remaining time
  - Flash on expiry warning

#### Raid Buffs
- **Missing Buff Alerts**
  - Flask, food, rune
  - Raid-wide buffs (fort, int, stam)
  - Custom alerts for specific buffs

- **Display Mode**
  - Separate bar for raid buffs
  - Integrated with personal buffs
  - Icon-only or icon + text

### Debuff Bar

#### Personal Debuffs
- Same options as buff bar
- Dispellable highlight (by class)
- Boss debuff prominence

#### Target Debuffs
- **Your Debuffs Only**: Filter to show only your applied debuffs on target
- **All Debuffs**: Show all debuffs on target
- **Important Only**: Show only high-priority debuffs (enrage, magic vulnerabilities)

### Configuration Path
`/prey` -> **Buff Bars** section

### Technical Details
- **Module**: `prey_buffbar.lua`
- **Update**: Every 0.1s for timer accuracy
- **Memory**: Buff icons created from pool, recycled efficiently

---

## Cooldown Manager

Advanced cooldown tracking system (CDM) for monitoring your abilities and party/raid cooldowns.

### Overview

The CDM provides visual cooldown bars that track essential, utility, and defensive abilities for you and your party/raid members.

### Features

#### Cooldown Bars
- **Essential Bar**: Major DPS cooldowns (Bloodlust, hero, major CDs)
- **Utility Bar**: CC, interrupts, utility abilities
- **Defensive Bar**: Defensive CDs, immunities, healing CDs

#### Visual Options
- **Icon Size**: 30-80px
- **Arrangement**: Horizontal or vertical
- **Spacing**: Adjustable gaps between icons
- **Glow Effects**: Proc glow when ability is off cooldown

#### Filtering System
- **Auto-Detection**: Automatically detects class/spec abilities
- **Custom Filters**: Add/remove specific spell IDs
- **Priority System**: Important abilities shown first
- **Charge Tracking**: Shows ability charges (1/2, 2/3, etc.)

#### Party/Raid Tracking
- **Group Cooldowns**: See party/raid member cooldowns
- **Role-Based Filtering**: Filter by tank, healer, or DPS cooldowns
- **Mouseover Info**: Tooltip shows who owns the cooldown

### Setup Guide

1. **Enable CDM**: `/prey` -> **Cooldown Manager** -> Enable
2. **Enter Edit Mode**: `/prey editmode` or standard Edit Mode
3. **Position Bars**: Drag CDM bars to desired locations
4. **Adjust Size**: Use Edit Mode scaling or `/prey` settings
5. **Configure Filters**: Add/remove abilities as needed
6. **Save Layout**: Click "Save" in Edit Mode

### Best Practices

- Use 100% icon size in Edit Mode for optimal display
- Position bars near player frame for quick glance
- Enable glow effects for instant feedback
- Separate essential from utility for visual clarity

### Configuration Path
`/prey` -> **Cooldown Manager** section  
`/cdm` for quick settings access

### Technical Details
- **Module**: `prey_ncdm.lua`
- **Update Rate**: Event-driven + 0.5s polling
- **Spell Database**: Per-class spell lists in module
- **Performance**: Minimal impact, efficient spell tracking

---

## Mythic+ Features

Comprehensive tools for Mythic+ dungeon content.

### M+ Timer

#### Core Features
- **Main Timer**
  - Large, visible timer display
  - Depleted/completed visual feedback
  - Pause detection (disconnect, leave dungeon)

- **Split Timers**
  - +3 chest timer (green)
  - +2 chest timer (yellow)
  - Time remaining to each level

- **Progress Tracking**
  - Enemy forces: current/total (percentage)
  - Boss kills: X/Total
  - Progress bar visualization
  - Real-time updates

#### Death Tracking
- **Death Counter**
  - Total deaths in dungeon
  - Time penalty per death (configurable)
  - Death log with timestamps
  - Mouseover for death details

#### Affix Information
- **Active Affixes**: Display this week's affixes with icons
- **Seasonal Mechanics**: Special mechanic timers (e.g., orb spawns)
- **Affix Warnings**: Visual/audio alerts for key events

#### Customization
- **Position & Size**: Drag to reposition, scale to preference
- **Color Themes**: Success (green), warning (yellow), danger (red)
- **Font Options**: LibSharedMedia font selection
- **Display Modes**: Compact, standard, or detailed

### Keystone Manager

#### Features
- **Active Key Display**
  - Current keystone level and dungeon
  - Visual icon on UI
  - Quick reference

- **Auto-Announce**
  - Announce key in party/raid chat
  - Customizable message format
  - Manual or automatic triggers

- **Key Tracking**
  - Track your weekly key
  - Track party members' keys
  - Visual indicators for completed keys

### Dungeon Teleports

#### Quick Teleport System
- **One-Click Teleports**: Teleport to any dungeon entrance
- **Season Awareness**: Only shows current season dungeons
- **Party Leader Detection**: Only available to party/raid leader
- **Integration**: Access via `/prey` -> **M+ & Raiding** -> **Teleports**

#### Available Dungeons
- All current season M+ dungeons
- Previous season dungeons (optional)
- Raid entrances

### Configuration Path
`/prey` -> **M+ & Raiding** section

### Technical Details
- **M+ Timer Module**: `prey_mplus_timer.lua`
- **Keystone Module**: `prey_keystone.lua`
- **Dungeon Data**: `prey_dungeon_data.lua` (season-aware)
- **Events**: `CHALLENGE_MODE_START`, `CHALLENGE_MODE_COMPLETED`, `PLAYER_DEAD`, etc.

---

## Combat Enhancements

Features that improve combat awareness and performance.

### Combat Text

#### Outgoing Damage
- **Damage Numbers**: Show your damage on targets
- **Crit Animation**: Larger, different color for crits
- **Multi-Target**: Cleave/AoE combined numbers
- **Scroll Direction**: Up, down, or arc

#### Incoming Damage
- **Damage Taken**: See incoming damage
- **Absorb Indication**: Show absorbed damage separately
- **Position**: Near player frame or custom

#### Healing Numbers
- **Self Healing**: Track your self-healing
- **Outgoing Healing**: Show healing done to others
- **HoT Ticks**: Optional periodic healing display

#### Customization
- **Font & Size**: Full font control
- **Colors**: By damage type, school, or custom
- **Animation**: Bounce, arc, fountain styles
- **Throttling**: Combine small hits to reduce spam

### Combat Timer

#### Features
- **Engagement Timer**: Tracks time since combat started
- **Encounter Timer**: Boss fight duration
- **Reset on Exit**: Auto-resets when leaving combat
- **Display Options**: Show during combat only or always visible

#### Use Cases
- Practice rotation timings
- Track boss kill times
- Monitor combat uptime

### Rotation Assist

#### Ability Suggestions
- **Next Ability**: Suggests next ability in rotation (basic implementation)
- **Cooldown Ready**: Highlights when major CDs are available
- **Proc Tracking**: Shows when procs are active

#### Visual Feedback
- **Icon Glow**: Glows around suggested abilities
- **Priority System**: Shows most important ability first
- **Spec Awareness**: Adapts to your current specialization

### Configuration Path
`/prey` -> **Combat Enhancements** section

### Technical Details
- **Combat Text Module**: `prey_combattext.lua`
- **Combat Timer Module**: `prey_combattimer.lua`
- **Rotation Assist Module**: `prey_rotationassist.lua`
- **Events**: `COMBAT_LOG_EVENT_UNFILTERED` (optimized parsing)

---

## Custom Trackers

Create custom tracking displays for any buff, debuff, or resource.

### Overview

The custom tracker system allows you to create visual indicators for specific spells, buffs, or resources that are important to your class/spec.

### Features

#### Tracker Types
- **Icon Tracker**: Shows an icon when buff/debuff is active
- **Bar Tracker**: Shows a progress bar (duration or stacks)
- **Numeric Tracker**: Shows a number (stacks, resource amount)
- **Text Tracker**: Shows custom text with dynamic values

#### Trigger Conditions
- **Aura Tracking**: Track specific buffs/debuffs by spell ID
- **Resource Tracking**: Track custom resources (e.g., holy power, combo points)
- **Cooldown Tracking**: Track specific cooldown availability
- **Conditional Display**: Show only in combat, on specific targets, etc.

#### Visual Options
- **Size & Position**: Drag to position, resize as needed
- **Colors**: Custom colors for active/inactive states
- **Glow Effects**: Apply glow when active
- **Timers**: Show remaining duration on icons/bars

### Creating a Custom Tracker

1. **Open GUI**: `/prey` -> **Custom Trackers**
2. **Create New**: Click "Create New Tracker"
3. **Configure Trigger**:
   - Enter Spell ID or Spell Name
   - Select trigger type (buff, debuff, cooldown)
   - Set target unit (player, target, focus)
4. **Customize Display**:
   - Choose display type (icon, bar, numeric)
   - Set size, colors, fonts
   - Configure visibility conditions
5. **Position**: Drag tracker to desired location
6. **Test**: Apply buff/use ability to verify

### Example Use Cases

#### Shadow Priest: Voidform Tracker
- Track Voidform buff duration
- Show visual warning at low duration
- Position near player frame

#### Feral Druid: Combo Point Display
- Large combo point icons
- Glow when at max combo points
- Position near target frame

#### Protection Warrior: Shield Block Tracker
- Track Shield Block uptime
- Show charges remaining
- Alert when all charges on cooldown

### Configuration Path
`/prey` -> **Custom Trackers** section

### Technical Details
- **Module**: `prey_customtrackers.lua`
- **Database**: Trackers stored in character profile
- **Events**: `UNIT_AURA`, `SPELL_UPDATE_COOLDOWN`, `UNIT_POWER_UPDATE`
- **Performance**: Each tracker adds minimal overhead (`~0.01ms` per update)

---

## Chat System

Enhanced chat functionality with improved visuals and features.

### Features

#### URL Detection
- **Auto-Detection**: Automatically detects and highlights URLs
- **Clickability**: Click URLs to copy to clipboard
- **Supported Formats**: `http://`, `https://`, `www.`, `.com/.net/.org`

#### Channel Abbreviations
- **Shortened Names**: Long channel names abbreviated
  - `[General]` -> `[G]`
  - `[Trade]` -> `[T]`
  - `[Guild]` -> `[GD]`
  - Custom abbreviations configurable

#### Timestamps
- **Message Timestamps**: `[HH:MM]` or `[HH:MM:SS]` format
- **Color Options**: Custom color for timestamps
- **Toggle**: Enable/disable per preference

#### Player Names
- **Class Colors**: Player names colored by class
- **BattleTag Format**: Show `BattleTag#1234` or simplify
- **Realm Display**: Show or hide realm names

#### Chat Styling
- **Custom Colors**: Per-channel color customization
- **Font Options**: Change chat font and size
- **Background**: Adjust chat background opacity
- **Border**: Custom border style for chat frames

### Chat Commands

- **Copy Chat**: Right-click chat frame -> "Copy Chat" to copy all text
- **Clear Chat**: `/clear` to clear active chat frame
- **Font Size**: `/fontsize [size]` to adjust chat font

### Configuration Path
`/prey` -> **Chat** section

### Technical Details
- **Module**: `prey_chat.lua`
- **Hooks**: Chat frame message processing
- **Performance**: URL scanning optimized with caching

---

## Tooltips

Enhanced tooltip system with additional information and styling.

### Features

#### Item Information
- **Item Level**: Shows item level on gear tooltips
- **Vendor Price**: Buy/sell prices
- **Stack Size**: Current/max stack count
- **Item ID**: Shows item ID (useful for addon developers)

#### Player Information
- **Inspect Info**: When mousing over players
  - Character level and class
  - Item level (if inspectable)
  - Guild name
  - Current zone

- **Achievement Info**: Points, date earned
- **Mount/Pet Source**: Where mount/pet is obtained

#### Spell Information
- **Spell ID**: Shows spell ID for developers
- **Cooldown**: Spell base cooldown
- **Range**: Min/max range
- **Cost**: Mana/resource cost

#### NPC Information
- **NPC ID**: Shows NPC ID
- **Faction**: Horde/Alliance/Neutral
- **Classification**: Normal, Rare, Elite, Boss

#### Mythic+ Information
- **Keystone Info**: Shows keystone level and dungeon
- **M+ Rating**: Shows character's M+ rating
- **Best Run**: Best run for specific dungeon

### Visual Options
- **Position**: Anchor to mouse or fixed position
- **Colors**: Custom background and border colors
- **Font**: Tooltip font and size
- **Fade**: Mouseover fade timing

### Configuration Path
`/prey` -> **Tooltips** section

### Technical Details
- **Module**: `prey_tooltips.lua`
- **Hooks**: `OnTooltipSetItem`, `OnTooltipSetUnit`, `OnTooltipSetSpell`
- **Performance**: Information gathered on-demand, no pre-caching

---

## Quality of Life

Miscellaneous features that improve everyday gameplay.

### Quick Salvage

#### Features
- **One-Click Salvage**: Salvage anima/artifact items with one click
- **Quality Detection**: Automatically detects salvageable items
- **Bulk Processing**: Salvage all eligible items at once
- **Safety Check**: Confirms before salvaging valuable items

#### Configuration
- **Keybind**: Set custom keybind for quick salvage
- **Auto-Confirm**: Skip confirmation for low-value items
- **Include Threshold**: Set minimum item value to prompt confirmation

### Blizzard Options Integration

#### Quick Access
- **Game Menu Shortcuts**: Adds shortcuts to `/prey` in game menu
- **Interface Options**: Quick links to common Blizzard settings
- **Edit Mode Access**: One-click access to edit mode

### Auto-Repair

- **Auto-Repair**: Automatically repairs gear at vendors
- **Use Guild Bank**: Option to repair using guild bank funds
- **Spending Limit**: Set maximum auto-repair cost

### Auto-Sell Junk

- **Sell Gray Items**: Automatically sells all gray items at vendors
- **Confirmation**: Optional confirmation dialog
- **Earnings Report**: Shows total gold earned from selling

### Skyriding Enhancements

#### Vigor Display
- **Vigor Bar**: Visual vigor/energy bar
- **Charge Indicators**: Individual charge dots
- **Cooldown Timers**: Shows time until next vigor charge

#### Dragonriding Options
- **Auto-Mount**: Auto-mount dragonriding mount in Dragon Isles
- **Favorite Mount**: Set preferred dragonriding mount
- **Glyph Tracker**: Track collected dragonriding glyphs

### Configuration Path
`/prey` -> **Quality of Life** section

### Technical Details
- **Quick Salvage Module**: `prey_quicksalvage.lua`
- **QoL Module**: `prey_qol.lua`
- **Skyriding Module**: `prey_skyriding.lua`

---

## Anchoring System

Advanced anchoring system for creating custom anchor points and attaching UI elements.

### Overview

The anchoring system allows you to create named anchor points and attach multiple UI elements to them. When you move an anchor, all attached elements move together, maintaining their relative positions.

### Features

#### Anchor Creation
- **Named Anchors**: Create anchors with custom names
- **Base Position**: Set initial position on screen
- **Visual Marker**: Toggle visibility of anchor markers for positioning

#### Element Attachment
- **Attach Elements**: Attach unit frames, bars, trackers to anchors
- **Relative Positioning**: Set offset from anchor point
- **Growth Direction**: Elements can grow in any direction from anchor

#### Anchor Management
- **Move Anchor**: Drag anchor to reposition, all elements follow
- **Delete Anchor**: Remove anchor (elements revert to absolute positioning)
- **Lock/Unlock**: Lock anchors to prevent accidental movement

### Use Cases

#### Example 1: Target Frame Cluster
Create an anchor for target-related elements:
- Anchor: `TargetCluster` at center-right of screen
- Attach: Target frame, target castbar, target debuffs
- Result: One anchor point controls the entire target UI section

#### Example 2: Raid Frame Anchors
Create anchors for different raid frame positions:
- Anchor: `HealFrames` for healing focus
- Attach: Party frames, raid frames, incoming heal indicators
- Easy to move entire healing UI as one unit

#### Example 3: Cooldown Anchor
- Anchor: `CooldownSection` near action bars
- Attach: CDM bars, custom cooldown trackers
- Keep all cooldown information together

### Creating an Anchor

1. **Open GUI**: `/prey` -> **Anchoring** tab
2. **Create New**: Click "Create New Anchor"
3. **Name**: Enter descriptive name (e.g., `PlayerCluster`)
4. **Position**: Drag anchor marker to desired location
5. **Attach Elements**: Use dropdown to attach UI elements
6. **Configure Offsets**: Set X/Y offsets for each element
7. **Save**: Anchors auto-save to profile

### Configuration Path
`/prey` -> **Anchoring** section

### Technical Details
- **Module**: `prey_anchoring.lua` + `prey_anchoring_options.lua`
- **Storage**: Anchors stored in character profile
- **Update**: Attached elements update on anchor move
- **Performance**: Minimal, only updates when anchor is moved

---

## Performance Tools

Tools and features to optimize game performance.

### FPS Preset System

#### Overview
One-click graphics optimization that applies 58 CVars for maximum performance while maintaining visual quality.

#### Features
- **Balanced Preset**: Optimizes common performance bottlenecks
- **DirectX 12**: Recommends DX12 for better performance
- **Low Latency Mode**: Enables optimal low latency settings
- **Smart Defaults**: Disables high-cost features (shadows, SSAO, ray tracing)

#### Applied Settings (58 CVars)
The FPS preset adjusts:
- VSync disabled for lower input lag
- MSAA disabled (performance killer)
- Shadow quality reduced
- Particle density lowered
- SSAO and depth effects disabled
- Ray tracing disabled
- Texture filtering optimized
- View distance balanced
- Physics simulations reduced
- Many other optimizations

#### How to Use
1. **Open GUI**: `/prey` -> **Performance** tab
2. **View Current Settings**: See your current CVar values
3. **Apply Preset**: Click "Apply PreyUI FPS Preset"
4. **Reload**: Reload UI for changes to take effect
5. **Test**: Test performance in various scenarios
6. **Revert (if needed)**: Click "Restore Defaults" to revert

#### Performance Gain
- **Expected FPS Increase**: 30-50% in most scenarios
- **Input Lag**: Reduced by 5-10ms
- **Minimum FPS**: More stable, fewer dips

### Perfect Pixel

#### Overview
Automatically adjusts UI scale to ensure crisp, non-blurry textures and fonts.

#### Features
- **Auto-Scale Calculation**: Based on screen resolution
- **Pixel-Perfect Rendering**: Prevents sub-pixel rendering
- **One-Click Apply**: Applies optimal UI scale automatically
- **Preview Mode**: Test scale before applying

#### How It Works
Perfect Pixel calculates the optimal UI scale based on:
- Screen resolution (`1920x1080`, `2560x1440`, `3840x2160`, etc.)
- Current UI scale setting
- Pixel density

Formula: `optimalScale = 768 / screenHeight`

#### When to Use
- After changing screen resolution
- If UI appears blurry or pixelated
- When fonts look fuzzy
- After major graphics updates

### Memory Management

#### Garbage Collection
- **Manual GC**: Force garbage collection via `/prey` -> **Performance**
- **Auto-GC**: Automatically run GC at optimal times (loading screens, out of combat)
- **Memory Display**: Shows current addon memory usage

### Configuration Path
`/prey` -> **Performance** section

### Technical Details
- **FPS Module**: Embedded in `prey_options.lua`
- **Perfect Pixel Module**: `perfectpixel.lua`
- **CVar Application**: Uses Blizzard's CVar API
- **Memory Tracking**: Uses Blizzard's memory profiler APIs

---

## Additional Features

### Ready Check Styling
- Custom ready check frame design
- Large, clear buttons
- Visual feedback on accept/decline
- Timer display for ready check expiry

### Loot Frame Styling
- Modern loot window design
- Item rarity borders
- Quick loot keybinds
- Master looter frame improvements

### Character Panel Styling
- Enhanced character panel UI
- Item level display on equipped gear
- Stat breakdowns and tooltips
- Transmog preview improvements

### Inspect Frame Styling
- Clean inspect frame design
- Shows inspected player's:
  - Current spec and item level
  - Equipped legendary/tier pieces
  - Enchants and sockets
  - M+ rating (if available)

### Instance Frames
- Styled boss frames
- Arena frames with DR tracking
- Raid target icons on frames
- Enemy healer highlighting

### Objective Tracker Styling
- Clean quest tracker design
- Collapsible quest categories
- Progress bars for objectives
- Achievement tracker integration
- Dungeon/scenario objective highlighting

### Alert Frames
- Styled achievement alerts
- Loot roll frames
- Boss encounter warnings
- Battleground/arena score updates

---

## Configuration & Profiles

### Profile System

#### Profile Types
- **Character-Specific**: Unique settings per character
- **Class-Wide**: Share settings across all characters of a class
- **Account-Wide**: Same settings for all characters
- **Custom Profiles**: Create named profiles to share

#### Profile Management
- **Create**: Make new profiles from scratch or copy existing
- **Copy**: Copy settings from another profile
- **Import**: Import profile strings from other players
- **Export**: Export your profile as a string to share
- **Reset**: Reset profile to default settings

#### Auto-Switching
- **Spec-Based**: Automatically switch profiles when changing specs
- **Instance-Based**: Different profiles for raid, M+, PvP, overworld

### Configuration Import/Export

#### Import Profile String
1. **Open GUI**: `/prey` -> **Profiles** tab
2. **Click Import**: Open import dialog
3. **Paste String**: Paste profile string from clipboard
4. **Confirm**: Review settings and confirm import
5. **Reload**: Reload UI to apply

#### Export Profile String
1. **Open GUI**: `/prey` -> **Profiles** tab
2. **Select Profile**: Choose profile to export
3. **Click Export**: Generates string
4. **Copy String**: String automatically copied to clipboard
5. **Share**: Share string with others

### Reset Options

#### Full Reset
- Resets ALL settings to default
- Requires confirmation
- Creates backup of current settings

#### Module Reset
- Reset specific modules (action bars, unit frames, etc.)
- Other settings remain unchanged

#### Position Reset
- Resets only element positions
- Keeps all other settings

### Configuration Path
`/prey` -> **Profiles** tab

---

## Troubleshooting

### Common Issues

#### Action Bars Not Showing
- Check `/prey` -> **Actionbars** -> ensure bars are not set to fade
- Verify bars are not hidden in Edit Mode
- Try `/reload` to refresh action bar state

#### Cooldown Manager Not Working
- Ensure CDM is enabled in settings
- Position CDM bars in Edit Mode
- Check if abilities are in filter list
- Reload UI after enabling

#### Frame Positions Reset After Reload
- Save Edit Mode layout before reloading
- Check if profile auto-switching is enabled (may load different profile)
- Ensure you're not in "Copy from" mode

#### Performance Issues
- Apply FPS preset via `/prey` -> **Performance**
- Disable unused modules
- Reduce number of custom trackers
- Check for conflicting addons

#### Text/Fonts Appearing Blurry
- Use Perfect Pixel via `/prey` -> **Performance** -> **Apply Perfect Pixel**
- Ensure UI scale is appropriate for your resolution
- Check graphics settings (Resolution Scale should be 100%)

### Debug Mode

Enable debug mode for detailed error logging:

```text
/prey debug
```

This will:
- Enable verbose console output
- Log module initialization
- Track event registrations
- Reload UI with debugging active

### Getting Help

If issues persist:
1. Check the PreyUI issue tracker / known issues page
2. Disable other addons to test for conflicts
3. Report bugs with steps to reproduce
4. Include WoW version, PreyUI version, and error messages (if any)

---

## Developer Information

### Module Structure

PreyUI uses a modular architecture:
- **Core**: `preycore_main.lua` - Main initialization and profile management
- **Utils**: `utils/` folder - Individual feature modules
- **Skinning**: `skinning/` folder - Blizzard frame restyling
- **Locales**: `Locales/` folder - Localization files
- **Assets**: `assets/` folder - Textures, fonts, icons

### Adding Custom Modules

To create a custom module:

1. Create `.lua` file in `utils/` folder
2. Add file reference to `utils/utils.xml`
3. Use module template:

```lua
local ADDON_NAME, ns = ...
local PREY = PreyUI
local PREYCore = ns.Addon

-- Module initialization
local function InitModule()
    -- Your code here
end

-- Hook into PREYCore initialization
PREYCore:RegisterEvent("ADDON_LOADED")
PREYCore.InitMyModule = InitModule
```

### API Documentation

#### PREYCore Global Functions

- `PREYCore:SafeReload()` - Safely reload UI (queues if in combat)
- `PREYCore:GetDB()` - Returns AceDB database object
- `PREYCore:RegisterOption(name, table)` - Register options for GUI
- `PREYCore:GetTexture(name)` - Get texture from LibSharedMedia
- `PREYCore:GetFont(name)` - Get font from LibSharedMedia

#### Creating Custom Trackers Programmatically

```lua
local trackerId = PREYCore:CreateCustomTracker({
    name = "My Tracker",
    spellId = 12345,
    triggerType = "buff",
    unitType = "player",
    displayType = "icon",
    size = 40,
    position = { point = "CENTER", x = 0, y = 0 }
})
```

### Contributing

See main README for contribution guidelines.

---

*Documentation version 2.0.0 - Last updated February 2026*
