import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// ─────────────────────────────────────────────────────────────────────────
///  MARINA design system — "Riviera"
///  Deep midnight navy, champagne gold and warm ivory.
///  Every screen draws from these tokens so day & night feel like one brand.
/// ─────────────────────────────────────────────────────────────────────────

class MarinaColors {
  // Signature navy family (headers, hero surfaces, ink accents).
  static const navy = Color(0xFF101B2D);
  static const midnight = Color(0xFF0A111E);
  static const navySoft = Color(0xFF16253C);
  static const ocean = Color(0xFF1C2A3F);

  // Refined sapphire for interactive hints (kept from the classic identity).
  static const royal = Color(0xFF2F5D9E);
  static const electric = Color(0xFF7FA3D8);
  static const deepRoyal = Color(0xFF234B85);

  // Champagne gold — the luxury signature.
  static const gold = Color(0xFFC29B4C);
  static const goldBright = Color(0xFFE2C283);
  static const goldDeep = Color(0xFF97783B);
  static const goldTint = Color(0xFFF4ECD9);
  static const onGold = Color(0xFF241B07);

  // Day palette.
  static const ivory = Color(0xFFF7F5F0);
  static const nearWhite = ivory;
  static const sand = Color(0xFFF1ECE1);
  static const softBlue = sand; // legacy alias — warm container tint
  static const ink = Color(0xFF171B22);
  static const muted = Color(0xFF6E727B);
  static const line = Color(0xFFE1DACA);

  // Night palette.
  static const nightBg = Color(0xFF0C1017);
  static const nightSurface = Color(0xFF151B28);
  static const nightSurfaceSoft = Color(0xFF1B2231);
  static const nightLine = Color(0xFF283042);
  static const nightInk = Color(0xFFF3F5F9);
  static const nightMuted = Color(0xFF98A1B0);

  // Semantic.
  static const success = Color(0xFF3E7C4F);
  static const successTint = Color(0xFFE4EFE4);
  static const danger = Color(0xFFB3402F);
  static const dangerTint = Color(0xFFF7E5E1);
  static const warning = Color(0xFFB58945);

  // Legacy aliases.
  static const royalBlueSurface = Color(0xFF12395F);
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
  static const xs = 12.0,
      sm = 14.0,
      md = 18.0,
      lg = 24.0,
      hero = 32.0,
      floating = 30.0;
}

class MarinaMotion {
  static const fast = Duration(milliseconds: 160),
      normal = Duration(milliseconds: 280),
      slow = Duration(milliseconds: 460);
  static const curve = Curves.easeOutCubic;
  static const spring = Curves.easeOutBack;
}

/// Brightness-aware palette handed to widgets: `final p = MarinaPalette.of(context);`
class MarinaPalette {
  const MarinaPalette({
    required this.brightness,
    required this.background,
    required this.backgroundAlt,
    required this.surface,
    required this.surfaceSoft,
    required this.ink,
    required this.muted,
    required this.line,
    required this.gold,
    required this.goldSoft,
    required this.onGold,
    required this.accent,
    required this.headerTop,
    required this.headerBottom,
    required this.cardShadow,
  });

  final Brightness brightness;
  final Color background, backgroundAlt, surface, surfaceSoft;
  final Color ink, muted, line, gold, goldSoft, onGold, accent;
  final Color headerTop, headerBottom;
  final List<BoxShadow> cardShadow;

  bool get isDark => brightness == Brightness.dark;

  static MarinaPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;

  static const light = MarinaPalette(
    brightness: Brightness.light,
    background: MarinaColors.ivory,
    backgroundAlt: Colors.white,
    surface: Colors.white,
    surfaceSoft: MarinaColors.sand,
    ink: MarinaColors.ink,
    muted: MarinaColors.muted,
    line: MarinaColors.line,
    gold: MarinaColors.goldDeep,
    goldSoft: MarinaColors.goldTint,
    onGold: MarinaColors.onGold,
    accent: MarinaColors.deepRoyal,
    headerTop: MarinaColors.navy,
    headerBottom: MarinaColors.midnight,
    cardShadow: [
      BoxShadow(color: Color(0x14142033), blurRadius: 26, offset: Offset(0, 12)),
    ],
  );

