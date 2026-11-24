import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/dl_share_profile_tokens.dart';
import 'dl_settings_kit.dart';

/// Shared Figma `TopNavigation` header used by both QR Display and Camera Scan modes.
/// Renders a horizontal `56px` wrapper (`16px` gap) inside the `104px` header area
/// with a `231x24` centered title slot on a `375px` canvas.
class DlShareTopNavigation extends StatelessWidget {
  const DlShareTopNavigation({
    required this.tokens,
    required this.headerKey,
    required this.wrapperKey,
    required this.backButtonKey,
    required this.titleKey,
    required this.onBack,
    super.key,
    this.title,
    this.trailing,
  });

  final DlShareProfileTokens tokens;
  final Key headerKey;
  final Key wrapperKey;
  final Key backButtonKey;
  final Key titleKey;
  final VoidCallback onBack;
  final String? title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final backIcon =
        isRtl ? CupertinoIcons.chevron_right : CupertinoIcons.chevron_left;
    final topInset = MediaQuery.paddingOf(context).top;
    final headerHeight = math.max(
      DlShareProfileLayout.headerTotalHeight,
      topInset + DlShareProfileLayout.topNavHeight,
    );

    return SizedBox(
      key: headerKey,
      height: headerHeight,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          key: wrapperKey,
          width: double.infinity,
          height: DlShareProfileLayout.topNavHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DlShareProfileLayout.topNavHorizontalPadding,
            ),
            child: Row(
              children: [
                ApoloDlIconCircleButton(
                  key: backButtonKey,
                  icon: backIcon,
                  backgroundColor: tokens.pillBackground,
                  iconColor: tokens.ink,
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  onPressed: onBack,
                ),
                const SizedBox(width: DlShareProfileLayout.topNavGap),
                Expanded(
                  child: SizedBox(
                    key: titleKey,
                    height: DlShareProfileLayout.topNavTitleHeight,
                    child: Center(
                      child: Text(
                        title ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: tokens.textBaseBold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: DlShareProfileLayout.topNavGap),
                SizedBox(
                  width: DlShareProfileLayout.topNavActionSize,
                  height: DlShareProfileLayout.topNavActionSize,
                  child: trailing,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
