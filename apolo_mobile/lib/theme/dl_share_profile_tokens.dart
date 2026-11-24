import 'package:flutter/material.dart';

import '../widgets/dl_settings_kit.dart';

/// Color tokens extracted from Figma `dynamic-layer-core-v5.1` (`Share profile / Default`).
abstract final class DlShareProfileColors {
  /// `color/grey/black`
  static const Color colorGreyBlack = Color(0xFF000000);

  /// `color/grey/white`
  static const Color colorGreyWhite = Color(0xFFFFFFFF);

  /// `color/grey/grey-100`
  static const Color colorGrey100 = Color(0xFFEEEEEE);

  /// `color/grey/grey-500`
  static const Color colorGrey500 = Color(0xFF757575);
}

/// Border-radius tokens extracted from Figma `dynamic-layer-core-v5.1`.
@immutable
class DlShareProfileRadii {
  const DlShareProfileRadii({
    this.roundedXl = 16.0,
    this.rounded5Xl = 32.0,
    this.pill = 999.0,
  });

  /// `roundedXl` — used for the inner `220x220` pure white QR container.
  final double roundedXl;

  /// `rounded5Xl` — used for the outer `284x364` QR profile card.
  final double rounded5Xl;

  /// Pill radius used for bottom CTA controls.
  final double pill;
}

/// Typography tokens extracted from Figma `dynamic-layer-core-v5.1`.
abstract final class DlShareProfileTypography {
  /// `font/size/2`
  static const double fontSize2 = 14.0;

  /// `font/size/3`
  static const double fontSize3 = 16.0;

  /// `font/line-height/2`
  static const double fontLineHeight2 = 20.0;

  /// `font/line-height/3`
  static const double fontLineHeight3 = 24.0;

  /// `font/letter-spacing/1`
  static const double fontLetterSpacing1 = 0.0;

  /// `Typography/textBase/Bold` (`font/size/3`, `font/line-height/3`, `700`).
  static TextStyle textBaseBold(Color color) => TextStyle(
        fontSize: fontSize3,
        height: fontLineHeight3 / fontSize3,
        fontWeight: FontWeight.w700,
        letterSpacing: fontLetterSpacing1,
        color: color,
      );

  /// `Typography/textBase/Regular` (`font/size/3`, `font/line-height/3`, `400`).
  static TextStyle textBaseRegular(Color color) => TextStyle(
        fontSize: fontSize3,
        height: fontLineHeight3 / fontSize3,
        fontWeight: FontWeight.w400,
        letterSpacing: fontLetterSpacing1,
        color: color,
      );

  /// `Typography/textSm/Regular` (`font/size/2`, `font/line-height/2`, `400`).
  static TextStyle textSmRegular(Color color) => TextStyle(
        fontSize: fontSize2,
        height: fontLineHeight2 / fontSize2,
        fontWeight: FontWeight.w400,
        letterSpacing: fontLetterSpacing1,
        color: color,
      );
}

/// Exact structural geometry constants from Figma `Share profile / Default` (`375x812`).
abstract final class DlShareProfileLayout {
  static const double canvasWidth = 375.0;
  static const double headerTotalHeight = 104.0;
  static const double topNavHeight = 56.0;
  static const double topNavHorizontalPadding = 16.0;
  static const double topNavGap = 16.0;
  static const double topNavActionSize = 40.0;
  static const double topNavTitleHeight = 24.0;

  static const double screenHorizontalPadding = 32.0;
  static const double sectionGap = 32.0;

  static const double outerCardPadding = 32.0;
  static const double innerQrSize = 220.0;
  static const double qrCodeOffset = 30.0;
  static const double qrCodeSize = 160.0;
  static const double identityLineHeight = 24.0;

  static const double privacyMaxWidth = 311.0;
  static const double privacyMinHeight = 60.0;

  static const double bottomBarHeight = 144.0;
  static const double bottomBarPadding = 32.0;
  static const double homeIndicatorHeight = 34.0;
}

/// Modular token bundle for [ShareProfileScreen] adapting cleanly to Light/Dark mode.
@immutable
class DlShareProfileTokens {
  const DlShareProfileTokens({
    required this.scaffoldBackground,
    required this.cardBackground,
    required this.qrBackground,
    required this.qrForeground,
    required this.ink,
    required this.mutedInk,
    required this.pillBackground,
    this.radii = const DlShareProfileRadii(),
  });

  final Color scaffoldBackground;
  final Color cardBackground;
  final Color qrBackground;
  final Color qrForeground;
  final Color ink;
  final Color mutedInk;
  final Color pillBackground;
  final DlShareProfileRadii radii;

  static const DlShareProfileTokens light = DlShareProfileTokens(
    scaffoldBackground: DlShareProfileColors.colorGreyWhite,
    cardBackground: DlShareProfileColors.colorGrey100,
    qrBackground: DlShareProfileColors.colorGreyWhite,
    qrForeground: DlShareProfileColors.colorGreyBlack,
    ink: DlShareProfileColors.colorGreyBlack,
    mutedInk: DlShareProfileColors.colorGrey500,
    pillBackground: DlShareProfileColors.colorGrey100,
  );

  static final DlShareProfileTokens dark = DlShareProfileTokens(
    scaffoldBackground: ApoloDlPalette.dark.bg,
    cardBackground: ApoloDlPalette.dark.groupCard,
    qrBackground: DlShareProfileColors.colorGreyWhite,
    qrForeground: DlShareProfileColors.colorGreyBlack,
    ink: ApoloDlPalette.dark.ink,
    mutedInk: ApoloDlPalette.dark.muted,
    pillBackground: ApoloDlPalette.dark.pill,
  );

  static DlShareProfileTokens of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }

  TextStyle get textBaseBold => DlShareProfileTypography.textBaseBold(ink);

  TextStyle get textBaseRegular =>
      DlShareProfileTypography.textBaseRegular(mutedInk);

  TextStyle get textSmRegular =>
      DlShareProfileTypography.textSmRegular(mutedInk);
}
