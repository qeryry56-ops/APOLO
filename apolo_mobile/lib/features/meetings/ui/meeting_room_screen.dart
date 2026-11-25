import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/config/app_config.dart';
import '../../../core/state/app_state.dart';
import '../controllers/meeting_room_controller.dart';
import '../l10n/meeting_strings.dart';
import '../models/meeting_models.dart';
import '../services/meeting_e2ee_manager.dart';
import 'widgets/meeting_controls_dock.dart';
import 'widgets/network_reconnecting_banner.dart';
import 'widgets/participant_tile.dart';
import 'widgets/participants_moderation_sheet.dart';

class MeetingRoomScreen extends StatefulWidget {
  final MeetingRoomController controller;
  final Locale? localeOverride;

  const MeetingRoomScreen({
    super.key,
    required this.controller,
    this.localeOverride,
  });

  @override
  State<MeetingRoomScreen> createState() => _MeetingRoomScreenState();
}

class _MeetingRoomScreenState extends State<MeetingRoomScreen> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: widget.controller.currentPageIndex,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final mins = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final secs = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:$mins:$secs';
    }
    return '$mins:$secs';
  }

  Future<void> _confirmHangUp(
    BuildContext context,
    MeetingStrings strings,
  ) async {
    final summary = widget.controller.roomSummary;
    final isPrimaryHost = summary?.isPrimaryHost ?? false;

    if (!isPrimaryHost) {
      await widget.controller.leaveCall();
      if (context.mounted) Navigator.of(context).maybePop();
      return;
    }

    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF0D1D2F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 18, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton.icon(
                  onPressed: () => Navigator.of(sheetCtx).pop('end_all'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppConfig.brandRed,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  icon: const Icon(Icons.call_end_rounded),
                  label: Text(strings.endForAll),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(sheetCtx).pop('leave'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.22),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  icon: const Icon(Icons.exit_to_app_rounded),
                  label: Text(strings.leaveCall),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (choice == 'end_all') {
      await widget.controller.endMeetingForAll();
      if (context.mounted) Navigator.of(context).maybePop();
    } else if (choice == 'leave') {
      await widget.controller.leaveCall();
      if (context.mounted) Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = widget.localeOverride ?? AppState().locale;
    final isRtl = locale.languageCode == 'ar';
    final strings = MeetingStrings(locale.languageCode);

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFF07111E),
        body: AnimatedBuilder(
          animation: widget.controller,
          builder: (context, _) {
            final ctrl = widget.controller;
            final phase = ctrl.phase;

            if (phase == MeetingConnectionPhase.fetchingToken ||
                phase == MeetingConnectionPhase.connectingSfu) {
              return _ConnectingStateView(strings: strings);
            }

            if (phase == MeetingConnectionPhase.failed ||
                phase == MeetingConnectionPhase.ended) {
              return _EndedOrFailedStateView(
                strings: strings,
                errorMessage: ctrl.errorMessage,
                onClose: () => Navigator.of(context).maybePop(),
              );
            }

            final totalPages = ctrl.totalPages;
            final summary = ctrl.roomSummary;

            return Column(
              children: [
                // Top RTL-aware status & security bar
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      14,
                      10,
                      14,
                      6,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                ctrl.e2eeActive
                                    ? Icons.verified_user_rounded
                                    : Icons.shield_outlined,
                                size: 15,
                                color: ctrl.e2eeActive
                                    ? AppConfig.success
                                    : Colors.white70,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _formatDuration(ctrl.elapsed),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                summary?.title ?? 'Apolo Meeting',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (summary != null)
                                GestureDetector(
                                  onTap: () async {
                                    final link =
                                        MeetingE2eeManager.buildInviteLink(
                                      roomCode: summary.roomCode,
                                      e2eeSecretKey: ctrl.e2eeSecretKey,
                                    );
                                    await Clipboard.setData(
                                      ClipboardData(text: link),
                                    );
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(strings.inviteCopied),
                                        ),
                                      );
                                    }
                                  },
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        summary.roomCode,
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.62,
                                          ),
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.copy_rounded,
                                        size: 12,
                                        color: Colors.white.withValues(
                                          alpha: 0.62,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: strings.switchToAudioOnly,
                          onPressed: () =>
                              ctrl.setAudioOnlyMode(!ctrl.isAudioOnlyMode),
                          icon: Icon(
                            ctrl.isAudioOnlyMode
                                ? Icons.hearing_rounded
                                : Icons.hd_rounded,
                            color: ctrl.isAudioOnlyMode
                                ? AppConfig.success
                                : Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Graceful Reconnection / Low Bandwidth / Audio-Only Banner
                NetworkReconnectingBanner(
                  phase: phase,
                  lowBandwidthDetected: ctrl.lowBandwidthDetected,
                  isAudioOnlyMode: ctrl.isAudioOnlyMode,
                  strings: strings,
                  onToggleAudioOnly: () =>
                      ctrl.setAudioOnlyMode(!ctrl.isAudioOnlyMode),
                ),

                // Paginated Responsive SFU Video Stage (max 6 decoded streams per page)
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: totalPages,
                    onPageChanged: ctrl.setPageIndex,
                    itemBuilder: (context, pageIdx) {
                      final all = ctrl.allParticipants;
                      final perPage = ctrl.maxTilesPerPage;
                      final start = pageIdx * perPage;
                      final end = (start + perPage).clamp(0, all.length);
                      final pageTiles = start < all.length
                          ? all.sublist(start, end)
                          : const <MeetingParticipantTileData>[];

                      return Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          12,
                          6,
                          12,
                          6,
                        ),
                        child: _AdaptiveStageGrid(
                          tiles: pageTiles,
                          strings: strings,
                          pinnedIdentity: ctrl.pinnedParticipantIdentity,
                          onDoubleTapPin: ctrl.togglePinParticipant,
                        ),
                      );
                    },
                  ),
                ),

                // Pagination dots + page indicator when > 6 participants (8..25+)
                if (totalPages > 1)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          strings.pageIndicator(
                            ctrl.currentPageIndex + 1,
                            totalPages,
                          ),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 10),
                        ...List.generate(totalPages, (idx) {
                          final selected = idx == ctrl.currentPageIndex;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: selected ? 18 : 6,
                            height: 6,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppConfig.brandRed
                                  : Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),

                // Bottom Frosted Call Controls Dock
                MeetingControlsDock(
                  strings: strings,
                  isMicEnabled: ctrl.isMicEnabled,
                  isCameraEnabled: ctrl.isCameraEnabled,
                  isSpeakerOn: ctrl.isSpeakerOn,
                  isScreenSharing: ctrl.isScreenShareEnabled,
                  participantCount: ctrl.totalParticipantCount,
                  onToggleMic: ctrl.toggleMicrophone,
                  onToggleCamera: ctrl.toggleCamera,
                  onSwitchCamera: ctrl.switchCameraFacing,
                  onToggleSpeaker: ctrl.toggleSpeakerphone,
                  onToggleScreenShare: ctrl.toggleScreenShare,
                  onOpenParticipants: () {
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => Directionality(
                        textDirection:
                            isRtl ? TextDirection.rtl : TextDirection.ltr,
                        child: ParticipantsModerationSheet(
                          controller: ctrl,
                          strings: strings,
                        ),
                      ),
                    );
                  },
                  onHangUp: () => _confirmHangUp(context, strings),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AdaptiveStageGrid extends StatelessWidget {
  final List<MeetingParticipantTileData> tiles;
  final MeetingStrings strings;
  final String? pinnedIdentity;
  final void Function(String identity) onDoubleTapPin;

  const _AdaptiveStageGrid({
    required this.tiles,
    required this.strings,
    required this.pinnedIdentity,
    required this.onDoubleTapPin,
  });

  @override
  Widget build(BuildContext context) {
    if (tiles.isEmpty) {
      return const SizedBox.shrink();
    }

    if (tiles.length == 1) {
      final single = tiles.first;
      return ParticipantTile(
        data: single,
        strings: strings,
        isPinned: pinnedIdentity == single.identity,
        onDoubleTapPin: () => onDoubleTapPin(single.identity),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isLandscape = constraints.maxWidth > constraints.maxHeight * 1.15;
        final count = tiles.length;

        final int columns;
        if (isLandscape) {
          columns = count <= 2 ? 2 : 3;
        } else {
          columns = count <= 2 ? 1 : 2;
        }
        final rows = (count / columns).ceil();
        const spacing = 10.0;
        final tileWidth =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;
        final tileHeight =
            (constraints.maxHeight - (spacing * (rows - 1))) / rows;
        final aspectRatio =
            (tileWidth > 0 && tileHeight > 0) ? (tileWidth / tileHeight) : 0.85;

        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          itemCount: count,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: aspectRatio.clamp(0.45, 2.4),
          ),
          itemBuilder: (context, index) {
            final item = tiles[index];
            return ParticipantTile(
              key: ValueKey(item.identity),
              data: item,
              strings: strings,
              isPinned: pinnedIdentity == item.identity,
              onDoubleTapPin: () => onDoubleTapPin(item.identity),
            );
          },
        );
      },
    );
  }
}

class _ConnectingStateView extends StatelessWidget {
  final MeetingStrings strings;
  const _ConnectingStateView({required this.strings});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 44,
              height: 44,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(AppConfig.brandRed),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              strings.connectingToSfu,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              strings.sfuBadge,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.62),
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EndedOrFailedStateView extends StatelessWidget {
  final MeetingStrings strings;
  final String? errorMessage;
  final VoidCallback onClose;

  const _EndedOrFailedStateView({
    required this.strings,
    required this.errorMessage,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppConfig.brandRed.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.call_end_rounded,
                color: AppConfig.brandRed,
                size: 30,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              errorMessage ?? strings.leaveCall,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 22),
            FilledButton(
              onPressed: onClose,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.14),
                foregroundColor: Colors.white,
              ),
              child: Text(strings.leaveCall),
            ),
          ],
        ),
      ),
    );
  }
}
