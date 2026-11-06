import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';

/// Shared helpers for the Messages list & Chat room (2026 UI).

DateTime? parseChatDate(dynamic raw) {
  if (raw == null) return null;
  return DateTime.tryParse(raw.toString())?.toLocal();
}

String? chatAdImage(dynamic ad) {
  if (ad is! Map) return null;
  final v = ad['main_image'] ?? ad['primary_image'] ?? ad['image_url'] ?? ad['image'] ?? ad['thumbnail'];
  if (v == null) return null;
  final str = v.toString();
  return str.trim().isEmpty ? null : str;
}

String _two(int n) => n.toString().padLeft(2, '0');

String formatChatClock(DateTime t) => '${_two(t.hour)}:${_two(t.minute)}';

bool isSameChatDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _weekday(int wd, AppStrings s) {
  const ar = ['الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];
  const fr = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
  return s.isAr ? ar[wd - 1] : fr[wd - 1];
}

/// "14:32" today, "Hier", weekday within a week, else dd/MM/yy.
String formatChatListTime(DateTime t, AppStrings s) {
  final now = DateTime.now();
  if (isSameChatDay(t, now)) return formatChatClock(t);
  final yesterday = now.subtract(const Duration(days: 1));
  if (isSameChatDay(t, yesterday)) return s.tr('أمس', 'Hier');
  if (now.difference(t).inDays < 7) return _weekday(t.weekday, s);
  return '${_two(t.day)}/${_two(t.month)}/${t.year % 100}';
}

/// Day separator label inside a conversation.
String formatChatDayLabel(DateTime t, AppStrings s) {
  final now = DateTime.now();
  if (isSameChatDay(t, now)) return s.tr('اليوم', "Aujourd'hui");
  if (isSameChatDay(t, now.subtract(const Duration(days: 1)))) return s.tr('أمس', 'Hier');
  if (now.difference(t).inDays < 7) return _weekday(t.weekday, s);
  return '${_two(t.day)}/${_two(t.month)}/${t.year}';
}

/// Soft brand-tinted gradient avatar with the peer's initial.
class ChatInitialAvatar extends StatelessWidget {
  final String name;
  final double size;

  const ChatInitialAvatar({super.key, required this.name, this.size = 46});

  static const List<List<Color>> _palettes = [
    [Color(0xFFFF6B6B), Color(0xFFE31B23)],
    [Color(0xFFFFA26B), Color(0xFFF2552C)],
    [Color(0xFF7C8CF8), Color(0xFF4F5BD5)],
    [Color(0xFF4FD1A5), Color(0xFF1FA67A)],
    [Color(0xFFB98AF5), Color(0xFF8B5CF6)],
    [Color(0xFF5BC0F8), Color(0xFF2B8FD6)],
  ];

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final initial = trimmed.isNotEmpty ? trimmed.characters.first.toUpperCase() : 'A';
    final palette = _palettes[trimmed.hashCode.abs() % _palettes.length];
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: palette,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.4,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
