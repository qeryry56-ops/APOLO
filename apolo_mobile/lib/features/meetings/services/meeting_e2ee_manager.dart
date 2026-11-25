import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:livekit_client/livekit_client.dart';

/// Client-side End-to-End Encryption (E2EE) key manager for LiveKit SFU calls.
///
/// Media frames are encrypted/decrypted with AES-GCM on participant devices via
/// WebRTC Insertable Streams / Encoded Transforms. The SFU server forwards RTP
/// packets without ever receiving or seeing the secret room key.
class MeetingE2eeManager {
  BaseKeyProvider? _keyProvider;
  String? _currentSecretKey;
  int _ratchetGeneration = 0;

  BaseKeyProvider? get keyProvider => _keyProvider;
  bool get isInitialized => _keyProvider != null;
  int get ratchetGeneration => _ratchetGeneration;

  /// Generates a cryptographically strong 256-bit base64url room secret key.
  static String generateSecretKey() {
    final rng = Random.secure();
    final bytes = Uint8List.fromList(
      List<int>.generate(32, (_) => rng.nextInt(256)),
    );
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  /// Computes a short public fingerprint (`sha256:<16-hex>`) that can safely be
  /// stored as `e2ee_key_hint` on the backend so joiners verify they hold the
  /// matching room key before connecting—without exposing the secret key.
  static String computePublicKeyHint(String secretKey) {
    final normalized = secretKey.trim();
    final digest = sha256.convert(utf8.encode('apolo-e2ee-v1:$normalized'));
    return 'sha256:${digest.toString().substring(0, 16)}';
  }

  /// Verifies whether a candidate passphrase matches the room's public key hint.
  static bool matchesKeyHint(String candidateSecretKey, String? expectedHint) {
    if (expectedHint == null || expectedHint.trim().isEmpty) return true;
    return computePublicKeyHint(candidateSecretKey) == expectedHint.trim();
  }

  /// Builds a shareable invite link keeping the E2EE secret strictly inside the
  /// URL `#key=...` fragment (RFC 3986 fragments are never sent in HTTP requests).
  static String buildInviteLink({
    required String roomCode,
    String? e2eeSecretKey,
    String baseOrigin = 'https://apolo.ma',
  }) {
    final cleanCode = Uri.encodeComponent(roomCode.trim().toLowerCase());
    if (e2eeSecretKey != null && e2eeSecretKey.trim().isNotEmpty) {
      final encodedKey = Uri.encodeQueryComponent(e2eeSecretKey.trim());
      return '$baseOrigin/meet/$cleanCode#key=$encodedKey';
    }
    return '$baseOrigin/meet/$cleanCode';
  }

  /// Extracts `(roomCode, e2eeSecretKey)` from either a raw code or a full invite URL.
  static ({String roomCode, String? e2eeSecretKey}) parseInviteInput(
    String rawInput,
  ) {
    final trimmed = rawInput.trim();
    final uri = Uri.tryParse(trimmed);
    if (uri != null && (uri.hasScheme || trimmed.contains('/meet/'))) {
      final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
      final code = segments.isNotEmpty ? segments.last.toLowerCase() : trimmed;
      String? secret;
      if (uri.fragment.isNotEmpty) {
        final fragParams = Uri.splitQueryString(uri.fragment);
        secret = fragParams['key'];
      }
      return (roomCode: code, e2eeSecretKey: secret);
    }
    return (roomCode: trimmed.toLowerCase(), e2eeSecretKey: null);
  }

  /// Initializes AES-GCM `E2EEOptions` if supported on the current platform.
  Future<E2EEOptions?> createOptions(String secretKey) async {
    if (!lkPlatformSupportsE2EE()) {
      return null;
    }
    final normalized = secretKey.trim();
    if (normalized.isEmpty) {
      throw ArgumentError('E2EE secret key must not be empty.');
    }

    final provider = await BaseKeyProvider.create(
      sharedKey: true,
      ratchetWindowSize: 16,
      failureTolerance: -1,
    );
    await provider.setSharedKey(normalized);
    _keyProvider = provider;
    _currentSecretKey = normalized;
    _ratchetGeneration = 0;
    return E2EEOptions(keyProvider: provider);
  }

  /// Ratchets the shared room key forward (forward secrecy when a participant is
  /// removed by the host so the removed peer cannot decrypt subsequent media).
  Future<bool> ratchetRoomKey() async {
    final provider = _keyProvider;
    if (provider == null || _currentSecretKey == null) return false;
    await provider.ratchetSharedKey();
    _ratchetGeneration++;
    return true;
  }

  void dispose() {
    _keyProvider = null;
    _currentSecretKey = null;
    _ratchetGeneration = 0;
  }
}
