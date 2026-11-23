import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ios26_imessage_kit.dart';
import 'perceived_performance.dart';

/// A curated die-cut sticker item for the iOS 26 iMessage Sticker Pack grid.
class IMessageStickerItem {
  final String id;
  final String emoji;
  final String labelAr;
  final String labelFr;
  final String labelEn;
  final Color tint;
  final double tiltDeg;

  const IMessageStickerItem({
    required this.id,
    required this.emoji,
    required this.labelAr,
    required this.labelFr,
    required this.labelEn,
    required this.tint,
    this.tiltDeg = 0,
  });

  String labelFor(String lang) {
    if (lang == 'ar') return labelAr;
    if (lang == 'en') return labelEn;
    return labelFr;
  }

  static const List<IMessageStickerItem> defaultPack = [
    IMessageStickerItem(
      id: 'salam',
      emoji: '👋',
      labelAr: 'السلام عليكم',
      labelFr: 'Salam !',
      labelEn: 'Hello!',
      tint: Color(0xFFE0F2FE),
      tiltDeg: -3,
    ),
    IMessageStickerItem(
      id: 'deal',
      emoji: '🤝',
      labelAr: 'متافقين',
      labelFr: 'Marché conclu',
      labelEn: 'Deal!',
      tint: Color(0xFFDCFCE7),
      tiltDeg: 2.5,
    ),
    IMessageStickerItem(
      id: 'price',
      emoji: '💰',
      labelAr: 'آخر ثمن؟',
      labelFr: 'Dernier prix ?',
      labelEn: 'Best price?',
      tint: Color(0xFFFEF3C7),
      tiltDeg: -2,
    ),
    IMessageStickerItem(
      id: 'available',
      emoji: '👀',
      labelAr: 'باقي متوفر؟',
      labelFr: 'Disponible ?',
      labelEn: 'Available?',
      tint: Color(0xFFF3E8FF),
      tiltDeg: 3,
    ),
    IMessageStickerItem(
      id: 'fire',
      emoji: '🔥',
      labelAr: 'واعر بزاف',
      labelFr: 'Top !',
      labelEn: 'Fire!',
      tint: Color(0xFFFFEDD5),
      tiltDeg: -2.5,
    ),
    IMessageStickerItem(
      id: 'thanks',
      emoji: '❤️',
      labelAr: 'شكراً بزاف',
      labelFr: 'Merci !',
      labelEn: 'Thanks!',
      tint: Color(0xFFFCE7F3),
      tiltDeg: 2,
    ),
    IMessageStickerItem(
      id: 'omw',
      emoji: '🚗',
      labelAr: 'أنا فطريق',
      labelFr: 'En route',
      labelEn: 'On my way',
      tint: Color(0xFFE0E7FF),
      tiltDeg: -2,
    ),
    IMessageStickerItem(
      id: 'location',
      emoji: '📍',
      labelAr: 'فين نتلاقاو؟',
      labelFr: 'Où se voir ?',
      labelEn: 'Meetup spot?',
      tint: Color(0xFFCCFBF1),
      tiltDeg: 2.5,
    ),
    IMessageStickerItem(
      id: 'ok',
      emoji: '👍',
      labelAr: 'تمام',
      labelFr: 'Parfait',
      labelEn: 'Sounds good',
      tint: Color(0xFFE0F2FE),
      tiltDeg: -3,
    ),
    IMessageStickerItem(
      id: 'soon',
      emoji: '⏱️',
      labelAr: '5 دقائق',
      labelFr: '5 minutes',
      labelEn: '5 mins',
      tint: Color(0xFFF1F5F9),
      tiltDeg: 2,
    ),
    IMessageStickerItem(
      id: 'celebrate',
      emoji: '🎉',
      labelAr: 'مبروك!',
      labelFr: 'Félicitations',
      labelEn: 'Congrats!',
      tint: Color(0xFFFEF9C3),
      tiltDeg: -2.5,
    ),
    IMessageStickerItem(
      id: 'inshallah',
      emoji: '✨',
      labelAr: 'إن شاء الله',
      labelFr: 'Inshallah',
      labelEn: 'Inshallah',
      tint: Color(0xFFEDE9FE),
      tiltDeg: 2.5,
    ),
  ];

