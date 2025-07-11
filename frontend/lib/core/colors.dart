import 'package:flutter/material.dart';

// Custom color extension for additional colors
@immutable
class CustomColors extends ThemeExtension<CustomColors> {
  const CustomColors({
    required this.success,
    required this.warning,
    required this.info,
    required this.purple,
    required this.indigo,
    required this.pink,
    required this.gray50,
    required this.gray100,
    required this.gray200,
    required this.gray300,
    required this.gray400,
    required this.gray500,
    required this.gray600,
    required this.gray700,
    required this.gray800,
    required this.gray900,
    required this.slate50,
    required this.slate100,
    required this.slate200,
    required this.slate300,
    required this.slate400,
    required this.slate500,
    required this.slate600,
    required this.slate700,
    required this.slate800,
    required this.slate900,
  });

  final Color success;
  final Color warning;
  final Color info;
  final Color purple;
  final Color indigo;
  final Color pink;
  final Color gray50;
  final Color gray100;
  final Color gray200;
  final Color gray300;
  final Color gray400;
  final Color gray500;
  final Color gray600;
  final Color gray700;
  final Color gray800;
  final Color gray900;
  final Color slate50;
  final Color slate100;
  final Color slate200;
  final Color slate300;
  final Color slate400;
  final Color slate500;
  final Color slate600;
  final Color slate700;
  final Color slate800;
  final Color slate900;

  @override
  CustomColors copyWith({
    Color? success,
    Color? warning,
    Color? info,
    Color? purple,
    Color? indigo,
    Color? pink,
    Color? gray50,
    Color? gray100,
    Color? gray200,
    Color? gray300,
    Color? gray400,
    Color? gray500,
    Color? gray600,
    Color? gray700,
    Color? gray800,
    Color? gray900,
    Color? slate50,
    Color? slate100,
    Color? slate200,
    Color? slate300,
    Color? slate400,
    Color? slate500,
    Color? slate600,
    Color? slate700,
    Color? slate800,
    Color? slate900,
  }) {
    return CustomColors(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      purple: purple ?? this.purple,
      indigo: indigo ?? this.indigo,
      pink: pink ?? this.pink,
      gray50: gray50 ?? this.gray50,
      gray100: gray100 ?? this.gray100,
      gray200: gray200 ?? this.gray200,
      gray300: gray300 ?? this.gray300,
      gray400: gray400 ?? this.gray400,
      gray500: gray500 ?? this.gray500,
      gray600: gray600 ?? this.gray600,
      gray700: gray700 ?? this.gray700,
      gray800: gray800 ?? this.gray800,
      gray900: gray900 ?? this.gray900,
      slate50: slate50 ?? this.slate50,
      slate100: slate100 ?? this.slate100,
      slate200: slate200 ?? this.slate200,
      slate300: slate300 ?? this.slate300,
      slate400: slate400 ?? this.slate400,
      slate500: slate500 ?? this.slate500,
      slate600: slate600 ?? this.slate600,
      slate700: slate700 ?? this.slate700,
      slate800: slate800 ?? this.slate800,
      slate900: slate900 ?? this.slate900,
    );
  }

  @override
  CustomColors lerp(ThemeExtension<CustomColors>? other, double t) {
    if (other is! CustomColors) {
      return this;
    }
    return CustomColors(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
      purple: Color.lerp(purple, other.purple, t)!,
      indigo: Color.lerp(indigo, other.indigo, t)!,
      pink: Color.lerp(pink, other.pink, t)!,
      gray50: Color.lerp(gray50, other.gray50, t)!,
      gray100: Color.lerp(gray100, other.gray100, t)!,
      gray200: Color.lerp(gray200, other.gray200, t)!,
      gray300: Color.lerp(gray300, other.gray300, t)!,
      gray400: Color.lerp(gray400, other.gray400, t)!,
      gray500: Color.lerp(gray500, other.gray500, t)!,
      gray600: Color.lerp(gray600, other.gray600, t)!,
      gray700: Color.lerp(gray700, other.gray700, t)!,
      gray800: Color.lerp(gray800, other.gray800, t)!,
      gray900: Color.lerp(gray900, other.gray900, t)!,
      slate50: Color.lerp(slate50, other.slate50, t)!,
      slate100: Color.lerp(slate100, other.slate100, t)!,
      slate200: Color.lerp(slate200, other.slate200, t)!,
      slate300: Color.lerp(slate300, other.slate300, t)!,
      slate400: Color.lerp(slate400, other.slate400, t)!,
      slate500: Color.lerp(slate500, other.slate500, t)!,
      slate600: Color.lerp(slate600, other.slate600, t)!,
      slate700: Color.lerp(slate700, other.slate700, t)!,
      slate800: Color.lerp(slate800, other.slate800, t)!,
      slate900: Color.lerp(slate900, other.slate900, t)!,
    );
  }
}

