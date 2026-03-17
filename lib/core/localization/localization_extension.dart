import 'package:jugendkompass_app/core/localization/app_translations.dart';

extension StringLocalization on String {
  /// Translate a string based on current language
  /// Usage: 'home'.tr
  String get tr {
    return AppTranslations.t(this);
  }

  /// Translate a string with parameters
  /// Usage: 'days_ago'.trParams({'days': '5'})
  String trParams(Map<String, String> params) {
    return AppTranslations.tWithParams(this, params);
  }
}
