import 'package:flutter/material.dart';

/// Unified Apolo.ma Real-Time Chat Design Tokens (`dynamic-layer-core-v5.1`).
///
/// Strictly applies Apolo.ma brand identity:
/// - Primary Red (`#E31B23`) for outgoing bubbles, Send CTA, unread pills, and active accents
/// - Pure White (`#FFFFFF`) for clean canvas, frosted surfaces, and crisp high-contrast ink on red
/// - Balanced `dynamic-layer-core-v5.1` neutrals (`#0A0A0A`, `#757575`, `#EEEEEE`, `#F6F6F6`)
abstract final class ApoloChatDlTokens {
  // Brand Identity
  static const Color primaryRed = Color(0xFFE31B23);
  static const Color primaryRedSoft = Color(0xFFFEF2F2);
  static const Color pureWhite = Color(0xFFFFFFFF);

  // dynamic-layer-core-v5.1 Neutrals
  static const Color inkPrimary = Color(0xFF0A0A0A);
  static const Color inkSecondary = Color(0xFF757575);
  static const Color surfaceSubtle = Color(0xFFF6F6F6);
  static const Color bubbleIncoming = Color(0xFFEEEEEE);
  static const Color borderNeutral = Color(0xFFE2E2E2);
  static const Color onlineGreen = Color(0xFF15803D);

  // Explicit 3-Stage ACK Indicator Colors
  /// Single gray tick (`✓`) — Server ACK
  static const Color ackSentColor = Color(0xFF8E8E93);

  /// Double gray tick (`✓✓`) — Delivered to recipient device ACK
  static const Color ackDeliveredColor = Color(0xFF757575);

  /// Double highlighted Apolo Red tick (`✓✓`) — Read inside active conversation ACK
  static const Color ackReadColor = primaryRed;

  // Accessible dynamic-layer-core-v5.1 geometry
  static const double minTouchTarget = 44.0;
  static const double bubbleRadius = 18.0;
  static const double listingCardRadius = 16.0;
  static const double composerHeight = 45.0;
}
