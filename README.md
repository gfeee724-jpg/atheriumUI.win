# VibeUI

Monochrome slate UI library for Roblox (Luau): sidebar tabs, search, live
controls, viewport preview, charts, keybind panel and a floating watermark.

Everything is one theme: flat cards, hairline separators, Lucide icons, no
color accents except the ones you set yourself. The window has camera-tracked
acrylic blur, snap dragging and resizing.

## Files

| File | What it is |
| --- | --- |
| `VibeUI.lua` | the library (generated, `return VibeUI`) |
| `vibe_hub.lua` | single-file demo: the whole UI plus a demo window, `loadstring`-ready |
| `API.md` | full API reference |
| `build_module.py` | regenerates `VibeUI.lua` from `vibe_hub.lua` |

## Usage

```lua
-- library
local VibeUI = loadstring(readfile("VibeUI.lua"))()
local win = VibeUI:CreateWindow({ Title = "My Hub" })
local tab = win:AddTab("Main", "house")
local sec = tab:AddSection("General", "sparkles")

sec:AddToggle({ Name = "ESP", Callback = function(on) print(on) end })
sec:AddSlider({ Name = "FOV", Min = 10, Max = 120, Default = 70 })
win:CreateWatermark()
```

```lua
-- or the whole demo in one shot
loadstring(game:HttpGet("<raw url of vibe_hub.lua>"))()
```

`RightShift` toggles the window. Right-click the watermark for its segment menu.
See `API.md` for every control and method.

## Notes

- Icons are loaded at runtime from the public Lucide icon set
  (`Footagesus/Icons`), so the client needs HTTP access.
- `getgenv().Atherium` exposes `{ Version, UI, Window, Watermark }` for other
  scripts. Names starting with `_` are private and may change.
- `VibeUI.lua` is generated: run `python build_module.py` after editing
  `vibe_hub.lua`.

## Build

```
python build_module.py
```

Splits `vibe_hub.lua` at the demo marker, stamps `VibeUI.Version` into the
banner, appends `return VibeUI`. Add `--check` to run the Lua balance checkers
if they are present.
