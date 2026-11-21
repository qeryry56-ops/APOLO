# Apolo Mascot Integration Specification

**Design Principle:** The Apolo felt mascot acts as a **tactile punctuation mark**—warming up high-friction, transitional, or empty moments in the marketplace journey while staying completely invisible during high-density shopping, price comparison, and checkout flows.

---

## 1. Placement & Layout Matrix

### Approved Touchpoints
| Screen / Context | Role in Journey | Rendered Size (`pt`/`dp`) | Vertical Placement & Spacing | Exit / Dismissal Behavior |
| :--- | :--- | :--- | :--- | :--- |
| **Onboarding Welcome** | First-impression brand anchor on slide 1 only | `120 × 120` | Centered horizontally; `24pt` below top safe-area inset; `20pt` above headline | Transitions out with page swipe; does not persist on permission/form steps |
| **AI Product Scan / Auto-Fill** | Masks latency while vision model extracts title, category, and price | `72 × 72` | Centered inside a bottom sheet (`24pt` top padding, `16pt` above status label) | Cross-fades (`180ms` ease-out) into extracted form fields once ready |
| **Listing Published** | Rewards seller completion and confirms live status | `96 × 96` | Upper third of confirmation modal; `24pt` above listing preview card | Plays once, settles into idle frame; dismissed via primary CTA |
| **Empty States** *(Saved, Orders, Search)* | Softens dead-ends and directs user to next action | `80 × 80` | Vertically centered in available viewport (`-24pt` optical offset); `16pt` above title | Replaced immediately when list state populates |

### Strict Exclusion Zones (Where the Mascot Must *Never* Appear)
* **Browse & Discovery Feeds:** Never place in search result grids, category carousels, or promotional banners—product photography must own 100% of visual chroma.
* **Product Detail Pages (PDP) & Checkout:** Keep price breakdowns, escrow/payment sheets, and shipping selectors strictly utilitarian to preserve transactional trust.
* **Navigation Chrome:** Never use as a tab bar icon, floating action button (FAB), or persistent AI chat bubble.
* **High-Stakes Alerts:** Never use on payment declined, account suspended, or payout error modals.

---

## 2. Core Mascot States & Micro-Copy

Copy tone is **concise, capable, and calm**—avoiding first-person baby talk (*"Oopsie! I dropped the box!"*) or excessive exclamation marks.

| State ID | Visual & Motion Choreography | Loop Mode | Haptic Pairing | Micro-Copy Example (Title / Subtitle) |
| :--- | :--- | :--- | :--- | :--- |
| **`01_wave`** *(Welcome / Idle)* | Gentle right-arm raise (Frames 1–5) with subtle `2°` head tilt; soft felt pile catch-light | Ping-pong (`1→5→1`), `2.5s` rest between cycles | Light impact on initial mount | **Welcome to Apolo** <br> *Buy and sell local goods in seconds.* |
| **`02_scan`** *(AI Thinking)* | Slow side-to-side weight shift (Frames 6–8) with subtle crest bob; pairs with a soft radial pulse underneath | Continuous ping-pong at `10 FPS` | None (avoid vibration fatigue during wait) | **Analyzing your item…** <br> *Detecting category, condition, and fair price.* |
| **`03_celebrate`** *(Listing Live)* | Quick `8pt` vertical hop with both arms lifted and crest perked, settling back to neutral | Play once (`900ms`), freeze on Frame 1 | Success notification (`UINotificationFeedbackGenerator`) | **Your listing is live** <br> *Visible to buyers within 15 km.* |
| **`04_rest`** *(Empty State)* | Neutral standing posture (Frame 1) with a slow blink every `4s` | Static or low-frequency blink loop | None | **No saved items yet** <br> *Tap the heart on any listing to track price drops.* |
| **`05_confused`** *(Soft Error / No Match)* | Slight head tilt (`6°`) with one arm raised halfway (Frame 2); neutral mouth | Single ease-in transition (`400ms`), hold | Soft warning tap | **No exact matches nearby** <br> *Try broadening your filters or checking spelling.* |

