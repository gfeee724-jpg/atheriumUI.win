# VibeUI - API reference

Monochrome Slate UI library for Roblox (Luau). Full control reference; see
[`../README.md`](../README.md) for install snippets and the project layout.
Two ways to use it:

```lua
-- module build
local VibeUI = loadstring(readfile("VibeUI.lua"))()
local win = VibeUI:CreateWindow({ Title = "My Hub" })

-- single file demo (vibe_hub.lua) already returns the VibeUI table and builds a demo window
```

`VibeUI.Version` is the build number (`"10.0"`). Check it when you depend on
behaviour that was added later:

```lua
local VibeUI = loadstring(readfile("VibeUI.lua"))()
assert(VibeUI.Version == "10.0", "stale VibeUI.lua, re-download it")
```

`readfile` returns whatever copy you saved earlier, and raw URLs sit behind a
CDN cache for a few minutes, so an old version number is the usual reason a
control looks like a previous release. Fetch with `?v=<os.time()>` and
`writefile` the result to refresh the local copy.

Anything named with a leading underscore (`win._glass`, `win:_tc`, `VibeUI._demo`)
is private: it may change without a version bump.

## Build

`VibeUI.lua` is generated, never edited by hand:

```
python tools/build_module.py
```

It copies `vibe_hub.lua` up to the demo marker, stamps `VibeUI.Version` into the
banner, appends `return VibeUI`, and runs the Lua balance checkers on the result.
`vibe_hub.lua` stays a self-contained demo and still returns `VibeUI`.

---

## VibeUI (library root)

| Function | Notes |
| --- | --- |
| `VibeUI.Version` | build string, e.g. `"10.0"` |
| `VibeUI.BuildTag` | internal build id |
| `VibeUI.FontChoices()` | array of font names valid on this client |
| `VibeUI.Paint(inst, color, transp)` | applies a picker color/transparency to a UI or Drawing object |
| `VibeUI.Palette(name)` | chart palette as an array of `Color3`: `mono`, `frost`, `ember`, `mint`, `candy` |
| `VibeUI.FmtInt(v)` | `1234` -> `"1,234"` |
| `VibeUI.FmtK(v)` | `1234` -> `"1.2K"` |
| `VibeUI.FmtPct(v, digits)` | `0.42` -> `"42%"` |
| `VibeUI.RescueCharacter()` | detaches stray Camera / Humanoid manipulation before rebuilding the GUI |
| `VibeUI:CreateWindow(opts)` | builds the window, returns `win` |

### CreateWindow opts

| Key | Type | Default | Notes |
| --- | --- | --- | --- |
| `Title` | string | `"VIBE HUB"` | `GothamBlack` title bar |
| `Subtitle` | string | `"v<Version> mono"` | small top-bar caption |
| `Accent` | `Color3` | white | accent for sliders, toggles, tabs |
| `Acrylic` | boolean | `true` | camera-tracked DoF/glass under the main window |
| `Autosave` | boolean | `false` | periodic `SaveConfig` of dirty state |
| `AutosaveInterval` | number | `30` | seconds, clamped to 5..600 |
| `NotifyLimit` | number | `4` | max visible toasts, the rest queue |

Window is draggable, resizable (`500x540` .. `860x800`), toggled with `RightShift`.
The sidebar tab list scrolls once it no longer fits above the profile card.

---

## win (window)

```lua
local win = VibeUI:CreateWindow({ Title = "My Hub" })
local tab = win:AddTab("Main", "house")
```

| Method | Description |
| --- | --- |
| `win:AddTab(name, icon)` | adds a sidebar tab, returns `Tab` |
| `win:Toggle()` | shows/hides the window (same as the RightShift bind) |
| `win:Notify(title, text, dur, kind)` | toast in the window corner, see below |
| `win:SetAccent(color)` | live accent change |
| `win:SetAcrylic(on)` | enables/disables the blur stack |
| `win:CreatePanel(opts)` | floating panel: `{Title, Icon, Width}`, returns `{frame, body}` |
| `win:CreateKeyList()` | floating keybind list, auto-refreshes from `AddKeybind` controls |
| `win:CreateWatermark(opts)` | floating watermark, see below |
| `win:SetWatermarkVisible(bool)` | show/hide the watermark |

### Notify

```lua
win:Notify("Saved", "Config written to disk.", 3.5, "success")

local n = win:Notify({ Title = "Error", Text = "Load failed.", Duration = 4, Kind = "error" })
n:Close() -- dismiss early
```

`Kind` is one of `info` (default), `success`, `warn`, `error` and only changes
the leading icon. Cards size themselves to the wrapped text, stack upward, and
queue once more than `NotifyLimit` (a `CreateWindow` option, default 4) are on
screen. Clicking a card dismisses it; the thin bar under the text is a life bar
for `Duration` seconds. `Duration = 0` keeps the card up until clicked. The
returned handle exposes `:Close()`.

Theme:

