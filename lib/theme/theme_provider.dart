import 'package:flutter/material.dart';

import 'package:messenger_clone/core/local/secure_storage.dart';

class ThemeProvider with ChangeNotifier {
  ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

  ThemeProvider() {
    _loadThemePreference();
  }

  void _loadThemePreference() async {
    final themeModeString = await Store.getThemeMode();
    switch (themeModeString) {
      case 'dark':
        themeNotifier.value = ThemeMode.dark;
        break;
      case 'light':
        themeNotifier.value = ThemeMode.light;
        break;
      default:
        themeNotifier.value = ThemeMode.system;
    }
    notifyListeners();
  }

  void setTheme(ThemeMode themeMode) async {
    String themeModeString = "";
    switch (themeMode) {
      case ThemeMode.dark:
        themeModeString = "dark";
        break;
      case ThemeMode.light:
        themeModeString = "light";
        break;
      default:
        themeModeString = "system";
    }
    await Store.setThemeMode(themeModeString);
    themeNotifier.value = themeMode;
    notifyListeners();
  }
}