  static IMessageStickerItem? findById(String id) {
    for (final item in defaultPack) {
      if (item.id == id) return item;
    }
    return null;
  }
}

/// Die-cut floating sticker tile used both inside the Sticker Pack grid and
/// rendered borderlessly inside the chat transcript (`type: 'sticker'`).
class IMessageDieCutSticker extends StatelessWidget {
  final String emoji;
  final String label;
  final Color tint;
  final double tiltDeg;
  final double size;

  const IMessageDieCutSticker({
    super.key,
    required this.emoji,
    required this.label,
    required this.tint,
    this.tiltDeg = 0,
    this.size = 96,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: tiltDeg * 3.14159265 / 180.0,
      child: Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: tint,
          borderRadius: BorderRadius.circular(size * 0.28),
          border: Border.all(color: Colors.white, width: 3.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              emoji,
              style: TextStyle(fontSize: size * 0.38, height: 1.05),
            ),
            if (label.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: (size * 0.125).clamp(10.0, 13.0),
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0A0A0A),
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Active tab inside the iOS 26 Half-Height Liquid Glass `+` Sheet.
enum Ios26DrawerTab {
  apps,
  stickers,
}

/// Exact Apple iOS 26 **Half-Height Liquid Glass Apps & Stickers Sheet**
/// (`Chat - Sticker Pack (Half-Height)`, Figma node `0:99` & `2057:3840`):
/// - Height: `346px`, `rounded-[34px]`, horizontal inset `6px`
/// - Top `36×5px` `#CCCCCC` Grabber handle (drag down to dismiss)
/// - Liquid Glass frosted background `rgba(245, 245, 245, 0.80)` + `BackdropFilter(32)`
/// - Smoothly switches between **iMessage Apps** (Photos, Camera, Stickers, Audio,
///   Location, Price Offer) and the **3-column Sticker Pack Grid (`100×100` tiles)**.
class Ios26IMessageDrawer extends StatefulWidget {
  final Ios26DrawerTab initialTab;
  final String lang;
  final bool hasListingContext;
  final String listingPrice;
  final VoidCallback onClose;
  final VoidCallback onPickPhoto;
  final VoidCallback onTakePhoto;
  final VoidCallback onStartVoice;
  final VoidCallback onSendLocation;
  final ValueChanged<String>? onSendOffer;
  final ValueChanged<IMessageStickerItem> onSendSticker;

  const Ios26IMessageDrawer({
    super.key,
    this.initialTab = Ios26DrawerTab.apps,
    required this.lang,
    this.hasListingContext = false,
    this.listingPrice = '',
    required this.onClose,
    required this.onPickPhoto,
    required this.onTakePhoto,
    required this.onStartVoice,
    required this.onSendLocation,
    this.onSendOffer,
    required this.onSendSticker,
  });

  @override
  State<Ios26IMessageDrawer> createState() => _Ios26IMessageDrawerState();
}

class _Ios26IMessageDrawerState extends State<Ios26IMessageDrawer> {
  late Ios26DrawerTab _tab;
  bool _showOfferComposer = false;
  final TextEditingController _offerCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;
  }

  @override
  void dispose() {
    _offerCtrl.dispose();
    super.dispose();
  }

  String _tr(String ar, String fr, String en) {
    if (widget.lang == 'ar') return ar;
    if (widget.lang == 'en') return en;
    return fr;
  }

  void _submitOffer() {
    final amount = _offerCtrl.text.trim();
    if (amount.isEmpty) return;
    HapticFeedback.mediumImpact();
    widget.onSendOffer?.call(amount);
    _offerCtrl.clear();
    setState(() => _showOfferComposer = false);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return GestureDetector(
      onVerticalDragEnd: (details) {
        if ((details.primaryVelocity ?? 0) > 260) {
          HapticFeedback.lightImpact();
          widget.onClose();
        }
      },
      child: Container(
        key: const Key('ios26-imessage-drawer'),
        height: 336 + bottomInset,
        margin: EdgeInsets.fromLTRB(6, 0, 6, bottomInset > 0 ? 4 : 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(34),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(34),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xD6F5F5F7), // Figma rgba(245,245,245,0.6..0.84)
                borderRadius: BorderRadius.circular(34),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.80),
                  width: 1.0,
                ),
              ),
              child: Column(
                children: [
                  // Exact Figma Grabber bar (`2056:1213`: 36x5 #CCCCCC)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: widget.onClose,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 10),
                      child: Center(
                        child: Container(
                          width: 36,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Ios26IMessageTokens.placeholderGray,
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Sleek iOS 26 Segmented Glass Switcher (Apps | Stickers)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _buildTabPill(
                          selected: _tab == Ios26DrawerTab.apps,
                          icon: CupertinoIcons.square_grid_2x2_fill,
                          label: _tr('التطبيقات', 'Apps', 'Apps'),
                          key: const Key('ios26-drawer-tab-apps'),
                          onTap: () => setState(() {
                            _tab = Ios26DrawerTab.apps;
                            _showOfferComposer = false;
                          }),
                        ),
                        const SizedBox(width: 8),
                        _buildTabPill(
                          selected: _tab == Ios26DrawerTab.stickers,
                          icon: CupertinoIcons.smiley_fill,
                          label: _tr('الملصقات', 'Stickers', 'Stickers'),
                          key: const Key('ios26-drawer-tab-stickers'),
                          onTap: () => setState(() {
                            _tab = Ios26DrawerTab.stickers;
                            _showOfferComposer = false;
                          }),
                        ),
                        const Spacer(),
                        LiquidGlassSurface(
                          width: 32,
                          height: 32,
                          borderRadius: BorderRadius.circular(999),
                          elevated: false,
                          fillAlpha: 0.72,
                          onTap: widget.onClose,
                          child: const Center(
                            child: Icon(
                              CupertinoIcons.xmark,
                              size: 14,
                              color: Ios26IMessageTokens.controlIconPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Drawer Body
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: ApoloMotion.microDuration,
                      switchInCurve: ApoloMotion.easeOutCurve,
                      child: _tab == Ios26DrawerTab.stickers
                          ? _buildStickerGrid(bottomInset)
                          : _showOfferComposer
                              ? _buildOfferComposer()
                              : _buildAppsList(bottomInset),
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

  Widget _buildTabPill({
    required bool selected,
    required IconData icon,
    required String label,
    required Key key,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      key: key,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: ApoloMotion.easeOutCurve,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? Ios26IMessageTokens.bubbleMine
              : Colors.white.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(999),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color:
                        Ios26IMessageTokens.bubbleMine.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: selected
                  ? Colors.white
                  : Ios26IMessageTokens.controlIconPrimary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected
                    ? Colors.white
                    : Ios26IMessageTokens.controlIconPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Exact Apple iOS 26 iMessage Apps grid inside the `+` drawer
  Widget _buildAppsList(double bottomInset) {
    final apps = <_IMessageAppAction>[
      _IMessageAppAction(
        key: const Key('ios26-app-photos'),
        icon: CupertinoIcons.photo_fill_on_rectangle_fill,
        label: _tr('الصور', 'Photos', 'Photos'),
        gradient: const [Color(0xFF34D399), Color(0xFF059669)],
        onTap: widget.onPickPhoto,
      ),
      _IMessageAppAction(
        key: const Key('ios26-app-camera'),
        icon: CupertinoIcons.camera_fill,
        label: _tr('الكاميرا', 'Caméra', 'Camera'),
        gradient: const [Color(0xFF4B5563), Color(0xFF1F2937)],
        onTap: widget.onTakePhoto,
      ),
      _IMessageAppAction(
        key: const Key('ios26-app-stickers'),
        icon: CupertinoIcons.smiley_fill,
        label: _tr('الملصقات', 'Stickers', 'Stickers'),
        gradient: const [Color(0xFFFBBF24), Color(0xFFF59E0B)],
        onTap: () => setState(() => _tab = Ios26DrawerTab.stickers),
      ),
      _IMessageAppAction(
        key: const Key('ios26-app-audio'),
        icon: CupertinoIcons.waveform,
        label: _tr('صوت', 'Audio', 'Audio'),
        gradient: const [Color(0xFFFB7185), Color(0xFFE11D48)],
        onTap: widget.onStartVoice,
      ),
      _IMessageAppAction(
        key: const Key('ios26-app-location'),
        icon: CupertinoIcons.location_solid,
        label: _tr('الموقع', 'Position', 'Location'),
        gradient: const [Color(0xFF38BDF8), Color(0xFF0284C7)],
        onTap: widget.onSendLocation,
      ),
      if (widget.onSendOffer != null)
        _IMessageAppAction(
          key: const Key('ios26-app-offer'),
          icon: CupertinoIcons.tag_fill,
          label: _tr('عرض ثمن', 'Offre', 'Make Offer'),
          gradient: const [
            Ios26IMessageTokens.bubbleMineTop,
            Ios26IMessageTokens.bubbleMine,
          ],
          onTap: () => setState(() => _showOfferComposer = true),
        ),
    ];

    return GridView.builder(
      key: const ValueKey('apps-grid'),
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(18, 4, 18, bottomInset + 14),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 132,
        mainAxisExtent: 104,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: apps.length,
      itemBuilder: (_, idx) {
        final app = apps[idx];
        return LiquidGlassSurface(
          key: app.key,
          borderRadius: BorderRadius.circular(24),
          fillAlpha: 0.80,
          elevated: false,
          onTap: app.onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: app.gradient,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: app.gradient.last.withValues(alpha: 0.28),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Icon(app.icon, color: Colors.white, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                app.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Ios26IMessageTokens.labelPrimary,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Exact Figma `Stickers/Regular` (`2057:3744`): 3-column grid of 100×100 tiles
  Widget _buildStickerGrid(double bottomInset) {
    const pack = IMessageStickerItem.defaultPack;
    return GridView.builder(
      key: const ValueKey('stickers-grid'),
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16, 4, 16, bottomInset + 16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 132,
        mainAxisExtent: 104,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: pack.length,
      itemBuilder: (_, idx) {
        final item = pack[idx];
        return GestureDetector(
          key: Key('ios26-sticker-${item.id}'),
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onSendSticker(item);
          },
          child: Center(
            child: IMessageDieCutSticker(
              emoji: item.emoji,
              label: item.labelFor(widget.lang),
              tint: item.tint,
              tiltDeg: item.tiltDeg,
              size: 96,
            ),
          ),
        );
      },
    );
  }

  /// Inline Liquid Glass Price Offer panel for Apolo listings
  Widget _buildOfferComposer() {
    return Padding(
      key: const ValueKey('offer-composer'),
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _showOfferComposer = false),
                child: const Icon(
                  CupertinoIcons.chevron_back,
                  size: 18,
                  color: Ios26IMessageTokens.bubbleMine,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _tr('اقترح ثمن على البائع', 'Proposer un prix',
                    'Make a price offer'),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Ios26IMessageTokens.labelPrimary,
                ),
              ),
              if (widget.listingPrice.isNotEmpty) ...[
                const Spacer(),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    widget.listingPrice,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Ios26IMessageTokens.dateGray,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          LiquidGlassSurface(
            borderRadius: BorderRadius.circular(18),
            fillAlpha: 0.90,
            elevated: false,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: TextField(
              key: const Key('ios26-offer-input'),
              controller: _offerCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Ios26IMessageTokens.labelPrimary,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: _tr('مثلاً: 100 DH', 'Ex: 100 DH', 'e.g. 100 DH'),
                hintStyle: const TextStyle(
                  color: Ios26IMessageTokens.placeholderGray,
                  fontWeight: FontWeight.w500,
                ),
                suffixText: 'DH',
                suffixStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Ios26IMessageTokens.bubbleMine,
                ),
              ),
              onSubmitted: (_) => _submitOffer(),
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            key: const Key('ios26-offer-submit'),
            onTap: _submitOffer,
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                gradient: Ios26IMessageTokens.bubbleMineGradient,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color:
                        Ios26IMessageTokens.bubbleMine.withValues(alpha: 0.30),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                _tr('إرسال العرض', 'Envoyer l’offre', 'Send Offer'),
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IMessageAppAction {
  final Key key;
  final IconData icon;
  final String label;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _IMessageAppAction({
    required this.key,
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });
}
