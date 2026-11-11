import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../core/state/app_state.dart';

/// RTC is not integrated. Never simulate a connection or dial a guessed number.
class CallScreen extends StatelessWidget {
  final String peerName;
  final String? peerAvatar;
  final String? peerPhone;
  final bool isVideo;

  const CallScreen({
    super.key,
    required this.peerName,
    this.peerAvatar,
    this.peerPhone,
    this.isVideo = false,
  });

  @override
  Widget build(BuildContext context) {
    final s = AppState().s;
    return Scaffold(
      appBar: AppBar(title: Text(s.tr('المكالمات', 'Appels'))),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(CupertinoIcons.phone,
                  size: 48, color: Color(0xFFE31B23)),
              const SizedBox(height: 20),
              Text(
                  s.tr('المكالمات غير متاحة حالياً',
                      'Appels indisponibles pour le moment'),
                  key: const Key('calls-unavailable'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Text(
                  s.tr(
                      'لم يتم إجراء أي اتصال. يمكنك التواصل عبر الرسائل النصية.',
                      'Aucun appel lancé. Vous pouvez utiliser les messages texte.'),
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton(
                  onPressed: () => Navigator.maybePop(context),
                  child: Text(
                      s.tr('العودة للمحادثة', 'Revenir à la conversation'))),
            ],
          ),
        ),
      ),
    );
  }
}
