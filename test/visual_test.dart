import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marina_app/core/theme/marina_theme.dart';
import 'package:marina_app/features/admin/presentation/admin_screens.dart';
import 'package:marina_app/features/admin/data/admin_operations_repository.dart';
import 'package:marina_app/features/auth/presentation/auth_screens.dart';

void main() {
  testWidgets('welcome visual', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(theme: MarinaTheme.light(), home: const WelcomeScreen()),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await expectLater(
      find.byType(WelcomeScreen),
      matchesGoldenFile('goldens/welcome.png'),
    );
  });

  testWidgets('admin dashboard visual', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 960);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminDashboardProvider.overrideWith(
            (_) async => {
              'sales': 428650,
              'orders': 1245,
              'newCustomers': 312,
              'averageOrderValue': 344.12,
              'lowStock': 3,
              'recentOrders': [
                {
                  'id': '11111111-1111-1111-1111-111111111111',
                  'publicNumber': 'MAR-2026-10458',
                  'status': 'Processing',
                  'total': 1280,
                },
              ],
            },
          ),
          currentPermissionsProvider.overrideWith(
            (_) async => {
              ...adminItems.expand((item) => item.$4.split('|')),
              'Products.Create',
            },
          ),
        ],
        child: MaterialApp(
          theme: MarinaTheme.light(),
          home: const AdminShell(child: AdminDashboardScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(AdminDashboardScreen),
      matchesGoldenFile('goldens/admin_dashboard.png'),
    );
  });
}
