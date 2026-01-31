import 'package:flutter/material.dart';
import 'app_colors.dart';
import '../extensions/custom_theme_extension.dart';

final lightTheme = ThemeData(
  brightness: Brightness.light,
  useMaterial3: true,
  scaffoldBackgroundColor: AppColors.bgLight,
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.appBarLight,
    foregroundColor: AppColors.textColorLight,
    elevation: 0,
  ),
  colorScheme: const ColorScheme.light(
    primary: AppColors.blueLight,
    surface: AppColors.tileColorLight,
    onSurface: AppColors.textColorLight,
  ),
  extensions: <ThemeExtension<dynamic>>[CustomThemeExtension.lightMode],
);

final darkTheme = ThemeData(
  brightness: Brightness.dark,
  useMaterial3: true,
  scaffoldBackgroundColor: AppColors.bgDark,
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.appBarDark,
    foregroundColor: AppColors.textColorDark,
    elevation: 0,
  ),
  colorScheme: const ColorScheme.dark(
    primary: AppColors.blueDark,
    surface: AppColors.tileColorDark,
    onSurface: AppColors.textColorDark,
  ),
  extensions: <ThemeExtension<dynamic>>[CustomThemeExtension.darkMode],
);
