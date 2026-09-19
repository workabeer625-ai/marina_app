import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MarinaColors {
  static const navy = Color(0xFF0B0D10), midnight = Color(0xFF15181D), ocean = Color(0xFF242A31),
      royal = Color(0xFF2F6BFF), electric = Color(0xFF7EA2FF), deepRoyal = Color(0xFF1D4ED8),
      softBlue = Color(0xFFE9EEF7), nearWhite = Color(0xFFF7F8FA), ink = Color(0xFF111318),
      muted = Color(0xFF737985), line = Color(0xFFE0E3E8), nightSurface = Color(0xFF171A20), nightLine = Color(0xFF303640);
}

class MarinaSpacing {
  static const xxs = 4.0,
      xs = 8.0,
      sm = 12.0,
      md = 18.0,
      lg = 24.0,
      xl = 34.0,
      xxl = 48.0;
}

class MarinaRadius {
  static const sm = 10.0, md = 16.0, lg = 24.0, hero = 32.0, floating = 36.0;
}

class MarinaMotion {
  static const fast = Duration(milliseconds: 160),
      normal = Duration(milliseconds: 280),
      slow = Duration(milliseconds: 460);
  static const curve = Curves.easeOutCubic;
}

class MarinaShadows {
  static const soft = [
    BoxShadow(color: Color(0x13020E20), blurRadius: 28, offset: Offset(0, 12)),
  ];
  static const glow = [
    BoxShadow(color: Color(0x55087CFA), blurRadius: 26, offset: Offset(0, 8)),
  ];
}

final themeModeProvider = NotifierProvider<MarinaThemeMode, ThemeMode>(
  MarinaThemeMode.new,
);

class MarinaThemeMode extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;
  void set(ThemeMode value) => state = value;
}

class MarinaTheme {
  static const ivory = MarinaColors.nearWhite,
      ink = MarinaColors.ink,
      blue = MarinaColors.royal,
      sand = MarinaColors.softBlue,
      line = MarinaColors.line;

  static TextTheme _type(Color foreground, Color muted) => TextTheme(
    displayLarge: TextStyle(
      fontSize: 48,
      height: 1.02,
      fontWeight: FontWeight.w800,
      letterSpacing: -2.4,
      color: foreground,
    ),
    headlineLarge: TextStyle(
      fontSize: 35,
      height: 1.08,
      fontWeight: FontWeight.w800,
      letterSpacing: -1.1,
      color: foreground,
    ),
    headlineMedium: TextStyle(
      fontSize: 27,
      height: 1.14,
      fontWeight: FontWeight.w800,
      letterSpacing: -.7,
      color: foreground,
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      letterSpacing: -.3,
      color: foreground,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: foreground,
    ),
    bodyLarge: TextStyle(fontSize: 16, height: 1.55, color: foreground),
    bodyMedium: TextStyle(fontSize: 14.5, height: 1.5, color: foreground),
    bodySmall: TextStyle(fontSize: 12.5, height: 1.45, color: muted),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      letterSpacing: .1,
      color: foreground,
    ),
  );

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final surface = dark ? MarinaColors.nightSurface : Colors.white;
    final background = dark ? MarinaColors.navy : MarinaColors.nearWhite;
    final foreground = dark ? const Color(0xFFF5F9FF) : MarinaColors.ink;
    final muted = dark ? const Color(0xFFAABBD0) : MarinaColors.muted;
    final line = dark ? MarinaColors.nightLine : MarinaColors.line;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: MarinaColors.royal,
          brightness: brightness,
          surface: surface,
        ).copyWith(
          primary: MarinaColors.royal,
          secondary: MarinaColors.electric,
          surface: surface,
          onSurface: foreground,
          outline: line,
        );
    OutlineInputBorder inputBorder(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(MarinaRadius.md),
          borderSide: BorderSide(color: color, width: width),
        );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: background,
      colorScheme: scheme,
      textTheme: _type(foreground, muted),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: foreground,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? const Color(0xFF0B213C) : Colors.white,
        labelStyle: TextStyle(color: muted),
        hintStyle: TextStyle(color: muted.withValues(alpha: .8)),
        border: inputBorder(line),
        enabledBorder: inputBorder(line),
        focusedBorder: inputBorder(MarinaColors.electric, 1.5),
        errorBorder: inputBorder(const Color(0xFFE05263)),
        focusedErrorBorder: inputBorder(const Color(0xFFE05263), 1.5),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 17,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: const WidgetStatePropertyAll(MarinaColors.royal),
          foregroundColor: const WidgetStatePropertyAll(Colors.white),
          minimumSize: const WidgetStatePropertyAll(Size(0, 56)),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(MarinaRadius.md),
            ),
          ),
          overlayColor: const WidgetStatePropertyAll(Color(0x22FFFFFF)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 54),
          foregroundColor: foreground,
          side: BorderSide(color: line),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MarinaRadius.md),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      dividerColor: line,
    );
  }
}
