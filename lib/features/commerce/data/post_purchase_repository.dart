import '../../../core/network/api_models.dart';
import '../../../shared/widgets/page_controls.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

class ProductReview {
  const ProductReview({
    required this.id,
    required this.rating,
    required this.title,
    required this.body,
    required this.displayName,
    required this.createdUtc,
  });

  final String id, title, body, displayName;
  final int rating;
  final DateTime createdUtc;

  factory ProductReview.fromJson(Map<String, dynamic> json) => ProductReview(
    id: json['id'].toString(),
    rating: (json['rating'] as num).toInt(),
    title: (json['title'] ?? '').toString(),
    body: (json['body'] ?? '').toString(),
    displayName: (json['displayName'] ?? 'MARINA customer').toString(),
    createdUtc:
        DateTime.tryParse((json['createdUtc'] ?? '').toString()) ??
        DateTime.now(),
  );
}

class ReviewPage {
  const ReviewPage({
    required this.items,
    required this.average,
    required this.count,
  });
  final List<ProductReview> items;
  final double average;
  final int count;
}

class OrderSummary {
  const OrderSummary({
    required this.id,
    required this.publicNumber,
    required this.status,
    required this.total,
    required this.itemCount,
    required this.createdUtc,
  });
  final String id, publicNumber, status;
  final double total;
  final int itemCount;
  final DateTime createdUtc;

  factory OrderSummary.fromJson(Map<String, dynamic> json) => OrderSummary(
    id: json['id'].toString(),
    publicNumber: json['publicNumber'].toString(),
    status: _enumName(json['status']),
    total: (json['total'] as num?)?.toDouble() ?? 0,
    itemCount: (json['itemCount'] as num?)?.toInt() ?? 0,
    createdUtc:
        DateTime.tryParse((json['createdUtc'] ?? '').toString()) ??
        DateTime.now(),
  );
}

class OrderLine {
  const OrderLine({
    required this.id,
    required this.productName,
    required this.sku,
    required this.quantity,
    required this.unitPrice,
  });
  final String id, productName, sku;
  final int quantity;
  final double unitPrice;

  factory OrderLine.fromJson(Map<String, dynamic> json) => OrderLine(
    id: json['id'].toString(),
    productName: (json['productName'] ?? '').toString(),
    sku: (json['sku'] ?? '').toString(),
    quantity: (json['quantity'] as num?)?.toInt() ?? 1,
    unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
  );
}

class OrderTimelineEntry {
  const OrderTimelineEntry(this.status, this.createdUtc, this.reason);
  final String status;
  final DateTime createdUtc;
  final String? reason;

  factory OrderTimelineEntry.fromJson(Map<String, dynamic> json) =>
      OrderTimelineEntry(
        _enumName(json['status']),
        DateTime.tryParse((json['createdUtc'] ?? '').toString()) ??
            DateTime.now(),
        json['reason']?.toString(),
      );
}

class OrderDetails {
  const OrderDetails({
    required this.id,
    required this.publicNumber,
    required this.status,
    required this.total,
    required this.items,
    required this.timeline,
  });
  final String id, publicNumber, status;
  final double total;
  final List<OrderLine> items;
  final List<OrderTimelineEntry> timeline;

  factory OrderDetails.fromJson(Map<String, dynamic> json) => OrderDetails(
    id: json['id'].toString(),
    publicNumber: json['publicNumber'].toString(),
    status: _enumName(json['status']),
    total: (json['total'] as num?)?.toDouble() ?? 0,
    items: (json['items'] as List? ?? const [])
        .map((x) => OrderLine.fromJson(x as Map<String, dynamic>))
        .toList(),
    timeline: (json['timeline'] as List? ?? const [])
        .map((x) => OrderTimelineEntry.fromJson(x as Map<String, dynamic>))
        .toList(),
  );
}

class ReturnSummary {
  const ReturnSummary({
    required this.id,
    required this.orderId,
    required this.publicNumber,
    required this.status,
    required this.reason,
    required this.itemCount,
    required this.createdUtc,
  });
  final String id, orderId, publicNumber, status, reason;
  final int itemCount;
  final DateTime createdUtc;

  factory ReturnSummary.fromJson(Map<String, dynamic> json) => ReturnSummary(
    id: json['id'].toString(),
    orderId: json['orderId'].toString(),
    publicNumber: json['publicNumber'].toString(),
    status: _returnStatus(json['status']),
    reason: (json['reason'] ?? '').toString(),
    itemCount: (json['itemCount'] as num?)?.toInt() ?? 0,
    createdUtc:
        DateTime.tryParse((json['createdUtc'] ?? '').toString()) ??
        DateTime.now(),
  );
}

class ReturnLineDetails {
  const ReturnLineDetails({
    required this.productName,
    required this.sku,
    required this.quantity,
  });
  final String productName, sku;
  final int quantity;

  factory ReturnLineDetails.fromJson(Map<String, dynamic> json) =>
      ReturnLineDetails(
        productName: (json['productName'] ?? '').toString(),
        sku: (json['sku'] ?? '').toString(),
        quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      );
}

class ReturnTimelineEntry {
  const ReturnTimelineEntry({
    required this.status,
    required this.createdUtc,
    this.note,
  });
  final String status;
  final DateTime createdUtc;
  final String? note;

  factory ReturnTimelineEntry.fromJson(Map<String, dynamic> json) =>
      ReturnTimelineEntry(
        status: _returnStatus(json['status']),
        createdUtc:
            DateTime.tryParse((json['createdUtc'] ?? '').toString()) ??
            DateTime.now(),
        note: json['note']?.toString(),
      );
}

