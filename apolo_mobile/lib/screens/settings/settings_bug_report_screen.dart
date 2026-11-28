import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/state/app_state.dart';
import '../../features/bug_report/services/bug_report_controller.dart';
import '../../features/bug_report/ui/bug_report_strings.dart';
import '../../widgets/dl_settings_kit.dart';
import '../support_screen.dart';
import '../../l10n/l10n.dart';

/// Dedicated full-screen settings view for bug reporting, shake trigger, and diagnostics.
class SettingsBugReportScreen extends StatelessWidget {
  const SettingsBugReportScreen({super.key});

  String _platformLabel() {
    if (kIsWeb) return 'Web (Ctrl+Shift+B)';
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS => 'iOS',
      TargetPlatform.android => 'Android',
      TargetPlatform.macOS => 'macOS',
      TargetPlatform.windows => 'Windows',
      TargetPlatform.linux => 'Linux',
      TargetPlatform.fuchsia => 'Fuchsia',
    };
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState();
    final shakeService = BugReportController.instance.shakeService;

    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final s = state.s;
        final strings = BugReportStrings(s);
        final palette = ApoloDlPalette.of(context);

        return Directionality(
          textDirection: s.isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: palette.bg,
            body: SafeArea(
              child: Column(
                children: [
                  ApoloDlTopNav(
                    title: strings.settingsRowTitle,
                    size: ApoloDlTopNavSize.md,
                  ),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                          children: [
                            Text(
                              strings.entrySubtitle,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.45,
                                color: palette.muted,
                              ),
                            ),
                            ApoloDlSectionHeader(
                              title: s.tr(
                                'التشغيل السريع',
                                'Déclenchement rapide',
                                appL10n.settingsBugReportQuickTrigger,
                              ),
                            ),
                            ValueListenableBuilder<bool>(
                              valueListenable: shakeService.enabled,
                              builder: (context, shakeEnabled, _) {
                                final baseDesc = strings.shakeToggleSubtitle(
                                  shakeEnabled,
                                  shakeService.isHardwareSupported,
                                );
                                final desc = kIsWeb
                                    ? '$baseDesc · Ctrl+Shift+B'
                                    : baseDesc;
                                return ApoloDlLineItem(
                                  key: const Key('settings-bug-shake-toggle'),
                                  title: strings.shakeToggleTitle,
                                  description: desc,
                                  leadingIcon: Icons.vibration_outlined,
                                  type: ApoloDlLineItemType.toggle,
                                  value: shakeEnabled,
                                  showSeparator: false,
                                  onChanged: (val) {
                                    shakeService.setEnabled(val);
                                  },
                                );
                              },
                            ),
                            ApoloDlSectionHeader(
                              title: s.tr(
                                'ملخص التشخيص',
                                'Résumé du diagnostic',
                                appL10n.settingsBugReportDiagnosticsSummary,
                              ),
                            ),
                            ApoloDlLineItem(
                              title: s.tr(
                                'إصدار التطبيق',
                                'Version de l’app',
                                appL10n.settingsAppDataAppVersion,
                              ),
                              leadingIcon: CupertinoIcons.app_badge,
                              trailingText:
                                  'v${AppConfig.appVersion}+${AppConfig.appBuildNumber}',
                              type: ApoloDlLineItemType.plain,
                            ),
                            ApoloDlLineItem(
                              title: s.tr(
                                'المنصة',
                                'Plateforme',
                                appL10n.settingsBugReportPlatform,
                              ),
                              leadingIcon: CupertinoIcons.device_phone_portrait,
                              trailingText: _platformLabel(),
                              type: ApoloDlLineItemType.plain,
                            ),
                            ApoloDlLineItem(
                              title: s.tr(
                                'اللغة النشطة',
                                'Langue active',
                                appL10n.settingsBugReportActiveLanguage,
                              ),
                              leadingIcon: CupertinoIcons.globe,
                              trailingText: state.locale.languageCode,
                              type: ApoloDlLineItemType.plain,
                              showSeparator: false,
                            ),
                            const SizedBox(height: 24),
                            ApoloDlButton(
                              key: const Key('settings-open-bug-reporter'),
                              label: strings.entryPrimaryCta,
                              leadingIcon: Icons.bug_report_outlined,
                              variant: ApoloDlButtonVariant.primary,
                              fullWidth: true,
                              onPressed: () {
                                BugReportController.instance
                                    .openBugReporter(context: context);
                              },
                            ),
                            const SizedBox(height: 10),
                            ApoloDlButton(
                              key: const Key('settings-bug-open-support'),
                              label: s.tr(
                                'المساعدة والدعم',
                                'Aide et assistance',
                                appL10n.settingsBugReportHelpSupport,
                              ),
                              leadingIcon: Icons.help_outline,
                              variant: ApoloDlButtonVariant.secondary,
                              fullWidth: true,
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const SupportScreen(),
                                  ),
                                );
                              },
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
