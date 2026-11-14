# Native Mobile UI/UX Engineering Standards & Audit Ruleset

Actionable engineering standards, native interaction rules, Human Interface Guidelines (HIG) constraints, codebase audit checklist, and physical-device validation protocols for maintaining **60fps native performance** and **App Store Review Guideline 4.2 compliance** (preventing "repackaged website" rejections).

---

## Core Engineering Mandate

> **"Use the system's navigation, native stack, native tabs, native sheets — nothing custom unless explicitly required. Every button reacts when a finger lands, not when it lifts. Anything you drag follows your finger. Buttons at least 44 points. Haptics only when something actually happens."**

---

## 1. Native UX Rules

### 1.1 Native Navigation Stack
- **Requirement**: Always use the platform's native navigation stack (`CupertinoPageRoute` / native stack router / `Stack` in Expo Router) rather than custom JS/CSS view transitions or manual overlay swaps.
- **Why**: Native stacks run transitions on the system UI/render thread, preserve scroll positions automatically across pushes/pops, and provide system-standard headers and back gestures out of the box.
- **Anti-Pattern**: Custom top headers with manual back buttons that replace the system navigation bar or break the native route history stack.

### 1.2 Interactive Edge-Swipe Back Gesture
- **Requirement**: Interactive left-edge (or RTL right-edge) swipe-back must be enabled by default on iOS and native stacks.
- **Physics & Cancellation**: When dragging back from the screen edge slowly and pausing halfway, the top screen must track the user's finger 1:1. If the user changes their mind and releases before the commit threshold, the screen must spring back smoothly to its current route without popping.

### 1.3 Native Tab Bar & Active-Tab Re-Tap Behavior
- **Requirement**: Use system-backed native tab bars (`NativeTabs` / platform tab controllers) rather than custom `<div>` or row-based bottom bars.
- **Scroll-to-Top on Re-Tap**: Tapping the tab icon for the tab the user is **already on** while scrolled far down a list must automatically scroll the active list back to the top (or pop nested stack routes to the tab root).

### 1.4 Native Modal Sheets (`formSheet` & Detents)
- **Requirement**: Bottom sheets and modals must use native sheet presentation (`presentation: formSheet` with `sheetAllowedDetents` / `CupertinoSheetRoute` / interactive draggable sheet physics).
- **Interactive Drag Tracking**: Pulling a sheet halfway down and letting go must track the finger continuously with rubber-band physics and settle cleanly into the nearest detent or dismiss smoothly—never snap with a fixed-duration CSS/linear timer.

### 1.5 60fps Scroll Performance
- **Requirement**: Long lists must use virtualized/lazy cell recycling (`ListView.builder`, `SliverList`, `FlashList`) and maintain a locked **60fps (or 120Hz ProMotion)** frame rate during fast flings.
- **Zero Blank Rows / Zero Stutter**: Fast scrolling through a long feed must produce zero dropped frames, zero layout jumps, and zero blank white rows while cells render.
- **Release-Build Verification**: Scroll performance must always be evaluated on a **release build** on a physical device, never judged solely in debug/simulator mode.

### 1.6 Touch-Down Button Feedback (Immediate Press State)
- **Requirement**: Every interactive button, card, and row must react **the instant a finger lands (`onTapDown` / `onPressIn`)**, not when the finger lifts (`onTapUp` / `onClick`).
- **Why**: Web click handlers wait until touch-up (~100–300ms delay) to distinguish taps from scrolls, making the UI feel dead or laggy. Native controls show immediate visual feedback (opacity/scale/highlight) on touch-down.

---

## 2. Human Interface Guidelines (HIG)

### 2.1 Minimum `44 × 44 pt` Touch Targets
- **Rule**: Every interactive element (icon buttons, close `X` buttons, filter chips, password visibility toggles, list actions) must have a minimum hit-test area of **`44 × 44 pt`** (`48 × 48 dp` on Android).
- **Implementation**: Even if a visual icon is `18–24 pt`, pad its hit box (`ConstrainedBox(constraints: BoxConstraints(minWidth: 44, minHeight: 44))` or `hitSlop`) so the tappable region is at least `44 × 44 pt`.

### 2.2 Viewport & Input Focus Behavior (No Auto-Zoom)
- **Rule**: Tapping a text input field must keep the screen viewport completely stable—**zero page zoom, zero horizontal viewport shift**.
- **Web-Wrapper / PWA Guardrail**: In webviews or hybrid builds, iOS Safari automatically zooms the viewport if an `<input>` or `<textarea>` has a computed `font-size` smaller than `16px`. Enforce `font-size >= 16px` on all inputs and lock viewport scaling where appropriate so tapping a text box never zooms the layout.

### 2.3 Contextual Haptics (Signal, Not Noise)
- **Rule**: Trigger haptics **only when a meaningful state change or physical threshold actually occurs**—never on every routine navigation tap.
- **Approved Haptic Moments**:
  - Completing a transaction, posting an ad, or toggling a favorite (`HapticFeedback.lightImpact()` / `UINotificationFeedbackGenerator.success`).
  - Crossing a physical gesture threshold (e.g., pull-to-refresh trigger point, snapping a sheet detent, or long-press activation).
  - Validation or payment failure (`UINotificationFeedbackGenerator.error`).
