import 'package:flutter/cupertino.dart';

/// Central theme definitions for the app.
///
/// Only brightness, primaryColor, and surface colors are defined here.
/// Text styles are intentionally omitted — CupertinoApp resolves all
/// navTitleTextStyle / tabLabelTextStyle / bodyText styles automatically
/// from the brightness value, avoiding TextStyle.lerp inherit-mismatch crashes.
class AppThemes {
  static const Color _primary = Color(0xFF007AFF); // iOS system blue

  static const CupertinoThemeData lightTheme = CupertinoThemeData(
    brightness: Brightness.light,
    primaryColor: _primary,
    primaryContrastingColor: CupertinoColors.white,
    scaffoldBackgroundColor: CupertinoColors.systemBackground,
    barBackgroundColor: CupertinoColors.systemBackground,
  );

  static const CupertinoThemeData darkTheme = CupertinoThemeData(
    brightness: Brightness.dark,
    primaryColor: _primary,
    primaryContrastingColor: CupertinoColors.white,
    scaffoldBackgroundColor: CupertinoColors.systemBackground,
    barBackgroundColor: CupertinoColors.systemBackground,
  );
}
