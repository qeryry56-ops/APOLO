import 'package:flutter/widgets.dart';

import '../core/state/app_state.dart';
import 'app_localizations.dart';

export 'app_localizations.dart';

final Map<String, AppLocalizations> _cachedByLang = <String, AppLocalizations>{};

AppLocalizations lookupAppL10nByCode(String languageCode) {
  final normalized = switch (languageCode) {
    'ar' || 'fr' || 'en' || 'es' || 'de' || 'ja' => languageCode,
    _ => 'en',
  };
  return _cachedByLang.putIfAbsent(
    normalized,
    () => lookupAppLocalizations(Locale(normalized)),
  );
}

/// Active locale accessor backed by generated `.arb` catalogs (`en`, `fr`,
/// `ar`, `es`, `de`, `ja`), usable in non-widget helpers and standalone tests.
AppLocalizations get appL10n =>
    lookupAppL10nByCode(AppState().locale.languageCode);

extension AppLocalizationsBuildContextX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this) ?? appL10n;
}