- **Prohibited**: Firing haptics on ordinary tab switches, standard back navigation, or every button tap.

---

## 3. Codebase Audit Checklist

Run this audit across every screen in the repository before fixing anything. Report findings **by file path and line number**:

> **Audit Prompt / Mandate**: *"Go through every screen. List custom headers, custom tabs, buttons under 44 points, and buttons with no pressed state, by file and line. Fix nothing yet."*

### Checklist Items to Scan:
- [ ] **1. Custom Headers Replacing System Navigation**
  - Scan for manual `Row` / `Container` top bars with custom back icons that bypass `AppBar` / `CupertinoNavigationBar` or disable the native interactive edge-swipe back gesture.
- [ ] **2. Custom Tab Bars Without Active-Tab Scroll-to-Top**
  - Scan bottom navigation implementations for custom tab widgets that do not attach a `ScrollController` to scroll the current feed to offset `0` when the active tab is tapped again.
- [ ] **3. Undersized Touch Targets (`< 44 × 44 pt`)**
  - Scan for `GestureDetector` or `InkWell` wrapping small `Icon` (`size: 16..22`), compact chips (`height: 24..36`), or tight `padding` without `minWidth: 44, minHeight: 44`.
- [ ] **4. Missing Touch-Down Pressed States**
  - Scan for raw `GestureDetector(onTap: ...)` wrapping `Container` or `Row` where no visual change (opacity, scale, or highlight color) occurs on `onTapDown` / press-in.
- [ ] **5. Non-Interactive Modals & Sheets**
  - Scan for dialogs or bottom sheets that cannot be dragged down interactively with finger-tracking physics or lack detent snapping.
- [ ] **6. Unvirtualized Lists & Scroll Bottlenecks**
  - Scan for `SingleChildScrollView(child: Column(children: [...items.map(...)]))` on dynamic feeds instead of lazy `ListView.builder` / `SliverList`, or heavy synchronous work inside `itemBuilder`.
- [ ] **7. Web-Wrapper & Input Zoom Tells**
  - Scan web/hybrid CSS and input styles for `<input>` font sizes `< 16px`, accidental text selection on UI chrome (`user-select: none` missing), rubber-band overscroll on fixed headers, or `300ms` tap delays.

---

## 4. Validation & Testing Framework

### Part A: The Six Physical-Device Thumb Tests
Run all 6 tests on a **real phone running a release build** before every release:

| # | Test Name | Action on Physical Device | Pass Criteria |
| :--- | :--- | :--- | :--- |
| **1** | **Swipe** | Drag back from the left edge slowly, halfway across the screen, then change your mind and let go. | The screen tracks your finger 1:1, then springs back cleanly to the current screen. |
| **2** | **Text Box** | Tap any text input field. | The screen stays put; keyboard rises smoothly with **zero viewport zoom**. |
| **3** | **Tab** | Scroll far down a list, then tap the tab bar icon you are already on. | The list immediately scrolls/jumps back to the top. |
| **4** | **Sheet** | Pull a modal bottom sheet halfway down and let go. | The sheet follows your finger during the drag, then settles smoothly into its detent or closes. |
| **5** | **Scroll** | Flick-scroll a long list as fast as possible (in a **release build**). | **Zero stutter, zero frame drops, and zero blank rows.** |
| **6** | **Press** | Press a button and hold your finger down without lifting. | Visual feedback (highlight/scale/opacity) happens **before you let go**. |

---

### Part B: "The Stranger's-Thumb Test" (Observational Friction Protocol)
Users rarely articulate technical UI bugs—they simply say the app *"feels off"*. Use this 4-step observational protocol to locate hidden UX bottlenecks:

1. **Give your phone to a friend** (someone who did not build the screen).
2. **Give them one clear task** (e.g., *"Find a car in Casablanca and message the seller"*).
3. **Say nothing** (no hints, no pointing, no explaining where buttons are).
4. **Film their thumb** (record the screen and their hand movement, not their face).

#### Diagnostic & Triage Workflow:
- **Every time the thumb hesitates, stops, taps twice, or hunts for a way back, log that exact timestamp.**
  - *Classic Friction Pattern 1 — The Long List*: The user scrolls deep into a feed and gets stuck trying to get back to the top (fix: active-tab re-tap scroll-to-top).
  - *Classic Friction Pattern 2 — Saved Twice / Double Tap*: The user taps "Save" or "Submit" twice because nothing reacted on touch-down (fix: immediate pressed state on `onTapDown` + loading state).
  - *Classic Friction Pattern 3 — Hunting for Back*: The user tries to swipe from the left edge, nothing happens, and their thumb has to reach to the top corner to find a custom back icon (fix: native stack with interactive edge-swipe back).
- **Prioritized Remediation**:
  1. List every place the stranger's thumb stopped.
  2. Map each stop to which of the **6 Thumb Tests** or **HIG Rules** it violated.
  3. **Fix the smallest violation first**, re-test on a release build, and repeat.
