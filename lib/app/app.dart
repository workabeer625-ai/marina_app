import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/localization/app_localizations.dart';
import '../core/theme/marina_theme.dart';
import 'router.dart';

class MarinaApp extends ConsumerWidget {
  const MarinaApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final arabic = locale.languageCode == 'ar';
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'MARINA',
      theme: MarinaTheme.light(arabic: arabic),
      darkTheme: MarinaTheme.dark(arabic: arabic),
      themeMode: themeMode,
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}
