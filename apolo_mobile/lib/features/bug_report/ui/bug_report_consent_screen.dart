import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/bug_report_models.dart';
import 'bug_report_strings.dart';
import 'bug_report_theme.dart';

enum BugReportConsentDecision {
  includeLogs,
  skipLogs,
  openAbuseGuide,
  cancelled,
}

/// Step 2: Explicit Logs & Diagnostics Consent Screen.
class BugReportConsentScreen extends StatelessWidget {
  final BugReportStrings strings;
  final BugReportContextSnapshot contextSnapshot;

  const BugReportConsentScreen({
    super.key,
    required this.strings,
    required this.contextSnapshot,
  });

  @override
  Widget build(BuildContext context) {
    final palette = BugReportPalette.of(context);

    return Directionality(
      textDirection: strings.isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: palette.surface,
        appBar: AppBar(
          backgroundColor: palette.surface,
          foregroundColor: palette.textPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          leading: IconButton(
            key: const Key('bug-report-consent-close-btn'),
            tooltip: strings.close,
            icon: Icon(Icons.close, color: palette.textPrimary, size: 24),
            onPressed: () =>
                Navigator.of(context).pop(BugReportConsentDecision.cancelled),
          ),
          title: Text(
            strings.flowHeaderTitle,
            style: TextStyle(
              color: palette.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Abuse / Spam exclusion notice card
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: palette.card,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: palette.border),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: palette.textSecondary
                                          .withValues(alpha: 0.45),
                                    ),
                                  ),
                                  child: Icon(
                                    CupertinoIcons.exclamationmark_triangle,
                                    size: 18,
                                    color: palette.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${strings.abuseNoticeTitle} ${strings.abuseNoticeSubtitle}',
                                        style: TextStyle(
                                          color: palette.textSecondary,
                                          fontSize: 12.8,
                                          height: 1.45,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      GestureDetector(
                                        key: const Key(
                                          'bug-report-consent-abuse-link',
                                        ),
                                        onTap: () {
                                          HapticFeedback.selectionClick();
                                          Navigator.of(context).pop(
                                            BugReportConsentDecision
                                                .openAbuseGuide,
                                          );
                                        },
                                        child: Text(
                                          strings.learnMoreAbuse,
                                          style: TextStyle(
                                            color: palette.secondaryActionRed,
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),

                          Text(
                            strings.consentHeading,
                            style: TextStyle(
                              color: palette.textPrimary,
                              fontSize: 23,
                              fontWeight: FontWeight.w800,
                              height: 1.22,
                              letterSpacing: strings.isRtl ? 0.0 : -0.4,
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Always-collected context block
                          _DiagnosticsExplanationCard(
                            palette: palette,
                            icon: CupertinoIcons.info_circle_fill,
                            title: strings.basicContextHeading,
                            body: strings.basicContextBody,
                            chips: [
                              'v${contextSnapshot.appVersion}',
                              contextSnapshot.platform,
                              contextSnapshot.routeName,
                              '${contextSnapshot.locale} (${contextSnapshot.isRtl ? 'RTL' : 'LTR'})',
                              if (contextSnapshot.userId != null)
                                'UID #${contextSnapshot.userId}',
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Optional diagnostics block
                          _DiagnosticsExplanationCard(
                            palette: palette,
                            icon: CupertinoIcons.doc_text_search,
                            iconColor: palette.brandRed,
                            title: strings.optionalLogsHeading,
                            body: strings.optionalLogsBody,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom pinned explicit choice actions
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    decoration: BoxDecoration(
                      color: palette.surface,
                      border: Border(top: BorderSide(color: palette.border)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            key: const Key('bug-report-include-logs-btn'),
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
                                  .pop(BugReportConsentDecision.includeLogs);
                            },
                            child: Text(
                              strings.includeAndContinue,
                              style: const TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 44,
                          child: TextButton(
                            key: const Key('bug-report-skip-logs-btn'),
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              Navigator.of(context)
                                  .pop(BugReportConsentDecision.skipLogs);
                            },
                            child: Text(
                              strings.dontIncludeAndContinue,
                              style: TextStyle(
                                color: palette.secondaryActionRed,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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

class _DiagnosticsExplanationCard extends StatelessWidget {
  final BugReportPalette palette;
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String body;
  final List<String> chips;

  const _DiagnosticsExplanationCard({
    required this.palette,
    required this.icon,
    required this.title,
    required this.body,
    this.iconColor,
    this.chips = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: iconColor ?? palette.textPrimary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: TextStyle(
              color: palette.textSecondary,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          if (chips.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: chips.map((label) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: palette.secondarySurface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: palette.border),
                  ),
                  child: Text(
                    label,
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                      color: palette.textPrimary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
