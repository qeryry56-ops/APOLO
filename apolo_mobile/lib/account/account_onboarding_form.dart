import 'package:flutter/material.dart';
import '../core/state/app_state.dart';
import 'account_helpers.dart';

/// Mandatory server onboarding; choices are never backed by fabricated IDs.
class AccountOnboardingForm extends StatefulWidget {
  final AccountAuth auth;
  final AccountSession session;
  final Future<void> Function(AccountSession) onComplete;
  const AccountOnboardingForm(
      {super.key,
      required this.auth,
      required this.session,
      required this.onComplete});
  @override
  State<AccountOnboardingForm> createState() => _AccountOnboardingFormState();
}

class _AccountOnboardingFormState extends State<AccountOnboardingForm> {
  List<Map<String, dynamic>> _cities = [];
  List<Map<String, dynamic>> _categories = [];
  String _type = 'individual';
  int? _city;
  final Set<int> _selected = {};
  bool _busy = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  int? _id(Map<String, dynamic> item) => int.tryParse('${item['id']}');
  List<Map<String, dynamic>> _items(dynamic source) => source is List
      ? source
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .where((item) => (_id(item) ?? 0) > 0)
          .toList()
      : [];
  String _label(Map<String, dynamic> item) =>
      (item[AppState().s.isAr ? 'name_ar' : 'name_fr'] ?? item['name'] ?? '')
          .toString();

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final data = await widget.auth.taxonomy();
      if (!mounted) return;
      final cities = _items(data['cities']);
      final categories = _items(data['categories']);
      if (cities.isEmpty || categories.isEmpty) {
        throw const AccountFailure('taxonomy');
      }
      setState(() {
        _cities = cities;
        _categories = categories;
      });
    } catch (error) {
      if (mounted) {
        setState(() => _error = accountError(error, AppState().s.isAr));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (_busy || _city == null || _selected.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final session =
          await widget.auth.onboard(widget.session, _type, _city!, _selected);
      if (!mounted) return;
      await widget.onComplete(session);
    } catch (error) {
      if (mounted) {
        setState(() => _error = accountError(error, AppState().s.isAr));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppState().s;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(s.tr('أكمل إعداد حسابك', 'Complétez votre compte'),
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),
      Text(s.tr(
          'اختر نوع الحساب والمدينة والمجالات التي تهمك. لن تكتمل الجلسة حتى يؤكد الموقع حفظ هذه المعلومات.',
          'Choisissez le type de compte, votre ville et vos centres d’intérêt. La session ne sera ouverte qu’après confirmation du site.')),
      const SizedBox(height: 24),
      if (_cities.isNotEmpty && _categories.isNotEmpty) ...[
        DropdownButtonFormField<String>(
            initialValue: _type,
            decoration: InputDecoration(
                labelText: s.tr('نوع الحساب', 'Type de compte')),
            items: [
              DropdownMenuItem(
                  value: 'individual', child: Text(s.tr('فرد', 'Particulier'))),
              DropdownMenuItem(
                  value: 'pro', child: Text(s.tr('مهني', 'Professionnel')))
            ],
            onChanged:
                _busy ? null : (value) => setState(() => _type = value!)),
        const SizedBox(height: 20),
        DropdownButtonFormField<int>(
            initialValue: _city,
            isExpanded: true,
            decoration: InputDecoration(labelText: s.tr('المدينة', 'Ville')),
            items: _cities
                .map((item) => DropdownMenuItem(
                    value: _id(item),
                    child: Text(_label(item), overflow: TextOverflow.ellipsis)))
                .toList(),
            onChanged: _busy ? null : (value) => setState(() => _city = value)),
        const SizedBox(height: 24),
        Text(s.tr('اختر مجالاً واحداً على الأقل',
            'Choisissez au moins un centre d’intérêt')),
        const SizedBox(height: 12),
        Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.map((item) {
              final id = _id(item)!;
              return FilterChip(
                  label: Text(_label(item)),
                  selected: _selected.contains(id),
                  onSelected: _busy
                      ? null
                      : (selected) => setState(() {
                            selected ? _selected.add(id) : _selected.remove(id);
                          }));
            }).toList()),
        const SizedBox(height: 24),
        FilledButton(
            onPressed:
                _busy || _city == null || _selected.isEmpty ? null : _save,
            child: Text(s.tr('حفظ ومتابعة', 'Enregistrer et continuer'))),
      ],
      if (_busy)
        const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator())),
      if (_error != null) ...[
        Semantics(
            liveRegion: true,
            child: Text(_error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error))),
        if (_cities.isEmpty || _categories.isEmpty)
          TextButton(
              onPressed: _busy ? null : _load,
              child: Text(s.tr('إعادة تحميل الخيارات', 'Recharger les choix'))),
      ],
    ]);
  }
}
