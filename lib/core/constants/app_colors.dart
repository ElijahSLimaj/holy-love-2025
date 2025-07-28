import 'package:flutter/material.dart';

class AppColors {
  // Primary Brand Colors (Based on your existing Holy Love palette)
  static const Color primary = Color(0xFF6B46C1); // Deep purple - spiritual
  static const Color primaryLight = Color(0xFF8B5CF6); // Lighter purple
  static const Color primaryDark = Color(0xFF553C9A); // Darker purple
  
  // Secondary Colors
  static const Color secondary = Color(0xFFEC4899); // Warm pink - love
  static const Color secondaryLight = Color(0xFFF472B6); // Light pink
  static const Color secondaryDark = Color(0xBE185D); // Dark pink
  
  // Accent Colors
  static const Color accent = Color(0xFFF59E0B); // Gold - divine light
  static const Color accentLight = Color(0xFFFBBF24); // Light gold
  static const Color accentDark = Color(0xFFD97706); // Dark gold
  
  // Neutral Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFFAFAFA);
  static const Color lightGray = Color(0xFFF3F4F6);
  static const Color gray = Color(0xFF9CA3AF);
  static const Color darkGray = Color(0xFF6B7280);
  static const Color charcoal = Color(0xFF374151);
  static const Color black = Color(0xFF111827);
  
  // Background Colors
  static const Color background = Color(0xFFFFFBFB); // Warm white
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFEFEFE);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnSecondary = Color(0xFFFFFFFF);
  
  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFF34D399);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFF6B6B);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);
  
  // Interactive Colors
  static const Color buttonPrimary = primary;
  static const Color buttonSecondary = Color(0xFFF3F4F6);
  static const Color buttonDisabled = Color(0xFFE5E7EB);
  
  // Border Colors
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderLight = Color(0xFFF3F4F6);
  static const Color borderDark = Color(0xFFD1D5DB);
  
  // Shadow Colors
  static const Color shadow = Color(0x1A000000);
  static const Color shadowLight = Color(0x0A000000);
  static const Color shadowDark = Color(0x26000000);
  
  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryLight, secondaryLight], // Use love gradient colors
  );
  
  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondaryLight, secondary],
  );
  
  static const LinearGradient loveGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryLight, secondaryLight],
  );
  
  // Card and Surface Shadows
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: shadow,
      offset: Offset(0, 2),
      blurRadius: 8,
      spreadRadius: 0,
    ),
  ];
  
  static const List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: shadowLight,
      offset: Offset(0, 1),
      blurRadius: 3,
      spreadRadius: 0,
    ),
  ];
} 