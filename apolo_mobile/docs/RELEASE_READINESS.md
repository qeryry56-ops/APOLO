# Apolo release readiness

This is a release-candidate hardening pass, not a certification that production is error-free.

## Implemented & Verified Locally (`apolo_mobile`)

- Minimal light splash and bilingual welcome with actual guest/sign-in/register navigation.
- Arabic typography, directional layouts, LTR-isolated monetary amounts and sensitive inputs.
- Native in-app Account Security (`AccountSecurityScreen`): logged-in users can update their password (`PUT /auth/password`), email, and Moroccan phone number (`PUT /auth/profile`) directly in the app, while retaining the external `apolo.ma` fallback.
- Web & Mobile VIP Boost checkout (`BoostSheet`): enabled direct web checkout via `/ads/{id}/boost/verify-iap` (`platform: 'web'`) alongside native iOS/Android in-app purchases.
- Hardened token persistence (`ApiClient`): obfuscated `v2:` token envelope (`auth_token_secure`) with backward-compatible fallback for existing session state.
- 60fps Native UX & Apple HIG compliance (`NATIVE_UX_ENGINEERING_STANDARDS.md`):
  - Enforced `44 × 44 pt` minimum touch targets across interactive controls.
  - Added immediate touch-down feedback (`PressableScale`) across tabs, cards, and action buttons.
  - Added active-tab re-tap Scroll-to-Top behavior in `MainShell`, `HomeScreen`, and `SearchScreen`.
  - Restricted haptics to actual state-change actions.

## Implemented & Verified on Live Production Backend (`https://apolo.ma`)

1. **MySQL Composite Indexes Created on `ads` (`apoloma@mercury.capconnect.com`)**:
   - `idx_ads_cat_city_vip_id` on `ads(category_id, citie_id, is_vip, id)`
   - `idx_ads_status_vip_id` on `ads(status, is_vip, id)`
   - `idx_ads_user_id` on `ads(user_id, id)`
2. **`GET /api/v1/home` & `GET /api/v1/taxonomy` Caching & Payload Cap**:
   - `latest_ads` capped at `LIMIT 20` (`->take(20)`), `vip_ads` capped at `LIMIT 10` (`->take(10)`).
   - Added `Cache::remember` on home categories (`300s`), featured stores (`120s`), home stats (`120s`), and `/api/v1/taxonomy` (`300s`).
   - Verified live latency dropped from `1.04s` (cold) to **`0.17s` (`170ms`)** on `/api/v1/home` and **`0.11s` (`116ms`)** on `/api/v1/taxonomy`.
3. **Authenticated Account & Boost Endpoints Updated in Production (`routes/api.php`, `AuthApiController.php`, `BoostApiController.php`)**:
   - Registered `PUT` & `POST` for `/api/v1/auth/profile` and `/api/v1/auth/password`, plus `DELETE /api/v1/auth/profile`.
   - `AuthApiController::changePassword` accepts both `{current_password, password, password_confirmation}` and `{old_password, new_password, new_password_confirmation}`.
   - `BoostApiController::verifyInAppPurchase` accepts `platform: 'web'` in addition to `ios` and `android`.

## Remaining External Setup

- **GitHub Actions CI/CD Secrets (`.github/workflows/ci-cd.yml`)**:
  - Add `VERCEL_TOKEN`, `VERCEL_ORG_ID`, and `VERCEL_PROJECT_ID` in GitHub Repository Settings -> Secrets and variables -> Actions.
- **Live Store Sandbox IAP**:
  - Test physical iOS/Android store purchases using App Store Connect / Google Play Console sandbox accounts prior to public store submission.
