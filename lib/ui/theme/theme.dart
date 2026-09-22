import 'package:flutter/material.dart';

/// Shared colors for Velo Cambo.
class VeloColors {
  static const Color primary = Color(0xFFF4A261);
  static const Color secondary = Color(0xFF7BA35A);

  static const Color background = Color(0xFFF7F4F1);
  static const Color backgroundAccent = Color(0xFFF5F5F5);
  static const Color white = Colors.white;

  static const Color neutralDark = Color(0xFF30251F);
  static const Color neutral = Color(0xFF6D5142);
  static const Color neutralLight = Color(0xFF826D61);
  static const Color neutralLighter = Color(0xFFAA988C);
  static const Color greyLight = Color(0xFFE0E0E0);
  static const Color border = Color(0xFFE7D6C9);

  static const Color success = Color(0xFF447027);
  static const Color successLight = Color(0xFFDDF0D1);
  static const Color warning = Color(0xFF9C6B53);
  static const Color warningLight = Color(0xFFFFE8D6);
  static const Color error = Color(0xFFC0392B);
  static const Color errorLight = Color(0xFFF9D4D0);
  static const Color info = Color(0xFF365F82);
  static const Color infoLight = Color(0xFFD6E8F7);

  static const Color backgroundColor = background;
  static const Color textNormal = neutralDark;
  static const Color textLight = neutralLight;
  static const Color iconNormal = neutral;
  static const Color iconLight = neutralLighter;
  static const Color disabled = greyLight;
}

/// Shared typography. Uses Flutter's default platform font.
class VeloTextStyles {
  static const TextStyle heading = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    color: VeloColors.textNormal,
  );
  static const TextStyle title = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: VeloColors.textNormal,
  );
  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: VeloColors.textNormal,
  );
  static const TextStyle label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: VeloColors.textLight,
  );
  // Inherits its foreground color from the button theme.
  static const TextStyle button = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );
}

/// Spacing and corner radii in logical pixels.
class VeloSpacings {
  static const double xs = 8;
  static const double s = 12;
  static const double m = 16;
  static const double l = 24;
  static const double xl = 32;
  static const double xxl = 40;

  static const double radius = 16;
  static const double radiusLarge = 24;
}

class VeloSize {
  static const double icon = 24;
  static const double buttonHeight = 48;
}

/// Default light theme for the application.
final ThemeData veloTheme = ThemeData(
  useMaterial3: true,
  colorScheme:
      ColorScheme.fromSeed(
        seedColor: VeloColors.primary,
        brightness: Brightness.light,
      ).copyWith(
        primary: VeloColors.primary,
        onPrimary: VeloColors.neutralDark,
        secondary: VeloColors.secondary,
        onSecondary: VeloColors.neutralDark,
        surface: VeloColors.white,
        onSurface: VeloColors.textNormal,
        error: VeloColors.error,
        onError: VeloColors.white,
        outline: VeloColors.neutralLight,
        outlineVariant: VeloColors.border,
      ),
  scaffoldBackgroundColor: VeloColors.background,
  disabledColor: VeloColors.disabled,
  dividerColor: VeloColors.border,
  textTheme: const TextTheme(
    headlineMedium: VeloTextStyles.heading,
    titleLarge: VeloTextStyles.title,
    bodyLarge: VeloTextStyles.body,
    bodyMedium: VeloTextStyles.label,
    labelLarge: VeloTextStyles.button,
  ),
  iconTheme: const IconThemeData(
    color: VeloColors.iconNormal,
    size: VeloSize.icon,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: VeloColors.background,
    foregroundColor: VeloColors.textNormal,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    titleTextStyle: VeloTextStyles.title,
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: VeloColors.white,
    selectedItemColor: VeloColors.primary,
    unselectedItemColor: VeloColors.neutralLight,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: VeloColors.primary,
      foregroundColor: VeloColors.neutralDark,
      disabledBackgroundColor: VeloColors.disabled,
      disabledForegroundColor: VeloColors.textLight,
      minimumSize: const Size(0, VeloSize.buttonHeight),
      padding: const EdgeInsets.symmetric(
        horizontal: VeloSpacings.l,
        vertical: VeloSpacings.s,
      ),
      textStyle: VeloTextStyles.button,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(VeloSpacings.radius),
      ),
    ),
  ),
);
