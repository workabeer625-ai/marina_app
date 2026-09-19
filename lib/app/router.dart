import 'package:go_router/go_router.dart';

import '../features/admin/presentation/admin_screens.dart';
import '../features/admin/presentation/admin_queue_screens.dart';
import '../features/auth/presentation/auth_screens.dart';
import '../features/commerce/presentation/commerce_screens.dart';
import '../features/commerce/presentation/post_purchase_screens.dart';
import '../features/products/domain/product.dart';
import '../features/profile/presentation/profile_screens.dart';
import '../features/profile/data/customer_repository.dart';
import '../features/profile/presentation/customer_account_screens.dart';
import '../features/store/presentation/store_screens.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../core/network/api_client.dart';
import '../shared/widgets/customer_shell.dart';

final router = GoRouter(
  initialLocation: '/splash',
  refreshListenable: apiClient.sessionExpired,
  redirect: (_, state) async {
    final path = state.matchedLocation;
    const protected = [
      '/cart',
      '/favorites',
      '/profile',
      '/checkout',
      '/orders',
      '/returns',
      '/notifications',
      '/edit-profile',
      '/addresses',
      '/security',
      '/change-password',
      '/sessions',
    ];
    final needsSession =
        protected.any((route) => path == route || path.startsWith('$route/')) ||
        path.startsWith('/admin');
    if (!needsSession) return null;
    if (!await apiClient.hasSession()) {
      return '/login?expired=${apiClient.sessionExpired.value ? 1 : 0}&returnTo=${Uri.encodeComponent(state.uri.toString())}';
    }
    if (path.startsWith('/admin') &&
        (await apiClient.currentPermissions()).isEmpty) {
      return '/home';
    }
    return null;
  },
  routes: [
    GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
    GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
    GoRoute(path: '/welcome', builder: (_, _) => const WelcomeScreen()),
    GoRoute(
      path: '/login',
      builder: (_, state) => LoginScreen(
        sessionExpired: state.uri.queryParameters['expired'] == '1',
      ),
    ),
    GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
    GoRoute(
      path: '/forgot-password',
      builder: (_, _) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/reset-password',
      builder: (_, state) =>
          ResetPasswordScreen(initialEmail: state.uri.queryParameters['email'], initialToken: state.uri.queryParameters['token']),
    ),
    GoRoute(
      path: '/verification',
      builder: (_, state) =>
          VerificationScreen(initialEmail: state.uri.queryParameters['email'], initialToken: state.uri.queryParameters['token']),
    ),
    GoRoute(
      path: '/mfa',
      builder: (_, state) {
        final data = state.extra as Map<String, dynamic>? ?? const {};
        return MfaLoginScreen(
          email: data['email']?.toString() ?? '',
          password: data['password']?.toString() ?? '',
          setupRequired: data['setupRequired'] == true,
          sharedKey: data['sharedKey']?.toString(),
          account: data['account']?.toString(),
          issuer: data['issuer']?.toString(),
        );
      },
    ),
    ShellRoute(
      builder: (_, _, child) => CustomerShell(child: child),
      routes: [
        GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
        GoRoute(
          path: '/categories',
          builder: (_, _) => const CategoriesScreen(),
        ),
        GoRoute(path: '/cart', builder: (_, _) => const CartScreen()),
        GoRoute(
          path: '/favorites',
          builder: (_, _) => const ApiFavoritesScreen(),
        ),
        GoRoute(path: '/profile', builder: (_, _) => const ApiProfileScreen()),
      ],
    ),
    GoRoute(
      path: '/products',
      builder: (_, state) => CatalogScreen(
        categoryId: state.uri.queryParameters['category'],
        brandId: state.uri.queryParameters['brand'],
      ),
    ),
    GoRoute(
      path: '/new-arrivals',
      builder: (_, _) =>
          const CatalogScreen(titleKey: 'new', newArrivals: true),
    ),
    GoRoute(
      path: '/offers',
      builder: (_, _) => const CatalogScreen(titleKey: 'offers', offers: true),
    ),
    GoRoute(path: '/brands', builder: (_, _) => const BrandsScreen()),
    GoRoute(path: '/search', builder: (_, _) => const SearchScreen()),
    GoRoute(
      path: '/product/:id',
      builder: (_, s) => ProductDetailScreen(
        id: s.pathParameters['id']!,
        product: s.extra is Product ? s.extra as Product : null,
      ),
    ),
    GoRoute(
      path: '/product/:id/gallery',
      builder: (_, s) => GalleryScreen(
        productId: s.pathParameters['id']!,
        product: s.extra is Product ? s.extra as Product : null,
      ),
    ),
    GoRoute(
      path: '/product/:id/reviews',
      builder: (_, state) =>
          ProductReviewsScreen(productId: state.pathParameters['id']!),
    ),
    GoRoute(path: '/checkout', builder: (_, _) => const CheckoutScreen()),
    GoRoute(
      path: '/order-success',
      builder: (_, state) =>
          OrderSuccessScreen(order: state.extra as Map<String, dynamic>?),
    ),
    GoRoute(path: '/orders', builder: (_, _) => const ApiOrdersScreen()),
    GoRoute(path: '/returns', builder: (_, _) => const ApiReturnsScreen()),
    GoRoute(
      path: '/returns/:id',
      builder: (_, state) =>
          ReturnDetailsScreen(returnId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/orders/:id',
      builder: (_, state) =>
          ApiOrderDetailsScreen(orderId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/orders/:id/return',
      builder: (_, state) =>
          ReturnRequestScreen(orderId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/notifications',
      builder: (_, _) => const ApiNotificationsScreen(),
    ),
    GoRoute(
      path: '/edit-profile',
      builder: (_, _) => const ApiEditProfileScreen(),
    ),
    GoRoute(path: '/addresses', builder: (_, _) => const ApiAddressesScreen()),
    GoRoute(
      path: '/addresses/new',
      builder: (_, _) => const ApiAddressFormScreen(),
    ),
    GoRoute(
      path: '/addresses/edit',
      builder: (_, state) =>
          ApiAddressFormScreen(address: state.extra as CustomerAddress?),
    ),
    GoRoute(path: '/security', builder: (_, _) => const SecurityScreen()),
    GoRoute(
      path: '/change-password',
      builder: (_, _) => const ChangePasswordScreen(),
    ),
    GoRoute(path: '/sessions', builder: (_, _) => const SessionsScreen()),
    GoRoute(path: '/language', builder: (_, _) => const LanguageScreen()),
    GoRoute(
      path: '/about',
      builder: (_, _) =>
          const InfoScreen(titleKey: 'about', bodyKey: 'aboutBody'),
    ),
    GoRoute(
      path: '/privacy',
      builder: (_, _) =>
          const InfoScreen(titleKey: 'privacy', bodyKey: 'privacyBody'),
    ),
    GoRoute(
      path: '/terms',
      builder: (_, _) =>
          const InfoScreen(titleKey: 'terms', bodyKey: 'termsBody'),
    ),
    GoRoute(
      path: '/support',
      builder: (_, _) =>
          const InfoScreen(titleKey: 'help', bodyKey: 'helpBody'),
    ),
    ShellRoute(
      builder: (_, _, child) => AdminShell(child: child),
      routes: [
        GoRoute(
          path: '/admin',
          builder: (_, _) => const AdminDashboardScreen(),
        ),
        GoRoute(
          path: '/admin/products',
          builder: (_, _) => const AdminLiveListScreen(
            titleKey: 'products',
            endpoint: '/admin/catalog/products',
            addRoute: '/admin/products/new',
          ),
        ),
        GoRoute(
          path: '/admin/reference',
          builder: (_, _) => const AdminReferenceScreen(),
        ),
        GoRoute(
          path: '/admin/products/new',
          builder: (_, _) => const AdminProductFormScreen(),
        ),
        GoRoute(
          path: '/admin/products/:id/edit',
          builder: (_, state) =>
              AdminProductFormScreen(productId: state.pathParameters['id']),
        ),
        GoRoute(
          path: '/admin/inventory',
          builder: (_, _) => const AdminLiveListScreen(
            titleKey: 'inventory',
            endpoint: '/admin/inventory',
          ),
        ),
        GoRoute(
          path: '/admin/orders',
          builder: (_, _) => const AdminLiveListScreen(
            titleKey: 'orders',
            endpoint: '/admin/orders',
          ),
        ),
        GoRoute(
          path: '/admin/returns',
          builder: (_, _) => const AdminReturnQueueScreen(),
        ),
        GoRoute(
          path: '/admin/reviews',
          builder: (_, _) => const AdminReviewQueueScreen(),
        ),
        GoRoute(
          path: '/admin/customers',
          builder: (_, _) => const AdminLiveListScreen(
            titleKey: 'customers',
            endpoint: '/admin/customers',
          ),
        ),
        GoRoute(
          path: '/admin/coupons',
          builder: (_, _) => const AdminLiveListScreen(
            titleKey: 'coupons',
            endpoint: '/admin/coupons',
            addRoute: '/admin/coupons/new',
          ),
        ),
        GoRoute(
          path: '/admin/coupons/new',
          builder: (_, _) => const AdminCouponFormScreen(),
        ),
        GoRoute(
          path: '/admin/reports',
          builder: (_, _) => const AdminReportsScreen(),
        ),
        GoRoute(
          path: '/admin/users',
          builder: (_, _) => const AdminAccessScreen(),
        ),
        GoRoute(
          path: '/admin/audit',
          builder: (_, _) => const AdminLiveListScreen(
            titleKey: 'audit',
            endpoint: '/admin/audit',
          ),
        ),
        GoRoute(
          path: '/admin/security-events',
          builder: (_, _) => const AdminLiveListScreen(
            titleKey: 'securityEvents',
            endpoint: '/admin/security-events',
          ),
        ),
        GoRoute(
          path: '/admin/notifications',
          builder: (_, _) => const AdminNotificationsScreen(),
        ),
        GoRoute(
          path: '/admin/settings',
          builder: (_, _) => const AdminSettingsScreen(),
        ),
      ],
    ),
  ],
);
