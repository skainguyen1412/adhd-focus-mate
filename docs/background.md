# Dayflow Window Background (Full-Window / Titlebar)

This doc explains why the background in `Dayflow/Dayflow/App/DayflowApp.swift` visually “fills the whole app”, including the window bar/titlebar area.

## What creates the background

In `DayflowApp.swift`, the app applies an asset-backed image as a background on the root container:

- `Image("MainUIBackground")`
- `.resizable()` + `.scaledToFill()` makes it behave like a wallpaper (covers the available area, potentially cropping).
- `.allowsHitTesting(false)` prevents the background from stealing clicks.

The asset lives at:

- `Dayflow/Dayflow/Assets.xcassets/MainUIBackground.imageset/` (the 1x filename is `Content Area.png`).

## Why it extends into the titlebar area

Two things combine to make the background appear “behind” the titlebar:

1. **The window style hides the titlebar backing**
   - `WindowGroup { ... }.windowStyle(.hiddenTitleBar)`
   - This hides the title and the titlebar area’s backing, allowing more of your content to show through there.

2. **The background ignores safe areas**
   - The background image has `.ignoresSafeArea()`
   - That allows it to extend into areas SwiftUI would normally inset/avoid (including window safe areas).

## Why it covers the whole window

The root container is sized to fill the available window space:

- `.frame(minWidth: 900, maxWidth: .infinity, minHeight: 600, maxHeight: .infinity)`

Because the background is attached to that root container, it fills whatever that container fills.

## Quick “recipe” (the pattern)

If you want this effect elsewhere, the pattern is:

- Put your content inside a root container (`ZStack` is common).
- Apply the background at the root level via `.background { ... }`.
- Make the background ignore safe areas.
- Use a window style that removes the titlebar backing if you want the background to appear in the titlebar.

## Notes / gotchas

- If you apply the background to a nested view (not the root), it will only cover that subview.
- If you remove `.ignoresSafeArea()`, the background may stop at safe-area boundaries and no longer appear in the titlebar area.
- If you remove `.windowStyle(.hiddenTitleBar)`, the titlebar backing may cover your content/background (depending on macOS/window configuration).

