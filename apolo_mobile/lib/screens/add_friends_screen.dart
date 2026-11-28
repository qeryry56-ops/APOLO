import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../core/config/app_config.dart';
import '../core/state/app_state.dart';
import '../theme/dl_share_profile_tokens.dart';
import '../widgets/dl_settings_kit.dart';
import 'widgets/app_image.dart';
import '../l10n/l10n.dart';

/// Descriptor for a single contact / friend row on [AddFriendsScreen].
class ApoloContactCandidate {
  final String id;
  final String name;
  final String handle;
  final String? avatarUrl;

  const ApoloContactCandidate({
    required this.id,
    required this.name,
    required this.handle,
    this.avatarUrl,
  });
}

/// Dynamic Layer v5.1 `AUTH-SUP-009 - Contacts` (`Add your friends`, Figma `33215:34358`):
/// - Pure `#FFFFFF` canvas (`palette.bg`)
/// - `TopNavigation` (`height: topInset + 56px`): `40×40` `#EEEEEE` circular `←` back button +
///   centered `16px Bold` `Add your friends` (`أضف أصدقاءك` / `Ajouter des amis`), no divider
/// - `Contacts` (`13px Regular #757575`) section label above a `20px`-rounded `#FFFFFF` card
///   with `1px #EEEEEE` border and `1px #EEEEEE` inner dividers
/// - Each row: `42×42` circular avatar (photo or `#EEEEEE` initial), bold name + `@handle`,
///   and trailing `32px` `#EEEEEE` stadium `Invite` pill (`#000000` `Invited` when tapped)
/// - Fixed bottom `ButtonDock` (`56px` `#000000` solid black `Continue` stadium pill)
class AddFriendsScreen extends StatefulWidget {
  final VoidCallback? onContinue;
  final List<ApoloContactCandidate>? initialContacts;

  const AddFriendsScreen({
    super.key,
    this.onContinue,
    this.initialContacts,
  });

  static const List<ApoloContactCandidate> defaultContacts =
      <ApoloContactCandidate>[
    ApoloContactCandidate(
      id: 'c1',
      name: 'Yassine El Mansouri',
      handle: '@yassine_casa',
    ),
    ApoloContactCandidate(
      id: 'c2',
      name: 'Salma Benali',
      handle: '@salma_rabat',
    ),
    ApoloContactCandidate(
      id: 'c3',
      name: 'Mehdi Chraibi',
      handle: '@mehdi_auto',
    ),
    ApoloContactCandidate(
      id: 'c4',
      name: 'Rania Tazi',
      handle: '@rania_deco',
    ),
    ApoloContactCandidate(
      id: 'c5',
      name: 'Karim Idrissi',
      handle: '@karim_tech',
    ),
  ];

  @override
  State<AddFriendsScreen> createState() => _AddFriendsScreenState();
}

class _AddFriendsScreenState extends State<AddFriendsScreen> {
  final AppState _state = AppState();
  late List<ApoloContactCandidate> _contacts;
  final Set<String> _invitedIds = <String>{};

  @override
  void initState() {
    super.initState();
    _contacts = List<ApoloContactCandidate>.from(
      widget.initialContacts ?? AddFriendsScreen.defaultContacts,
    );
    if (widget.initialContacts == null) {
      _loadSuggestedCommunityContacts();
    }
  }

