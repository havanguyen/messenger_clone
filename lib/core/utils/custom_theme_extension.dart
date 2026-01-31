import 'package:flutter/material.dart';

import 'package:messenger_clone/theme/app_colors.dart';

ThemeData darkTheme = ThemeData(
  extensions: const <ThemeExtension<dynamic>>[CustomThemeExtension.darkMode],
);

ThemeData lightTheme = ThemeData(
  extensions: const <ThemeExtension<dynamic>>[CustomThemeExtension.lightMode],
);

extension ExtendedTheme on BuildContext {
  CustomThemeExtension get theme =>
      Theme.of(this).extension<CustomThemeExtension>()!;
}

class CustomThemeExtension extends ThemeExtension<CustomThemeExtension> {
  final Color bg;
  final Color appBar;
  final Color textColor;
  final Color yellow;
  final Color blue;
  final Color red;
  final Color green;
  final Color grey;
  final Color tileColor;
  final Color white;
  final Color bottomNav;
  final Color textGrey;
  final Color titleHeaderColor;

  static const lightMode = CustomThemeExtension(
    bg: AppColors.bgLight,
    appBar: AppColors.appBarLight,
    textColor: AppColors.textColorLight,
    yellow: AppColors.yellowLight,
    blue: AppColors.blueLight,
    red: AppColors.redLight,
    green: AppColors.greenLight,
    grey: AppColors.greyLight,
    tileColor: AppColors.tileColorLight,
    white: AppColors.whiteColorLight,
    bottomNav: AppColors.bottomNavBarLight,
    textGrey: AppColors.textColorLight,
    titleHeaderColor: AppColors.titleHeadColorLight,
  );

  static const darkMode = CustomThemeExtension(
    bg: AppColors.bgDark,
    appBar: AppColors.appBarDark,
    textColor: AppColors.textColorDark,
    yellow: AppColors.yellowDark,
    blue: AppColors.blueDark,
    red: AppColors.redDark,
    green: AppColors.greenDark,
    grey: AppColors.greyDark,
    tileColor: AppColors.tileColorDark,
    white: AppColors.whiteColorDark,
    bottomNav: AppColors.bottomNavBarDark,
    textGrey: AppColors.textGreyDark,
    titleHeaderColor: AppColors.titleHeadColorDark,
  );

  const CustomThemeExtension({
    required this.bg,
    required this.appBar,
    required this.textColor,
    required this.yellow,
    required this.blue,
    required this.red,
    required this.green,
    required this.grey,
    required this.tileColor,
    required this.white,
    required this.bottomNav,
    required this.textGrey,
    required this.titleHeaderColor,
  });

  @override
  ThemeExtension<CustomThemeExtension> copyWith({Color? circleImageColor}) {
    return CustomThemeExtension(
      bg: bg,
      appBar: appBar,
      textColor: textColor,
      yellow: yellow,
      blue: blue,
      red: red,
      green: green,
      grey: grey,
      tileColor: tileColor,
      white: white,
      bottomNav: bottomNav,
      textGrey: textGrey,
      titleHeaderColor: titleHeaderColor,
    );
  }

  @override
  ThemeExtension<CustomThemeExtension> lerp(
    covariant ThemeExtension<CustomThemeExtension>? other,
    double t,
  ) {
    if (other is! CustomThemeExtension) {
      return this;
    }
    return CustomThemeExtension(
      bg: bg,
      appBar: appBar,
      textColor: textColor,
      yellow: yellow,
      blue: blue,
      red: red,
      green: green,
      grey: grey,
      tileColor: tileColor,
      white: white,
      bottomNav: bottomNav,
      textGrey: textGrey,
      titleHeaderColor: titleHeaderColor,
    );
  }
}
