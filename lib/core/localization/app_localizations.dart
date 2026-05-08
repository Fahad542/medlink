import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'package:medlink/core/localization/app_translations.dart';

/// Lightweight, in-process localization helper for the patient portal.
///
/// We deliberately avoid `flutter gen-l10n` / `.arb` codegen so the app keeps
/// a single source of truth in [AppTranslations] and keeps build configuration
/// unchanged. Strings missing in the active locale fall back to the English
/// map and ultimately to the raw key, so callers always render *something*.
class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  /// Locales the patient portal currently has copy for.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('fr'),
    Locale('en'),
  ];

  /// Default locale used when the device locale is not in [supportedLocales].
  /// French is the product default per requirements; missing French keys still
  /// fall back to English at lookup time.
  static const Locale defaultLocale = Locale('fr');

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    final loc = Localizations.of<AppLocalizations>(context, AppLocalizations);
    return loc ?? AppLocalizations(defaultLocale);
  }

  /// Resolves [deviceLocales] to one of [supportedLocales]; returns
  /// [defaultLocale] when no language match is found.
  static Locale resolve(List<Locale>? deviceLocales) {
    if (deviceLocales == null || deviceLocales.isEmpty) return defaultLocale;
    for (final locale in deviceLocales) {
      if (AppTranslations.isSupported(locale.languageCode)) {
        return Locale(locale.languageCode);
      }
    }
    return defaultLocale;
  }

  late final Map<String, String> _strings =
      AppTranslations.forLocale(locale.languageCode);

  late final Map<String, String> _fallback =
      AppTranslations.forLocale(AppTranslations.fallbackLocale);

  /// Look up [key]; falls back to English then to the key itself.
  ///
  /// Optional [params] performs `{name}`-style substitution.
  String tr(String key, {Map<String, Object?>? params}) {
    final raw = _strings[key] ?? _fallback[key] ?? key;
    if (params == null || params.isEmpty) return raw;
    var result = raw;
    params.forEach((name, value) {
      result = result.replaceAll('{$name}', value?.toString() ?? '');
    });
    return result;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppTranslations.isSupported(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

/// Convenience extension so views can call `context.tr('home.greeting.morning')`.
extension AppLocalizationsX on BuildContext {
  String tr(String key, {Map<String, Object?>? params}) =>
      AppLocalizations.of(this).tr(key, params: params);
}