  static const dark = MarinaPalette(
    brightness: Brightness.dark,
    background: MarinaColors.nightBg,
    backgroundAlt: MarinaColors.nightSurface,
    surface: MarinaColors.nightSurface,
    surfaceSoft: MarinaColors.nightSurfaceSoft,
    ink: MarinaColors.nightInk,
    muted: MarinaColors.nightMuted,
    line: MarinaColors.nightLine,
    gold: MarinaColors.goldBright,
    goldSoft: Color(0xFF241E10),
    onGold: MarinaColors.onGold,
    accent: MarinaColors.goldBright,
    headerTop: MarinaColors.midnight,
    headerBottom: Color(0xFF070B12),
    cardShadow: [
      BoxShadow(color: Color(0x59000000), blurRadius: 26, offset: Offset(0, 12)),
    ],
  );
}

class MarinaGradients {
  const MarinaGradients._();

  static LinearGradient header({bool dark = false}) => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: dark
        ? const [MarinaColors.midnight, Color(0xFF070B12)]
        : const [MarinaColors.navy, MarinaColors.midnight],
  );

  static const gold = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE7CE96), MarinaColors.gold, Color(0xFFAD8840)],
  );

  static const goldSheen = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0x00E7CE96), Color(0x55E7CE96), Color(0x00E7CE96)],
  );

  static LinearGradient heroOverlay({bool rtl = false}) => LinearGradient(
    begin: rtl ? Alignment.centerRight : Alignment.centerLeft,
    end: rtl ? Alignment.centerLeft : Alignment.centerRight,
    colors: const [
      Color(0xF20A111E),
      Color(0xD90A111E),
      Color(0x330A111E),
    ],
  );

  static const bottomFade = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x000A111E), Color(0xCC0A111E)],
  );
}

class MarinaShadows {
  const MarinaShadows._();

  static const soft = [
    BoxShadow(color: Color(0x14142033), blurRadius: 28, offset: Offset(0, 12)),
  ];

  static const glow = [
    BoxShadow(color: Color(0x66C29B4C), blurRadius: 30, offset: Offset(0, 10)),
  ];

  static List<BoxShadow> forBrightness(Brightness brightness) =>
      brightness == Brightness.dark
          ? const [
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 30,
                offset: Offset(0, 14),
              ),
            ]
          : soft;
}

/// ── Theme mode controller (persisted, mirrors the locale controller). ──

final themeModeProvider = NotifierProvider<MarinaThemeMode, ThemeMode>(
  MarinaThemeMode.new,
);

class MarinaThemeMode extends Notifier<ThemeMode> {
  static const _storage = FlutterSecureStorage();
  bool _loading = false;

  @override
  ThemeMode build() {
    if (!_loading) {
      _loading = true;
      _restore();
    }
    return ThemeMode.system;
  }

  Future<void> _restore() async {
    final saved = await _storage.read(key: 'marina_theme_mode');
    final mode = switch (saved) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    if (mode != state) state = mode;
  }

  void set(ThemeMode value) {
    state = value;
    unawaitedSave(value);
  }

  Future<void> unawaitedSave(ThemeMode value) => _storage.write(
    key: 'marina_theme_mode',
    value: switch (value) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      _ => 'system',
    },
  );
}

/// ── Typography ──

class MarinaType {
  const MarinaType._();

  static bool isArabic(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'ar';

  /// Luxury serif display — Marcellus for Latin, Tajawal for Arabic.
  static TextStyle display(
    BuildContext context, {
    double? size,
    Color? color,
    double height = 1.12,
    FontWeight weight = FontWeight.w700,
  }) => TextStyle(
    fontFamily: isArabic(context) ? 'Tajawal' : 'Marcellus',
    fontFamilyFallback: const ['Tajawal'],
    fontSize: size,
    height: height,
    fontWeight: isArabic(context) ? FontWeight.w800 : weight,
    color: color,
    letterSpacing: 0,
  );

  /// Small gold eyebrow label above titles (Latin only gets letter-spacing).
  static TextStyle kicker(
    BuildContext context, {
    Color? color,
    double size = 11.5,
  }) => TextStyle(
    fontSize: size,
    fontWeight: FontWeight.w700,
    letterSpacing: isArabic(context) ? 0 : 3.2,
    color: color ?? MarinaPalette.of(context).gold,
    height: 1.2,
  );
}

/// ── ThemeData builders ──

class MarinaTheme {
  static const ivory = MarinaColors.ivory,
      ink = MarinaColors.ink,
      blue = MarinaColors.deepRoyal,
      sand = MarinaColors.sand,
      line = MarinaColors.line;

