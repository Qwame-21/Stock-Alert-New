import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central place for colors and text styles so no screen ever hardcodes
/// a hex value. Keeping this thin on purpose — one accent color, mostly
/// neutrals, nothing decorative.
class AppColors {
  AppColors._();

  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Colors.white;

  // the one accent — used only for primary actions and active states
  static const Color accent = Color(0xFF1B5349); // richer, premium deep teal

  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color hairline = Color(0xFFE3E3E3);

  // status colors, reserved only for stock/verification states
  static const Color statusGood = Color(0xFF2E7D32);
  static const Color statusWarning = Color(0xFFB8860B);
  static const Color statusBad = Color(0xFFB3261E);

  // used behind frosted glass panels
  static const Color glassTint = Color(
      0x66FFFFFF); // more translucent for higher contrast against background
}

class AppRadius {
  AppRadius._();
  static const double card = 20.0;
}

/// All text styles use Poppins for consistent, premium typography.
/// Weights follow a clear hierarchy:
///   heading     → SemiBold 24pt  (w600)
///   subheading  → Medium   16pt  (w500)
///   body        → Regular  14pt  (w400)
///   label       → Medium   12pt  (w500, slightly tracked)
class AppTextStyles {
  AppTextStyles._();

  static TextStyle get heading => GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.2,
      );

  static TextStyle get subheading => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      );

  static TextStyle get body => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.5,
      );

  static TextStyle get label => GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        letterSpacing: 0.2,
      );
}

ThemeData buildAppTheme() {
  // Apply Poppins to the entire Material text theme so all widgets
  // that inherit from the theme automatically use the right font.
  final base = GoogleFonts.poppinsTextTheme();

  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      surface: AppColors.surface,
    ),
    iconTheme: const IconThemeData(color: AppColors.textPrimary),
    listTileTheme: const ListTileThemeData(iconColor: AppColors.textPrimary),
    textTheme: base.copyWith(
      headlineSmall: AppTextStyles.heading,
      titleMedium: AppTextStyles.subheading,
      bodyMedium: AppTextStyles.body,
      labelSmall: AppTextStyles.label,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 78,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      indicatorColor: const Color(0xFFF0F0F0),
      indicatorShape: const CircleBorder(),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          size: states.contains(WidgetState.selected) ? 27 : 24,
          color: states.contains(WidgetState.selected)
              ? AppColors.accent
              : AppColors.textSecondary,
        ),
      ),
      labelTextStyle: WidgetStateProperty.all(
        GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      headerBackgroundColor: AppColors.accent,
      headerForegroundColor: Colors.white,
      dayForegroundColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
              ? Colors.white
              : AppColors.textPrimary),
      dayBackgroundColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
              ? AppColors.accent
              : Colors.transparent),
      todayForegroundColor: const WidgetStatePropertyAll(AppColors.accent),
      todayBorder: const BorderSide(color: AppColors.accent),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
  );
}

class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) =>
      child;

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const ClampingScrollPhysics();
}
