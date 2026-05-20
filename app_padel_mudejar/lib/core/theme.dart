import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tema global de la app Club de Pádel Mudéjar.
/// Define colores, tipografía, botones, inputs y transiciones de página.
class AppTheme {
  // --- Paleta de colores principal ---
  static const Color primary = Color(0xFF2ECC71);       // Verde principal
  static const Color primaryDark = Color(0xFF27AE60);   // Verde oscuro
  static const Color secondary = Color(0xFF3498DB);     // Azul secundario
  static const Color accent = Color(0xFFF39C12);        // Naranja/dorado para estrellas
  static const Color danger = Color(0xFFE74C3C);        // Rojo para errores y cancelar
  static const Color background = Color(0xFFF5F7FA);    // Fondo claro
  static const Color cardBg = Color(0xFFFFFFFF);        // Fondo de cards
  static const Color textDark = Color(0xFF2C3E50);      // Texto principal
  static const Color textMedium = Color(0xFF7F8C8D);    // Texto secundario
  static const Color textLight = Color(0xFFBDC3C7);     // Texto desactivado

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: secondary,
      ),
      scaffoldBackgroundColor: background,

      // Transiciones suaves entre pantallas sin frame blanco
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),

      // Tipografía Poppins en todos los textos
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        displayLarge: GoogleFonts.poppins(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: textDark,
        ),
        displayMedium: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: textDark,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textMedium,
        ),
      ),

      // Estilo global de botones elevados
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          elevation: 0,
        ),
      ),

      // Estilo global de campos de texto
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        // CORREGIDO: era danger (rojo) — ahora gris claro como corresponde
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: danger, width: 2),
        ),
        hintStyle: GoogleFonts.poppins(color: textLight, fontSize: 14),
      ),

      // Estilo global de cards
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // Estilo global del AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: textDark),
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
      ),
    );
  }
}