  static TextTheme _type(Color foreground, Color muted, bool arabic) {
    double tracking(double latin) => arabic ? 0 : latin;
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 46,
        height: 1.04,
        fontWeight: FontWeight.w800,
        letterSpacing: tracking(-2),
        color: foreground,
      ),
      displayMedium: TextStyle(
        fontSize: 38,
        height: 1.06,
        fontWeight: FontWeight.w800,
        letterSpacing: tracking(-1.4),
        color: foreground,
      ),
      headlineLarge: TextStyle(
        fontSize: 32,
        height: 1.1,
        fontWeight: FontWeight.w800,
        letterSpacing: tracking(-.9),
        color: foreground,
      ),
      headlineMedium: TextStyle(
        fontSize: 25,
        height: 1.16,
        fontWeight: FontWeight.w800,
        letterSpacing: tracking(-.6),
        color: foreground,
      ),
      headlineSmall: TextStyle(
        fontSize: 20.5,
        height: 1.2,
        fontWeight: FontWeight.w800,
        letterSpacing: tracking(-.4),
        color: foreground,
      ),
      titleLarge: TextStyle(
        fontSize: 19,
        height: 1.25,
        fontWeight: FontWeight.w800,
        letterSpacing: tracking(-.3),
        color: foreground,
      ),
      titleMedium: TextStyle(
        fontSize: 15.5,
        height: 1.3,
        fontWeight: FontWeight.w700,
        letterSpacing: tracking(-.1),
        color: foreground,
      ),
      titleSmall: TextStyle(
        fontSize: 13.5,
        height: 1.3,
        fontWeight: FontWeight.w700,
        color: foreground,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        height: 1.6,
        letterSpacing: tracking(-.1),
        color: foreground,
      ),
      bodyMedium: TextStyle(
        fontSize: 14.5,
        height: 1.55,
        letterSpacing: tracking(-.05),
        color: foreground,
      ),
      bodySmall: TextStyle(
        fontSize: 12.5,
        height: 1.5,
        color: muted,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: tracking(.1),
        color: foreground,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: muted,
      ),
      labelSmall: TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        letterSpacing: tracking(.8),
        color: muted,
      ),
    );
  }

  static ThemeData light({bool arabic = false}) =>
      _build(Brightness.light, arabic);
  static ThemeData dark({bool arabic = false}) =>
      _build(Brightness.dark, arabic);

  static ThemeData _build(Brightness brightness, bool arabic) {
    final dark = brightness == Brightness.dark;
    final p = dark ? MarinaPalette.dark : MarinaPalette.light;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: dark ? MarinaColors.goldBright : MarinaColors.navy,
      onPrimary: dark ? MarinaColors.onGold : Colors.white,
      primaryContainer: dark ? const Color(0xFF2B2412) : MarinaColors.goldTint,
      onPrimaryContainer:
          dark ? MarinaColors.goldBright : MarinaColors.goldDeep,
      secondary: p.gold,
      onSecondary: p.onGold,
      secondaryContainer: dark ? const Color(0xFF2B2412) : MarinaColors.goldTint,
      onSecondaryContainer:
          dark ? MarinaColors.goldBright : MarinaColors.goldDeep,
      tertiary: MarinaColors.royal,
      onTertiary: Colors.white,
      error: p.isDark ? const Color(0xFFE58877) : MarinaColors.danger,
      onError: Colors.white,
      surface: p.surface,
      onSurface: p.ink,
      surfaceContainerHighest: p.surfaceSoft,
      surfaceContainerHigh: p.surfaceSoft,
      surfaceContainer: p.surfaceSoft,
      surfaceContainerLow: p.surface,
      surfaceContainerLowest: p.background,
      onSurfaceVariant: p.muted,
      outline: p.line,
      outlineVariant: p.line,
      inverseSurface: dark ? MarinaColors.ivory : MarinaColors.midnight,
      onInverseSurface: dark ? MarinaColors.midnight : Colors.white,
      inversePrimary: dark ? MarinaColors.navy : MarinaColors.goldBright,
      shadow: Colors.black,
      scrim: Colors.black,
    );

    OutlineInputBorder inputBorder(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(MarinaRadius.md),
          borderSide: BorderSide(color: color, width: width),
        );

    WidgetStateProperty<Color?> overlay(Color base) => WidgetStateProperty
        .resolveWith((states) => states.contains(WidgetState.pressed)
            ? base.withValues(alpha: .16)
            : base.withValues(alpha: .08));

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: p.background,
      colorScheme: scheme,
      textTheme: _type(p.ink, p.muted, arabic),
      splashFactory: InkSparkle.splashFactory,
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
        backgroundColor: p.background,
        foregroundColor: p.ink,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: arabic ? 0 : -.3,
          color: p.ink,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? const Color(0xFF101624) : Colors.white,
        labelStyle: TextStyle(color: p.muted, fontWeight: FontWeight.w500),
        hintStyle: TextStyle(color: p.muted.withValues(alpha: .75)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
        border: inputBorder(p.line),
        enabledBorder: inputBorder(p.line),
        focusedBorder: inputBorder(p.gold, 1.4),
        errorBorder: inputBorder(scheme.error),
        focusedErrorBorder: inputBorder(scheme.error, 1.4),
        disabledBorder: inputBorder(p.line.withValues(alpha: .6)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return p.muted.withValues(alpha: .16);
            }
            return dark ? MarinaColors.goldBright : MarinaColors.navy;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) return p.muted;
            return dark ? MarinaColors.onGold : Colors.white;
          }),
          minimumSize: const WidgetStatePropertyAll(Size(0, 56)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 26, vertical: 15),
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
          ),
          elevation: const WidgetStatePropertyAll(0),
          overlayColor: overlay(Colors.white),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 54),
          foregroundColor: p.ink,
          side: BorderSide(color: p.line),
          backgroundColor: dark ? p.surface.withValues(alpha: .5) : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: dark ? p.gold : MarinaColors.deepRoyal,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: p.ink),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: dark ? MarinaColors.goldBright : MarinaColors.navy,
        foregroundColor: dark ? MarinaColors.onGold : Colors.white,
        elevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(19)),
        extendedPadding: const EdgeInsets.symmetric(horizontal: 22),
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MarinaRadius.lg),
          side: BorderSide(color: p.line),
        ),
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.surfaceSoft,
        selectedColor: dark ? MarinaColors.goldBright : MarinaColors.navy,
        checkmarkColor: dark ? MarinaColors.onGold : Colors.white,
        labelStyle: TextStyle(color: p.ink, fontWeight: FontWeight.w600),
        secondaryLabelStyle: TextStyle(
          color: dark ? MarinaColors.onGold : Colors.white,
          fontWeight: FontWeight.w700,
        ),
        side: BorderSide(color: p.line),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MarinaRadius.sm + 4),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26),
        ),
        titleTextStyle: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w800,
          color: p.ink,
        ),
        contentTextStyle: TextStyle(fontSize: 14.5, height: 1.55, color: p.ink),
        barrierColor: Colors.black.withValues(alpha: .55),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: Colors.black.withValues(alpha: .5),
        showDragHandle: true,
        dragHandleColor: p.line,
        dragHandleSize: const Size(42, 4),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: dark ? const Color(0xFF222B3C) : MarinaColors.midnight,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 6,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.gold,
        linearTrackColor: p.line,
        circularTrackColor: p.line.withValues(alpha: .4),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? (dark ? MarinaColors.onGold : Colors.white)
                : p.muted),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? p.gold
                : p.line.withValues(alpha: .8)),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? p.gold : Colors.transparent),
        checkColor: const WidgetStatePropertyAll(MarinaColors.onGold),
        side: BorderSide(color: p.muted.withValues(alpha: .6)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? p.gold
                : p.muted.withValues(alpha: .8)),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: p.muted,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
          color: p.ink,
        ),
        subtitleTextStyle: TextStyle(fontSize: 12.5, color: p.muted, height: 1.4),
      ),
      dividerTheme: DividerThemeData(color: p.line, thickness: 1, space: 1),
      popupMenuTheme: PopupMenuThemeData(
        color: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: p.line),
        ),
        textStyle: TextStyle(fontSize: 14, color: p.ink),
      ),
      badgeTheme: BadgeThemeData(
        backgroundColor: p.gold,
        textColor: p.onGold,
        textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF222B3C) : MarinaColors.midnight,
          borderRadius: BorderRadius.circular(10),
        ),
        textStyle: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: p.ink,
        unselectedLabelColor: p.muted,
        indicatorColor: p.gold,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: p.line,
        labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(p.surface),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
        ),
      ),
    );
  }
}