| Method | Description |
| --- | --- |
| `win:SetThemeFont(name)` | `Gotham`, `Montserrat`, `Roboto`, `SourceSans`, `Arial`, `Ubuntu`, `Inter`, `FredokaOne` |
| `win:SetTextColor(color3)` | primary text color |
| `win:SetSubColor(color3)` | secondary text color |
| `win:ResetTheme()` | back to the shipped Slate palette |
| `win:ApplyTheme(root)` | paints an arbitrary GUI tree with the active theme |
| `win:ApplyThemeData(table)` | applies a saved theme blob |
| `win:ThemeRegister(inst, role)` | registers a custom instance for theme repaints (`role` = `text`, `sub`, `icon`, `border`) |

Configs (files live in `Atherium/Configs`):

| Method | Description |
| --- | --- |
| `win:ListConfigs()` | array of saved names |
| `win:SaveConfig(name, silent)` | writes every registered control + theme |
| `win:LoadConfig(name)` | restores controls and theme, toggles keybinds |
| `win:DeleteConfig(name)` | deletes one file |

---

## Tab

| Method | Description |
| --- | --- |
| `tab:AddSection(title, icon)` | section card, returns `Section` |
| `tab:AddSubTab(name, icon)` | inline subtab, returns `Tab` |

## Section

Every `Add*` returns a control object. All controls are saved/restored by name
inside their tab/section unless `NoSave = true`.

Every control also accepts `Tooltip = "text"`. Hovering the row for 0.35s (or
holding it 0.45s on touch) shows one shared bubble above the row; when there is
no room above it flips below. The bubble is capped at 230x180 and wraps.

### AddToggle

```lua
local tg = section:AddToggle({ Name = "Aimbot", Default = false,
    Callback = function(on) print(on) end })
tg:Get() ; tg:Set(true, true) -- second arg = fire Callback
```

### AddSlider

```lua
local sl = section:AddSlider({ Name = "FOV", Min = 10, Max = 120,
    Default = 70, ShowValue = true, Callback = function(v) end })
sl:Get() ; sl:Set(90) -- Set fires Callback
```

The row is title + rail. The current value sits in a fixed 64px slot at the
right of the title line, right aligned and monospace, so every slider lines up
regardless of how many digits it has. It brightens while hovering or dragging
and returns to the secondary tone afterwards. `ShowValue = false` removes that
slot entirely and hands the width back to the title. The track is one flat 5px
capsule (no glow stack, no dark sleeve around the active part); the thumb is a
single 15x20 capsule with one hairline rim, sized 17x22 on hover, flattened to
20x14 while dragging and sprung back on release. Fast drags update position
immediately (no tween), `Set()` and window resizes animate. Title text sits at a
12px left inset and the value ends at the same 12px right inset.

### AddButton

```lua
section:AddButton({ Name = "Reset", Icon = "rotate-ccw", Style = "dark",
    Height = 32, Callback = function() end })
```

`Style = "dark"` gives the filled variant; omit it for the flat row. `Height` is
clamped to 20..60.

### AddDropdown

```lua
local dd = section:AddDropdown({ Name = "Mode", Options = { "Legit", "Rage" },
    Default = "Legit", NoSave = false, Callback = function(v) end })
dd:Get() ; dd:Set("Rage") ; dd:SetOptions({ "A", "B", "C" })
```

Single-select is unchanged: `Get()` returns the string, `Set` fires the callback
unless you pass `false` as the second argument.

Multi-select:

```lua
local parts = section:AddDropdown({
    Name = "Hit Parts",
    Options = { "Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg" },
    Default = { "Head", "Torso" },
    Multiple = true,
    Callback = function(list) print(#list) end,
})
parts:IsMultiple() -- true
parts:Get()        -- { "Head", "Torso" }, in Options order
parts:Set({ "Head", "Left Leg" })
parts:Open() ; parts:Close()
```

With `Multiple = true` the panel grows a `Select all` / `Clear` footer and the
trigger summarises the selection (`None`, the single name, or `3 selected`).
Unknown names passed to `Set` are ignored, and `SetOptions` drops selections
that no longer exist.

Lists longer than six options get a search field automatically (type to filter,
Enter picks the first match); pass `Search = false` to suppress it. The option
list scrolls past eight rows, so a long list never runs off the window.

### AddTextBox

```lua
local tb = section:AddTextBox({ Name = "Prefix", Placeholder = "!", Default = "!",
    Callback = function(text) end })
tb:Get() ; tb:Set("?")
```

### AddColorPicker

```lua
local cp = section:AddColorPicker({ Name = "Highlight", Default = Color3.new(1, 1, 1),
    Transparency = 0, Callback = function(color, transp) end })
cp:Get()          -- color, transparency
cp:Set(color, false)
cp:SetTransparency(0.4)
```

Pair with `VibeUI.Paint` to drive ESP / Drawing objects.

### AddKeybind

```lua
local kb = section:AddKeybind({ Name = "Aimbot Key", Default = Enum.KeyCode.E,
    Toggle = aimToggle, -- optional: a toggle control that gates the bind
    Callback = function(key) end })
kb:Get() -- Enum.KeyCode ; kb:Set(Enum.KeyCode.Q)
```

`RightShift` is reserved for the UI toggle. Bind state feeds `CreateKeyList`.

