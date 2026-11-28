import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/config/app_config.dart';
import '../core/state/app_state.dart';
import '../screens/widgets/kinetic_widgets.dart';
import 'dl_settings_kit.dart';
import '../l10n/l10n.dart';

/// Opens a strict Dynamic Layer v5.1 modal bottom sheet allowing a user
/// to rate (1–5 stars) and write a review for a seller/listing.
Future<bool?> showApoloWriteReviewSheet(
  BuildContext context, {
  required int sellerId,
  required String sellerName,
  int? adId,
  String? adTitle,
  int? initialRating,
}) {
  final state = AppState();
  final existing = state.getMyReviewForSeller(
    sellerId > 0 ? sellerId : (adId != null && adId > 0 ? 1000000 + adId : 1),
  );
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) => _ApoloWriteReviewSheetBody(
      sellerId: sellerId,
      sellerName: sellerName,
      adId: adId,
      adTitle: adTitle,
      initialRating: initialRating ??
          (int.tryParse('${existing?['rating'] ?? ''}') ?? 5),
      initialComment: (existing?['comment'] ?? '').toString(),
      initialTags: (existing?['tags'] is List)
          ? (existing!['tags'] as List).map((e) => e.toString()).toList()
          : const <String>[],
      isEditing: existing != null,
    ),
  );
}

class _ApoloWriteReviewSheetBody extends StatefulWidget {
  final int sellerId;
  final String sellerName;
  final int? adId;
  final String? adTitle;
  final int initialRating;
  final String initialComment;
  final List<String> initialTags;
  final bool isEditing;

  const _ApoloWriteReviewSheetBody({
    required this.sellerId,
    required this.sellerName,
    this.adId,
    this.adTitle,
    required this.initialRating,
    required this.initialComment,
    required this.initialTags,
    required this.isEditing,
  });

  @override
  State<_ApoloWriteReviewSheetBody> createState() =>
      _ApoloWriteReviewSheetBodyState();
}

