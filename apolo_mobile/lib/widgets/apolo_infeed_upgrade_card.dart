import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/config/app_config.dart';
import '../core/state/app_state.dart';
import '../screens/auth_screen.dart';
import '../screens/pro_plus_screen.dart';
import '../screens/widgets/app_image.dart';
import '../screens/widgets/kinetic_widgets.dart';

/// Instagram "Meta One — Upgrade your profile" style in-feed upsell card
/// shown naturally while non-Premium users scroll through Home or Explore.
///
/// Features:
/// - Top-end `×` dismiss icon & bottom `Not now` button (session-dismissed in [AppState]).
/// - User's own circular avatar (`88×88`) + `Apolo Premium` blue eyebrow + live preview
///   of their own `@username` / name wearing the blue Verified badge.
/// - Signature `#5865F2` full-width `Upgrade your profile` CTA opening `ProPlusScreen`
///   (`99 DH/mo • Google Pay`).
class ApoloInFeedUpgradePromoCard extends StatelessWidget {
  final EdgeInsetsGeometry margin;

  const ApoloInFeedUpgradePromoCard({
    super.key,
    this.margin = EdgeInsets.zero,
  });

  static const Color _ctaBlue = Color(0xFF5865F2);
  static const Color _verifiedBlue = Color(0xFF3897F0);

  String _resolvePreviewHandle(Map<String, dynamic>? user, AppStrings s) {
    final username = (user?['username'] ?? '').toString().trim();
    if (username.isNotEmpty) {
      return username.replaceFirst(RegExp(r'^@+'), '');
    }
    final name =
        (user?['name'] ?? user?['full_name'] ?? '').toString().trim();
    if (name.isNotEmpty) {
      return name;
    }
    return s.tr('حسابك على Apolo', 'votre_profil', 'your_profile');
  }

  String _resolveAvatarUrl(Map<String, dynamic>? user) {
    return (user?['avatar_url'] ?? user?['avatar'] ?? '').toString().trim();
  }

  String _resolveInitial(String handleOrName) {
    final cleaned = handleOrName.trim().replaceFirst(RegExp(r'^@+'), '');
    if (cleaned.isEmpty) return 'A';
    return cleaned.characters.first.toUpperCase();
  }

  Future<void> _handleUpgradeTap(BuildContext context, AppState state) async {
    HapticFeedback.mediumImpact();
    if (!state.isLoggedIn) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const AuthScreen()),
      );
      if (!context.mounted || !state.isLoggedIn || state.isProPlusAccount) {
        return;
      }
    }
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => const ProPlusScreen(initialPlanId: 'monthly'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState();
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        if (!state.shouldShowInFeedUpgradePromo) {
          return const SizedBox.shrink();
        }

        final s = state.s;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final user = state.currentUser;
        final previewHandle = _resolvePreviewHandle(user, s);
        final avatarUrl = _resolveAvatarUrl(user);
        final initial = _resolveInitial(previewHandle);

        final Color cardBg =
            isDark ? const Color(0xFF0E1015) : const Color(0xFFF6F7FB);
        final Color borderColor =
            isDark ? const Color(0xFF222530) : const Color(0xFFE6E8F0);
        final Color titleColor =
            isDark ? Colors.white : const Color(0xFF0A0A0A);
        final Color subtitleColor =
            isDark ? const Color(0xFFD0D5DD) : const Color(0xFF525866);
        final Color eyebrowColor =
            isDark ? const Color(0xFF58A6FF) : const Color(0xFF2575FC);
        final Color notNowColor =
            isDark ? const Color(0xFF7A88FF) : const Color(0xFF4B56E8);
        final Color avatarSurface =
            isDark ? const Color(0xFF1C202B) : const Color(0xFFEAECEF);

        return Padding(
          padding: margin,
          child: Container(
            key: const Key('apolo-infeed-upgrade-card'),
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. Top-end `×` dismiss icon (Instagram style)
                Align(
                  alignment: AlignmentDirectional.topEnd,
                  child: GestureDetector(
                    key: const Key('infeed-upgrade-close-btn'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      state.dismissInFeedUpgradePromo();
                    },
                    child: SizedBox(
                      width: 32,
                      height: 32,
                      child: Center(
                        child: Icon(
                          CupertinoIcons.xmark,
                          size: 18,
                          color: isDark
                              ? const Color(0xFFD0D5DD)
                              : const Color(0xFF667085),
                        ),
                      ),
                    ),
                  ),
                ),

                // 2. Centered `88×88` Circular User Profile Avatar
                Container(
                  key: const Key('infeed-upgrade-avatar'),
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: avatarSurface,
                    border: Border.all(
                      color: borderColor,
                      width: 1.5,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  alignment: Alignment.center,
                  child: avatarUrl.isNotEmpty
                      ? AppImage(
                          url: avatarUrl,
                          width: 88,
                          height: 88,
                          fit: BoxFit.cover,
                          fallback: _buildInitialFallback(
                            state.isLoggedIn,
                            initial,
                            titleColor,
                          ),
                        )
                      : _buildInitialFallback(
                          state.isLoggedIn,
                          initial,
                          titleColor,
                        ),
                ),

                const SizedBox(height: 14),

                // 3. Blue Eyebrow Label (`Apolo Premium`)
                Text(
                  'Apolo Premium',
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: eyebrowColor,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.1,
                  ),
                ),

                const SizedBox(height: 5),

                // 4. User's Handle + Blue Verified Seal Preview (`elas_amine` + blue badge)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        previewHandle,
                        key: const Key('infeed-upgrade-handle'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: titleColor,
                          fontSize: 17.5,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    SizedBox(
                      key: const Key('infeed-upgrade-verified-preview'),
                      width: 18,
                      height: 18,
                      child: Image.asset(
                        'assets/badges/verified_blue.png',
                        width: 18,
                        height: 18,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          CupertinoIcons.checkmark_seal_fill,
                          size: 18,
                          color: _verifiedBlue,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // 5. 2-Line Credibility Value Proposition
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 305),
                  child: Text(
                    s.tr(
                      'ابني ثقة أكبر مع المشترين، وحوّل حسابك لـ متجر Business مع نشر غير محدود ملي تشترك فـ Apolo Premium.',
                      'Gagnez la confiance des acheteurs avec le badge Verified et votre boutique Business sur Apolo Premium.',
                      'Build credibility with buyers when you subscribe to Apolo Premium.',
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: subtitleColor,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // 6. Signature Royal-Blue Full-Width CTA (`Upgrade your profile`)
                PressableScale(
                  onTap: () => _handleUpgradeTap(context, state),
                  child: Container(
                    key: const Key('infeed-upgrade-cta-btn'),
                    width: double.infinity,
                    height: 46,
                    decoration: BoxDecoration(
                      color: _ctaBlue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      s.tr(
                        'ترقية ملفك الشخصي',
                        'Mettre à niveau votre profil',
                        'Upgrade your profile',
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // 7. Secondary `Not now` Action
                GestureDetector(
                  key: const Key('infeed-upgrade-not-now-btn'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    state.dismissInFeedUpgradePromo();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: Text(
                      s.tr('ليس الآن', 'Pas maintenant', 'Not now'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: notNowColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInitialFallback(bool isLoggedIn, String initial, Color fg) {
    if (!isLoggedIn) {
      return Icon(
        CupertinoIcons.person_fill,
        size: 38,
        color: fg.withValues(alpha: 0.75),
      );
    }
    return Text(
      initial,
      style: TextStyle(
        color: fg,
        fontSize: 32,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}
