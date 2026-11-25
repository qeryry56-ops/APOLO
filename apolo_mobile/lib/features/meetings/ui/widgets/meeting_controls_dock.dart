import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/config/app_config.dart';
import '../../l10n/meeting_strings.dart';

class MeetingControlsDock extends StatelessWidget {
  final MeetingStrings strings;
  final bool isMicEnabled;
  final bool isCameraEnabled;
  final bool isSpeakerOn;
  final bool isScreenSharing;
  final int participantCount;
  final VoidCallback onToggleMic;
  final VoidCallback onToggleCamera;
  final VoidCallback onSwitchCamera;
  final VoidCallback onToggleSpeaker;
  final VoidCallback onToggleScreenShare;
  final VoidCallback onOpenParticipants;
  final VoidCallback onHangUp;

  const MeetingControlsDock({
    super.key,
    required this.strings,
    required this.isMicEnabled,
    required this.isCameraEnabled,
    required this.isSpeakerOn,
    required this.isScreenSharing,
    required this.participantCount,
    required this.onToggleMic,
    required this.onToggleCamera,
    required this.onSwitchCamera,
    required this.onToggleSpeaker,
    required this.onToggleScreenShare,
    required this.onOpenParticipants,
    required this.onHangUp,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(12, 6, 12, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1D2F).withValues(alpha: 0.86),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _DockActionButton(
                      icon: isMicEnabled
                          ? Icons.mic_rounded
                          : Icons.mic_off_rounded,
                      tooltip: isMicEnabled ? strings.micOn : strings.micOff,
                      isActive: isMicEnabled,
                      isAlertWhenInactive: true,
                      onTap: onToggleMic,
                    ),
                    const SizedBox(width: 8),
                    _DockActionButton(
                      icon: isCameraEnabled
                          ? Icons.videocam_rounded
                          : Icons.videocam_off_rounded,
                      tooltip: isCameraEnabled ? strings.camOn : strings.camOff,
                      isActive: isCameraEnabled,
                      isAlertWhenInactive: true,
                      onTap: onToggleCamera,
                    ),
                    if (isCameraEnabled) ...[
                      const SizedBox(width: 8),
                      _DockActionButton(
                        icon: Icons.cameraswitch_rounded,
                        tooltip: strings.switchCamera,
                        isActive: true,
                        onTap: onSwitchCamera,
                      ),
                    ],
                    if (!kIsWeb) ...[
                      const SizedBox(width: 8),
                      _DockActionButton(
                        icon: isSpeakerOn
                            ? Icons.volume_up_rounded
                            : Icons.phone_in_talk_rounded,
                        tooltip: strings.speaker,
                        isActive: isSpeakerOn,
                        onTap: onToggleSpeaker,
                      ),
                    ],
                    const SizedBox(width: 8),
                    _DockActionButton(
                      icon: isScreenSharing
                          ? Icons.stop_screen_share_rounded
                          : Icons.present_to_all_rounded,
                      tooltip: isScreenSharing
                          ? strings.stopScreenShare
                          : strings.screenShare,
                      isActive: isScreenSharing,
                      highlightColor: AppConfig.success,
                      onTap: onToggleScreenShare,
                    ),
                    const SizedBox(width: 8),
                    _ParticipantsCountButton(
                      count: participantCount,
                      tooltip: strings.participants,
                      onTap: onOpenParticipants,
                    ),
                    const SizedBox(width: 10),
                    Material(
                      color: AppConfig.brandRed,
                      shape: const StadiumBorder(),
                      child: InkWell(
                        customBorder: const StadiumBorder(),
                        onTap: onHangUp,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.call_end_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                strings.leaveCall,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
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
          ),
        ),
      ),
    );
  }
}

class _DockActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool isActive;
  final bool isAlertWhenInactive;
  final Color? highlightColor;
  final VoidCallback onTap;

  const _DockActionButton({
    required this.icon,
    required this.tooltip,
    required this.isActive,
    this.isAlertWhenInactive = false,
    this.highlightColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color bgColor;
    if (highlightColor != null && isActive) {
      bgColor = highlightColor!;
    } else if (!isActive && isAlertWhenInactive) {
      bgColor = AppConfig.brandRed.withValues(alpha: 0.22);
    } else if (isActive) {
      bgColor = Colors.white.withValues(alpha: 0.14);
    } else {
      bgColor = Colors.white.withValues(alpha: 0.07);
    }

    final Color iconColor = (!isActive && isAlertWhenInactive)
        ? AppConfig.brandRed
        : Colors.white;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: bgColor,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 46,
            height: 46,
            child: Icon(icon, color: iconColor, size: 21),
          ),
        ),
      ),
    );
  }
}

class _ParticipantsCountButton extends StatelessWidget {
  final int count;
  final String tooltip;
  final VoidCallback onTap;

  const _ParticipantsCountButton({
    required this.count,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.14),
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.people_alt_rounded,
                  color: Colors.white,
                  size: 19,
                ),
                const SizedBox(width: 5),
                Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
