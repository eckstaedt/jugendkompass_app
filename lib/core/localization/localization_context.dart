import 'package:flutter/material.dart';

/// Global context for accessing localizations
class LocalizationContext {
  static final LocalizationContext _instance = LocalizationContext._internal();

  factory LocalizationContext() {
    return _instance;
  }

  LocalizationContext._internal();

  Locale _currentLocale = const Locale('de');

  Locale get currentLocale => _currentLocale;

  void setLocale(Locale locale) {
    _currentLocale = locale;
  }
}