### AddLabel / AddColumns

```lua
section:AddLabel("plain text")

local left, right = section:AddColumns()
left:AddToggle({ Name = "A" })
right:AddToggle({ Name = "B" })
```

`AddColumns` returns two `Section` proxies so any `Add*` can be used per column.

### AddViewport

```lua
local vp = section:AddViewport({
    Name = "Preview", Height = 220, Model = someModel,
    Clean = true, Clone = true,
    AutoRotate = true, RotateSpeed = 25, Angle = { az = 35, el = 12 },
    FOV = 40, ShowControls = true, Backdrop = Color3.fromRGB(18, 18, 21),
})
vp:SetModel(model, { scale = 1 }) ; vp:SetFromGame(instance)
vp:SetPlayer(player) ; vp:Focus() ; vp:Refresh()
vp:SetAngles(azimuth, elevation) ; vp:SetDistance(9) ; vp:GetDistance()
vp:SetFOV(40) ; vp:SetAutoRotate(true) ; vp:GetAutoRotate()
vp:SetSpeed(25)
vp:SetLighting(ambientColor, lightColor, lightDirection)
vp:SetBackdrop(color3) ; vp:SetBackdrop(nil) -- nil = transparent
vp:Clear()
```

`Angle` accepts a number or `{ az = ..., el = ... }`. `Lighting` in the options
table accepts a table of viewport properties (`Ambient`, `LightColor`, `LightDirection`, ...).
`ShowControls` adds drag-to-rotate and scroll-to-zoom.

### AddChart

```lua
local ch = section:AddChart({
    Name = "FPS", Type = "line", Height = 96, Value = 0, Smooth = true,
    Window = 60, MaxPoints = 120, Thickness = 2, Animated = true,
    AnimationSpeed = 0.18, ShowLabels = true,
    Format = function(v) return string.format("%d", math.floor(v + 0.5)) end,
    Colors = "mono", Data = {}, Delta = 0.2, Caption = "",
})
ch:Push(value) ; ch:SetValue(v) ; ch:SetData({...})
ch:SetColors("mono") -- or a Color3, or an array of Color3
ch:SetThickness(2) ; ch:SetAnimationSpeed(0.18)
ch:SetTitle("...") ; ch:SetFormat(fn) ; ch:SetType("line")
ch:SetWindow(60) ; ch:SetSmooth(true)
ch:GetData() ; ch:GetTotal() ; ch:GetStats()
ch:Stream(fn, 0.25) ; ch:Stop() ; ch:Clear() ; ch:Refresh()
```

`Type`: `bar`, `line`, `donut`, `stat`, `spark`, `graph`. `Format` is a function
returning the label string (defaults to `VibeUI.FmtInt`). `Height` is clamped to
48..420. `Colors` also accepts a palette name (`mono`, `frost`, `ember`, `mint`, `candy`).

---

## Watermark

```lua
local wm = win:CreateWatermark({ Version = "v10.0", Position = UDim2.new(0, 16, 0, 54) })
```

Segments are fixed: `cheat` (brand), `players`, `ping`, `time`, `player`, `fps`.
They always render in that order, so re-enabling a module restores its slot
instead of appending it to the end.

| Method | Description |
| --- | --- |
| `wm:SetVisible(bool)` / `wm:GetVisible()` | fade in/out (scale + opacity) |
| `wm:SetOption(key, bool)` | enable/disable one segment with a width animation |
| `wm:GetOptions()` | map of enabled keys |
| `wm:Rebuild()` | rebuild segments from the current order |
| `wm:ResetWatermark()` | back to all segments |
| `wm:CloseMenu()` | close the right-click menu |
| `wm:HideAllWatermark()` | alias for `SetVisible(false)` |
| `wm:Destroy()` | removes the watermark and its menu |

Right-click the pill for the live segment menu. `wmorder` is persisted with
configs. `AddDeath`, `ResetKD`, `SetKDSource` exist as no-ops for backwards
compatibility with older watermark call sites.

---

## Global handle

`CreateWindow` publishes a single entry point for other scripts:

```lua
local api = getgenv().Atherium
api.Version    -- "10.0"
api.UI         -- VibeUI table
api.Window     -- win
api.Watermark  -- watermark handle (nil until CreateWatermark)
```

Legacy aliases `getgenv().AtheriumUI`, `.AtheriumWin`, and the misspelled
`AhteriumUI` / `AhteriumWin` still point at the same objects.

---

## Minimal example

```lua
local VibeUI = loadstring(readfile("VibeUI.lua"))()

local win = VibeUI:CreateWindow({ Title = "Atherium", Subtitle = "v" .. VibeUI.Version })
local tab = win:AddTab("Main", "house")
local sec = tab:AddSection("General", "sparkles")

local esp = sec:AddToggle({ Name = "ESP", Callback = function(on) end })
local col = sec:AddColorPicker({ Name = "Color", Callback = function(c, t) end })
sec:AddKeybind({ Name = "Toggle Key", Default = Enum.KeyCode.F, Toggle = esp })

local wm = win:CreateWatermark()
wm:SetOption("players", true)
```
