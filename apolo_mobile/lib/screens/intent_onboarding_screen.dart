import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../account/account_helpers.dart';
import '../core/config/app_config.dart';
import '../core/state/app_state.dart';
import '../theme/dl_share_profile_tokens.dart';
import '../widgets/dl_settings_kit.dart';
import 'widgets/kinetic_widgets.dart';
import '../l10n/l10n.dart';

/// Descriptor for a single tilted intent pill on [ApoloIntentOnboardingScreen].
class ApoloIntentOption {
  final String id;
  final String emoji;
  final String labelAr;
  final String labelFr;
  final String labelEn;
  final double tiltDegrees;
  final Set<int> categoryIds;

  const ApoloIntentOption({
    required this.id,
    required this.emoji,
    required this.labelAr,
    required this.labelFr,
    required this.labelEn,
    required this.tiltDegrees,
    required this.categoryIds,
  });

  String labelFor(AppStrings s) => s.tr(labelAr, labelFr, labelEn);
}

/// Dynamic Layer v5.1 User Intent Onboarding Screen (`# Onboarding`, `45952:346`):
/// - Pure `#FFFFFF` canvas with `56px` top navigation (`40×40` `#EEEEEE` circular back button, no separator)
/// - `Main Container` (`padding: 32px top/bottom, 64px left/right` on `375px` canvas, responsive on narrow viewports)
/// - Centered 2-line `24px Bold` heading ("فاش غادي تستعمل Apolo؟" / "What will you use Apolo for?")
/// - 4 playful tilted selectable stadium pills:
///   * Unselected: `#EEEEEE` background, `#000000` bold label, `#B5B5B5` `18×18` circle with white `+`
///   * Selected: `#1877F2` blue background, `#FFFFFF` bold label, `#FFFFFF` `18×18` circle with blue `−`
/// - Fixed bottom `ButtonDock` (`56px` black stadium `Continue / متابعة` button)
///   that saves preferences to [AppState] (and backend `/auth/onboard` when newly registered)
///   and routes cleanly into the personalized [MainShell].
class ApoloIntentOnboardingScreen extends StatefulWidget {
  final Widget Function(BuildContext context, Set<String> selectedIntents)?
      nextBuilder;
  final AccountAuth? auth;
  final AccountSession? session;
  final String accountType;
  final int cityId;

  const ApoloIntentOnboardingScreen({
    super.key,
    this.nextBuilder,
    this.auth,
    this.session,
    this.accountType = 'individual',
    this.cityId = 1,
  });

  static const List<ApoloIntentOption> options = <ApoloIntentOption>[
    ApoloIntentOption(
      id: 'buying',
      emoji: '🛍️',
      labelAr: 'نشري هميزات',
      labelFr: 'Pour acheter',
      labelEn: 'For Buying',
      tiltDegrees: -2.5,
      categoryIds: {1, 3, 4},
    ),
    ApoloIntentOption(
      id: 'selling',
      emoji: '🏷️',
      labelAr: 'نبيع سلعتي',
      labelFr: 'Pour vendre',
      labelEn: 'For Selling',
      tiltDegrees: 2.2,
      categoryIds: {1, 2, 3},
    ),
    ApoloIntentOption(
      id: 'pro_store',
      emoji: '🏪',
      labelAr: 'نفتح متجر PRO',
      labelFr: 'Boutique PRO',
      labelEn: 'For PRO Store',
      tiltDegrees: -1.6,
      categoryIds: {1, 8},
    ),
    ApoloIntentOption(
      id: 'auto_immo',
      emoji: '🚗',
      labelAr: 'سيارات وعقارات',
      labelFr: 'Auto & Immo',
      labelEn: 'Cars & Real Estate',
      tiltDegrees: -2.2,
      categoryIds: {2, 5},
    ),
  ];

  @override
  State<ApoloIntentOnboardingScreen> createState() =>
      _ApoloIntentOnboardingScreenState();
}

