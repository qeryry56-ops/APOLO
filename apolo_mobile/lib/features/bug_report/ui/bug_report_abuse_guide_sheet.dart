import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../screens/widgets/apolo_safety_sheet.dart';
import 'bug_report_strings.dart';
import 'bug_report_theme.dart';

/// Default destination when the user taps the abuse/spam notice in Step 1 or Step 2
/// and no screen-specific `onReportAbuse` hook was supplied.
Future<void> showBugReportAbuseGuideSheet(
  BuildContext context, {
  required BugReportStrings strings,
}) async {
  final palette = BugReportPalette.of(context);

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    routeSettings: const RouteSettings(name: '/bug_report/abuse_guide'),
    builder: (ctx) {
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
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: palette.brandRed.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          CupertinoIcons.shield_lefthalf_fill,
                          color: palette.brandRed,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          strings.abuseGuideTitle,
                          style: TextStyle(
                            color: palette.textPrimary,
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    strings.abuseGuideBody,
                    style: TextStyle(
                      color: palette.textSecondary,
                      fontSize: 13.5,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
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
                        Navigator.of(ctx).pop();
                        if (context.mounted) {
                          showApoloReportSheet(
                            context,
                            targetType: 'user',
                            targetId: 'general_safety',
                            targetName: 'Apolo.ma Safety',
                          );
                        }
                      },
                      child: Text(
                        strings.openSafetyReportCta,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text(
                      strings.close,
                      style: TextStyle(
                        color: palette.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
