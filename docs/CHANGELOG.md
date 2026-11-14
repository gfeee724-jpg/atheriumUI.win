# Changelog

All notable changes to Atherium UI. Newest first. The current build is `9.5`;
`VibeUI.Version` matches the newest entry.

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
