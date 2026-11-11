# Apolo release readiness

This is a release-candidate hardening pass, not a certification that production is error-free.

## Implemented locally

- Minimal light splash and bilingual welcome with actual guest/sign-in/register navigation.
- Arabic typography, directional layouts, LTR-isolated monetary amounts and sensitive inputs.
- Dedicated support and account-security pages with explicit external browser/mail behavior.
- Server-confirmed login, OTP and account onboarding. Pending credentials stay separate from the persisted session.
- Profile and deletion errors no longer silently succeed; fabricated analytics and simulated calls/media are no longer presented as working features.
- Reels use real listing actions instead of fake sound/follow/counts or invented conversation IDs.
- Network outages no longer clear authenticated sessions indiscriminately.
- Posting validates price and contact information; missing taxonomy does not submit invented IDs.
- Sandbox payment receipts and fabricated paid plans removed from the production path.

## Release blockers requiring backend/device validation

- Native password and email changes are NOT implemented: backend contracts, reauthentication and verification need confirmation. Account Security opens the website and says this explicitly. The existing profile-update phone route is retained but not verified against live production.
- Auth/OTP/onboarding and deletion schemas are based on existing local client routes. No production SSH access or test account mutation was performed. Verify with a designated staging account before release.
- OAuth native callbacks, real-time audio/video, voice recording and media messaging remain unavailable. The app now says so instead of simulating success.
- In-app purchase completion, receipt verification, restore association with the correct listing, store configuration and refund handling require a sandbox-device purchase test. Do not launch paid boosts based solely on local compilation.
- Support email comes from the project's existing privacy copy. Mail delivery and ownership still need confirmation.
- Persisted access tokens currently use SharedPreferences. Review secure storage and web session protection before public account launch.
- Android/iOS device behavior, permissions, keyboard/safe areas, accessibility, store privacy disclosures and signing are not certified by Flutter web tests.

## Verification

Final analyzer, test and web-build results will be recorded after completed runs. Interrupted runs are not passes.

## Deployment

The repository's Vercel configuration serves `apolo_mobile/build/web` directly. A successful current web build is required before deployment. Do not publish partially updated build output. No commit or push is authorized by a request merely to retry tests.
