import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';

import '../../../core/config/app_config.dart';
import '../../../core/state/app_state.dart';
import '../controllers/meeting_room_controller.dart';
import '../l10n/meeting_strings.dart';
import '../models/meeting_models.dart';
import '../services/meeting_e2ee_manager.dart';
import 'meeting_room_screen.dart';

/// Pre-join lobby for Apolo.ma Group Meetings (8–25+ participants).
/// Lets users test camera/microphone, toggle End-to-End Encryption (E2EE),
/// choose room capacity, or paste a room code / `#key=...` invite link.
class MeetingLobbyScreen extends StatefulWidget {
  final String? initialInviteOrCode;
  final int? channelId;
  final int? adId;
  final String? defaultTitle;
  final Locale? localeOverride;
  final MeetingRoomController? controllerOverride;
  final bool autoStartCameraPreview;

  const MeetingLobbyScreen({
    super.key,
    this.initialInviteOrCode,
    this.channelId,
    this.adId,
    this.defaultTitle,
    this.localeOverride,
    this.controllerOverride,
    this.autoStartCameraPreview = true,
  });

  @override
  State<MeetingLobbyScreen> createState() => _MeetingLobbyScreenState();
}

class _MeetingLobbyScreenState extends State<MeetingLobbyScreen> {
  late final MeetingRoomController _controller;
  late final bool _ownsController;

  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _roomCodeCtrl = TextEditingController();
  final TextEditingController _e2eeKeyCtrl = TextEditingController();

  bool _isJoinMode = false;
  bool _enableE2ee = true;
  int _selectedMaxParticipants = 25;

