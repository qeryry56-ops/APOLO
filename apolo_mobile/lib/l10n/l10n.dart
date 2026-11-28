import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

export 'app_localizations.dart';

final AppLocalizations _fallbackEnglishL10n =
    lookupAppLocalizations(const Locale('en'));

/// Synchronous English source-of-truth accessor for non-widget helpers,
/// validators, and standalone widget tests without localization delegates.
AppLocalizations get appL10n => _fallbackEnglishL10n;

extension AppLocalizationsBuildContextX on BuildContext {
  AppLocalizations get l10n =>
      AppLocalizations.of(this) ?? _fallbackEnglishL10n;
}
