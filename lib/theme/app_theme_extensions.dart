import 'package:flutter/material.dart';

/// Extensión de ColorScheme para acceder a colores personalizados de la app
/// Uso: final colors = Theme.of(context).extension[AppThemeColors]!;
extension AppThemeColors on ColorScheme {
  // Fondos
  Color get infoCardBackground => brightness == Brightness.dark 
      ? const Color(0xFF1A1A1A) 
      : Colors.blue.shade50;
  
  Color get infoCardBorder => brightness == Brightness.dark 
      ? Colors.grey[700] ?? Colors.grey 
      : Colors.blue.shade100;

  // Texto secundario
  Color get secondaryText => brightness == Brightness.dark 
      ? Colors.grey[400]! 
      : Colors.grey;

  Color get tertiaryText => brightness == Brightness.dark 
      ? Colors.grey[500]! 
      : Colors.grey[600]!;

  // Fondos de componentes
  Color get iconContainerBackground => brightness == Brightness.dark 
      ? Colors.grey[800]! 
      : Colors.white;

  Color get skeletonBackground => brightness == Brightness.dark 
      ? Colors.grey[700]! 
      : Colors.grey[300]!;

  // Divisores
  Color get dividerColor => brightness == Brightness.dark 
      ? Colors.grey[700]! 
      : Colors.grey[300]!;

  // Superficies alternadas
  Color get alternativeSurface => brightness == Brightness.dark 
      ? Colors.grey[900]! 
      : Colors.grey[50]!;
}

/// Utilidades para acceder a colores de tema sin necesidad de Theme.of()
class AppTheme {
  static Color getInfoCardBackground(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.grey[900]! : Colors.blue.shade50;
  }

  static Color getSecondaryText(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.grey[400]! : Colors.grey;
  }

  static Color getIconContainerBackground(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.grey[800]! : Colors.white;
  }

  static Color getSkeletonBackground(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.grey[700]! : Colors.grey[300]!;
  }

  static Color getDividerColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.grey[700]! : Colors.blue.shade200;
  }

  static Color getAlternativeSurface(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.grey[900]! : Colors.grey[50]!;
  }
}