// App Colors - Static color constants
class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF6366F1);
  static const Color primaryContainer = Color(0xFF4F46E5);
  static const Color onPrimary = Colors.white;
  static const Color onPrimaryContainer = Colors.white;
  
  // Secondary Colors
  static const Color secondary = Color(0xFF8B5CF6);
  static const Color secondaryContainer = Color(0xFF7C3AED);
  static const Color onSecondary = Colors.white;
  static const Color onSecondaryContainer = Colors.white;
  
  // Tertiary Colors
  static const Color tertiary = Color(0xFF06B6D4);
  static const Color onTertiary = Colors.white;
  
  // Error Colors
  static const Color error = Color(0xFFEF4444);
  static const Color errorContainer = Color(0xFFDC2626);
  static const Color onError = Colors.white;
  static const Color onErrorContainer = Colors.white;
  
  // Background Colors
  static const Color background = Color(0xFF0B0B0F);
  static const Color onBackground = Colors.white;
  static const Color surface = Color(0xFF1F1F28);
  static const Color onSurface = Colors.white;
  static const Color surfaceVariant = Color(0xFF2A2A35);
  static const Color onSurfaceVariant = Color(0xFF9CA3AF);
  
  // Outline Colors
  static const Color outline = Color(0xFF2A2A35);
  static const Color outlineVariant = Color(0xFF1F1F28);
  
  // Shadow Colors
  static final Color shadow = Colors.black.withOpacity(0.5);
  static final Color scrim = Colors.black.withOpacity(0.8);
  
  // Inverse Colors
  static const Color inverseSurface = Color(0xFFE5E7EB);
  static const Color onInverseSurface = Color(0xFF0B0B0F);
  static const Color inversePrimary = Color(0xFF4338CA);
  static const Color surfaceTint = Color(0xFF6366F1);
  
  // Success Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF06B6D4);
  
  // Additional Brand Colors
  static const Color purple = Color(0xFF8B5CF6);
  static const Color indigo = Color(0xFF6366F1);
  static const Color pink = Color(0xFFEC4899);
  
  // Gray Scale
  static const Color gray50 = Color(0xFFF9FAFB);
  static const Color gray100 = Color(0xFFF3F4F6);
  static const Color gray200 = Color(0xFFE5E7EB);
  static const Color gray300 = Color(0xFFD1D5DB);
  static const Color gray400 = Color(0xFF9CA3AF);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray600 = Color(0xFF4B5563);
  static const Color gray700 = Color(0xFF374151);
  static const Color gray800 = Color(0xFF1F2937);
  static const Color gray900 = Color(0xFF111827);
  
  // Slate Scale
  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate900 = Color(0xFF0F172A);
}

// Theme extension getter
extension ThemeExtensionGetter on ThemeData {
  CustomColors get customColors => extension<CustomColors>() ?? const CustomColors(
    success: AppColors.success,
    warning: AppColors.warning,
    info: AppColors.info,
    purple: AppColors.purple,
    indigo: AppColors.indigo,
    pink: AppColors.pink,
    gray50: AppColors.gray50,
    gray100: AppColors.gray100,
    gray200: AppColors.gray200,
    gray300: AppColors.gray300,
    gray400: AppColors.gray400,
    gray500: AppColors.gray500,
    gray600: AppColors.gray600,
    gray700: AppColors.gray700,
    gray800: AppColors.gray800,
    gray900: AppColors.gray900,
    slate50: AppColors.slate50,
    slate100: AppColors.slate100,
    slate200: AppColors.slate200,
    slate300: AppColors.slate300,
    slate400: AppColors.slate400,
    slate500: AppColors.slate500,
    slate600: AppColors.slate600,
    slate700: AppColors.slate700,
    slate800: AppColors.slate800,
    slate900: AppColors.slate900,
  );
}

