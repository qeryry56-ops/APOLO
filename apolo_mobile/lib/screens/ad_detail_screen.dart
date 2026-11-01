import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../core/config/app_config.dart';
import '../core/state/app_state.dart';
import 'widgets/ad_card.dart';
import 'widgets/app_image.dart';
import 'widgets/boost_sheet.dart';
import 'chat_room_screen.dart';
import 'store_detail_screen.dart';
import 'auth_screen.dart';

class AdDetailScreen extends StatefulWidget {
  final int adId;
  final Map<String, dynamic>? initialAd;
  final Map<String, dynamic>? initialData;

  const AdDetailScreen({
    super.key,
    required this.adId,
    this.initialAd,
    this.initialData,
  });

  @override
  State<AdDetailScreen> createState() => _AdDetailScreenState();
}

class _AdDetailScreenState extends State<AdDetailScreen> {
  final AppState _state = AppState();
  Map<String, dynamic>? _ad;
  List<dynamic> _relatedAds = [];
  bool _loading = true;
  int _currentImgIndex = 0;

  static const Color _ink = Color(0xFF0F1B2D);
  static const Color _blue = Color(0xFF2F6BE4);
  static const Color _muted = Color(0xFF8A94A6);
  static const Color _badgeBg = Color(0xFFE7F0FE);
  static const Color _cardBlue = Color(0xFFEAF1FE);
  static const Color _border = Color(0xFFE7EAF0);

  @override
  void initState() {
    super.initState();
    _ad = widget.initialAd ?? widget.initialData;
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    try {
      final res = await _state.api.dio.get('/ads/${widget.adId}');
      if (res.data is Map && res.data['status'] == 'success') {
        if (mounted) {
          setState(() {
            _ad = res.data['ad'];
            _relatedAds = res.data['related_ads'] ?? [];
            _loading = false;
          });
        }
        return;
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _callPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openWhatsApp(String phone, String title) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final intlPhone = clean.startsWith('0') ? '212${clean.substring(1)}' : clean;
    final text = Uri.encodeComponent(
      '${_state.s.tr('السلام عليكم، بخصوص إعلانك على Apolo.ma:', 'Bonjour, concernant votre annonce sur Apolo.ma :')} $title',
    );
    final uri = Uri.parse('https://wa.me/$intlPhone?text=$text');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openInAppChat() async {
    if (!_state.isLoggedIn) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
      return;
    }
    try {
      final res = await _state.api.dio.post('/chat/start', data: {'ad_id': widget.adId});
      if (res.data is Map && res.data['status'] == 'success') {
        final conv = res.data['conversation'] ?? {};
        final int convId = int.tryParse(conv['id'].toString()) ?? 0;
        if (mounted && convId > 0) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatRoomScreen(
                conversationId: convId,
                peerName: (conv['other_user']?['name'] ??
                        _ad?['seller']?['name'] ??
                        'Apolo User')
                    .toString(),
                adTitle: (_ad?['title'] ?? '').toString(),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _state.s.tr(
                'لا يمكنك مراسلة نفسك أو المستخدم غير متاح',
                'Impossible de démarrer la conversation',
              ),
            ),
          ),
        );
      }
    }
  }

