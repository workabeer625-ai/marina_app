import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:marina_app/shared/widgets/marina_wordmark.dart';

void main() {
  testWidgets('shows bilingual MARINA wordmark', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MarinaWordmark()));
    expect(find.text('M A R I N A'), findsOneWidget);
    expect(find.text('مارينا'), findsOneWidget);
  });

  for (final locale in const [Locale('en'), Locale('ar')]) {
    testWidgets('${locale.languageCode} applies the correct text direction', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          supportedLocales: const [Locale('en'), Locale('ar')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const Scaffold(body: Text('MARINA')),
        ),
      );
      final direction = tester.widget<Directionality>(
        find.byType(Directionality).first,
      );
      expect(
        direction.textDirection,
        locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
      );
    });
  }
}
