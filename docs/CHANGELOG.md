# Changelog

All notable changes to Atherium UI. Newest first. The current build is `10.3`;
`VibeUI.Version` matches the newest entry.

## 10.3

- Swatch corners are rounded on the fill itself, not only on the container.
  The fill draws in a higher `ZIndex` pass, so the container's rounded clip
  never reached it and the chip rendered as a hard square. The wrap, the fill
  and the popup chip now all carry a 7px radius, and the 1px hairline rides the
  fill so the border follows the same curve.

## 10.2

- Colour swatch no longer reads as a chess tile: 4px squares in a softer pair
  of greys, back to a 20x18 chip with a 6px radius, and the colour fill now
  carries an explicit ZIndex so it always paints over the checkerboard.
- The popup chip got the same treatment (4px cells, 6px radius).

## 10.1

- Slider thumb is smaller: 10x14 idle, 12x16 on hover, 14x9 while dragging,
  with a 5px corner radius. The 22px track stays the drag target.
- Colour picker transparency is real alpha now. The swatch, the popup chip and
  the strip all sit on a checkerboard, and the strip ramps from the chosen
  colour to fully transparent (it used to stop at 85% and read as grey).
- Dropping alpha no longer washes the preview into white, grey and black.

## 10.0

- Sidebar tab list is now a `ScrollingFrame` with `AutomaticCanvasSize`, so a hub
  with a dozen tabs scrolls instead of colliding with the profile card.
- Tooltips: any control accepts `Tooltip = "text"`. One shared bubble is reused
  for every row, appears after a 0.35s hover (0.45s long-press on touch), flips
  below the row when there is no room above, and caps at 230x180.
- Dropdown v2: `Multiple = true` for multi-select with `Select all` / `Clear`,
  a search field that turns on automatically past six options, an eight-row
  scroll window, and `IsMultiple()`, `Open()`, `Close()` on the handle.
  Single-select calls are unchanged.
- Notify v2: cards size themselves to the text, messages queue past
  `NotifyLimit` (default 4), click to dismiss, four kinds (`info`, `success`,
  `warn`, `error`) and a thin life bar. `win:Notify` also accepts a table and
  returns a handle with `:Close()`.
- Version bumped to `10.0`; module rebuilt.

## 9.5

- Slider value moved into a fixed 64px slot on the title line, right aligned and
  monospace, so every row lines up regardless of digit count.
- The readout brightens while hovering or dragging instead of appearing and
  disappearing, and `ShowValue = false` removes the slot entirely.
- Slider thumb is roomier (15x20 idle, 17x22 hover, 20x14 drag) with a neutral
  1px rim that reads evenly against both the white fill and the dark rail.
- Section cards gained vertical padding (14px top, 10px bottom).

## 9.4

- Slider thumb fixed: `place()` no longer parks it on the top edge of the track.
- Removed the concentric halo rings and the two gradient glow bands behind the
  active rail.
- Track rebuilt as one flat 5px capsule with a slightly off-white fill, so it no
  longer blooms against the background.
- Uniform 12px gutters for titles, rail and values.

## 9.3

- Slider value now appears inline on the title line instead of a floating chip
  above the thumb.
- Slower, springier easing for thumb squash and release.

## 9.2

- New slider: pill rail, white active section, soft glow, capsule thumb with
  squash-on-drag.
- Input listeners detach themselves once the row is destroyed.

## 9.1

- Slider redesign pass: value on the title line, rail plus knob, no percent text
  on the track.

## 9.0

- Charts rebuilt for a monochrome theme: bar with grid and gradient, line with
  glow and a single endpoint marker, donut with 48 tangential segments.
- Watermark segments no longer use a `CanvasGroup` each; fades are driven by one
  `NumberValue` per segment.
- Streamed charts coalesce redraws to 5 per second.
- Viewport clones clear `LocalTransparencyModifier` and skip frames while hidden.
- `AutoPerf`: if the first four seconds average under 45 fps, acrylic is disabled
  automatically and a notification is shown.