class _ApoloIntentOnboardingScreenState
    extends State<ApoloIntentOnboardingScreen> {
  final AppState _state = AppState();
  late final Set<String> _selected;
  bool _saving = false;

  static const Color _bg = Color(0xFFFFFFFF);
  static const Color _ink = Color(0xFF000000);
  static const Color _pillGrey = Color(0xFFEEEEEE);
  static const Color _plusCircleGrey = Color(0xFFB5B5B5);
  static const Color _selectedBlue = Color(0xFF1877F2);

  @override
  void initState() {
    super.initState();
    if (_state.userIntents.isNotEmpty) {
      _selected = Set<String>.from(_state.userIntents);
    } else {
      // Pre-select the 2nd pill (`selling`) by default matching Figma `45952:346`
      _selected = <String>{'selling'};
    }
  }

  void _toggleOption(String id) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  void _handleBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    if (widget.nextBuilder != null) {
      final target = widget.nextBuilder!(
        context,
        _selected.isEmpty ? const <String>{'buying'} : _selected,
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => target),
      );
    }
  }

  Future<void> _handleContinue() async {
    if (_saving || _selected.isEmpty) return;
    HapticFeedback.mediumImpact();
    setState(() => _saving = true);

    final chosen = Set<String>.from(_selected);
    await _state.saveUserIntents(chosen);

    if (widget.auth != null && widget.session != null) {
      final catIds = <int>{};
      for (final opt in ApoloIntentOnboardingScreen.options) {
        if (chosen.contains(opt.id)) {
          catIds.addAll(opt.categoryIds);
        }
      }
      try {
        await widget.auth!.onboard(
          widget.session!,
          chosen.contains('pro_store') ? 'business' : widget.accountType,
          widget.cityId,
          catIds.isEmpty ? const <int>{1, 2, 3} : catIds,
        );
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() => _saving = false);

    if (widget.nextBuilder != null) {
      final target = widget.nextBuilder!(context, chosen);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => target),
      );
    } else {
      Navigator.of(context).maybePop(chosen);
    }
  }

  Widget _buildTopNav(bool isAr) {
    final topInset = MediaQuery.paddingOf(context).top;
    final backIcon =
        isAr ? CupertinoIcons.chevron_right : CupertinoIcons.chevron_left;

    return SizedBox(
      key: const Key('dl-intent-top-nav'),
      height: topInset + DlShareProfileLayout.topNavHeight,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          height: DlShareProfileLayout.topNavHeight,
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DlShareProfileLayout.topNavHorizontalPadding,
            ),
            child: Row(
              children: [
                ApoloDlIconCircleButton(
                  key: const Key('dl-intent-back-button'),
                  icon: backIcon,
                  backgroundColor: _pillGrey,
                  iconColor: _ink,
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  onPressed: _handleBack,
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTiltedIntentPill(ApoloIntentOption option, AppStrings s) {
    final bool isSelected = _selected.contains(option.id);
    final double radians = option.tiltDegrees * (math.pi / 180.0);

    return Center(
      child: Transform.rotate(
        angle: radians,
        child: PressableScale(
          pressedScale: 0.95,
          onTap: () => _toggleOption(option.id),
          child: Semantics(
            button: true,
            selected: isSelected,
            label: option.labelFor(s),
            child: AnimatedContainer(
              key: Key('dl-intent-pill-${option.id}'),
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              constraints: const BoxConstraints(minHeight: 54.0),
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 13.0,
              ),
              decoration: BoxDecoration(
                color: isSelected ? _selectedBlue : _pillGrey,
                borderRadius: BorderRadius.circular(999),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: _selectedBlue.withValues(alpha: 0.22),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    option.emoji,
                    style: const TextStyle(fontSize: 18.0, height: 1.1),
                  ),
                  const SizedBox(width: 9.0),
                  Flexible(
                    child: Text(
                      option.labelFor(s),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isSelected ? Colors.white : _ink,
                        fontSize: 16.0,
                        fontWeight: FontWeight.w700,
                        height: 24.0 / 16.0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10.0),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 18.0,
                    height: 18.0,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : _plusCircleGrey,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      isSelected ? CupertinoIcons.minus : CupertinoIcons.plus,
                      size: 11.0,
                      color: isSelected ? _selectedBlue : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = _state.s;
    final isAr = s.isAr;
    final screenSize = MediaQuery.sizeOf(context);
    final mediaPadding = MediaQuery.paddingOf(context);
    final bottomSafe =
        DlShareProfileLayout.resolveBottomSafeInset(screenSize, mediaPadding);
    final bottomDockPad = math.max(20.0, bottomSafe + 8.0);
    // Exact Figma `45952:346` `Main Container` horizontal margin is `64px` on `375px` width,
    // gracefully clamping down on narrower screens so pills never clip.
    final double horizontalMargin =
        screenSize.width >= 375.0 ? 64.0 : (screenSize.width * 0.08).clamp(16.0, 48.0);
    final bool canContinue = _selected.isNotEmpty && !_saving;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: _bg,
        body: Column(
          children: [
            _buildTopNav(isAr),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460.0),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      key: const Key('dl-intent-main-container'),
                      padding: EdgeInsets.fromLTRB(
                        horizontalMargin,
                        32.0,
                        horizontalMargin,
                        32.0,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            s.tr(
                              'فاش غادي تستعمل\nApolo؟',
                              'Comment allez-vous\nutiliser Apolo ?',
                              appL10n.intentOnboardingWhatWillYouUseApolo,
                            ),
                            key: const Key('dl-intent-heading'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: _ink,
                              fontSize: 24.0,
                              fontWeight: FontWeight.w700,
                              height: 32.0 / 24.0,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 52.0),
                          for (int i = 0;
                              i < ApoloIntentOnboardingScreen.options.length;
                              i++) ...[
                            _buildTiltedIntentPill(
                              ApoloIntentOnboardingScreen.options[i],
                              s,
                            ),
                            if (i <
                                ApoloIntentOnboardingScreen.options.length - 1)
                              const SizedBox(height: 18.0),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Fixed bottom `ButtonDock` (`56px` black stadium pill `Continue / متابعة`)
            Padding(
              key: const Key('dl-intent-button-dock'),
              padding: EdgeInsets.fromLTRB(16.0, 8.0, 16.0, bottomDockPad),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56.0,
                    child: Material(
                      color: canContinue ? _ink : const Color(0xFFD4D4D4),
                      shape: const StadiumBorder(),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        key: const Key('dl-intent-continue-button'),
                        customBorder: const StadiumBorder(),
                        onTap: canContinue ? _handleContinue : null,
                        child: Center(
                          child: Text(
                            s.tr('متابعة', 'Continuer', appL10n.continueButton),
                            style: TextStyle(
                              color: canContinue
                                  ? Colors.white
                                  : const Color(0xFF757575),
                              fontSize: 16.0,
                              fontWeight: FontWeight.w600,
                              height: 24.0 / 16.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