// App Theme - Complete theme configuration
class AppTheme {
  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    primaryColor: AppColors.primary,
    
    // App Bar Theme
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
    
    // Card Theme
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.outline, width: 1),
      ),
      shadowColor: Colors.transparent,
    ),
    
    // Elevated Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
    ),
    
    // Icon Button Theme
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    
    // Text Theme
    textTheme: TextTheme(
      displayLarge: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w700,
        fontSize: 32,
      ),
      displayMedium: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
        fontSize: 28,
      ),
      displaySmall: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
        fontSize: 24,
      ),
      headlineLarge: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
        fontSize: 22,
      ),
      headlineMedium: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
        fontSize: 20,
      ),
      headlineSmall: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
        fontSize: 18,
      ),
      titleLarge: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
      titleMedium: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w500,
        fontSize: 14,
      ),
      titleSmall: TextStyle(
        color: AppColors.gray400,
        fontWeight: FontWeight.w500,
        fontSize: 12,
      ),
      bodyLarge: TextStyle(
        color: AppColors.gray200,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: TextStyle(
        color: AppColors.gray400,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      bodySmall: TextStyle(
        color: AppColors.gray500,
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
      labelLarge: TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: TextStyle(
        color: AppColors.gray400,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      labelSmall: TextStyle(
        color: AppColors.gray500,
        fontSize: 10,
        fontWeight: FontWeight.w400,
      ),
    ),
    
    // Color Scheme
    colorScheme: ColorScheme.dark(
      brightness: Brightness.dark,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryContainer,
      secondary: AppColors.secondary,
      onSecondary: AppColors.onSecondary,
      secondaryContainer: AppColors.secondaryContainer,
      onSecondaryContainer: AppColors.onSecondaryContainer,
      tertiary: AppColors.tertiary,
      onTertiary: AppColors.onTertiary,
      error: AppColors.error,
      onError: AppColors.onError,
      errorContainer: AppColors.errorContainer,
      onErrorContainer: AppColors.onErrorContainer,
      background: AppColors.background,
      onBackground: AppColors.onBackground,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      surfaceVariant: AppColors.surfaceVariant,
      onSurfaceVariant: AppColors.onSurfaceVariant,
      outline: AppColors.outline,
      outlineVariant: AppColors.outlineVariant,
      shadow: AppColors.shadow,
      scrim: AppColors.scrim,
      inverseSurface: AppColors.inverseSurface,
      onInverseSurface: AppColors.onInverseSurface,
      inversePrimary: AppColors.inversePrimary,
      surfaceTint: AppColors.surfaceTint,
    ),
    
    // Additional Themes
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.surface,
      contentTextStyle: TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      behavior: SnackBarBehavior.floating,
      elevation: 0,
    ),
    
    dividerTheme: DividerThemeData(
      color: AppColors.outline,
      thickness: 1,
    ),
    
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: AppColors.primary,
      linearTrackColor: AppColors.outline,
      circularTrackColor: AppColors.outline,
    ),
    
    // Material 3
    useMaterial3: true,
    
    // Custom properties
    extensions: [
      CustomColors(
        success: AppColors.success,
        warning: AppColors.warning,
        info: AppColors.info,
        purple: AppColors.purple,
        indigo: AppColors.indigo,
        pink: AppColors.pink,
        gray50: AppColors.gray50,
        gray100: AppColors.gray100,
        gray200: AppColors.gray200,
        gray300: AppColors.gray300,
        gray400: AppColors.gray400,
        gray500: AppColors.gray500,
        gray600: AppColors.gray600,
        gray700: AppColors.gray700,
        gray800: AppColors.gray800,
        gray900: AppColors.gray900,
        slate50: AppColors.slate50,
        slate100: AppColors.slate100,
        slate200: AppColors.slate200,
        slate300: AppColors.slate300,
        slate400: AppColors.slate400,
        slate500: AppColors.slate500,
        slate600: AppColors.slate600,
        slate700: AppColors.slate700,
        slate800: AppColors.slate800,
        slate900: AppColors.slate900,
      ),
    ],
  );
} 