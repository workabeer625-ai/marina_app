import 'package:flutter_test/flutter_test.dart';
import 'package:marina_app/features/commerce/data/post_purchase_repository.dart';

void main() {
  test('order details decode string enum and safe item values', () {
    final order = OrderDetails.fromJson({
      'id': 'order-1',
      'publicNumber': 'MAR-2026-ABC',
      'status': 'Delivered',
      'total': 218.5,
      'items': [
        {
          'id': 'item-1',
          'productName': 'Linen dress',
          'sku': 'DR-1',
          'quantity': 2,
          'unitPrice': 95,
        },
      ],
      'timeline': [
        {'status': 'Delivered', 'createdUtc': '2026-08-30T10:00:00Z'},
      ],
    });

    expect(order.status, 'Delivered');
    expect(order.items.single.quantity, 2);
    expect(order.timeline.single.status, 'Delivered');
  });

  test('review page model preserves verified review content', () {
    final review = ProductReview.fromJson({
      'id': 'review-1',
      'rating': 5,
      'title': 'Beautiful',
      'body': 'Excellent quality and fit.',
      'displayName': 'Sara',
      'createdUtc': '2026-08-30T10:00:00Z',
    });

    expect(review.rating, 5);
    expect(review.displayName, 'Sara');
    expect(review.body, contains('quality'));
  });
}
