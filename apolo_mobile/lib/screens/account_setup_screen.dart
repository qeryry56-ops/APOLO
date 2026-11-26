import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../account/account_helpers.dart';
import '../core/config/app_config.dart';
import '../core/state/app_state.dart';
import '../theme/dl_share_profile_tokens.dart';
import '../widgets/dl_settings_kit.dart';

/// Descriptor for a selectable profile type chip on [AccountSetupScreen].
class ApoloAccountTypeOption {
  final String id;
  final String intentId;
  final String labelAr;
  final String labelFr;
  final String labelEn;
  final Set<int> categoryIds;

  const ApoloAccountTypeOption({
    required this.id,
    required this.intentId,
    required this.labelAr,
    required this.labelFr,
    required this.labelEn,
    required this.categoryIds,
  });

  String labelFor(AppStrings s) => s.tr(labelAr, labelFr, labelEn);
}

/// Dynamic Layer v5.1 `Account Setup / Default` & `Account Setup / Active` (`21825:25569`):
/// - Pure `#FFFFFF` canvas (`ApoloDlPalette.bg`)
/// - `TopNavigation` (`height: topInset + 56px`): `40×40` `#EEEEEE` back circle +
///   centered `16px Bold` `Create account` (`إنشاء حساب` / `Créer un compte`), no divider
/// - Start-aligned `Main Container` (`padding: 32px top/bottom, 16px left/right`):
///   - `Account type` (`20px Bold #000000`)
///   - `Choose at least one profile type to personalize your setup.` (`15px Regular #757575`)
///   - `Wrap` of multi-select pill chips (`height: 40px`):
///     * Default (unselected): `#EEEEEE` fill, `#000000` `14px Bold`
///     * Active (selected): `#000000` fill, `#FFFFFF` `14px Bold`
/// - Bottom `ButtonDock` (`56px` stadium `Continue` pill):
///   * Default (0 selected): `#EEEEEE` fill, `#757575` text (disabled)
///   * Active (>= 1 selected): `#000000` fill, `#FFFFFF` text (enabled)
class AccountSetupScreen extends StatefulWidget {
  final Widget Function(BuildContext context, Set<String> selectedTypes)?
      nextBuilder;
  final Set<String>? initialSelected;
  final AccountAuth? auth;
  final AccountSession? session;
  final int cityId;

  const AccountSetupScreen({
    super.key,
    this.nextBuilder,
    this.initialSelected,
    this.auth,
    this.session,
    this.cityId = 1,
  });

  static const List<ApoloAccountTypeOption> options = <ApoloAccountTypeOption>[
    ApoloAccountTypeOption(
      id: 'buyer',
      intentId: 'buying',
      labelAr: 'مشتري',
      labelFr: 'Acheteur',
      labelEn: 'Buyer',
      categoryIds: {1, 3, 4},
    ),
    ApoloAccountTypeOption(
      id: 'seller',
      intentId: 'selling',
      labelAr: 'بائع',
      labelFr: 'Vendeur',
      labelEn: 'Seller',
      categoryIds: {1, 2, 3},
    ),
    ApoloAccountTypeOption(
      id: 'business',
      intentId: 'pro_store',
      labelAr: 'تاجر / متجر',
      labelFr: 'Business',
      labelEn: 'Business',
      categoryIds: {1, 8},
    ),
    ApoloAccountTypeOption(
      id: 'auto_immo',
      intentId: 'auto_immo',
      labelAr: 'سيارات وعقارات',
      labelFr: 'Auto & Immo',
      labelEn: 'Auto & Real Estate',
      categoryIds: {2, 5},
    ),
    ApoloAccountTypeOption(
      id: 'services',
      intentId: 'selling',
      labelAr: 'حرفي وخدمات',
      labelFr: 'Services',
      labelEn: 'Services',
      categoryIds: {8},
    ),
  ];

  @override
  State<AccountSetupScreen> createState() => _AccountSetupScreenState();
}

