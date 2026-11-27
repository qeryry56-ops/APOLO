import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/config/app_config.dart';
import '../core/state/app_state.dart';
import '../screens/auth_screen.dart';
import '../screens/pro_plus_screen.dart';
import '../screens/widgets/app_image.dart';
import '../screens/widgets/kinetic_widgets.dart';
import '../theme/app_typography.dart';
import 'dl_settings_kit.dart';

/// Cardless, open in-feed "Upgrade your profile" section inspired by Instagram's
/// inline profile upsell and harmonized with Apolo's Dynamic Layer v5.1 system:
/// - Zero card box or tinted container — sits directly on the screen canvas
///   between subtle hairline dividers so it feels 100% native while scrolling.
/// - Shows the user's real circular avatar (`84×84`), `Apolo Premium` label, and
///   live preview of their `@username` / name paired with the blue Verified seal.
/// - Uses Dynamic Layer `palette.ink` / `palette.onInk` stadium primary CTA and
///   `palette.muted` secondary `Not now` action.
class ApoloInFeedUpgradePromoCard extends StatelessWidget {
  final EdgeInsetsGeometry margin;

  const ApoloInFeedUpgradePromoCard({
    super.key,
    this.margin = EdgeInsets.zero,
  });

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
        final palette = ApoloDlPalette.of(context);
        final user = state.currentUser;
        final previewHandle = _resolvePreviewHandle(user, s);
        final avatarUrl = _resolveAvatarUrl(user);
        final initial = _resolveInitial(previewHandle);

        return Padding(
          padding: margin,
          child: SizedBox(
            key: const Key('apolo-infeed-upgrade-card'),
            width: double.infinity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Subtle centered top hairline separator (no boxed card)
                FractionallySizedBox(
                  widthFactor: 0.72,
                  child: Container(
                    height: 0.8,
                    color: palette.separator,
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 12, 8, 22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 1. Top-end `×` dismiss icon floating cleanly on canvas
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
                                size: 17,
                                color: palette.muted,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // 2. Centered `84×84` Circular User Avatar
                      Container(
                        key: const Key('infeed-upgrade-avatar'),
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: palette.pill,
                        ),
                        clipBehavior: Clip.antiAlias,
                        alignment: Alignment.center,
                        child: avatarUrl.isNotEmpty
                            ? AppImage(
                                url: avatarUrl,
                                width: 84,
                                height: 84,
                                fit: BoxFit.cover,
                                fallback: _buildInitialFallback(
                                  state.isLoggedIn,
                                  initial,
                                  palette.ink,
                                ),
                              )
                            : _buildInitialFallback(
                                state.isLoggedIn,
                                initial,
                                palette.ink,
                              ),
                      ),

                      const SizedBox(height: 12),

                      // 3. Subtle Blue Eyebrow (`Apolo Premium`)
                      const Text(
                        'Apolo Premium',
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _verifiedBlue,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.1,
                        ),
                      ),

                      const SizedBox(height: 4),

                      // 4. User's Handle + Official Blue Verified Seal Preview
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
                                color: palette.ink,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                                letterSpacing: AppTypography.trackingForContext(
                                  context,
                                  -0.3,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                          SizedBox(
                            key: const Key('infeed-upgrade-verified-preview'),
                            width: 17.5,
                            height: 17.5,
                            child: Image.asset(
                              'assets/badges/verified_blue.png',
                              width: 17.5,
                              height: 17.5,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(
                                CupertinoIcons.checkmark_seal_fill,
                                size: 17.5,
                                color: _verifiedBlue,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 7),

                      // 5. Concise 2-Line Value Proposition in `palette.muted`
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 296),
                        child: Text(
                          s.tr(
                            'ابني ثقة أكبر مع المشترين، وافتح متجر Business ونشر غير محدود مع Apolo Premium.',
                            'Inspirez confiance aux acheteurs avec le badge Verified et votre boutique Business.',
                            'Build credibility with buyers when you subscribe to Apolo Premium.',
                          ),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: palette.muted,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w400,
                            height: 1.4,
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // 6. Dynamic Layer v5.1 Stadium Primary CTA (`#000000` Light / `#FFFFFF` Dark)
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 340),
                        child: PressableScale(
                          onTap: () => _handleUpgradeTap(context, state),
                          child: Container(
                            key: const Key('infeed-upgrade-cta-btn'),
                            width: double.infinity,
                            height: 46,
                            decoration: BoxDecoration(
                              color: palette.ink,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              s.tr(
                                'ترقية ملفك الشخصي',
                                'Mettre à niveau votre profil',
                                'Upgrade your profile',
                              ),
                              style: TextStyle(
                                color: palette.onInk,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // 7. Clean `Not now` Text Action
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
                              color: palette.muted,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Subtle centered bottom hairline separator
                FractionallySizedBox(
                  widthFactor: 0.72,
                  child: Container(
                    height: 0.8,
                    color: palette.separator,
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
        size: 36,
        color: fg.withValues(alpha: 0.7),
      );
    }
    return Text(
      initial,
      style: TextStyle(
        color: fg,
        fontSize: 30,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}
