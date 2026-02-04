# Dayflow macOS Architecture: Main Window + Menu Bar (Status Item) + “Soft Quit”

This explains how Dayflow is structured as **a normal windowed macOS app** *and* a **menu bar (status item) companion**, and why the app can appear to “not quit” or “not show the window” depending on state.

---

## Two different “menu” concepts on macOS (important!)

Dayflow participates in both:

- **The app menu bar at the top of the screen** (File/Edit/View…): configured in SwiftUI via `.commands { ... }` in `DayflowApp`.
- **A menu bar *status item*** (icon on the right side of the menu bar): implemented via `NSStatusItem` + `NSPopover` (`StatusBarController`).

When people say “menu app”, they often mean the second one (status item).

---

## High-level architecture

Dayflow uses a **SwiftUI App lifecycle** for its main UI, while also using an **AppKit app delegate** for system-level integration:

- **SwiftUI entry point**: `Dayflow/Dayflow/App/DayflowApp.swift`
  - Creates the main window scene (`WindowGroup`)
  - Chooses *Onboarding vs Main UI*
  - Owns launch video overlay and other full-window overlays
  - Adds app-menu commands (Update, Release Notes, Reset Onboarding)

- **AppKit delegate**: `Dayflow/Dayflow/App/AppDelegate.swift`
  - Sets up status bar item (`StatusBarController`)
  - Handles analytics, background services, screen recording bootstrap, notification routing, etc.
  - Implements **soft quit** behavior by intercepting termination

Bridge between them:

- In `DayflowApp`: `@NSApplicationDelegateAdaptor(AppDelegate.self) var delegate`

---

## The main window (SwiftUI `WindowGroup`)

The “main app UI” lives in the SwiftUI scene declared in `DayflowApp`:

- `WindowGroup { ... }` defines the main window content.
- Inside the window, Dayflow uses a `ZStack` to layer:
  - **Base content**:
    - If `didOnboard == false`: `OnboardingFlow()`
    - If `didOnboard == true`: `AppRootView()` → `MainView()`
  - **Launch video overlay**: `VideoLaunchView()` (fades out while base content fades in)
  - **Journal onboarding overlay**: `JournalOnboardingVideoView(...)` when `JournalCoordinator` requests it
- The window is styled “modern macOS”:
  - `.windowStyle(.hiddenTitleBar)`
  - `.windowResizability(.contentMinSize)`
  - `.defaultSize(width: 1200, height: 800)`
  - content `.frame(minWidth: 900, minHeight: 600, ...)`

App-menu commands (top screen menu bar) are also owned here:

- Removes “New Window” via `CommandGroup(replacing: .newItem) { }`
- Adds:
  - “Check for Updates…”
  - “View Release Notes”
  - “Reset Onboarding” (and then terminates)

---

## The menu bar status item (icon on the right)

Dayflow creates a **menu bar status icon** using AppKit:

- Created in `AppDelegate.applicationDidFinishLaunching`:
  - `statusBar = StatusBarController()`

Implementation details:

- `Dayflow/Dayflow/System/StatusBarController.swift`
  - Creates an `NSStatusItem`:
    - `NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)`
  - On click, shows an `NSPopover`
  - The popover hosts SwiftUI content (`StatusMenuView`) via `NSHostingController`
  - The menu bar icon updates based on recording state:
    - Observes `AppState.shared.$isRecording`
    - Switches icon between `MenuBarOnIcon` and `MenuBarOffIcon`

So: **the status item is always “alive” as long as the process is running**, even if no windows are visible.

---

## What the status menu can do

`Dayflow/Dayflow/Menu/StatusMenuView.swift` defines the popover UI actions.

Key actions:

### “Open Dayflow”

This is the *primary* “bring back the window” path when the app is in the background:

1. Close the popover
2. Optionally show Dock icon:
   - reads `UserDefaults("showDockIcon")` (default: true)
   - if true: `NSApp.setActivationPolicy(.regular)`
3. Bring app forward:
   - `NSApp.unhide(nil)`
   - `NSApp.activate(ignoringOtherApps: true)`
4. Try to show an existing window:
   - iterates `NSApp.windows` and calls `makeKeyAndOrderFront`
5. If no usable windows exist:
   - calls `MainWindowManager.shared.showMainWindow()`

### “Quit Completely”

This bypasses Dayflow’s soft-quit behavior:

- `AppDelegate.allowTermination = true`
- `NSApp.terminate(nil)`

### “Check for Updates”

- Calls `UpdaterManager.checkForUpdates(showUI: true)`
- Activates the app to ensure the Sparkle UI can appear

---

## “Soft Quit”: why Cmd+Q may not actually quit

Dayflow intentionally behaves like a background/menu-bar utility.

In `AppDelegate.applicationShouldTerminate`:

- If `AppDelegate.allowTermination == true` → returns `.terminateNow`
- Otherwise → returns `.terminateCancel` and performs a “soft quit”:
  - `NSApp.hide(nil)`
  - `NSApp.setActivationPolicy(.accessory)` (Dock icon disappears)

Effect:

- Cmd+Q, Dock → Quit, or App menu → Quit may **hide the app** instead of quitting.
- The process stays running, and the **status item remains**.

This is “correct” for the intended product behavior — but it can feel “wrong” if you expected a normal app quit.

Places that intentionally flip `allowTermination = true`:

