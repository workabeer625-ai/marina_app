import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marina_app/core/theme/marina_theme.dart';
import 'package:marina_app/features/auth/presentation/auth_screens.dart';
import 'package:marina_app/features/onboarding/presentation/onboarding_screen.dart';
import 'package:marina_app/features/products/data/catalog_repository.dart';
import 'package:marina_app/features/products/domain/product.dart';
import 'package:marina_app/features/store/presentation/store_screens.dart';

void main() {
  const widths = [
    320.0,
    360.0,
    390.0,
    412.0,
    480.0,
    600.0,
    768.0,
    1024.0,
    1280.0,
    1440.0,
  ];
  for (final width in widths) {
    testWidgets('welcome has no overflow at ${width.toInt()}px', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 900);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        MaterialApp(theme: MarinaTheme.light(), home: const WelcomeScreen()),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
    testWidgets('onboarding has no overflow at ${width.toInt()}px', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 900);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        MaterialApp(theme: MarinaTheme.light(), home: const OnboardingScreen()),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
    testWidgets('home has no overflow at ${width.toInt()}px', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 900);
      addTearDown(tester.view.resetPhysicalSize);
      const product = Product(
        id: '1',
        name: 'MARINA Navy Sneakers',
        price: 249,
        image: null,
      );
      const data = CatalogHome(
        title: 'A refined new season',
        subtitle: 'Selected pieces for every day.',
        categories: [
          CatalogCategory(id: '1', name: 'Women', slug: 'women'),
          CatalogCategory(id: '2', name: 'Shoes', slug: 'shoes'),
        ],
        products: [product, product, product, product, product],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            catalogHomeProvider.overrideWith((ref, culture) async => data),
          ],
          child: MaterialApp(
            theme: MarinaTheme.light(),
            home: const HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