  @override
  void initState() {
    super.initState();
    final lang =
        (widget.localeOverride ?? AppState().locale).languageCode;
    _ownsController = widget.controllerOverride == null;
    _controller =
        widget.controllerOverride ?? MeetingRoomController(languageCode: lang);

    if (widget.defaultTitle != null && widget.defaultTitle!.isNotEmpty) {
      _titleCtrl.text = widget.defaultTitle!;
    }

    if (widget.initialInviteOrCode != null &&
        widget.initialInviteOrCode!.trim().isNotEmpty) {
      _isJoinMode = true;
      final parsed =
          MeetingE2eeManager.parseInviteInput(widget.initialInviteOrCode!);
      _roomCodeCtrl.text = parsed.roomCode;
      if (parsed.e2eeSecretKey != null) {
        _enableE2ee = true;
        _e2eeKeyCtrl.text = parsed.e2eeSecretKey!;
      }
    } else {
      _e2eeKeyCtrl.text = MeetingE2eeManager.generateSecretKey();
    }

    if (widget.autoStartCameraPreview) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controller.initializeLobbyPreview();
      });
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _roomCodeCtrl.dispose();
    _e2eeKeyCtrl.dispose();
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submitLobby() async {
    if (_isJoinMode) {
      final parsed = MeetingE2eeManager.parseInviteInput(_roomCodeCtrl.text);
      if (parsed.roomCode.isEmpty) return;

      final secret = parsed.e2eeSecretKey ??
          (_enableE2ee && _e2eeKeyCtrl.text.trim().isNotEmpty
              ? _e2eeKeyCtrl.text.trim()
              : null);

      final ok = await _controller.joinExistingMeeting(
        roomCode: parsed.roomCode,
        e2eeSecretKey: secret,
      );
      if (ok && mounted) {
        await _openRoomStage();
      }
    } else {
      final created = await _controller.createAndJoinMeeting(
        title: _titleCtrl.text,
        channelId: widget.channelId,
        adId: widget.adId,
        maxParticipants: _selectedMaxParticipants,
        enableE2ee: _enableE2ee,
        customE2eeKey: _enableE2ee ? _e2eeKeyCtrl.text : null,
      );
      if (created != null &&
          _controller.phase == MeetingConnectionPhase.connected &&
          mounted) {
        await _openRoomStage();
      }
    }
  }

  Future<void> _openRoomStage() async {
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => MeetingRoomScreen(
          controller: _controller,
          localeOverride: widget.localeOverride,
        ),
      ),
    );
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
        appBar: AppBar(
          backgroundColor: const Color(0xFF07111E),
          foregroundColor: Colors.white,
          elevation: 0,
          title: Text(
            strings.lobbyTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        body: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final isBusy =
                _controller.phase == MeetingConnectionPhase.fetchingToken ||
                    _controller.phase == MeetingConnectionPhase.connectingSfu;

            return SingleChildScrollView(
              padding: const EdgeInsetsDirectional.fromSTEB(18, 8, 18, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // SFU + SVC Architecture Pill
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppConfig.success.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: AppConfig.success.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.hub_rounded,
                            size: 15,
                            color: AppConfig.success,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            strings.sfuBadge,
                            style: const TextStyle(
                              color: AppConfig.success,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Camera Preview Squircle Card
                  Container(
                    height: 220,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D1D2F),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (_controller.lobbyPreviewTrack != null &&
                            _controller.initialCameraEnabled)
                          VideoTrackRenderer(
                            _controller.lobbyPreviewTrack!,
                            fit: VideoViewFit.cover,
                            mirrorMode: VideoViewMirrorMode.mirror,
                          )
                        else
                          Center(
                            child: Icon(
                              Icons.videocam_off_rounded,
                              size: 42,
                              color: Colors.white.withValues(alpha: 0.35),
                            ),
                          ),
                        PositionedDirectional(
                          bottom: 12,
                          start: 12,
                          end: 12,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _PreviewTogglePill(
                                icon: _controller.initialMicEnabled
                                    ? Icons.mic_rounded
                                    : Icons.mic_off_rounded,
                                label: _controller.initialMicEnabled
                                    ? strings.micOn
                                    : strings.micOff,
                                active: _controller.initialMicEnabled,
                                onTap: _controller.toggleLobbyMic,
                              ),
                              const SizedBox(width: 10),
                              _PreviewTogglePill(
                                icon: _controller.initialCameraEnabled
                                    ? Icons.videocam_rounded
                                    : Icons.videocam_off_rounded,
                                label: _controller.initialCameraEnabled
                                    ? strings.camOn
                                    : strings.camOff,
                                active: _controller.initialCameraEnabled,
                                onTap: _controller.toggleLobbyCamera,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Mode Segmented Switcher (Create vs Join)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D1D2F),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _ModeTabButton(
                            label: strings.createNewMeeting,
                            selected: !_isJoinMode,
                            onTap: () => setState(() => _isJoinMode = false),
                          ),
                        ),
                        Expanded(
                          child: _ModeTabButton(
                            label: strings.joinExistingMeeting,
                            selected: _isJoinMode,
                            onTap: () => setState(() => _isJoinMode = true),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (!_isJoinMode) ...[
                    TextField(
                      controller: _titleCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: _darkInputDecoration(
                        label: strings.meetingTitleLabel,
                        hint: strings.meetingTitleHint,
                        icon: Icons.groups_rounded,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Capacity chips (8 / 16 / 25 / 50)
                    Wrap(
                      spacing: 8,
                      children: [8, 16, 25, 50].map((cap) {
                        final selected = _selectedMaxParticipants == cap;
                        return ChoiceChip(
                          label: Text('$cap ${strings.participants}'),
                          selected: selected,
                          selectedColor: AppConfig.brandRed,
                          backgroundColor: const Color(0xFF0D1D2F),
                          labelStyle: TextStyle(
                            color: Colors.white,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                          ),
                          onSelected: (_) =>
                              setState(() => _selectedMaxParticipants = cap),
                        );
                      }).toList(),
                    ),
                  ] else ...[
                    TextField(
                      controller: _roomCodeCtrl,
                      style: const TextStyle(color: Colors.white),
                      onChanged: (val) {
                        final parsed = MeetingE2eeManager.parseInviteInput(val);
                        if (parsed.e2eeSecretKey != null &&
                            parsed.e2eeSecretKey!.isNotEmpty) {
                          setState(() {
                            _enableE2ee = true;
                            _e2eeKeyCtrl.text = parsed.e2eeSecretKey!;
                          });
                        }
                      },
                      decoration: _darkInputDecoration(
                        label: strings.joinExistingMeeting,
                        hint: strings.roomCodeHint,
                        icon: Icons.key_rounded,
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // End-to-End Encryption (E2EE) Card
                  Material(
                    color: const Color(0xFF0D1D2F),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: BorderSide(
                        color: _enableE2ee
                            ? AppConfig.success.withValues(alpha: 0.45)
                            : Colors.white.withValues(alpha: 0.10),
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            value: _enableE2ee,
                            activeTrackColor: AppConfig.success,
                            onChanged: (val) =>
                                setState(() => _enableE2ee = val),
                            title: Text(
                              strings.e2eeTitle,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              strings.e2eeSubtitle,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.62),
                                fontSize: 12,
                              ),
                            ),
                          ),
                          if (_enableE2ee) ...[
                            const SizedBox(height: 8),
                            TextField(
                              controller: _e2eeKeyCtrl,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                              decoration: _darkInputDecoration(
                                label: strings.e2eePassphraseLabel,
                                hint: 'AES-GCM 256-bit Secret Key',
                                icon: Icons.enhanced_encryption_rounded,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  if (_controller.errorMessage != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppConfig.brandRed.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppConfig.brandRed.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Text(
                        _controller.errorMessage!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 22),

                  FilledButton.icon(
                    onPressed: isBusy ? null : _submitLobby,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppConfig.brandRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: const StadiumBorder(),
                    ),
                    icon: isBusy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.video_call_rounded),
                    label: Text(
                      _isJoinMode ? strings.joinNow : strings.startMeeting,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  InputDecoration _darkInputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.white70, size: 20),
      filled: true,
      fillColor: const Color(0xFF13253C),
      labelStyle: const TextStyle(color: Colors.white70),
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.38)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppConfig.brandRed, width: 1.5),
      ),
    );
  }
}

class _PreviewTogglePill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _PreviewTogglePill({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active
          ? Colors.black.withValues(alpha: 0.62)
          : AppConfig.brandRed.withValues(alpha: 0.88),
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 17),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeTabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeTabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? AppConfig.brandRed : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white70,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
