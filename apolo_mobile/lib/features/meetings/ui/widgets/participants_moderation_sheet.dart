import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/config/app_config.dart';
import '../../controllers/meeting_room_controller.dart';
import '../../l10n/meeting_strings.dart';
import '../../services/meeting_e2ee_manager.dart';

class ParticipantsModerationSheet extends StatelessWidget {
  final MeetingRoomController controller;
  final MeetingStrings strings;

  const ParticipantsModerationSheet({
    super.key,
    required this.controller,
    required this.strings,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final summary = controller.roomSummary;
        final participants = controller.allParticipants;
        final canModerate = summary?.isHostOrCohost ?? false;

        return Material(
          color: const Color(0xFF0D1D2F),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(18, 12, 18, 24),
            child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.24),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Text(
                      '${strings.participants} (${participants.length}/${summary?.maxParticipants ?? 25})',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    if (controller.e2eeActive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppConfig.success.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: AppConfig.success.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.enhanced_encryption_rounded,
                              size: 14,
                              color: AppConfig.success,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'E2EE #${controller.e2eeRatchetGeneration}',
                              style: const TextStyle(
                                color: AppConfig.success,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Share Invite + Host Room Lock bar
                if (summary != null)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () async {
                          final invite = MeetingE2eeManager.buildInviteLink(
                            roomCode: summary.roomCode,
                            e2eeSecretKey: controller.e2eeSecretKey,
                          );
                          await Clipboard.setData(ClipboardData(text: invite));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(strings.inviteCopied)),
                            );
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        icon: const Icon(Icons.link_rounded, size: 17),
                        label: Text(strings.copyInviteLink),
                      ),
                      if (canModerate)
                        OutlinedButton.icon(
                          onPressed: controller.toggleRoomLock,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: summary.isLocked
                                ? AppConfig.vipGold
                                : Colors.white,
                            side: BorderSide(
                              color: summary.isLocked
                                  ? AppConfig.vipGold
                                  : Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          icon: Icon(
                            summary.isLocked
                                ? Icons.lock_rounded
                                : Icons.lock_open_rounded,
                            size: 17,
                          ),
                          label: Text(
                            summary.isLocked
                                ? strings.unlockRoom
                                : strings.lockRoom,
                          ),
                        ),
                    ],
                  ),
                const SizedBox(height: 12),

                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: participants.length,
                    separatorBuilder: (_, __) => Divider(
                      color: Colors.white.withValues(alpha: 0.08),
                      height: 1,
                    ),
                    itemBuilder: (context, index) {
                      final p = participants[index];
                      final showHostActions =
                          canModerate && !p.isLocal && p.role != 'host';

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF1E3A5F),
                          child: Text(
                            p.displayName.isNotEmpty
                                ? p.displayName.characters.first.toUpperCase()
                                : 'A',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        title: Text(
                          p.isLocal
                              ? '${p.displayName} (${strings.youBadge})'
                              : p.displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          p.role == 'host'
                              ? strings.hostBadge
                              : (p.role == 'cohost'
                                  ? strings.cohostBadge
                                  : 'SFU Participant'),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              p.isMicEnabled
                                  ? Icons.mic_rounded
                                  : Icons.mic_off_rounded,
                              size: 18,
                              color: p.isMicEnabled
                                  ? AppConfig.success
                                  : AppConfig.brandRed,
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              p.isCameraEnabled
                                  ? Icons.videocam_rounded
                                  : Icons.videocam_off_rounded,
                              size: 18,
                              color: p.isCameraEnabled
                                  ? Colors.white70
                                  : Colors.white30,
                            ),
                            if (showHostActions) ...[
                              const SizedBox(width: 4),
                              PopupMenuButton<String>(
                                icon: const Icon(
                                  Icons.more_vert_rounded,
                                  color: Colors.white70,
                                ),
                                color: const Color(0xFF152A42),
                                onSelected: (action) {
                                  if (action == 'mute') {
                                    controller.muteRemoteParticipant(p);
                                  } else if (action == 'kick') {
                                    controller.removeRemoteParticipant(p);
                                  }
                                },
                                itemBuilder: (_) => [
                                  if (p.isMicEnabled)
                                    PopupMenuItem(
                                      value: 'mute',
                                      child: Text(
                                        strings.muteParticipant,
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  PopupMenuItem(
                                    value: 'kick',
                                    child: Text(
                                      strings.removeParticipant,
                                      style: const TextStyle(
                                        color: AppConfig.brandRed,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      );
                    },
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
