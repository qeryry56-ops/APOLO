# 🚀 APOLO PLATFORM — COMPREHENSIVE PROJECT HANDOVER (FOR CLAUDE CODE)
> **Date:** November 10, 2026  
> **Platform:** Apolo.ma (Moroccan Classifieds Marketplace #1)  
> **Target Audience for this document:** Claude Code Agent (to instantly resume development with zero context loss).

---

## 📌 1. EXECUTIVE SUMMARY & ARCHITECTURE

The Apolo project consists of three interconnected layers:
1. **Local Flutter Mobile App (`apolo_mobile`)**:
   - Path: `c:\Users\amine\Documents\APOLO APP\apolo_mobile`
   - Language/SDK: Flutter 3.44+ / Dart 3.12+ (Null-Safety)
   - State Management: `AppState` singleton (`lib/core/state/app_state.dart`)
   - API Client: Dio with Bearer Token & Interceptors (`lib/core/services/api_service.dart`)
   - Web Output: `apolo_mobile/build/web` is directly deployed to **Vercel** (`https://apolo-app...`).
2. **Production Backend & Admin Dashboard (Laravel 10+)**:
   - Host: Mercury Capconnect Server (`apoloma@mercury.capconnect.com`)
   - Remote Path: `/home/apoloma/public_html`
   - Live URL: `https://apolo.ma`
   - Admin URL: `https://apolo.ma/admin`
   - API Base: `https://apolo.ma/api/v1/`
3. **Git Repository**:
   - Remote: `https://github.com/qeryry56-ops/APOLO.git` (Branch: `main`)

---

## 🔑 2. CREDENTIALS & ACCESS WORKFLOW

### SSH & Server Access:
* **SSH Key Path:** `$env:USERPROFILE\.ssh\apolo_ed25519`
* **SSH Connection Command:**
  ```powershell
  ssh -i "$env:USERPROFILE\.ssh\apolo_ed25519" apoloma@mercury.capconnect.com
  ```
* **SCP Upload Command Example:**
  ```powershell
  scp -i "$env:USERPROFILE\.ssh\apolo_ed25519" "local_file.php" apoloma@mercury.capconnect.com:/home/apoloma/public_html/resources/views/admin/
  ```

> [!WARNING]
> **PowerShell Command Escaping Rule:** When running PHP or bash commands over SSH from PowerShell on Windows, NEVER use inline double quotes with `$` (e.g. `$app->...`). PowerShell will evaluate the `$` locally and break the script. Instead, create a temporary `.php` or `.py` script locally, upload via `scp`, execute via `ssh`, and delete the temp file.

---

## 🎨 3. DESIGN SYSTEM & IDENTITY (2026 APPLE HIG GUIDELINES)

* **Primary Brand Crimson:** `#E31B23` (RGB: `227, 27, 35`)
* **Dark Background Canvas:** `#07111E` / Deep Sapphire `#0D1D2F` / Base `#050B13`
* **Light Mode Surface:** Canvas `#F4F7FB`, Card `#FFFFFF`, Header/Hover `#EDF2F9`
* **Light Mode High-Contrast Text:** Primary `--txt1: #0D233E` (Deep Navy), Secondary `--txt2: #475569` (Slate)
* **Continuous Squircles:** Border Radius `18px` for cards, `12px` for items, `999px` for pills.
* **Apple Spring Curves:** `cubic-bezier(0.16, 1, 0.3, 1)` or `Curves.easeOutCubic` / `Curves.easeInOutCubic`.
* **Language Support:** Full RTL/LTR duality (Arabic `Tajawal` / `IBMPlexSansArabic` + French `PlusJakartaSans`).

---

## ✅ 4. COMPLETED WORK & LATEST STATE (THIS SESSION)

### A. Live Admin Dashboard (`https://apolo.ma/admin`)
1. **Universal Dual-Theme Engine (`admin.blade.php`)**:
   - Fixed the critical bug where text/numbers inside cards and tables were invisible (white-on-white) in Light Mode.
   - Properly defined both `:root` (Dark) and `html.lm, body.lm, .app-shell.lm` (Light) with high-contrast text tokens (`--txt1: #0D233E`, `--txt2: #475569`).
   - Verified on all subpages (`dashboard.blade.php`, `email-stats.blade.php`, `users/index.blade.php`, etc.).
2. **App Control Center (Mobile Remote Config)**:
   - Added remote controls directly inside the Admin Dashboard:
     - 🔴 **Maintenance Mode Toggle** (`is_maintenance`) + Custom Arabic message.
     - 🚀 **Min App Version / Force Update** (`min_version`, `force_update`, App Store & Google Play URLs).
     - 📢 **In-App Announcement Banner** (`banner_enabled`, `banner_text`, `banner_type`).
     - 🔔 **Instant Push Broadcast Hub** (Send instant alerts to all mobile devices).
   - Handlers added to `AdminDashboardController.php` (`saveAppControl` and `broadcastPush`).
   - Synced with mobile API via `GET /api/v1/app/config` and injected into `GET /api/v1/home`.

### B. Mobile App Updates (`apolo_mobile`)
1. **2026 Ad Reels Screen (`lib/screens/ad_reels_screen.dart`)**:
   - **Zen Mode:** Single tap hides/reveals all UI overlays for distraction-free photo viewing.
   - **Natural Aspect Ratio Carousel:** Ambient blurred backdrop (`ImageFilter.blur(42, 42)`) so photos are never awkwardly cropped.
   - **Stories Progress Segments:** Micro progress bars at the top indicating carousel index (`1/4`, `2/4`).
   - **Double-Tap 3D Heart:** Spring-burst heart with `Curves.elasticOut` and medium haptic feedback.
   - **Interactive Right Dock:** Seller avatar with verified badge, Like button with spring bounce, Chat button, Direct Call button, Share button.
   - **Frosted Glass Card:** Category tag, VIP golden badge, negotiable tag, seller handle, bold Crimson price tag, and city.
   - **Skeleton Loader:** Dark shimmer loading state.
2. **Home Screen Header Clean-up (`lib/screens/home_screen.dart`)**:
   - Completely removed the logo from the top header bar per user request.
   - Header now cleanly displays only the greeting (`مرحباً، $_userName 👋`) and the circular notification bell.
3. **Brand New 2026 Minimalist Splash Screen (`lib/screens/splash_screen.dart`)**:
   - Deep velvety sapphire gradient (`#060E18` -> `#0D1D2F` -> `#050B13`).
   - Apple fluid spring entrance animation (scale `0.86` to `1.0`, opacity `0.0` to `1.0`).
   - Official Apolo logo with soft ambient ruby halo (`#E31B23` with 0.16 alpha).
   - Minimalist tagline badge: `سوقك الأول فالمغرب 🇲🇦` with pulsing dot.
   - Micro Cupertino activity indicator + version label.
   - Smooth 480ms cross-fade transition to `WelcomeScreen` (first run) or `MainShell` (logged in / guest).
4. **Clean & Simple Hello / Welcome Screen (`lib/screens/welcome_screen.dart`)**:
   - Removed the chaotic 3D explosion background (`welcome_burst_bg.jpg` with flying money/cars/watches).
   - Built a calm, studio-grade dark background with subtle ambient ruby back-light.
   - Central Apple frosted glass squircle tile hosting the official Apolo emblem.
   - 3 clean trust micro-pills: `0% عمولة` • `شات فوري` • `حسابات موثقة`.
   - Clear, high-contrast typography and buttons without visual noise.
5. **App Entry Point (`lib/main.dart`)**:
   - Wired `SplashScreen` as the initial home.
6. **Vercel Web Build Pipeline**:
   - Executed `flutter build web --release`.
   - All assets, service worker, and `main.dart.js` compiled cleanly.
   - Pushed to GitHub `main` branch (`925bf50`).

---

## ⚡ 5. CRITICAL WORKFLOW RULE FOR CLAUDE (DO NOT MISS!)

> [!IMPORTANT]
> **Vercel Deployment Workflow:**
> The user views and tests the mobile app via **Vercel** (`vercel.json`).
> Vercel is configured with:
> ```json
> "buildCommand": "",
> "outputDirectory": "apolo_mobile/build/web"
> ```
> This means **Vercel DOES NOT build Flutter on its servers**; it directly serves the committed `apolo_mobile/build/web` directory!
> Whenever you modify any Flutter files in `apolo_mobile/lib/`, you **MUST** run:
> ```powershell
> cd "c:\Users\amine\Documents\APOLO APP\apolo_mobile"
> flutter build web --release
> cd ..
> git add apolo_mobile/build/web/ apolo_mobile/lib/
> git commit -m "your message"
> git push origin main
> ```
> If you omit this step, the user will inspect Vercel and see the OLD code!

---

## 📋 6. RECOMMENDED NEXT STEPS FOR CLAUDE

When you resume with Claude, the user may ask to polish other parts of the app. Here are the logical next priorities:

1. **Ad Detail Screen (`lib/screens/ad_detail_screen.dart`)**:
   - Upgrade hero image carousel with Apple 2026 pinch-to-zoom and ambient blur.
   - Ensure action buttons stay locked to: **Chat** + **Direct Call** (WhatsApp deliberately excluded for platform engagement).
2. **Post Ad Screen (`lib/screens/post_ad_screen.dart`)**:
   - Multi-image upload stepper with drag-to-reorder and instant preview.
   - Category and city picker sheets with search.
3. **Chat Room (`lib/screens/chat_room_screen.dart`)**:
   - Real-time messaging with audio voice note recording, image sharing, and read receipts.
4. **Seller Profile (`lib/screens/seller_profile_screen.dart`)**:
   - Verified badge, store banner, active ads grid, and seller rating reviews.

---

## 💬 7. LANGUAGE PREFERENCE

* Communicate with the user in **Moroccan Darija (Arabic script)**:
  - Example: "صافي خويا أمين، قاديت لك هاد الشي وبدلت..."
  - Keep tone respectful, concise, proactive, and focused on delivering clean, working code.
