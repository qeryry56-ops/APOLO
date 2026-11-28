import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/state/app_state.dart';
import '../../widgets/dl_settings_kit.dart';
import '../../l10n/l10n.dart';

/// Dynamic Layer v5.1 `Appearance` (`Light` / `Dark` / `System`) settings screen
/// with interactive mini preview cards and instant app-wide persistence.
class SettingsAppearanceScreen extends StatefulWidget {
  const SettingsAppearanceScreen({super.key});

  @override
  State<SettingsAppearanceScreen> createState() =>
      _SettingsAppearanceScreenState();
}

class _SettingsAppearanceScreenState extends State<SettingsAppearanceScreen> {
  final AppState _state = AppState();

  Future<void> _selectMode(ThemeMode mode) async {
    HapticFeedback.selectionClick();
    await _state.setThemeMode(mode);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _state,
      builder: (context, _) {
        final s = _state.s;
        final isAr = s.isAr;
        final palette = ApoloDlPalette.of(context);
        final currentMode = _state.themeMode;

        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: palette.bg,
            body: SafeArea(
              child: Column(
                children: [
                  ApoloDlTopNav(
                    title: s.tr('المظهر', 'Apparence', appL10n.settingsAppearanceAppearance),
                    size: ApoloDlTopNavSize.md,
                  ),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                          children: [
                            Text(
                              s.tr(
                                'اختر مظهر Apolo المناسب لك. يمكنك التبديل بين الوضع الفاتح والوضع الداكن أو اتباع إعدادات جهازك تلقائياً.',
                                'Choisissez l’apparence d’Apolo. Basculez entre le mode clair, le mode sombre ou suivez votre appareil.',
                                appL10n.settingsAppearanceChooseHowApoloLooksSwitch,
                              ),
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.45,
                                color: palette.muted,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Interactive Side-by-Side Visual Preview Cards
                            Row(
                              children: [
                                Expanded(
                                  child: _AppearancePreviewCard(
                                    key: const Key('theme-card-light'),
                                    label: s.tr('فاتح', 'Clair', appL10n.appStateLight),
                                    icon: CupertinoIcons.sun_max_fill,
                                    selected: currentMode == ThemeMode.light,
                                    canvasColor: const Color(0xFFFFFFFF),
                                    surfaceColor: const Color(0xFFF6F6F6),
                                    pillColor: const Color(0xFFEEEEEE),
                                    inkColor: const Color(0xFF000000),
                                    activeBorderColor: palette.ink,
                                    idleBorderColor: palette.border,
                                    labelColor: palette.ink,
                                    mutedColor: palette.muted,
                                    onTap: () => _selectMode(ThemeMode.light),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _AppearancePreviewCard(
                                    key: const Key('theme-card-dark'),
                                    label: s.tr('داكن', 'Sombre', appL10n.appStateDark),
                                    icon: CupertinoIcons.moon_fill,
                                    selected: currentMode == ThemeMode.dark,
                                    canvasColor: const Color(0xFF0A0A0A),
                                    surfaceColor: const Color(0xFF161618),
                                    pillColor: const Color(0xFF222226),
                                    inkColor: const Color(0xFFFFFFFF),
                                    activeBorderColor: palette.ink,
                                    idleBorderColor: palette.border,
                                    labelColor: palette.ink,
                                    mutedColor: palette.muted,
                                    onTap: () => _selectMode(ThemeMode.dark),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 22),

                            ApoloDlLineItem(
                              key: const Key('theme-option-light'),
                              leadingIcon: CupertinoIcons.sun_max,
                              title: s.tr(
                                'الوضع الفاتح',
                                'Mode clair',
                                appL10n.profileLightMode,
                              ),
                              description: s.tr(
                                'خلفية بيضاء ناصعة وتباين واضح في النهار',
                                'Fond blanc épuré et contraste optimal de jour',
                                appL10n.settingsAppearanceCleanWhiteSurfacesCrispDaylight,
                              ),
                              type: ApoloDlLineItemType.radio,
                              value: currentMode == ThemeMode.light,
                              onChanged: (_) => _selectMode(ThemeMode.light),
                            ),
                            ApoloDlLineItem(
                              key: const Key('theme-option-dark'),
                              leadingIcon: CupertinoIcons.moon_stars,
                              title: s.tr(
                                'الوضع الداكن',
                                'Mode sombre',
                                appL10n.profileDarkMode,
                              ),
                              description: s.tr(
                                'مريح للعين في الإضاءة المنخفضة ويوفر طاقة البطارية',
                                'Confortable la nuit et économise la batterie',
                                appL10n.settingsAppearanceEasyEyesLowLightSaves,
                              ),
                              type: ApoloDlLineItemType.radio,
                              value: currentMode == ThemeMode.dark,
                              onChanged: (_) => _selectMode(ThemeMode.dark),
                            ),
                            ApoloDlLineItem(
                              key: const Key('theme-option-system'),
                              leadingIcon: CupertinoIcons.device_phone_portrait,
                              title: s.tr(
                                'تلقائي حسب الجهاز',
                                'Automatique (système)',
                                appL10n.settingsAppearanceSystemDefault,
                              ),
                              description: s.tr(
                                'يتغير تلقائياً مع مظهر الهاتف أو المتصفح',
                                'S’adapte automatiquement au thème de votre appareil',
                                appL10n.settingsAppearanceAutomaticallyMatchesPhoneBrowserTheme,
                              ),
                              type: ApoloDlLineItemType.radio,
                              showSeparator: false,
                              value: currentMode == ThemeMode.system,
                              onChanged: (_) => _selectMode(ThemeMode.system),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AppearancePreviewCard extends StatelessWidget {
  const _AppearancePreviewCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.canvasColor,
    required this.surfaceColor,
    required this.pillColor,
    required this.inkColor,
    required this.activeBorderColor,
    required this.idleBorderColor,
    required this.labelColor,
    required this.mutedColor,
    required this.onTap,
    super.key,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color canvasColor;
  final Color surfaceColor;
  final Color pillColor;
  final Color inkColor;
  final Color activeBorderColor;
  final Color idleBorderColor;
  final Color labelColor;
  final Color mutedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? activeBorderColor : idleBorderColor,
            width: selected ? 2.0 : 1.0,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 92,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: canvasColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: inkColor.withValues(alpha: 0.08),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: pillColor,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Icon(icon, size: 10, color: inkColor),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: pillColor,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 26,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const Spacer(),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: Container(
                      width: 44,
                      height: 12,
                      decoration: BoxDecoration(
                        color: inkColor,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  selected
                      ? CupertinoIcons.checkmark_circle_fill
                      : CupertinoIcons.circle,
                  size: 16,
                  color: selected ? labelColor : mutedColor,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? labelColor : mutedColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