class ReturnDetails {
  const ReturnDetails({
    required this.id,
    required this.orderId,
    required this.publicNumber,
    required this.status,
    required this.reason,
    required this.items,
    required this.timeline,
    this.customerNote,
    this.adminNote,
  });
  final String id, orderId, publicNumber, status, reason;
  final String? customerNote, adminNote;
  final List<ReturnLineDetails> items;
  final List<ReturnTimelineEntry> timeline;

  factory ReturnDetails.fromJson(Map<String, dynamic> json) => ReturnDetails(
    id: json['id'].toString(),
    orderId: json['orderId'].toString(),
    publicNumber: json['publicNumber'].toString(),
    status: _returnStatus(json['status']),
    reason: (json['reason'] ?? '').toString(),
    customerNote: json['customerNote']?.toString(),
    adminNote: json['adminNote']?.toString(),
    items: (json['items'] as List? ?? const [])
        .map((x) => ReturnLineDetails.fromJson(x as Map<String, dynamic>))
        .toList(),
    timeline: (json['timeline'] as List? ?? const [])
        .map((x) => ReturnTimelineEntry.fromJson(x as Map<String, dynamic>))
        .toList(),
  );
}

String _returnStatus(Object? value) {
  if (value is String) return value;
  const values = [
    'Requested',
    'Approved',
    'Rejected',
    'Received',
    'RefundPending',
    'Refunded',
    'Cancelled',
  ];
  return value is num && value >= 0 && value < values.length
      ? values[value.toInt()]
      : 'Unknown';
}

String _enumName(Object? value) {
  if (value is String) return value;
  const orderStatuses = [
    'Pending',
    'Confirmed',
    'Preparing',
    'Ready',
    'Shipped',
    'OutForDelivery',
    'Delivered',
    'Cancelled',
    'Returned',
    'Refunded',
  ];
  if (value is num && value >= 0 && value < orderStatuses.length) {
    return orderStatuses[value.toInt()];
  }
  return 'Unknown';
}

class PostPurchaseRepository {
  PostPurchaseRepository(this.client);
  final ApiClient client;

  Future<ReviewPage> reviews(String productId) async {
    final response = await client.dio.get(
      '/catalog/products/$productId/reviews',
    );
    final data = response.data as Map<String, dynamic>;
    return ReviewPage(
      items: (data['items'] as List? ?? const [])
          .map((x) => ProductReview.fromJson(x as Map<String, dynamic>))
          .toList(),
      average: (data['average'] as num?)?.toDouble() ?? 0,
      count: (data['count'] as num?)?.toInt() ?? 0,
    );
  }

  Future<void> submitReview(
    String productId, {
    required int rating,
    required String title,
    required String body,
  }) async => client.dio.put(
    '/catalog/products/$productId/reviews/mine',
    data: {'rating': rating, 'title': title, 'body': body},
  );

  Future<ApiPage<OrderSummary>> orders({int page = 1}) async => ApiPage.fromJson(
    (await client.dio.get('/orders', queryParameters: {'page': page, 'pageSize': 20})).data,
    OrderSummary.fromJson,
  );

  Future<OrderDetails> order(String id) async {
    final response = await client.dio.get('/orders/$id');
    return OrderDetails.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> cancelOrder(String id, String reason) =>
      client.dio.post('/orders/$id/cancel', data: {'reason': reason});

  Future<Map<String, dynamic>> createReturn(
    String orderId, {
    required String reason,
    String? note,
    required Map<String, int> quantities,
  }) async {
    final response = await client.dio.post(
      '/returns/orders/$orderId',
      data: {
        'reason': reason,
        'note': note,
        'items': quantities.entries
            .where((x) => x.value > 0)
            .map((x) => {'orderItemId': x.key, 'quantity': x.value})
            .toList(),
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<ApiPage<ReturnSummary>> returns({int page = 1}) async => ApiPage.fromJson(
    (await client.dio.get('/returns', queryParameters: {'page': page, 'pageSize': 20})).data,
    ReturnSummary.fromJson,
  );

  Future<void> cancelReturn(String id) =>
      client.dio.post('/returns/$id/cancel');

  Future<ReturnDetails> returnDetails(String id) async =>
      ReturnDetails.fromJson(
        (await client.dio.get('/returns/$id')).data as Map<String, dynamic>,
      );
}

final postPurchaseRepositoryProvider = Provider(
  (_) => PostPurchaseRepository(apiClient),
);
final productReviewsProvider = FutureProvider.family<ReviewPage, String>(
  (ref, productId) =>
      ref.watch(postPurchaseRepositoryProvider).reviews(productId),
);
final ordersProvider = FutureProvider<ApiPage<OrderSummary>>(
  (ref) => ref.watch(postPurchaseRepositoryProvider).orders(page: ref.watch(pageSelectionProvider('/orders'))),
);
final orderDetailsProvider = FutureProvider.family<OrderDetails, String>(
  (ref, id) => ref.watch(postPurchaseRepositoryProvider).order(id),
);
final returnsProvider = FutureProvider<ApiPage<ReturnSummary>>(
  (ref) => ref.watch(postPurchaseRepositoryProvider).returns(page: ref.watch(pageSelectionProvider('/returns'))),
);
final returnDetailsProvider = FutureProvider.family<ReturnDetails, String>(
  (ref, id) => ref.watch(postPurchaseRepositoryProvider).returnDetails(id),
);