  void _showReportDialog() {
    final s = _state.s;
    final msgCtrl = TextEditingController();
    String selectedType = 'scam';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.reportAd),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: selectedType,
              items: [
                DropdownMenuItem(
                  value: 'scam',
                  child: Text(s.tr('إعلان احتيالي أو وهمي', 'Arnaque ou fraude')),
                ),
                DropdownMenuItem(
                  value: 'inappropriate',
                  child: Text(s.tr('محتوى غير لائق', 'Contenu inapproprié')),
                ),
                DropdownMenuItem(
                  value: 'sold',
                  child: Text(s.tr('المنتج مباع أو غير متوفر', 'Produit déjà vendu')),
                ),
                DropdownMenuItem(
                  value: 'wrong_category',
                  child: Text(s.tr('قسم خاطئ أو مكرر', 'Mauvaise catégorie')),
                ),
              ],
              onChanged: (v) => selectedType = v ?? 'scam',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: msgCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: s.tr('أضف تفاصيل إضافية للإدارة...', 'Détails supplémentaires...'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.tr('إلغاء', 'Annuler')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppConfig.danger),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _state.api.dio.post('/ads/${widget.adId}/report', data: {
                  'type': selectedType,
                  'message': msgCtrl.text.trim().isNotEmpty ? msgCtrl.text.trim() : selectedType,
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        s.tr(
                          'تم إرسال التبليغ بنجاح، شكراً لمساهمتك',
                          'Signalement envoyé. Merci !',
                        ),
                      ),
                    ),
                  );
                }
              } catch (_) {}
            },
            child: Text(s.tr('إرسال التبليغ', 'Signaler')),
          ),
        ],
      ),
    );
  }

  Future<void> _blockSeller(int sellerId) async {
    if (!_state.isLoggedIn) return;
    try {
      await _state.api.dio.post('/users/block', data: {'blocked_user_id': sellerId});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_state.s.tr('تم حظر هذا المستخدم بنجاح', 'Utilisateur bloqué'))),
        );
        Navigator.pop(context);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final s = _state.s;
    final ad = _ad;
    if (ad == null && _loading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: _blue)),
      );
    }
    if (ad == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(backgroundColor: Colors.white),
        body: Center(child: Text(s.tr('الإعلان غير موجود', 'Annonce introuvable'))),
      );
    }

    final List images = (ad['images'] is List && (ad['images'] as List).isNotEmpty)
        ? ad['images']
        : (ad['main_image'] != null
            ? [ad['main_image']]
            : (ad['primary_image'] != null ? [ad['primary_image']] : []));
    final bool isFav = _state.favoriteAdIds.contains(widget.adId);
    final Map<String, dynamic> metadata =
        ad['metadata'] is Map ? Map<String, dynamic>.from(ad['metadata']) : {};
    final Map<String, dynamic>? seller =
        ad['seller'] is Map ? Map<String, dynamic>.from(ad['seller']) : null;
    final Map<String, dynamic>? store =
        ad['store'] is Map ? Map<String, dynamic>.from(ad['store']) : null;
    final String? phone = (ad['phone_call'] ?? ad['phone_whatsapp'])?.toString();
    final bool isOwner = _state.currentUser != null &&
        seller != null &&
        _state.currentUser!['id'].toString() == seller['id'].toString();

    final String cityName = ad['city'] is Map
        ? (s.isAr
                ? (ad['city']['name_ar'] ?? ad['city']['name'])
                : (ad['city']['name_fr'] ?? ad['city']['name']))
            .toString()
        : (s.isAr
                ? (ad['city_ar'] ?? ad['city_name'] ?? 'المغرب')
                : (ad['city_fr'] ?? ad['city_name'] ?? 'Maroc'))
            .toString();

    final String categoryName = ad['category'] is Map
        ? (s.isAr
                ? (ad['category']['name_ar'] ?? ad['category']['name'])
                : (ad['category']['name_fr'] ?? ad['category']['name']))
            .toString()
        : (s.isAr
                ? (ad['category_ar'] ?? ad['category_name'] ?? 'إعلان')
                : (ad['category_fr'] ?? ad['category_name'] ?? 'Annonce'))
            .toString();

    final String priceFormatted =
        (ad['price_formatted'] ?? '${ad['price'] ?? ''} MAD').toString();
    final topInset = MediaQuery.of(context).padding.top;
    final coverHeight = topInset + 265;

    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView(
        padding: const EdgeInsets.only(bottom: 110),
        children: [
          // Full-bleed Cover with Curved White Arch (Exact Triply-AI trip/[id].tsx)
          SizedBox(
            height: coverHeight,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                images.isNotEmpty
                    ? PageView.builder(
                        itemCount: images.length,
                        onPageChanged: (i) => setState(() => _currentImgIndex = i),
                        itemBuilder: (_, idx) => AppImage(
                          url: images[idx].toString(),
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      )
                    : Container(
                        color: const Color(0xFF1E293B),
                        child: const Center(
                          child: Icon(Icons.image_outlined, size: 64, color: Colors.white54),
                        ),
                      ),

                // Top & Bottom Gradient Overlay
                IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.0, 0.42, 1.0],
                        colors: [
                          Colors.black.withValues(alpha: 0.28),
                          Colors.black.withValues(alpha: 0.08),
                          Colors.black.withValues(alpha: 0.72),
                        ],
                      ),
                    ),
                  ),
                ),

                // Top Floating Circular White Buttons
                Positioned(
                  top: topInset + 10,
                  left: 20,
                  right: 20,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _CircleIconButton(
                        icon: Icons.chevron_left_rounded,
                        iconSize: 26,
                        onTap: () => Navigator.pop(context),
                      ),
                      Row(
                        children: [
                          _CircleIconButton(
                            icon: isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            iconColor: isFav ? const Color(0xFFE5484D) : _ink,
                            onTap: () async {
                              await _state.toggleFavorite(widget.adId);
                              setState(() {});
                            },
                          ),
                          const SizedBox(width: 10),
                          _CircleIconButton(
                            icon: Icons.more_horiz_rounded,
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                backgroundColor: Colors.white,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                                ),
                                builder: (ctx) => SafeArea(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ListTile(
                                        leading: const Icon(Icons.share_outlined, color: _ink),
                                        title: Text(s.tr('مشاركة الإعلان', 'Partager l\'annonce')),
                                        onTap: () {
                                          Navigator.pop(ctx);
                                          final shareUrl = ad['share_url'] ?? 'https://apolo.ma';
                                          Share.share('${ad['title']} - $priceFormatted\n$shareUrl');
                                        },
                                      ),
                                      ListTile(
                                        leading: const Icon(
                                          Icons.flag_outlined,
                                          color: Color(0xFFE5484D),
                                        ),
                                        title: Text(s.reportAd),
                                        onTap: () {
                                          Navigator.pop(ctx);
                                          _showReportDialog();
                                        },
                                      ),
                                      if (seller != null && !isOwner)
                                        ListTile(
                                          leading: const Icon(
                                            Icons.block_rounded,
                                            color: Color(0xFFE5484D),
                                          ),
                                          title: Text(s.blockUser),
                                          onTap: () {
                                            Navigator.pop(ctx);
                                            _blockSeller(
                                              int.tryParse(seller['id'].toString()) ?? 0,
                                            );
                                          },
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Title & Location Overlay above Curved Arch
                Positioned(
                  left: 22,
                  right: 22,
                  bottom: 44,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, size: 16, color: Colors.white),
                          const SizedBox(width: 5),
                          Text(
                            cityName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          if (images.length > 1) ...[
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '${_currentImgIndex + 1} / ${images.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        (ad['title'] ?? '').toString(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                          color: Colors.white,
                          height: 1.15,
                        ),
                      ),
                    ],
                  ),
                ),

                // Curved White Arch at Bottom of Cover (Exact Triply-AI COVER_ARCH = 30)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: -1,
                  height: 31,
                  child: CustomPaint(
                    painter: _CoverArchPainter(),
                  ),
                ),
              ],
            ),
          ),

          // 3-Column Circular Stat Row (Exact Triply-AI StatCol)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatCol(
                  icon: Icons.account_balance_wallet_outlined,
                  value: priceFormatted,
                  label: s.tr('الثمن', 'Prix'),
                ),
                _StatCol(
                  icon: Icons.category_outlined,
                  value: categoryName,
                  label: s.tr('القسم', 'Catégorie'),
                ),
                _StatCol(
                  icon: Icons.visibility_outlined,
                  value: '${ad['views_count'] ?? 1}',
                  label: s.tr('المشاهدات', 'Vues'),
                ),
              ],
            ),
          ),

          if (isOwner)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConfig.vipGold,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                ),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => BoostSheet(
                      adId: widget.adId,
                      adTitle: (ad['title'] ?? '').toString(),
                    ),
                  ).then((boosted) {
                    if (boosted == true) _fetchDetails();
                  });
                },
                icon: const Icon(Icons.bolt_rounded),
                label: Text(s.boostAd),
              ),
            ),

          // Description Section (Triply-AI tinted card style)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.tr('تفاصيل الإعلان', 'Détails & Description'),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  s.tr('معلومات كاملة من صاحب الإعلان', 'Informations fournies par le vendeur'),
                  style: const TextStyle(fontSize: 15, color: _muted),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: _cardBlue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: _blue,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.notes_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              (ad['title'] ?? '').toString(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: _ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          (ad['description'] ?? '').toString(),
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.55,
                            color: _ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Dynamic Metadata Specifications (Bordered Breakdown Card)
          if (metadata.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.tr('المواصفات التقنية', 'Caractéristiques'),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _border),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                    child: Column(
                      children: metadata.entries
                          .where(
                            (e) =>
                                e.value != null &&
                                e.value.toString().isNotEmpty &&
                                e.key != 'additional_images',
                          )
                          .map(
                            (e) => Container(
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              decoration: const BoxDecoration(
                                border: Border(bottom: BorderSide(color: Color(0xFFF0F2F5))),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    e.key.toString(),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: _muted,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Flexible(
                                    child: Text(
                                      e.value.toString(),
                                      textAlign: TextAlign.end,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: _ink,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),

          // Seller / Store Card (Triply-AI Profile User Card style)
          if (seller != null || store != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _border),
                ),
                child: Row(
                  children: [
                    AppAvatar(
                      url: (store?['logo_url'] ?? seller?['avatar_url'])?.toString(),
                      radius: 28,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (store?['name'] ?? seller?['name'] ?? 'Apolo Seller').toString(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: _ink,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            store != null
                                ? s.tr('متجر احترافي موثق ✓', 'Boutique Pro Vérifiée ✓')
                                : s.tr('معلن موثق على Apolo.ma', 'Annonceur sur Apolo.ma'),
                            style: const TextStyle(
                              fontSize: 14,
                              color: _muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (store != null)
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => StoreDetailScreen(
                                subdomain: store['subdomain'].toString(),
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                          decoration: BoxDecoration(
                            color: _badgeBg,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            s.tr('المتجر', 'Boutique'),
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: _blue,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

          // Related Ads
          if (_relatedAds.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
              child: Text(
                s.tr('إعلانات مشابهة', 'Annonces similaires'),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  color: _ink,
                ),
              ),
            ),
            SizedBox(
              height: 240,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: _relatedAds.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (_, idx) => SizedBox(
                  width: 185,
                  child: AdCard(ad: Map<String, dynamic>.from(_relatedAds[idx])),
                ),
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: _border)),
          ),
          child: Row(
            children: [
              if (phone != null && phone.isNotEmpty) ...[
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _blue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      onPressed: () => _callPhone(phone),
                      icon: const Icon(Icons.call_rounded, size: 18),
                      label: Text(
                        s.callSeller,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 52,
                  width: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: const CircleBorder(),
                    ),
                    onPressed: () => _openWhatsApp(phone, (ad['title'] ?? '').toString()),
                    child: const Icon(Icons.chat_rounded, size: 22),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _ink,
                      side: const BorderSide(color: _border, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    onPressed: _openInAppChat,
                    icon: const Icon(Icons.forum_outlined, size: 18, color: _blue),
                    label: Text(
                      s.chatInApp,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final double iconSize;
  final VoidCallback onTap;

  const _CircleIconButton({
    required this.icon,
    this.iconColor = const Color(0xFF0F1B2D),
    this.iconSize = 20,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: iconSize, color: iconColor),
      ),
    );
  }
}

class _StatCol extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatCol({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Color(0xFFE7F0FE),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 24, color: Color(0xFF2F6BE4)),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F1B2D),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF8A94A6),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoverArchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(size.width / 2, size.height * 2, size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
