import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../core/config/app_config.dart';
import '../core/state/app_state.dart';
import 'widgets/ad_card.dart';
import 'widgets/boost_sheet.dart';
import 'auth_screen.dart';
import 'post_ad_screen.dart';
import 'privacy_compliance_screen.dart';
import 'stores_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AppState _state = AppState();
  List<dynamic> _myAds = [];
  List<dynamic> _favorites = [];
  List<dynamic> _savedSearches = [];

  static const Color _ink = Color(0xFF0F1B2D);
  static const Color _blue = Color(0xFFE31B23);
  static const Color _muted = Color(0xFF8A94A6);
  static const Color _border = Color(0xFFEDEFF3);
  static const Color _divider = Color(0xFFF0F2F5);

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    if (!_state.isLoggedIn) return;
    try {
      final results = await Future.wait([
        _state.api.dio.get('/my-ads'),
        _state.api.dio.get('/favorites'),
        _state.api.dio.get('/saved-searches'),
      ]);
      if (mounted) {
        setState(() {
          _myAds = results[0].data['data'] ?? [];
          _favorites = results[1].data['data'] ?? [];
          _savedSearches = results[2].data['data'] ?? [];
        });
      }
    } catch (_) {}
  }

  Future<void> _confirmDeleteAccount() async {
    final s = _state.s;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.deleteAccount),
        content: Text(
          s.tr(
            'هل أنت متأكد من رغبتك في حذف حسابك وجميع إعلاناتك نهائياً؟ لا يمكن التراجع عن هذا الإجراء.',
            'Êtes-vous sûr de vouloir supprimer définitivement votre compte et vos annonces ?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.tr('إلغاء', 'Annuler')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppConfig.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.deleteAccount),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _state.api.dio.delete('/auth/account');
        await _state.logout();
        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(s.tr('تم حذف حسابك بنجاح', 'Votre compte a été supprimé')),
            ),
          );
        }
      } catch (_) {}
    }
  }

  void _openEditProfileModal() {
    final s = _state.s;
    final user = _state.currentUser ?? {};
    final nameCtrl = TextEditingController(text: (user['name'] ?? '').toString());
    final emailCtrl = TextEditingController(text: (user['email'] ?? '').toString());
    final phoneCtrl = TextEditingController(text: (user['phone'] ?? '').toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.tr('تعديل المعلومات الشخصية', 'Modifier mon profil'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: s.tr('الاسم الكامل', 'Nom complet'),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: s.tr('البريد الإلكتروني', 'Email'),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: s.tr('رقم الهاتف', 'Téléphone'),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  onPressed: () async {
                    try {
                      final res = await _state.api.dio.post('/auth/profile', data: {
                        'name': nameCtrl.text.trim(),
                        'email': emailCtrl.text.trim(),
                        'phone': phoneCtrl.text.trim(),
                      });
                      if (res.data is Map && res.data['status'] == 'success') {
                        await _state.fetchMe();
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          setState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppConfig.success,
                              content: Text(
                                s.tr('تم تحديث حسابك بنجاح', 'Profil mis à jour'),
                              ),
                            ),
                          );
                        }
                      }
                    } catch (_) {}
                  },
                  child: Text(s.tr('حفظ التغييرات', 'Enregistrer')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openChangePasswordModal() {
    final s = _state.s;
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.tr('تغيير كلمة المرور', 'Changer le mot de passe'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: oldCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: s.tr('كلمة المرور الحالية', 'Mot de passe actuel'),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: newCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: s.tr('كلمة المرور الجديدة', 'Nouveau mot de passe'),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: confirmCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: s.tr('تأكيد كلمة المرور الجديدة', 'Confirmer le mot de passe'),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  onPressed: () async {
                    try {
                      final res = await _state.api.dio.post('/auth/password', data: {
                        'old_password': oldCtrl.text,
                        'new_password': newCtrl.text,
                        'new_password_confirmation': confirmCtrl.text,
                      });
                      if (res.data is Map && res.data['status'] == 'success') {
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppConfig.success,
                              content: Text(
                                s.tr('تم تغيير كلمة المرور بنجاح', 'Mot de passe modifié'),
                              ),
                            ),
                          );
                        }
                      }
                    } catch (_) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppConfig.danger,
                            content: Text(
                              s.tr('تأكد من كلمة المرور الحالية وتطابق الجديدة', 'Vérifiez vos mots de passe'),
                            ),
                          ),
                        );
                      }
                    }
                  },
                  child: Text(s.tr('تحديث كلمة المرور', 'Mettre à jour')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openMyStoreModal() async {
    final s = _state.s;
    Map<String, dynamic>? store;
    List<dynamic> orders = [];
    try {
      final res = await _state.api.dio.get('/my-store');
      if (res.data is Map && res.data['status'] == 'success') {
        store = res.data['store'];
        orders = res.data['orders'] ?? [];
      }
    } catch (_) {}

    if (!mounted) return;
    final nameCtrl = TextEditingController(text: store?['name']?.toString() ?? '');
    final subCtrl = TextEditingController(text: store?['subdomain']?.toString() ?? '');
    final descCtrl = TextEditingController(text: store?['description']?.toString() ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                store != null
                    ? s.tr('إدارة متجري الاحترافي', 'Gérer ma boutique Pro')
                    : s.tr('إنشاء متجر احترافي', 'Créer ma boutique Pro'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: s.tr('اسم المتجر', 'Nom de la boutique'),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: subCtrl,
                decoration: InputDecoration(
                  labelText: s.tr('الرابط الفرعي (Subdomain)', 'Sous-domaine'),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: s.tr('وصف المتجر', 'Description'),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  onPressed: () async {
                    try {
                      await _state.api.dio.post('/my-store', data: {
                        'name': nameCtrl.text.trim(),
                        'subdomain': subCtrl.text.trim(),
                        'description': descCtrl.text.trim(),
                      });
                      if (mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppConfig.success,
                            content: Text(
                              s.tr('تم حفظ إعدادات المتجر بنجاح', 'Boutique enregistrée'),
                            ),
                          ),
                        );
                      }
                    } catch (_) {}
                  },
                  child: Text(s.tr('حفظ المتجر', 'Enregistrer la boutique')),
                ),
              ),
              if (orders.isNotEmpty) ...[
                const SizedBox(height: 18),
                Text(
                  '${s.tr('طلبات الزبناء', 'Commandes clients')} (${orders.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...orders.take(5).map(
                      (o) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('${o['full_name']} • ${o['phone_number']}'),
                        subtitle: Text('${o['city']} - ${o['location']}'),
                      ),
                    ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _openSavedSearchesSheet() {
    final s = _state.s;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          maxChildSize: 0.9,
          builder: (_, controller) => Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.tr('تنبيهات البحث المحفوظة', 'Recherches sauvegardées'),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: _savedSearches.isEmpty
                      ? Center(
                          child: Text(
                            s.tr('لا توجد تنبيهات بحث محفوظة حالياً', 'Aucune alerte enregistrée'),
                            style: const TextStyle(color: _muted, fontSize: 15),
                          ),
                        )
                      : ListView.separated(
                          controller: controller,
                          itemCount: _savedSearches.length,
                          separatorBuilder: (_, __) => const Divider(color: _divider),
                          itemBuilder: (_, idx) {
                            final ss = _savedSearches[idx];
                            final title = (ss['title'] ?? ss['query'] ?? s.tr('بحث محفوظ', 'Recherche')).toString();
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Container(
                                width: 42,
                                height: 42,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEAF1FE),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.notifications_active_outlined,
                                  color: _blue,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: _ink,
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: AppConfig.danger,
                                ),
                                onPressed: () async {
                                  await _state.api.dio.delete('/saved-searches/${ss['id']}');
                                  await _loadProfileData();
                                  setModalState(() {});
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openItemsSheet(String title, List<dynamic> items, {bool isMyAds = false}) {
    final s = _state.s;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.92,
        builder: (_, controller) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: items.isEmpty
                    ? Center(
                        child: Text(
                          s.tr('القائمة فارغة حالياً', 'Aucun élément pour le moment'),
                          style: const TextStyle(color: _muted, fontSize: 15),
                        ),
                      )
                    : ListView.separated(
                        controller: controller,
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, idx) {
                          final ad = Map<String, dynamic>.from(items[idx]);
                          final int adId = int.tryParse(ad['id'].toString()) ?? 0;
                          final bool isSold = ad['status'] == 2 || ad['status'] == '2';
                          return Column(
                            children: [
                              AdCard(ad: ad, horizontal: true),
                              if (isMyAds)
                                Wrap(
                                  alignment: WrapAlignment.end,
                                  spacing: 4,
                                  children: [
                                    TextButton.icon(
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => PostAdScreen(initialAd: ad),
                                          ),
                                        ).then((updated) {
                                          if (updated == true) _loadProfileData();
                                        });
                                      },
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                        color: _blue,
                                        size: 18,
                                      ),
                                      label: Text(
                                        s.tr('تعديل', 'Modifier'),
                                        style: const TextStyle(
                                          color: _blue,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    if (!isSold)
                                      TextButton.icon(
                                        onPressed: () async {
                                          await _state.api.dio.post('/ads/$adId/sold');
                                          if (ctx.mounted) Navigator.pop(ctx);
                                          _loadProfileData();
                                        },
                                        icon: const Icon(
                                          Icons.check_circle_outline_rounded,
                                          color: AppConfig.success,
                                          size: 18,
                                        ),
                                        label: Text(
                                          s.tr('مباع', 'Vendu'),
                                          style: const TextStyle(
                                            color: AppConfig.success,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    TextButton.icon(
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          backgroundColor: Colors.transparent,
                                          builder: (_) => BoostSheet(
                                            adId: adId,
                                            adTitle: (ad['title'] ?? '').toString(),
                                          ),
                                        ).then((_) => _loadProfileData());
                                      },
                                      icon: const Icon(
                                        Icons.bolt_rounded,
                                        color: AppConfig.vipGold,
                                        size: 18,
                                      ),
                                      label: Text(
                                        s.boostAd,
                                        style: const TextStyle(
                                          color: AppConfig.vipGold,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    TextButton.icon(
                                      onPressed: () async {
                                        await _state.api.dio.delete('/ads/$adId');
                                        if (ctx.mounted) Navigator.pop(ctx);
                                        _loadProfileData();
                                      },
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        color: AppConfig.danger,
                                        size: 18,
                                      ),
                                      label: Text(
                                        s.tr('حذف', 'Supprimer'),
                                        style: const TextStyle(color: AppConfig.danger),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = _state.s;
    final user = _state.currentUser;
    final topPadding = MediaQuery.of(context).padding.top;
    final String fullName = (user?['name'] ?? s.tr('زائر أبولو', 'Visiteur Apolo')).toString();
    final String email = (user?['email'] ?? user?['phone'] ?? 'contact@apolo.ma').toString();
    final String initial = fullName.trim().isNotEmpty ? fullName.trim()[0].toUpperCase() : 'A';

    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView(
        padding: EdgeInsets.only(top: topPadding + 14, bottom: 130),
        children: [
          // Balanced Title ("Profile" header)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              s.tr('حسابي', 'Profile'),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
                color: _ink,
              ),
            ),
          ),

          // User Card (rounded-[22px] border #EDEFF3)
          Container(
            margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: _border),
              boxShadow: [
                BoxShadow(
                  color: _ink.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE31B23),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                          color: _ink,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _state.isLoggedIn
                            ? email
                            : s.tr(
                                'سجل الدخول لإدارة إعلاناتك ومتجرك',
                                'Connectez-vous pour gérer vos annonces',
                              ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: _muted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!_state.isLoggedIn)
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AuthScreen()),
                      ).then((_) {
                        _loadProfileData();
                        setState(() {});
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: _blue,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        s.login,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // 3-Column Stats Card
          Container(
            margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: _border),
              boxShadow: [
                BoxShadow(
                  color: _ink.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                _ProfileStatCol(
                  icon: CupertinoIcons.square_stack_3d_up,
                  value: '${_myAds.length}',
                  label: s.tr('إعلاناتي', 'Annonces'),
                  onTap: () => _openItemsSheet(
                    s.tr('إعلاناتي', 'Mes annonces'),
                    _myAds,
                    isMyAds: true,
                  ),
                ),
                Container(width: 1, height: 52, color: _divider),
                _ProfileStatCol(
                  icon: CupertinoIcons.heart,
                  value: '${_favorites.length}',
                  label: s.tr('المفضلة', 'Favoris'),
                  onTap: () => _openItemsSheet(
                    s.tr('المفضلة', 'Mes favoris'),
                    _favorites,
                  ),
                ),
                Container(width: 1, height: 52, color: _divider),
                _ProfileStatCol(
                  icon: CupertinoIcons.bell,
                  value: '${_savedSearches.length}',
                  label: s.tr('تنبيهات', 'Alertes'),
                  onTap: _openSavedSearchesSheet,
                ),
              ],
            ),
          ),

          // Group 1: Account
          _SectionGroup(
            title: s.tr('الحساب والمتجر', 'Account'),
            rows: [
              _SettingsRowSpec(
                icon: CupertinoIcons.slider_horizontal_3,
                label: s.tr('إعلاناتي المنشورة', 'Mes annonces publiées'),
                onTap: () => _openItemsSheet(
                  s.tr('إعلاناتي', 'Mes annonces'),
                  _myAds,
                  isMyAds: true,
                ),
              ),
              if (_state.isLoggedIn)
                _SettingsRowSpec(
                  icon: CupertinoIcons.person_crop_circle,
                  label: s.tr('تعديل المعلومات الشخصية', 'Modifier mon profil'),
                  onTap: _openEditProfileModal,
                ),
              if (_state.isLoggedIn)
                _SettingsRowSpec(
                  icon: CupertinoIcons.lock,
                  label: s.tr('تغيير كلمة المرور', 'Changer le mot de passe'),
                  onTap: _openChangePasswordModal,
                ),
              _SettingsRowSpec(
                icon: CupertinoIcons.bag,
                label: s.tr('إدارة متجري الاحترافي (Pro)', 'Ma Boutique Pro'),
                onTap: () {
                  if (_state.isLoggedIn) {
                    _openMyStoreModal();
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AuthScreen()),
                    );
                  }
                },
              ),
              _SettingsRowSpec(
                icon: CupertinoIcons.checkmark_seal,
                label: s.tr('تصفح المتاجر الموثوقة', 'Boutiques Pro Vérifiées'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StoresScreen()),
                ),
              ),
            ],
          ),

          // Group 2: Preferences
          _SectionGroup(
            title: s.tr('الإعدادات', 'Preferences'),
            rows: [
              _SettingsRowSpec(
                icon: CupertinoIcons.globe,
                label: s.tr(
                  'اللغة (العربية / Français)',
                  'Language (${s.isAr ? "العربية" : "Français"})',
                ),
                onTap: () async {
                  await _state.toggleLanguage();
                  setState(() {});
                },
              ),
              _SettingsRowSpec(
                icon: CupertinoIcons.heart,
                label: s.tr('الإعلانات المحفوظة', 'Saved listings'),
                onTap: () => _openItemsSheet(
                  s.tr('المفضلة', 'Favoris'),
                  _favorites,
                ),
              ),
              _SettingsRowSpec(
                icon: CupertinoIcons.bell,
                label: s.tr('تنبيهات البحث المحفوظة', 'Alertes de recherche'),
                onTap: _openSavedSearchesSheet,
              ),
              _SettingsRowSpec(
                icon: CupertinoIcons.cloud,
                label: AppConfig.currentBaseUrl == AppConfig.prodBaseUrl
                    ? s.tr('الخادم: الإنتاج (Production)', 'Server: Production (apolo.ma)')
                    : s.tr('الخادم: التجريبي (Staging)', 'Server: Staging (staging.apolo.ma)'),
                onTap: () async {
                  final isProd = AppConfig.currentBaseUrl == AppConfig.prodBaseUrl;
                  await _state.switchEnvironment(
                    isProd ? AppConfig.stagingBaseUrl : AppConfig.prodBaseUrl,
                  );
                  setState(() {});
                },
              ),
            ],
          ),

          // Group 3: Privacy Policy, Account Deletion & AI Safety (Google Play 2026 Compliance)
          _SectionGroup(
            title: s.tr(
              'الخصوصية، الأمان والذكاء الاصطناعي',
              'Confidentialité, Sécurité & IA',
            ),
            rows: [
              _SettingsRowSpec(
                icon: CupertinoIcons.shield_lefthalf_fill,
                label: s.tr(
                  'سياسة الخصوصية وحماية البيانات',
                  'Politique de confidentialité',
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PrivacyComplianceScreen(initialTab: 0),
                  ),
                ),
              ),
              _SettingsRowSpec(
                icon: CupertinoIcons.flag_fill,
                label: s.tr(
                  'الإبلاغ عن محتوى الذكاء الاصطناعي (AI)',
                  'Signaler un contenu IA',
                ),
                onTap: () => showAiContentReportSheet(
                  context,
                  featureContext: s.tr(
                    'مركز الأمان والإبلاغ (Apolo AI)',
                    'Centre de sécurité IA',
                  ),
                ),
              ),
              _SettingsRowSpec(
                icon: CupertinoIcons.trash,
                label: s.tr(
                  'طلب حذف الحساب والبيانات الشخصية',
                  'Supprimer mon compte et mes données',
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PrivacyComplianceScreen(initialTab: 1),
                  ),
                ),
              ),
            ],
          ),

          // Standalone Log Out & Delete Account Cards (Exact Triply-AI style)
          if (_state.isLoggedIn) ...[
            GestureDetector(
              onTap: () async {
                await _state.logout();
                setState(() {});
              },
              child: Container(
                margin: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: _border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.square_arrow_right,
                      size: 20,
                      color: Color(0xFF111827),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        s.tr('تسجيل الخروج', 'Log out'),
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            GestureDetector(
              onTap: _confirmDeleteAccount,
              child: Container(
                margin: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: _border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.trash,
                      size: 20,
                      color: Color(0xFFE31B23),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        s.deleteAccount,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFE31B23),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),
          const Center(
            child: Text(
              'Apolo.ma v1.0.0',
              style: TextStyle(fontSize: 13, color: _muted),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileStatCol extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final VoidCallback onTap;

  const _ProfileStatCol({
    required this.icon,
    required this.value,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFFFEECEE),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 19, color: const Color(0xFFE31B23)),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F1B2D),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                color: Color(0xFF8A94A6),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsRowSpec {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SettingsRowSpec({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

class _SectionGroup extends StatelessWidget {
  final String title;
  final List<_SettingsRowSpec> rows;

  const _SectionGroup({
    required this.title,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, right: 4, bottom: 8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF8A94A6),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFEDEFF3)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F1B2D).withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: List.generate(rows.length, (idx) {
                final r = rows[idx];
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: r.onTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      border: idx > 0
                          ? const Border(top: BorderSide(color: Color(0xFFF0F2F5)))
                          : null,
                    ),
                    child: Row(
                      children: [
                        Icon(r.icon, size: 20, color: const Color(0xFF5A6475)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            r.label,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F1B2D),
                            ),
                          ),
                        ),
                        const Icon(
                          CupertinoIcons.chevron_forward,
                          size: 16,
                          color: Color(0xFF9BA3B0),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