---

## 3. UI, Surface & Technical Specifications

### Sizing, Spacing & Asset Export
| Parameter | Specification | Rationale |
| :--- | :--- | :--- |
| **Export Format** | **Animated WebP** (transparent alpha, lossy quality `88`) or **Lottie + WebP sequence** | Preserves micro-displacement felt fuzz texture that vector SVGs flatten |
| **Source Canvas** | `360 × 360 px` (`@3x` master for `120pt` max display) | Crisp rendering on High-DPI (`@3x` iOS / `xxhdpi` Android) at under `140 KB` per state |
| **Frame Rate** | **10–12 FPS** (on-twos stop-motion cadence) | Matches the handcrafted felt material; 60 FPS makes clay/felt characters look plastic and uncanny |
| **Internal Safe Margin** | `12%` transparent padding around silhouette | Prevents arm waves and crest bounce from clipping against container bounds |
| **Minimum Clear Space** | `16pt` minimum margin to any text; `24pt` to interactive buttons | Prevents the high-saturation `#E31B23` body from visually bleeding into `#E31B23` primary CTAs |

### Light & Dark Mode Contrast Rules
Because the mascot's body is brand red (`#E31B23`) with a pure white crest (`#FFFFFF`) and glossy black eyes:

| Theme | Allowed Backing Surfaces | Contrast & Shadow Treatment |
| :--- | :--- | :--- |
| **Light Mode** | Pure White (`#FFFFFF`) or Warm Stone (`#F7F7F8`) | Add a soft contact oval shadow (`16 × 4pt`, `#1A0505` at `10%` opacity) `2pt` below the feet so the white crest and red body feel grounded rather than floating. |
| **Dark Mode** | Carbon (`#121214`) or Elevated Surface (`#1C1C1F`) | The pure black studio background from the raw render must be stripped to true alpha. Use a subtle warm ambient pedestal (`radial-gradient` `#E31B23` at `8%` opacity, `64pt` blur) behind the mascot so the dark lower-right felt shading doesn't merge into the dark UI background. |
| **Forbidden Surface** | **Brand Red (`#E31B23`)** | **Never** place the mascot directly on a `#E31B23` background or banner. If a red surface is required, house the mascot inside a `#FFFFFF` or `#1C1C1F` squircle container (`border-radius: 24pt`). |

---

## 4. Developer Handoff Notes

1. **Zero Layout Shift (CLS Prevention):** Always wrap the mascot in a fixed `SizedBox` / aspect-ratio (`1:1`) container matching its target `pt`/`dp` token before the WebP decodes.
2. **Clean Alpha Premultiplication:** Because the original sprites sit on `#000000`, ensure the alpha matte cleanly separates the outer felt fibers without a dark 1px halo on Light Mode (`#FFFFFF`) backgrounds. Feather the alpha mask by `0.5px` inward and reconstruct red edge color (`#E31B23`) before exporting.
3. **Ping-Pong Playback Logic:** Rather than baking backwards frames into the image file (which doubles payload size), export the 9-frame forward arc (`01_wave.webp`) and drive ping-pong oscillation (`forward → reverse → delay(2500ms)`) via the native animation controller, or encode a 14-frame delta-optimized WebP loop with frame 1 held for `2500ms`.
4. **Accessibility (`Reduce Motion`):** Query `MediaQuery.disableAnimations` (Flutter) / `UIAccessibility.isReduceMotionEnabled` (iOS). When enabled, render static **Frame 1** (`mascot_static_neutral.webp`) immediately and skip loop decoding.
5. **Button Proximity Rule:** When a screen contains both the mascot and a primary `#E31B23` CTA button (e.g., Empty State with *"Browse Listings"* CTA), prefer a **Dark Charcoal (`#121214`)** or **Tinted Surface (`#FCE8E9` fill + `#E31B23` text)** button style so the mascot remains the sole focal block of primary brand red in the viewport.