class _ApoloWriteReviewSheetBodyState
    extends State<_ApoloWriteReviewSheetBody> {
  Color get _dlBg => ApoloDlPalette.of(context).bg;
  Color get _dlSurface => ApoloDlPalette.of(context).surfaceSubtle;
  Color get _dlPill => ApoloDlPalette.of(context).pill;
  Color get _dlInk => ApoloDlPalette.of(context).ink;
  Color get _dlOnInk => ApoloDlPalette.of(context).onInk;
  Color get _dlMuted => ApoloDlPalette.of(context).muted;
  Color get _dlSubtle => ApoloDlPalette.of(context).subtle;
  static const Color _dlStarAmber = Color(0xFFFFB800);
  Color get _dlStarIdle => (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF3F3F46) : const Color(0xFFD4D4D8));

  late int _rating;
  late final TextEditingController _commentCtrl;
  late final Set<String> _selectedTags;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating.clamp(1, 5);
    _commentCtrl = TextEditingController(text: widget.initialComment);
    _selectedTags = Set<String>.from(widget.initialTags);
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  String _ratingSentiment(AppStrings s, int stars) {
    switch (stars) {
      case 5:
        return s.tr('ممتاز', 'Excellent', appL10n.writeReviewExcellent);
      case 4:
        return s.tr('جيد جداً', 'Très bien', appL10n.writeReviewVeryGood);
      case 3:
        return s.tr('جيد', 'Bien', appL10n.adDetailGood);
      case 2:
        return s.tr('مقبول', 'Moyen', appL10n.settingsRateAppFair);
      default:
        return s.tr('ضعيف', 'Insuffisant', appL10n.writeReviewPoor);
    }
  }

  List<String> _quickTagOptions(AppStrings s) {
    return [
      s.tr('معاملة محترمة', 'Bonne communication', appL10n.writeReviewGreatCommunication),
      s.tr('سلعة مطابقة للوصف', 'Conforme à l’annonce', appL10n.writeReviewAsDescribed),
      s.tr('استجابة سريعة', 'Réponse rapide', appL10n.writeReviewFastResponse),
      s.tr('ثمن مناسب', 'Prix correct', appL10n.writeReviewFairPrice),
    ];
  }

  Future<void> _submit(AppStrings s) async {
    if (_submitting) return;
    HapticFeedback.mediumImpact();
    setState(() => _submitting = true);

    String finalComment = _commentCtrl.text.trim();
    if (finalComment.isEmpty && _selectedTags.isNotEmpty) {
      finalComment = _selectedTags.join(' · ');
    }
    if (finalComment.isEmpty) {
      finalComment = _ratingSentiment(s, _rating);
    }

    await AppState().submitSellerReview(
      sellerId: widget.sellerId,
      rating: _rating,
      comment: finalComment,
      adId: widget.adId,
      adTitle: widget.adTitle,
      tags: _selectedTags.toList(),
    );

    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    Navigator.of(context).pop(true);
    messenger?.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: _dlInk,
        content: Text(
          s.tr(
            'تم نشر تقييمك بنجاح',
            'Votre avis a été publié',
            appL10n.writeReviewReviewHasBeenPosted,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppState().s;
    final isAr = s.isAr;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final tags = _quickTagOptions(s);

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _dlPill,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isEditing
                              ? s.tr(
                                  'تعديل تقييمك',
                                  'Modifier votre avis',
                                  appL10n.adDetailEditReview2,
                                )
                              : s.tr(
                                  'أضف تقييمك',
                                  'Donner votre avis',
                                  appL10n.adDetailWriteReview2,
                                ),
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: _dlInk,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.sellerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _dlMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(false),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: _dlPill,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        CupertinoIcons.xmark,
                        size: 16,
                        color: _dlInk,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Interactive 1..5 Star Selector Card
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: _dlSurface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final starVal = index + 1;
                        final active = starVal <= _rating;
                        return GestureDetector(
                          key: Key('review-star-$starVal'),
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _rating = starVal);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            child: Icon(
                              active
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              size: 38,
                              color: active ? _dlStarAmber : _dlStarIdle,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _dlBg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$_rating/5 · ${_ratingSentiment(s, _rating)}',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: _dlInk,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Quick Highlight Tags
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: tags.map((tag) {
                  final selected = _selectedTags.contains(tag);
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        if (selected) {
                          _selectedTags.remove(tag);
                        } else {
                          _selectedTags.add(tag);
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: selected ? _dlInk : _dlPill,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: selected ? _dlOnInk : _dlInk,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              // Flat Borderless #F6F6F6 Review Comment Input
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                decoration: BoxDecoration(
                  color: _dlSurface,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    inputDecorationTheme: const InputDecorationTheme(
                      filled: false,
                      fillColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  child: TextField(
                    key: const Key('review-comment-input'),
                    controller: _commentCtrl,
                    minLines: 3,
                    maxLines: 4,
                    cursorColor: _dlInk,
                    style: TextStyle(
                      fontSize: 14,
                      color: _dlInk,
                      height: 1.4,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                      hintText: s.tr(
                        'شارك تجربتك مع هذا البائع (الجودة، التعامل، الموعد...)',
                        'Partagez votre expérience avec ce vendeur...',
                        appL10n.writeReviewShareExperienceThisSeller,
                      ),
                      hintStyle: TextStyle(
                        fontSize: 13.5,
                        color: _dlSubtle,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Primary #000000 Capsule Submit Button
              PressableScale(
                key: const Key('review-submit-btn'),
                onTap: () => _submit(s),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: _dlInk,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    widget.isEditing
                        ? s.tr(
                            'حفظ التقييم',
                            'Mettre à jour l’avis',
                            appL10n.writeReviewUpdateReview,
                          )
                        : s.tr(
                            'نشر التقييم',
                            'Publier l’avis',
                            appL10n.writeReviewSubmitReview,
                          ),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _dlOnInk,
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
