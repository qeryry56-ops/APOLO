import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/config/app_config.dart';
import '../../core/services/firebase_chat_service.dart';
import '../../core/state/app_state.dart';
import '../../widgets/dl_settings_kit.dart';
import '../widgets/app_image.dart';

/// Dedicated full-screen view for inspecting and unblocking blocked accounts.
class SettingsBlockedAccountsScreen extends StatefulWidget {
  const SettingsBlockedAccountsScreen({super.key});

  @override
  State<SettingsBlockedAccountsScreen> createState() =>
      _SettingsBlockedAccountsScreenState();
}

class _SettingsBlockedAccountsScreenState
    extends State<SettingsBlockedAccountsScreen> {
  final AppState _state = AppState();
  bool _loading = true;
  String? _unblockingId;
  List<Map<String, dynamic>> _blocked = <Map<String, dynamic>>[];

  int get _myUserId =>
      int.tryParse('${_state.currentUser?['id'] ?? 0}') ?? 0;

  @override
  void initState() {
    super.initState();
    _loadBlocked();
  }

  Future<void> _loadBlocked() async {
    if (mounted) {
      setState(() => _loading = true);
    }
    final list = await FirebaseChatService.instance.loadBlockedTargets(_myUserId);
    if (!mounted) return;
    setState(() {
      _blocked = List<Map<String, dynamic>>.from(list);
      _loading = false;
    });
  }

  Future<void> _unblock(String id, String name) async {
    if (_unblockingId != null || id.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() => _unblockingId = id);
    try {
      await FirebaseChatService.instance.unblockTarget(
        myUserId: _myUserId,
        targetId: id,
      );
      if (!mounted) return;
      setState(() {
        _blocked = List<Map<String, dynamic>>.from(
          FirebaseChatService.instance.blockedList,
        );
      });
      final s = _state.s;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            s.tr(
              'تم إلغاء حظر $name',
              '$name a été débloqué',
              'Unblocked $name',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _unblockingId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _state,
      builder: (context, _) {
        final s = _state.s;
        final palette = ApoloDlPalette.of(context);

        return Directionality(
          textDirection: s.isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: palette.bg,
            body: SafeArea(
              child: Column(
                children: [
                  ApoloDlTopNav(
                    title: s.tr(
                      'الحسابات المحظورة',
                      'Comptes bloqués',
                      'Blocked accounts',
                    ),
                    size: ApoloDlTopNavSize.md,
                  ),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: RefreshIndicator(
                          color: palette.ink,
                          onRefresh: _loadBlocked,
                          child: _buildBody(s, palette),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(AppStrings s, ApoloDlPalette palette) {
    if (_loading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: const [
          _BlockedSkeletonRow(),
          _BlockedSkeletonRow(),
          _BlockedSkeletonRow(showSeparator: false),
        ],
      );
    }

    if (_blocked.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 48, 16, 32),
        children: [
          ApoloDlEmptyState(
            icon: CupertinoIcons.shield_lefthalf_fill,
            headline: s.tr(
              'لا توجد حسابات محظورة حالياً',
              'Aucun compte bloqué pour le moment',
              'No blocked accounts yet',
            ),
            description: s.tr(
              'الحسابات أو المتاجر التي تقوم بحظرها من المحادثات أو الإعلانات ستظهر هنا ويمكنك إلغاء حظرها في أي وقت.',
              'Les comptes ou boutiques que vous bloquez apparaîtront ici et vous pourrez les débloquer à tout moment.',
              'Users or stores you block from chats or listings will appear here so you can unblock them anytime.',
            ),
            actionLabel: s.tr('تحديث', 'Actualiser', 'Try again'),
            onAction: _loadBlocked,
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      itemCount: _blocked.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              s.tr(
                'يمكنك إلغاء حظر أي مستخدم أو متجر في أي وقت.',
                'Débloquez un utilisateur ou une boutique à tout moment.',
                'You can unblock any user or store anytime.',
              ),
              style: TextStyle(
                fontSize: 13.5,
                color: palette.muted,
              ),
            ),
          );
        }

        final item = _blocked[index - 1];
        final id = (item['id'] ?? '').toString();
        final name = (item['name'] ?? 'Apolo User').toString();
        final avatar = (item['avatar'] ?? '').toString();
        final type = (item['type'] ?? 'user').toString();
        final isBusy = _unblockingId == id;
        final isLast = index == _blocked.length;

        return ApoloDlLineItem(
          key: Key('blocked-account-$id'),
          title: name,
          description: type == 'store'
              ? s.tr('متجر محظور', 'Boutique bloquée', 'Blocked store')
              : s.tr('حساب محظور', 'Compte bloqué', 'Blocked user'),
          leadingWidget: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: palette.ink,
              shape: BoxShape.circle,
            ),
            clipBehavior: Clip.antiAlias,
            alignment: Alignment.center,
            child: avatar.isNotEmpty
                ? AppImage(
                    url: avatar,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                  )
                : Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'A',
                    style: TextStyle(
                      color: palette.onInk,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
          ),
          type: ApoloDlLineItemType.button,
          state: isBusy
              ? ApoloDlLineItemState.disabled
              : ApoloDlLineItemState.normal,
          buttonLabel: s.tr('إلغاء الحظر', 'Débloquer', 'Unblock'),
          showSeparator: !isLast,
          onButtonPressed: () => _unblock(id, name),
        );
      },
    );
  }
}

class _BlockedSkeletonRow extends StatefulWidget {
  const _BlockedSkeletonRow({this.showSeparator = true});

  final bool showSeparator;

  @override
  State<_BlockedSkeletonRow> createState() => _BlockedSkeletonRowState();
}

class _BlockedSkeletonRowState extends State<_BlockedSkeletonRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.45, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = ApoloDlPalette.of(context);
    return FadeTransition(
      opacity: _opacity,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: palette.pill,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 140,
                        height: 14,
                        decoration: BoxDecoration(
                          color: palette.pill,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 90,
                        height: 11,
                        decoration: BoxDecoration(
                          color: palette.surfaceSubtle,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 76,
                  height: 32,
                  decoration: BoxDecoration(
                    color: palette.pill,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ],
            ),
          ),
          if (widget.showSeparator) const ApoloDlSeparator(),
        ],
      ),
    );
  }
}
