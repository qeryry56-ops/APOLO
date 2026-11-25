import 'package:flutter/material.dart';

import '../../../../core/config/app_config.dart';
import '../../l10n/meeting_strings.dart';
import '../../models/meeting_models.dart';

class NetworkReconnectingBanner extends StatelessWidget {
  final MeetingConnectionPhase phase;
  final bool lowBandwidthDetected;
  final bool isAudioOnlyMode;
  final MeetingStrings strings;
  final VoidCallback onToggleAudioOnly;

  const NetworkReconnectingBanner({
    super.key,
    required this.phase,
    required this.lowBandwidthDetected,
    required this.isAudioOnlyMode,
    required this.strings,
    required this.onToggleAudioOnly,
  });

  @override
  Widget build(BuildContext context) {
    final isReconnecting = phase == MeetingConnectionPhase.reconnecting;
    if (!isReconnecting && !lowBandwidthDetected && !isAudioOnlyMode) {
      return const SizedBox.shrink();
    }

    final Color accentColor = isReconnecting
        ? AppConfig.brandRed
        : (isAudioOnlyMode ? AppConfig.success : AppConfig.vipGold);

    final String message = isReconnecting
        ? strings.reconnectingBanner
        : (isAudioOnlyMode
            ? strings.audioOnlyActive
            : strings.lowBandwidthBanner);

    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      child: Container(
        margin: const EdgeInsetsDirectional.fromSTEB(14, 6, 14, 4),
        padding: const EdgeInsetsDirectional.fromSTEB(12, 9, 10, 9),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1D2F).withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accentColor.withValues(alpha: 0.55)),
        ),
        child: Row(
          children: [
            if (isReconnecting)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                ),
              )
            else
              Icon(
                isAudioOnlyMode
                    ? Icons.graphic_eq_rounded
                    : Icons.network_check_rounded,
                size: 18,
                color: accentColor,
              ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (!isReconnecting) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: onToggleAudioOnly,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  isAudioOnlyMode
                      ? strings.resumeVideoMode
                      : strings.switchToAudioOnly,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