- Status menu “Quit Completely”
- Sparkle update install flows (`UpdaterManager` sets this before install/relaunch)
- “Reset Onboarding” command (then terminates)
- System power-off event (sets allowTermination so shutdown can proceed)

---

## Dock icon visibility is a *preference*, not a constant

Dayflow has a user preference controlling whether the Dock icon is shown:

- In Settings: `SettingsView` uses:
  - `NSApp.setActivationPolicy(show ? .regular : .accessory)` when `showDockIcon` changes

Other parts respect the same preference:

- Status menu “Open Dayflow” only calls `.regular` if `showDockIcon == true`
- Notification tap handling also tries to ensure the Dock icon is visible if allowed

If your app “disappears” from the Dock, it’s likely because:

- activation policy is `.accessory`, *by design*, and the status item is now the primary entry point.

---

## Notification tap behavior (why the intro video may be skipped)

When a journal notification is tapped:

- `NotificationService`:
  - posts `.navigateToJournal`
  - sets `AppDelegate.pendingNavigationToJournal = true`
  - activates the app
  - optionally switches to `.regular` (if user allows Dock icon)
  - brings a window forward (`NSApp.windows.first?.makeKeyAndOrderFront(nil)`)

Then in `DayflowApp`:

- `VideoLaunchView` is skipped if `pendingNavigationToJournal` is true
- after the video handoff (or immediately when skipped), Dayflow posts `.navigateToJournal` again

This exists to prioritize **speed** over “brand intro” when the user explicitly tapped a notification.

---

## The “no windows exist” case: `MainWindowManager` fallback

This part is often the source of “my app doesn’t behave right”.

Because Dayflow can soft-quit into the background, users can end up in a state where:

- the process is running (status item visible)
- but **all windows are closed**

In that situation, “Open Dayflow” falls back to:

- `MainWindowManager.shared.showMainWindow()`

`MainWindowManager` is an AppKit window factory:

- Creates a brand-new `NSWindow`
- Sets title bar to hidden/transparent, min size, autosave name
- Sets content to an `NSHostingView` that hosts **`MainWindowContent`**

Important: this is a *separate* window creation path from SwiftUI’s `WindowGroup`.

---

## Why behavior can diverge: two root-view paths exist

Dayflow effectively has **two ways to produce the main UI**:

1. **SwiftUI scene path** (normal app window)
   - `DayflowApp` → `WindowGroup` → `AppRootView`/`OnboardingFlow`
   - Uses `@StateObject` instances owned by `DayflowApp` (like `journalCoordinator`)

2. **AppKit fallback path** (recreated window when none exist)
   - `MainWindowManager` → `NSWindow` → `MainWindowContent`
   - `MainWindowContent` duplicates much of `DayflowApp`’s layering logic

Because these are separate code paths, subtle differences can cause “weirdness”.

### Concrete differences to watch for

- **Different `CategoryStore` instances**
  - `DayflowApp` creates `@StateObject private var categoryStore = CategoryStore()`
  - `MainWindowManager` injects `CategoryStore.shared`
  - That means two in-memory stores can exist at once (even if both persist to UserDefaults).

- **Journal onboarding completion side effects differ**
  - In `MainWindowContent`, when the journal onboarding video finishes it sets:
    - `hasCompletedJournalOnboarding = true`
    - `journalCoordinator.showRemindersAfterOnboarding = true`
  - In `DayflowApp`, the same overlay completion sets:
    - `hasCompletedJournalOnboarding = true`
    - (but does not set `showRemindersAfterOnboarding`)

If you sometimes open the app via the WindowGroup window and other times via the AppKit fallback window, you can end up with:

- missing sheets/overlays
- state that seems “reset”
- UI that behaves slightly differently depending on *which window path you’re in*

---

## Debug checklist for “not behaving right”

### 1) Is the app actually quitting?

- If Cmd+Q “does nothing”: it’s probably **soft quit**.
- Use status menu → **Quit Completely** to confirm termination works.
- Check whether some flow is incorrectly leaving `AppDelegate.allowTermination = false` when you expected a real quit.

### 2) Is the Dock icon supposed to be visible?

- If the Dock icon disappears:
  - confirm `showDockIcon` preference
  - confirm activation policy is `.accessory`
  - use the status item → “Open Dayflow” to re-open

### 3) Are you seeing a WindowGroup window or a MainWindowManager window?

Clues you’re on the fallback window path:

- You had no visible windows, then used the status item “Open Dayflow”
- Behavior differs slightly from a normal launch

If you suspect this, inspect:

- `MainWindowManager.swift`
- `MainWindowContent.swift`

### 4) Are you accidentally using two sources of truth?

Common culprit in Dayflow specifically:

- `CategoryStore()` vs `CategoryStore.shared` (two instances)

If category-dependent UI looks inconsistent across openings, this is worth investigating first.

---

## Where to look if you want to “fix it” (likely root causes)

If your app’s behavior is wrong, it’s often one of these:

- **Soft quit is enabled but you expect normal quit**
  - adjust `applicationShouldTerminate` behavior
  - ensure there’s a clear UX entry for “Quit Completely” (Dayflow already has it)

- **Window recreation path diverges**
  - consider removing duplication so there’s only one canonical root view builder
  - ensure the fallback window uses the *exact same* state objects / environment objects as the main scene

- **Activation policy toggling is inconsistent**
  - ensure every “bring app forward” path sets `.regular` when needed (and when user preference allows)