class _AccountSetupScreenState extends State<AccountSetupScreen> {
  final AppState _state = AppState();
  late final Set<String> _selected;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Opens in exact Figma `Account Setup / Default` state (0 selected -> `#EEEEEE` Continue)
    // unless `initialSelected` is explicitly provided.
    _selected = widget.initialSelected != null
        ? Set<String>.from(widget.initialSelected!)
        : <String>{};
  }

  void _toggleType(String id) {
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
        _selected.isEmpty ? const <String>{'buyer'} : _selected,
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
    final mappedIntents = <String>{};
    final catIds = <int>{};
    for (final opt in AccountSetupScreen.options) {
      if (chosen.contains(opt.id)) {
        mappedIntents.add(opt.intentId);
        catIds.addAll(opt.categoryIds);
      }
    }

    final resolvedAccountType =
        chosen.contains('business') ? 'business' : 'individual';
    _state.accountType = resolvedAccountType;
    await _state.saveUserIntents(
      mappedIntents.isEmpty ? const <String>{'buying'} : mappedIntents,
    );

    if (widget.auth != null && widget.session != null) {
      try {
        await widget.auth!.onboard(
          widget.session!,
          resolvedAccountType,
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

  Widget _buildTopNav(
    bool isAr,
    ApoloDlPalette palette,
    Color primaryInk,
    AppStrings s,
  ) {
    final topInset = MediaQuery.paddingOf(context).top;
    final backIcon =
        isAr ? CupertinoIcons.chevron_right : CupertinoIcons.chevron_left;

    return SizedBox(
      key: const Key('dl-account-setup-top-nav'),
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
                  key: const Key('dl-account-setup-back-button'),
                  icon: backIcon,
                  backgroundColor: palette.pill,
                  iconColor: primaryInk,
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  onPressed: _handleBack,
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Text(
                    s.tr('إنشاء حساب', 'Créer un compte', 'Create account'),
                    key: const Key('dl-account-setup-header-title'),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: primaryInk,
                      fontSize: 16.0,
                      fontWeight: FontWeight.w700,
                      height: 24.0 / 16.0,
                    ),
                  ),
                ),
                const SizedBox(width: 16.0),
                const SizedBox(width: 40.0, height: 40.0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChip(
    ApoloAccountTypeOption option,
    AppStrings s,
    ApoloDlPalette palette,
    Color primaryInk,
  ) {
    final bool selected = _selected.contains(option.id);
    return Semantics(
      button: true,
      selected: selected,
      label: option.labelFor(s),
      child: GestureDetector(
        key: Key('dl-account-type-chip-${option.id}'),
        onTap: () => _toggleType(option.id),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          constraints: const BoxConstraints(minHeight: 40.0),
          padding: const EdgeInsets.symmetric(
            horizontal: 18.0,
            vertical: 10.0,
          ),
          decoration: BoxDecoration(
            color: selected ? primaryInk : palette.pill,
            borderRadius: BorderRadius.circular(999.0),
          ),
          child: Text(
            option.labelFor(s),
            style: TextStyle(
              color: selected ? palette.onInk : primaryInk,
              fontSize: 14.0,
              fontWeight: FontWeight.w700,
              height: 20.0 / 14.0,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = ApoloDlPalette.of(context);
    final primaryInk =
        isDark ? palette.ink : DlShareProfileColors.colorGreyBlack;
    final screenSize = MediaQuery.sizeOf(context);
    final mediaPadding = MediaQuery.paddingOf(context);
    final bottomSafe =
        DlShareProfileLayout.resolveBottomSafeInset(screenSize, mediaPadding);
    final bottomPad = math.max(16.0, bottomSafe + 8.0);
    final bool canContinue = _selected.isNotEmpty && !_saving;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: palette.bg,
        body: Column(
          children: [
            _buildTopNav(isAr, palette, primaryInk, s),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460.0),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        key: const Key('dl-account-setup-wrapper'),
                        padding: const EdgeInsets.fromLTRB(
                          16.0,
                          32.0,
                          16.0,
                          32.0,
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.tr(
                                  'نوع الحساب',
                                  'Type de compte',
                                  'Account type',
                                ),
                                key: const Key('dl-account-setup-title'),
                                style: TextStyle(
                                  color: primaryInk,
                                  fontSize: 20.0,
                                  fontWeight: FontWeight.w700,
                                  height: 28.0 / 20.0,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 8.0),
                              Text(
                                s.tr(
                                  'اختر نوع ملف شخصي واحد على الأقل لتخصيص إعداداتك.',
                                  'Choisissez au moins un type de profil pour personnaliser votre configuration.',
                                  'Choose at least one profile type to personalize your setup.',
                                ),
                                key: const Key('dl-account-setup-subtitle'),
                                style: TextStyle(
                                  color: palette.muted,
                                  fontSize: 15.0,
                                  fontWeight: FontWeight.w400,
                                  height: 22.0 / 15.0,
                                ),
                              ),
                              const SizedBox(height: 24.0),
                              Wrap(
                                spacing: 10.0,
                                runSpacing: 12.0,
                                children: [
                                  for (final opt in AccountSetupScreen.options)
                                    _buildChip(opt, s, palette, primaryInk),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Fixed Bottom `ButtonDock` (`#EEEEEE` Default -> `#000000` Active, `56px`)
            Padding(
              key: const Key('dl-account-setup-dock'),
              padding: EdgeInsets.fromLTRB(16.0, 12.0, 16.0, bottomPad),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56.0,
                    child: Material(
                      color: canContinue ? primaryInk : palette.pill,
                      shape: const StadiumBorder(),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        key: const Key('dl-account-setup-continue'),
                        customBorder: const StadiumBorder(),
                        onTap: canContinue ? _handleContinue : null,
                        child: Center(
                          child: _saving
                              ? CupertinoActivityIndicator(
                                  color: palette.onInk,
                                )
                              : Text(
                                  s.tr('متابعة', 'Continuer', 'Continue'),
                                  style: TextStyle(
                                    color: canContinue
                                        ? palette.onInk
                                        : palette.muted,
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.w700,
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
