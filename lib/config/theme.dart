import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TirtaTheme {
  // PDAM Tirta Pakuan Brand Colors + Frontend Matching Colors
  static const Color primaryBlue = Color(0xFF2563EB); // blue-600
  static const Color skyBlue = Color(0xFF0EA5E9); // sky-500
  static const Color cyan = Color(0xFF06B6D4); // cyan-500
  static const Color emerald = Color(0xFF059669); // emerald-600
  static const Color teal = Color(0xFF14B8A6); // teal-500
  static const Color rose = Color(0xFFE11D48); // rose-600
  static const Color pink = Color(0xFFEC4899); // pink-500
  static const Color amber = Color(0xFFF59E0B); // amber-500
  static const Color orange = Color(0xFFF97316); // orange-500
  static const Color green = Color(0xFF10B981); // emerald-500

  // Soft colors for cards/ backgrounds
  static const Color blueSoft = Color(0xFFDBEAFE); // blue-100
  static const Color greenSoft = Color(0xFFD1FAE5); // emerald-100
  static const Color orangeSoft = Color(0xFFFFEDD5); // orange-100
  static const Color redSoft = Color(0xFFFEE2E2); // red-100

  // Slate Colors from Tailwind
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
  static const Color slate950 = Color(0xFF020617);

  // Light Palette (matches frontend index.css bg-[#eef2f7])
  static const Color lightBg = Color(0xFFEEF2F7);
  static const Color lightCard = Colors.white;
  static const Color lightTextPrimary = slate800;
  static const Color lightTextSecondary = slate500;
  static const Color lightTextTertiary = slate400;

  // Dark Palette
  static const Color darkBg = slate950;
  static const Color darkCard = slate900;
  static const Color darkTextPrimary = slate50;
  static const Color darkTextSecondary = slate400;
  static const Color darkTextTertiary = slate500;

  // ─── Shared Text Styles ──────────────────────────────────────────────

  static TextStyle interW900(double size, [Color? color]) =>
      GoogleFonts.inter(fontSize: size, fontWeight: FontWeight.w900, color: color);

  static TextStyle interW800(double size, [Color? color]) =>
      GoogleFonts.inter(fontSize: size, fontWeight: FontWeight.w800, color: color);

  static TextStyle interW700(double size, [Color? color]) =>
      GoogleFonts.inter(fontSize: size, fontWeight: FontWeight.w700, color: color);

  static TextStyle interW500(double size, [Color? color]) =>
      GoogleFonts.inter(fontSize: size, fontWeight: FontWeight.w500, color: color);

  /// Uppercase tracking-widest label (matches web sidebar style:
  /// `text-[10px] font-black text-slate-400 uppercase tracking-[0.2em]`)
  static TextStyle navLabel(bool isDark) => GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w900,
        color: isDark ? slate500 : slate400,
        letterSpacing: 2.0,
      );

  static TextStyle navLabelActive(bool isDark) => GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w900,
        color: isDark ? skyBlue : primaryBlue,
        letterSpacing: 2.0,
      );

  // ─── Decorations ─────────────────────────────────────────────────────

  /// Premium card style (matches web `.premium-card`)
  static BoxDecoration premiumCardDecoration(bool isDark) => BoxDecoration(
        color: isDark ? darkCard : lightCard,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : const Color(0xFF1E3A8A).withValues(alpha: 0.04),
            blurRadius: 40,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: isDark ? slate800 : slate100,
        ),
      );

  /// Gradient button decoration (matches web `bg-gradient-to-r from-blue-600 to-sky-500`)
  static BoxDecoration gradientButtonDecoration() => BoxDecoration(
        gradient: const LinearGradient(
          colors: [primaryBlue, skyBlue],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(18),
      );

  /// Gradient button style for ElevatedButton
  static ButtonStyle gradientButtonStyle() => ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      );

  // ─── Theme ───────────────────────────────────────────────────────────

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryBlue,
      scaffoldBackgroundColor: lightBg,
      cardColor: lightCard,
      colorScheme: ColorScheme.light(
        primary: primaryBlue,
        secondary: skyBlue,
        tertiary: cyan,
        error: rose,
        surface: slate50,
        surfaceContainer: lightCard,
      ),
      textTheme:
          GoogleFonts.interTextTheme(ThemeData.light().textTheme).copyWith(
        titleLarge: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          color: lightTextPrimary,
          letterSpacing: -0.5,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: lightTextPrimary,
        ),
        titleSmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: lightTextSecondary,
          letterSpacing: 0.15,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: lightTextPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: lightTextSecondary,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: lightTextTertiary,
          letterSpacing: 0.1,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
      cardTheme: const CardThemeData(
        color: lightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(32)),
          side: BorderSide(color: slate100, width: 1),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: lightBg,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          color: lightTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w900,
        ),
        iconTheme: const IconThemeData(color: slate700),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: primaryBlue,
        unselectedItemColor: slate500,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: primaryBlue,
        unselectedLabelColor: slate400,
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
        indicatorColor: primaryBlue,
        indicatorSize: TabBarIndicatorSize.label,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: lightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32),
          side: const BorderSide(color: slate100),
        ),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: lightTextPrimary,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: slate50,
        selectedColor: primaryBlue,
        labelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: slate700,
        ),
        secondaryLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
        side: const BorderSide(color: slate200),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: slate100,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        titleTextStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: lightTextPrimary,
        ),
        subtitleTextStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: lightTextSecondary,
        ),
        leadingAndTrailingTextStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: slate200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: slate200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: skyBlue, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        prefixIconColor: slate500,
        hintStyle: GoogleFonts.inter(
          color: slate400,
          fontSize: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: primaryBlue,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryBlue,
      scaffoldBackgroundColor: darkBg,
      cardColor: darkCard,
      colorScheme: const ColorScheme.dark(
        primary: primaryBlue,
        secondary: skyBlue,
        tertiary: cyan,
        error: rose,
        surface: slate900,
        surfaceContainer: darkCard,
      ),
      textTheme:
          GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        titleLarge: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          color: darkTextPrimary,
          letterSpacing: -0.5,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: darkTextPrimary,
        ),
        titleSmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: darkTextSecondary,
          letterSpacing: 0.15,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: darkTextPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: darkTextSecondary,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: darkTextTertiary,
          letterSpacing: 0.1,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
      cardTheme: const CardThemeData(
        color: darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(32)),
          side: BorderSide(color: slate800, width: 1),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkBg,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          color: darkTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w900,
        ),
        iconTheme: const IconThemeData(color: slate200),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: skyBlue,
        unselectedItemColor: slate500,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: skyBlue,
        unselectedLabelColor: slate500,
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
        indicatorColor: skyBlue,
        indicatorSize: TabBarIndicatorSize.label,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32),
          side: const BorderSide(color: slate800),
        ),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: darkTextPrimary,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: slate800,
        selectedColor: primaryBlue,
        labelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: slate300,
        ),
        secondaryLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
        side: const BorderSide(color: slate700),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: slate800,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        titleTextStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: darkTextPrimary,
        ),
        subtitleTextStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: darkTextSecondary,
        ),
        leadingAndTrailingTextStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: skyBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: slate800.withValues(alpha: 0.6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: slate700),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: slate700),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: skyBlue, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        prefixIconColor: slate400,
        hintStyle: GoogleFonts.inter(
          color: slate500,
          fontSize: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: primaryBlue,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
