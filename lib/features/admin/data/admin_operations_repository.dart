import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

class AdminReviewItem {
  const AdminReviewItem({
    required this.id,
    required this.productId,
    required this.rating,
    required this.title,
    required this.body,
    required this.status,
  });
  final String id, productId, title, body, status;
  final int rating;

  factory AdminReviewItem.fromJson(Map<String, dynamic> json) =>
      AdminReviewItem(
        id: json['id'].toString(),
        productId: json['productId'].toString(),
        rating: (json['rating'] as num?)?.toInt() ?? 0,
        title: (json['title'] ?? '').toString(),
        body: (json['body'] ?? '').toString(),
        status: (json['status'] ?? 'Pending').toString(),
      );
}

class AdminReturnItem {
  const AdminReturnItem({
    required this.id,
    required this.publicNumber,
    required this.orderId,
    required this.reason,
    required this.status,
    required this.itemCount,
  });
  final String id, publicNumber, orderId, reason, status;
  final int itemCount;

  factory AdminReturnItem.fromJson(Map<String, dynamic> json) =>
      AdminReturnItem(
        id: json['id'].toString(),
        publicNumber: json['publicNumber'].toString(),
        orderId: json['orderId'].toString(),
        reason: (json['reason'] ?? '').toString(),
        status: (json['status'] ?? 'Requested').toString(),
        itemCount: (json['itemCount'] as num?)?.toInt() ?? 0,
      );
}

class AdminOperationsRepository {
  AdminOperationsRepository(this.client);
  final ApiClient client;

  Future<Map<String, dynamic>> dashboard() async =>
      (await client.dio.get('/admin/dashboard')).data as Map<String, dynamic>;

  Future<List<Map<String, dynamic>>> list(String endpoint) async {
    final data = (await client.dio.get(endpoint)).data;
    final values = data is Map<String, dynamic> ? data['items'] : data;
    return (values as List? ?? const [])
        .map((x) => Map<String, dynamic>.from(x as Map))
        .toList();
  }

  Future<Map<String, dynamic>> report() async =>
      (await client.dio.get('/admin/reports')).data as Map<String, dynamic>;

  Future<void> createProduct({
    required String slug,
    required String categoryId,
    required String englishName,
    required String arabicName,
    required String description,
    required String sku,
    required double price,
    required int stock,
    String? brandId,
  }) => client.dio.post(
    '/admin/catalog/products',
    data: {
      'slug': slug.trim(),
      'categoryId': categoryId,
      'brandId': brandId,
      'isActive': true,
      'isFeatured': false,
      'isNewArrival': true,
      'isOffer': false,
      'translations': [
        {
          'culture': 'en',
          'name': englishName.trim(),
          'description': description.trim(),
        },
        if (arabicName.trim().isNotEmpty)
          {
            'culture': 'ar',
            'name': arabicName.trim(),
            'description': description.trim(),
          },
      ],
      'variants': [
        {
          'sku': sku.trim(),
          'price': price,
          'initialStock': stock,
          'isActive': true,
        },
      ],
    },
  );

  Future<void> createCoupon({required String code, required double value}) {
    final now = DateTime.now().toUtc();
    return client.dio.post(
      '/admin/coupons',
      data: {
        'code': code.trim(),
        'type': 0,
        'value': value,
        'validFromUtc': now.toIso8601String(),
        'validToUtc': now.add(const Duration(days: 30)).toIso8601String(),
        'maxUsesPerCustomer': 1,
        'isActive': true,
      },
    );
  }

  Future<void> saveSetting(String key, String value, bool isPublic) =>
      client.dio.put(
        '/admin/settings',
        data: {'key': key.trim(), 'value': value.trim(), 'isPublic': isPublic},
      );

  Future<List<AdminReviewItem>> reviews() async {
    final response = await client.dio.get(
      '/admin/reviews',
      queryParameters: {'status': 'Pending'},
    );
    final data = response.data as Map<String, dynamic>;
    return (data['items'] as List? ?? const [])
        .map((x) => AdminReviewItem.fromJson(x as Map<String, dynamic>))
        .toList();
  }

  Future<void> moderateReview(String id, String status) async => client.dio.put(
    '/admin/reviews/$id',
    data: {'status': status, 'note': null},
  );

  Future<List<AdminReturnItem>> returns() async {
    final response = await client.dio.get('/admin/returns');
    final data = response.data as Map<String, dynamic>;
    return (data['items'] as List? ?? const [])
        .map((x) => AdminReturnItem.fromJson(x as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateReturn(String id, String status, {String? note}) async =>
      client.dio.put(
        '/admin/returns/$id/status',
        data: {'status': status, 'note': note},
      );
}

final adminOperationsRepositoryProvider = Provider(
  (_) => AdminOperationsRepository(apiClient),
);
final adminReviewsProvider = FutureProvider<List<AdminReviewItem>>(
  (ref) => ref.watch(adminOperationsRepositoryProvider).reviews(),
);
final adminReturnsProvider = FutureProvider<List<AdminReturnItem>>(
  (ref) => ref.watch(adminOperationsRepositoryProvider).returns(),
);
final adminDashboardProvider = FutureProvider<Map<String, dynamic>>(
  (ref) => ref.watch(adminOperationsRepositoryProvider).dashboard(),
);
final adminListProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
      (ref, endpoint) =>
          ref.watch(adminOperationsRepositoryProvider).list(endpoint),
    );
final adminReportProvider = FutureProvider<Map<String, dynamic>>(
  (ref) => ref.watch(adminOperationsRepositoryProvider).report(),
);
