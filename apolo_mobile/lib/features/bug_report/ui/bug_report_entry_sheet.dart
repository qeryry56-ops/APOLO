import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'bug_report_strings.dart';
import 'bug_report_theme.dart';

enum BugReportEntryAction {
  startReport,
  reportAbuse,
  dismissed,
}

/// Step 1: Entry Bottom Sheet (`showModalBottomSheet`, `isScrollControlled: true`).
Future<BugReportEntryAction?> showBugReportEntrySheet(
  BuildContext context, {
  required BugReportStrings strings,
  required ValueListenable<bool> shakeEnabled,
  required Future<void> Function(bool enabled) onToggleShake,
  required bool isShakeHardwareSupported,
}) {
  return showModalBottomSheet<BugReportEntryAction>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    routeSettings: const RouteSettings(name: '/bug_report/entry'),
    builder: (ctx) {
      return _BugReportEntrySheetBody(
        strings: strings,
        shakeEnabled: shakeEnabled,
        onToggleShake: onToggleShake,
        isShakeHardwareSupported: isShakeHardwareSupported,
      );
    },
  );
}

class _BugReportEntrySheetBody extends StatelessWidget {
  final BugReportStrings strings;
  final ValueListenable<bool> shakeEnabled;
  final Future<void> Function(bool enabled) onToggleShake;
  final bool isShakeHardwareSupported;

  const _BugReportEntrySheetBody({
    required this.strings,
    required this.shakeEnabled,
    required this.onToggleShake,
    required this.isShakeHardwareSupported,
  });

  @override
  Widget build(BuildContext context) {
    final palette = BugReportPalette.of(context);
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Directionality(
      textDirection: strings.isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Center(
        heightFactor: 1.0,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
              border: palette.isDark
                  ? Border(top: BorderSide(color: palette.border, width: 0.8))
                  : null,
            ),
            padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottomInset),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: palette.handleColor,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    strings.entryTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: palette.textPrimary,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      letterSpacing: strings.isRtl ? 0.0 : -0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      strings.entrySubtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: palette.textSecondary,
                        fontSize: 13.5,
                        height: 1.45,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      key: const Key('bug-report-start-cta'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: palette.brandRed,
                        foregroundColor: palette.onBrandRed,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        Navigator.of(context)
                            .pop(BugReportEntryAction.startReport);
                      },
                      child: Text(
                        strings.entryPrimaryCta,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      key: const Key('bug-report-abuse-row'),
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Navigator.of(context)
                            .pop(BugReportEntryAction.reportAbuse);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 12,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Icon(
                                CupertinoIcons.info_circle,
                                size: 24,
                                color: palette.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    strings.abuseNoticeTitle,
                                    style: TextStyle(
                                      color: palette.textPrimary,
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                      height: 1.3,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    strings.abuseNoticeSubtitle,
                                    style: TextStyle(
                                      color: palette.textSecondary,
                                      fontSize: 12.8,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Icon(
                                strings.isRtl
                                    ? CupertinoIcons.chevron_left
                                    : CupertinoIcons.chevron_right,
                                size: 17,
                                color: palette.mutedIcon,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Divider(height: 1, thickness: 1, color: palette.border),
                  const SizedBox(height: 8),
                  ValueListenableBuilder<bool>(
                    valueListenable: shakeEnabled,
                    builder: (context, isEnabled, _) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    strings.shakeToggleTitle,
                                    style: TextStyle(
                                      color: palette.textPrimary,
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    strings.shakeToggleSubtitle(
                                      isEnabled,
                                      isShakeHardwareSupported,
                                    ),
                                    style: TextStyle(
                                      color: palette.textSecondary,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Switch.adaptive(
                              key: const Key('bug-report-shake-switch'),
                              value: isEnabled,
                              activeTrackColor: palette.brandRed,
                              activeThumbColor: Colors.white,
                              onChanged: (next) {
                                HapticFeedback.selectionClick();
                                onToggleShake(next);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
