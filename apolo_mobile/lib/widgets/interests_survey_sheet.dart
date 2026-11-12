import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../account/account_helpers.dart';
import '../core/config/app_config.dart';
import '../core/state/app_state.dart';

/// Interactive Interests Survey Modal (نافذة منبثقة لاستطلاع الاهتمامات والتصنيفات)
///
/// Prompts newly registered users to pick their favorite categories to tailor their
/// feed and product recommendations, and saves their choices to the server.
class InterestsSurveySheet extends StatefulWidget {
  final AccountAuth auth;
  final AccountSession session;
  final String accountType;
  final int cityId;
  final VoidCallback? onFinished;

  const InterestsSurveySheet({
    super.key,
    required this.auth,
    required this.session,
    required this.accountType,
    required this.cityId,
    this.onFinished,
  });

  static Future<void> show(
    BuildContext context, {
    required AccountAuth auth,
    required AccountSession session,
    String accountType = 'individual',
    int cityId = 1,
    VoidCallback? onFinished,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      isDismissible: false,
      builder: (_) => InterestsSurveySheet(
        auth: auth,
        session: session,
        accountType: accountType,
        cityId: cityId,
        onFinished: onFinished,
      ),
    );
  }

  @override
  State<InterestsSurveySheet> createState() => _InterestsSurveySheetState();
}

class _InterestsSurveySheetState extends State<InterestsSurveySheet> {
  final _state = AppState();
  final Set<int> _selectedCategoryIds = {};
  List<Map<String, dynamic>> _categories = [];
  bool _loading = true;
  bool _saving = false;

  static const List<Map<String, dynamic>> _defaultCategories = [
    {'id': 1, 'name_ar': 'هواتف وإلكترونيات', 'name_fr': 'Électronique & Tech', 'icon': Icons.devices_outlined},
    {'id': 2, 'name_ar': 'سيارات ودراجات', 'name_fr': 'Véhicules & Autos', 'icon': Icons.directions_car_outlined},
    {'id': 3, 'name_ar': 'أزياء وملابس', 'name_fr': 'Mode & Vêtements', 'icon': Icons.checkroom_outlined},
    {'id': 4, 'name_ar': 'منزل وديكور', 'name_fr': 'Maison & Déco', 'icon': Icons.home_outlined},
    {'id': 5, 'name_ar': 'عقارات', 'name_fr': 'Immobilier', 'icon': Icons.apartment_outlined},
    {'id': 6, 'name_ar': 'رياضة وهوايات', 'name_fr': 'Sport & Loisirs', 'icon': Icons.fitness_center_outlined},
    {'id': 7, 'name_ar': 'مستلزمات الأطفال', 'name_fr': 'Bébés & Enfants', 'icon': Icons.child_care_outlined},
    {'id': 8, 'name_ar': 'خدمات وأعمال', 'name_fr': 'Services & Emploi', 'icon': Icons.work_outline},
    {'id': 9, 'name_ar': 'صحة وجمال', 'name_fr': 'Beauté & Santé', 'icon': Icons.spa_outlined},
    {'id': 10, 'name_ar': 'ألعاب وفيديو', 'name_fr': 'Jeux Vidéo', 'icon': Icons.sports_esports_outlined},
  ];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final taxonomy = await widget.auth.taxonomy();
      if (!mounted) return;
      final raw = taxonomy['categories'];
      if (raw is List && raw.isNotEmpty) {
        final parsed = raw
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .where((item) => (int.tryParse('${item['id']}') ?? 0) > 0)
            .toList();
        if (parsed.isNotEmpty) {
          setState(() {
            _categories = parsed;
            _loading = false;
          });
          return;
        }
      }
    } catch (_) {
      // Fallback seamlessly to default categories
    }

    if (mounted) {
      setState(() {
        _categories = _defaultCategories;
        _loading = false;
      });
    }
  }

  void _toggleCategory(int id) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedCategoryIds.contains(id)) {
        _selectedCategoryIds.remove(id);
      } else {
        _selectedCategoryIds.add(id);
      }
    });
  }

  Future<void> _saveInterests() async {
    if (_saving) return;
    HapticFeedback.lightImpact();
    setState(() => _saving = true);

    try {
      final selected = _selectedCategoryIds.isEmpty
          ? {1, 2, 3} // Default selection if none picked
          : _selectedCategoryIds;
      await widget.auth.onboard(
        widget.session,
        widget.accountType,
        widget.cityId,
        selected,
      );
    } catch (_) {
      // Non-blocking: user proceeds regardless
    } finally {
      if (mounted) {
        setState(() => _saving = false);
        Navigator.of(context).pop();
        widget.onFinished?.call();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _state.s;
    final isAr = s.isAr;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header Icon & Title
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5E48E8).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.auto_awesome,
                      color: Color(0xFF5E48E8),
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.tr('ما هي اهتماماتك؟', 'What are your interests?'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        s.tr(
                          'اختر التصنيفات التي تهمك لتخصيص تجربتك في Apolo',
                          'Pick categories to personalize your Apolo feed',
                        ),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Categories Grid / Chips
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF5E48E8),
                      ),
                    )
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 10,
                        children: _categories.map((cat) {
                          final id = int.tryParse('${cat['id']}') ?? 0;
                          final isSelected = _selectedCategoryIds.contains(id);
                          final label = (cat[isAr ? 'name_ar' : 'name_fr'] ??
                                  cat['name'] ??
                                  '')
                              .toString();
                          final icon = cat['icon'] as IconData? ??
                              Icons.category_outlined;

                          return GestureDetector(
                            onTap: () => _toggleCategory(id),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF5E48E8).withValues(alpha: 0.08)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF5E48E8)
                                      : const Color(0xFFE5E7EB),
                                  width: isSelected ? 1.6 : 1.2,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isSelected
                                        ? Icons.check_circle_rounded
                                        : icon,
                                    size: 18,
                                    color: isSelected
                                        ? const Color(0xFF5E48E8)
                                        : const Color(0xFF6B7280),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    label,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? const Color(0xFF5E48E8)
                                          : const Color(0xFF374151),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
            ),

            const SizedBox(height: 16),

            // Submit Button
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _saveInterests,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A0A0A),
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  elevation: 0,
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _selectedCategoryIds.isEmpty
                            ? s.tr('اكتشاف المنتجات', 'Discover products')
                            : s.tr(
                                'حفظ وتأكيد (${_selectedCategoryIds.length})',
                                'Save & continue (${_selectedCategoryIds.length})',
                              ),
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 8),

            // Skip button
            Center(
              child: TextButton(
                onPressed: _saving
                    ? null
                    : () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pop();
                        widget.onFinished?.call();
                      },
                child: Text(
                  s.tr('تخطي الآن', 'Skip for now'),
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF9CA3AF),
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
