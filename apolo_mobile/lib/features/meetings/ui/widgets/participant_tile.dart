import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';

import '../../../../core/config/app_config.dart';
import '../../controllers/meeting_room_controller.dart';
import '../../l10n/meeting_strings.dart';
import '../../models/meeting_models.dart';

class ParticipantTile extends StatelessWidget {
  final MeetingParticipantTileData data;
  final MeetingStrings strings;
  final bool isPinned;
  final VoidCallback? onDoubleTapPin;

  const ParticipantTile({
    super.key,
    required this.data,
    required this.strings,
    this.isPinned = false,
    this.onDoubleTapPin,
  });

  @override
  Widget build(BuildContext context) {
    final hasVideo = data.primaryVideoTrack != null &&
        (data.isCameraEnabled || data.isScreenSharing);

    final borderColor = data.isSpeaking
        ? AppConfig.success
        : (isPinned
            ? Colors.white.withValues(alpha: 0.55)
            : Colors.white.withValues(alpha: 0.10));

    return GestureDetector(
      onDoubleTap: onDoubleTapPin,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: const Color(0xFF0D1D2F),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: borderColor,
            width: data.isSpeaking ? 2.2 : 1.0,
          ),
          boxShadow: [
            if (data.isSpeaking)
              BoxShadow(
                color: AppConfig.success.withValues(alpha: 0.25),
                blurRadius: 16,
                spreadRadius: 1,
              ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasVideo)
              VideoTrackRenderer(
                data.primaryVideoTrack!,
                fit: data.isScreenSharing
                    ? VideoViewFit.contain
                    : VideoViewFit.cover,
                mirrorMode: (data.isLocal && !data.isScreenSharing)
                    ? VideoViewMirrorMode.mirror
                    : VideoViewMirrorMode.off,
              )
            else
              _AvatarFallback(data: data),

            // Subtle bottom legibility gradient
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 58,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.72),
                    ],
                  ),
                ),
              ),
            ),

            // Top directional badges (Pin / Role / Network Quality)
            PositionedDirectional(
              top: 10,
              start: 10,
              end: 10,
              child: Row(
                children: [
                  if (data.role == 'host' || data.role == 'cohost')
                    _RoleBadge(
                      label: data.role == 'host'
                          ? strings.hostBadge
                          : strings.cohostBadge,
                    ),
                  if (isPinned) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.push_pin_rounded,
                        size: 13,
                        color: Colors.white,
                      ),
                    ),
                  ],
                  const Spacer(),
                  _NetworkQualityPill(tier: data.networkTier),
                ],
              ),
            ),

            // Bottom directional name + mic indicator
            PositionedDirectional(
              bottom: 10,
              start: 10,
              end: 10,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      data.isLocal
                          ? '${data.displayName} (${strings.youBadge})'
                          : data.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: data.isMicEnabled
                          ? Colors.black.withValues(alpha: 0.50)
                          : AppConfig.brandRed.withValues(alpha: 0.92),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      data.isMicEnabled
                          ? Icons.mic_rounded
                          : Icons.mic_off_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  final MeetingParticipantTileData data;

  const _AvatarFallback({required this.data});

  @override
  Widget build(BuildContext context) {
    final trimmed = data.displayName.trim();
    final initial =
        trimmed.isNotEmpty ? trimmed.characters.first.toUpperCase() : 'A';

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.2),
          radius: 1.1,
          colors: [
            Color(0xFF152A42),
            Color(0xFF07111E),
          ],
        ),
      ),
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF1E3A5F),
            border: Border.all(
              color: data.isSpeaking
                  ? AppConfig.success
                  : Colors.white.withValues(alpha: 0.16),
              width: data.isSpeaking ? 2.5 : 1.2,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: (data.avatarUrl != null && data.avatarUrl!.isNotEmpty)
              ? CachedNetworkImage(
                  imageUrl: data.avatarUrl!,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => _InitialText(initial: initial),
                )
              : _InitialText(initial: initial),
        ),
      ),
    );
  }
}

class _InitialText extends StatelessWidget {
  final String initial;
  const _InitialText({required this.initial});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String label;
  const _RoleBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _NetworkQualityPill extends StatelessWidget {
  final MeetingNetworkTier tier;
  const _NetworkQualityPill({required this.tier});

  @override
  Widget build(BuildContext context) {
    if (tier == MeetingNetworkTier.unknown) return const SizedBox.shrink();

    final (Color color, int activeBars) = switch (tier) {
      MeetingNetworkTier.excellent => (AppConfig.success, 3),
      MeetingNetworkTier.good => (AppConfig.success, 2),
      MeetingNetworkTier.poor => (AppConfig.vipGold, 1),
      MeetingNetworkTier.lost => (AppConfig.brandRed, 0),
      MeetingNetworkTier.unknown => (Colors.white54, 2),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(3, (index) {
          final isActive = index < activeBars;
          return Container(
            width: 3,
            height: 5.0 + (index * 3.0),
            margin: const EdgeInsetsDirectional.only(end: 1.5),
            decoration: BoxDecoration(
              color: isActive ? color : Colors.white.withValues(alpha: 0.24),
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }
}