  Future<void> _loadSuggestedCommunityContacts() async {
    try {
      final res = await _state.api.dio.get('/stores');
      if (!mounted) return;
      if (res.data is Map && res.data['status'] == 'success') {
        final rawList = (res.data['stores'] ?? res.data['data']) as List?;
        if (rawList != null && rawList.isNotEmpty) {
          final loaded = <ApoloContactCandidate>[];
          for (final item in rawList.take(5)) {
            if (item is! Map) continue;
            final name = (item['name'] ?? '').toString().trim();
            if (name.isEmpty) continue;
            final sub = (item['subdomain'] ?? item['slug'] ?? '')
                .toString()
                .trim()
                .replaceAll(RegExp(r'[^a-zA-Z0-9_.-]'), '');
            final handle = sub.isNotEmpty
                ? '@$sub'
                : '@${name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')}';
            final avatar = (item['logo_url'] ?? item['avatar'] ?? '')
                .toString()
                .trim();
            loaded.add(
              ApoloContactCandidate(
                id: 'store_${item['id'] ?? loaded.length}',
                name: name,
                handle: handle.length > 1 ? handle : '@apolo_member',
                avatarUrl: avatar.isNotEmpty ? avatar : null,
              ),
            );
          }
          if (loaded.length >= 3 && mounted) {
            setState(() => _contacts = loaded);
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _toggleInvite(ApoloContactCandidate contact) async {
    HapticFeedback.selectionClick();
    final alreadyInvited = _invitedIds.contains(contact.id);
    setState(() {
      if (alreadyInvited) {
        _invitedIds.remove(contact.id);
      } else {
        _invitedIds.add(contact.id);
      }
    });

    if (!alreadyInvited) {
      final s = _state.s;
      final inviteMsg = s.tr(
        'انضم إليّ على Apolo.ma — سوق الإعلانات والمتاجر فالمغرب: https://apolo.ma',
        'Rejoins-moi sur Apolo.ma — la marketplace au Maroc : https://apolo.ma',
        appL10n.addFriendsJoinMeApoloMaMorocco,
      );
      try {
        await Clipboard.setData(ClipboardData(text: inviteMsg));
      } catch (_) {}
      try {
        await Share.share(inviteMsg, subject: AppConfig.appName);
      } catch (_) {}
    }
  }

  void _handleContinue() {
    HapticFeedback.mediumImpact();
    if (widget.onContinue != null) {
      widget.onContinue!();
      return;
    }
    Navigator.of(context).maybePop();
  }

  Widget _buildTopNav(bool isAr, ApoloDlPalette palette, AppStrings s) {
    final topInset = MediaQuery.paddingOf(context).top;
    final backIcon =
        isAr ? CupertinoIcons.arrow_right : CupertinoIcons.arrow_left;

    return SizedBox(
      key: const Key('dl-add-friends-top-nav'),
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
                  key: const Key('dl-add-friends-back-button'),
                  icon: backIcon,
                  iconSize: 19.0,
                  backgroundColor: palette.pill,
                  iconColor: palette.ink,
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Text(
                    s.tr(
                      'أضف أصدقاءك',
                      'Ajouter des amis',
                      appL10n.addFriendsAddFriends,
                    ),
                    key: const Key('dl-add-friends-title'),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: palette.ink,
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

  Widget _buildContactRow({
    required ApoloContactCandidate contact,
    required int index,
    required bool showDivider,
    required AppStrings s,
    required ApoloDlPalette palette,
  }) {
    final isInvited = _invitedIds.contains(contact.id);
    final initial = contact.name.trim().isNotEmpty
        ? contact.name.trim().characters.first.toUpperCase()
        : 'A';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 13.0,
          ),
          child: Row(
            children: [
              Container(
                width: 42.0,
                height: 42.0,
                decoration: BoxDecoration(
                  color: palette.pill,
                  shape: BoxShape.circle,
                ),
                clipBehavior: Clip.antiAlias,
                alignment: Alignment.center,
                child: contact.avatarUrl != null &&
                        contact.avatarUrl!.isNotEmpty
                    ? AppImage(
                        url: contact.avatarUrl!,
                        width: 42.0,
                        height: 42.0,
                        fit: BoxFit.cover,
                        fallback: Text(
                          initial,
                          style: TextStyle(
                            color: palette.ink,
                            fontSize: 15.0,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    : Text(
                        initial,
                        style: TextStyle(
                          color: palette.ink,
                          fontSize: 15.0,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: palette.ink,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        height: 20.0 / 14.5,
                      ),
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      contact.handle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                        color: palette.muted,
                        fontSize: 13.0,
                        fontWeight: FontWeight.w400,
                        height: 18.0 / 13.0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12.0),
              Material(
                color: isInvited ? palette.ink : palette.pill,
                shape: const StadiumBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  key: Key('dl-invite-btn-$index'),
                  customBorder: const StadiumBorder(),
                  onTap: () => _toggleInvite(contact),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 32.0),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14.0,
                        vertical: 7.0,
                      ),
                      child: Center(
                        child: Text(
                          isInvited
                              ? s.tr('تمت الدعوة', 'Invité', appL10n.addFriendsInvited)
                              : s.tr('دعوة', 'Inviter', appL10n.addFriendsInvite),
                          style: TextStyle(
                            color: isInvited ? palette.onInk : palette.ink,
                            fontSize: 13.0,
                            fontWeight: FontWeight.w700,
                            height: 16.0 / 13.0,
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
        if (showDivider)
          const ApoloDlSeparator(
            indentStart: 16.0,
            indentEnd: 16.0,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = _state.s;
    final isAr = s.isAr;
    final palette = ApoloDlPalette.of(context);
    final screenSize = MediaQuery.sizeOf(context);
    final mediaPadding = MediaQuery.paddingOf(context);
    final bottomSafe =
        DlShareProfileLayout.resolveBottomSafeInset(screenSize, mediaPadding);
    final bottomPad = math.max(16.0, bottomSafe + 8.0);

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: palette.bg,
        body: Column(
          children: [
            _buildTopNav(isAr, palette, s),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460.0),
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 24.0),
                    children: [
                      Text(
                        s.tr('جهات الاتصال', 'Contacts', appL10n.addFriendsContacts),
                        key: const Key('dl-add-friends-section-label'),
                        style: TextStyle(
                          color: palette.muted,
                          fontSize: 13.0,
                          fontWeight: FontWeight.w400,
                          height: 18.0 / 13.0,
                        ),
                      ),
                      const SizedBox(height: 10.0),
                      Container(
                        key: const Key('dl-add-friends-card'),
                        decoration: BoxDecoration(
                          color: palette.bg,
                          borderRadius: BorderRadius.circular(20.0),
                          border: Border.all(
                            color: palette.separator,
                            width: 1.0,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (int i = 0; i < _contacts.length; i++)
                              _buildContactRow(
                                contact: _contacts[i],
                                index: i,
                                showDivider: i < _contacts.length - 1,
                                s: s,
                                palette: palette,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Fixed Bottom `ButtonDock` (`56px` `#000000` solid black `Continue` pill)
            Padding(
              padding: EdgeInsets.fromLTRB(16.0, 12.0, 16.0, bottomPad),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56.0,
                    child: Material(
                      color: palette.ink,
                      shape: const StadiumBorder(),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        key: const Key('dl-add-friends-continue'),
                        customBorder: const StadiumBorder(),
                        onTap: _handleContinue,
                        child: Center(
                          child: Text(
                            s.tr('متابعة', 'Continuer', appL10n.continueButton),
                            style: TextStyle(
                              color: palette.onInk,
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
