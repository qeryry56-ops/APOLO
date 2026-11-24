import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/state/app_state.dart';
import '../../widgets/dl_settings_kit.dart';

/// Dedicated full-screen view for app diagnostics and remote taxonomy/profile sync.
class SettingsAppDataScreen extends StatefulWidget {
  const SettingsAppDataScreen({super.key});

  @override
  State<SettingsAppDataScreen> createState() => _SettingsAppDataScreenState();
}

class _SettingsAppDataScreenState extends State<SettingsAppDataScreen> {
  final AppState _state = AppState();
  bool _syncing = false;
  String? _statusMessage;
  bool _isError = false;

  Future<void> _syncNow() async {
    if (_syncing) return;
    final s = _state.s;
    setState(() {
      _syncing = true;
      _statusMessage = null;
      _isError = false;
    });
    try {
      await _state.refreshRemote();
      if (!mounted) return;
      setState(() {
        _isError = false;
        _statusMessage = s.tr(
          'تم تحديث بيانات التطبيق بنجاح.',
          'Données synchronisées avec succès.',
          'App data refreshed successfully.',
        );
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isError = true;
        _statusMessage = s.tr(
          'تعذر تحديث البيانات. تحقق من الاتصال وأعد المحاولة.',
          'Impossible de synchroniser les données. Vérifiez votre connexion.',
          'Could not refresh data. Check your connection and try again.',
        );
      });
    } finally {
      if (mounted) {
        setState(() => _syncing = false);
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
                      'بيانات التطبيق والتحديث',
                      'Données et synchronisation',
                      'App data & sync',
                    ),
                    size: ApoloDlTopNavSize.md,
                  ),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                          children: [
                            Text(
                              s.tr(
                                'معلومات النظام وحالة المزامنة المحلية مع خادم Apolo.ma.',
                                'Informations système et état de synchronisation avec Apolo.ma.',
                                'System information and local sync status with Apolo.ma.',
                              ),
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.45,
                                color: palette.muted,
                              ),
                            ),
                            if (_statusMessage != null) ...[
                              const SizedBox(height: 16),
                              ApoloDlAlert(
                                message: _statusMessage!,
                                type: _isError
                                    ? ApoloDlAlertType.danger
                                    : ApoloDlAlertType.success,
                              ),
                            ],
                            ApoloDlSectionHeader(
                              title: s.tr(
                                'حالة التطبيق',
                                'État de l’application',
                                'Application status',
                              ),
                              isFirst: true,
                            ),
                            ApoloDlLineItem(
                              title: s.tr(
                                'إصدار التطبيق',
                                'Version de l’app',
                                'App version',
                              ),
                              leadingIcon: CupertinoIcons.app_badge,
                              trailingText:
                                  'v${AppConfig.appVersion} (${AppConfig.appBuildNumber})',
                              type: ApoloDlLineItemType.plain,
                            ),
                            ApoloDlLineItem(
                              title: s.tr(
                                'الخادم',
                                'Serveur',
                                'Server',
                              ),
                              leadingIcon: CupertinoIcons.cloud,
                              trailingText: 'apolo.ma',
                              type: ApoloDlLineItemType.plain,
                            ),
                            ApoloDlLineItem(
                              title: s.tr(
                                'الأقسام المتزامنة',
                                'Catégories synchronisées',
                                'Synced categories',
                              ),
                              leadingIcon: CupertinoIcons.square_grid_2x2,
                              trailingText: '${_state.categories.length}',
                              type: ApoloDlLineItemType.plain,
                            ),
                            ApoloDlLineItem(
                              title: s.tr(
                                'المدن المتاحة',
                                'Villes disponibles',
                                'Synced cities',
                              ),
                              leadingIcon: CupertinoIcons.map,
                              trailingText: '${_state.cities.length}',
                              type: ApoloDlLineItemType.plain,
                            ),
                            ApoloDlLineItem(
                              title: s.tr(
                                'المنطقة النشطة',
                                'Zone active',
                                'Active zone',
                              ),
                              leadingIcon: CupertinoIcons.location,
                              trailingText: _state.hasActiveZone
                                  ? _state.activeZoneBadgeLabel(s)
                                  : s.allCities,
                              type: ApoloDlLineItemType.plain,
                            ),
                            ApoloDlLineItem(
                              key: const Key('settings-open-licenses'),
                              title: s.tr(
                                'التراخيص مفتوحة المصدر',
                                'Licences open source',
                                'Open-source licenses',
                              ),
                              leadingIcon: CupertinoIcons.doc_checkmark,
                              type: ApoloDlLineItemType.chevron,
                              showSeparator: false,
                              onTap: () => showLicensePage(
                                context: context,
                                applicationName: AppConfig.appName,
                                applicationVersion: 'v${AppConfig.appVersion}',
                              ),
                            ),
                            const SizedBox(height: 24),
                            ApoloDlButton(
                              key: const Key('settings-sync-now'),
                              label: s.tr(
                                'تحديث البيانات الآن',
                                'Synchroniser maintenant',
                                'Refresh data now',
                              ),
                              leadingIcon: CupertinoIcons.refresh,
                              variant: ApoloDlButtonVariant.primary,
                              fullWidth: true,
                              isLoading: _syncing,
                              onPressed: _syncing ? null : _syncNow,
                            ),
                          ],
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
}
