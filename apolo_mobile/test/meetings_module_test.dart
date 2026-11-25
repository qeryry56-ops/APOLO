import 'package:apolo_mobile/features/meetings/meetings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SFU Models & Media Policy', () {
    test('parses LiveKit SFU credentials, SVC L3T3_KEY, and TURN TLS 443 servers', () {
      final creds = JoinMeetingCredentials.fromJson({
        'room': {
          'room_code': 'apo-8x2m-4k9p',
          'title': 'اجتماع العقارات - الرباط',
          'host_user_id': 7,
          'max_participants': 25,
          'active_participants_count': 9,
          'e2ee_enabled': true,
          'e2ee_key_hint': 'sha256:abcd1234ef567890',
          'is_locked': false,
          'mute_on_entry': false,
          'region': 'ma-casablanca',
          'status': 'active',
          'my_role': 'host',
        },
        'sfu': {
          'provider': 'livekit',
          'topology': 'sfu',
          'ws_url': 'wss://rtc.apolo.ma',
          'access_token': 'eyJhbGciOiJIUzI1NiJ9.test.sig',
          'expires_at': 1800000900,
          'ttl_seconds': 900,
          'participant_identity': 'user_7',
          'ice_transport_policy': 'all',
          'ice_servers': [
            {
              'urls': ['stun:turn.apolo.ma:3478'],
            },
            {
              'urls': [
                'turn:turn.apolo.ma:3478?transport=udp',
                'turns:turn.apolo.ma:443?transport=tcp',
              ],
              'username': '1800003600:user_7',
              'credential': 'hmac_sig',
            },
          ],
          'media_policy': {
            'preferred_video_codec': 'vp9',
            'svc_scalability_mode': 'L3T3_KEY',
            'simulcast_enabled': true,
            'dynacast_enabled': true,
            'adaptive_stream_enabled': true,
            'max_visible_video_tiles_per_page': 6,
          },
        },
      });

      expect(creds.room.roomCode, 'apo-8x2m-4k9p');
      expect(creds.room.maxParticipants, 25);
      expect(creds.room.isPrimaryHost, isTrue);
      expect(creds.wsUrl, 'wss://rtc.apolo.ma');
      expect(creds.mediaPolicy.preferredVideoCodec, 'vp9');
      expect(creds.mediaPolicy.svcScalabilityMode, 'L3T3_KEY');
      expect(creds.mediaPolicy.simulcastEnabled, isTrue);
      expect(creds.mediaPolicy.dynacastEnabled, isTrue);
      expect(creds.mediaPolicy.adaptiveStreamEnabled, isTrue);
      expect(creds.mediaPolicy.maxVisibleVideoTilesPerPage, 6);
      expect(creds.iceServers.length, 2);
      expect(
        creds.iceServers[1].urls,
        contains('turns:turn.apolo.ma:443?transport=tcp'),
      );
    });
  });

  group('End-to-End Encryption (E2EE) Key Management', () {
    test('generates 256-bit secret keys, verifies hints, and isolates key in URL fragment', () {
      final secret = MeetingE2eeManager.generateSecretKey();
      expect(secret.length, greaterThanOrEqualTo(42));

      final hint = MeetingE2eeManager.computePublicKeyHint(secret);
      expect(hint, startsWith('sha256:'));
      expect(MeetingE2eeManager.matchesKeyHint(secret, hint), isTrue);
      expect(MeetingE2eeManager.matchesKeyHint('wrong-secret', hint), isFalse);

      final link = MeetingE2eeManager.buildInviteLink(
        roomCode: 'apo-7k2m-9x4p',
        e2eeSecretKey: secret,
      );
      final uri = Uri.parse(link);
      // Secret key must be inside #fragment and NEVER in query/path sent to HTTP servers
      expect(uri.queryParameters.containsKey('key'), isFalse);
      expect(uri.fragment, contains('key='));

      final parsed = MeetingE2eeManager.parseInviteInput(link);
      expect(parsed.roomCode, 'apo-7k2m-9x4p');
      expect(parsed.e2eeSecretKey, secret);
    });
  });

  group('RTL & LTR Mobile UI Verification', () {
    testWidgets('MeetingLobbyScreen renders in Arabic RTL directionality and populates invite fragment',
        (tester) async {
      final secret = MeetingE2eeManager.generateSecretKey();
      final inviteUrl = MeetingE2eeManager.buildInviteLink(
        roomCode: 'apo-9a8b-7c6d',
        e2eeSecretKey: secret,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MeetingLobbyScreen(
            localeOverride: const Locale('ar'),
            initialInviteOrCode: inviteUrl,
            autoStartCameraPreview: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final scaffoldContext = tester.element(find.byType(Scaffold));
      expect(Directionality.of(scaffoldContext), TextDirection.rtl);
      expect(find.textContaining('SFU + SVC'), findsOneWidget);
      expect(find.text('انضمام للاجتماع'), findsOneWidget);
      expect(find.text('apo-9a8b-7c6d'), findsOneWidget);
    });

    testWidgets('MeetingLobbyScreen switches cleanly to LTR for French locale',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MeetingLobbyScreen(
            localeOverride: Locale('fr'),
            autoStartCameraPreview: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final scaffoldContext = tester.element(find.byType(Scaffold));
      expect(Directionality.of(scaffoldContext), TextDirection.ltr);
      expect(find.text('Démarrer la réunion'), findsOneWidget);
    });
  });
}
