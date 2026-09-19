import 'package:flutter_test/flutter_test.dart';
import 'package:marina_app/core/state/commerce_state.dart';
import 'package:marina_app/features/commerce/data/post_purchase_repository.dart';
import 'package:marina_app/features/products/data/catalog_repository.dart';

void main() {
  test('cart snapshot preserves server item identity and availability', () {
    final cart = CartSnapshot.fromJson({
      'subtotal': 249.5,
      'items': [
        {
          'id': 'cart-item',
          'variantId': 'variant',
          'productId': 'product',
          'name': 'Linen dress',
          'price': 249.5,
          'quantity': 2,
          'available': 4,
          'color': 'Sand',
          'size': '6Y',
        },
      ],
    });

    expect(cart.subtotal, 249.5);
    expect(cart.items.single.id, 'cart-item');
    expect(cart.items.single.available, 4);
    expect(cart.items.single.color, 'Sand');
  });

  test('server quote decodes discount and final total', () {
    final quote = CartQuote.fromJson({
      'subtotal': 400,
      'discount': 40,
      'shipping': 0,
      'tax': 54,
      'total': 414,
      'couponCode': 'MARINA10',
    });

    expect(quote.couponCode, 'MARINA10');
    expect(quote.total, 414);
  });

  test('product details preserve selectable inventory variant', () {
    final details = ProductDetails.fromJson({
      'id': 'product',
      'name': 'Dress',
      'description': 'Description',
      'images': [
        {'url': 'https://example.test/image.jpg', 'altText': 'Dress'},
      ],
      'variants': [
        {
          'id': 'variant',
          'sku': 'MAR-1',
          'price': 100,
          'color': 'Blue',
          'size': '8Y',
          'available': true,
          'availableQuantity': 7,
        },
      ],
    });

    expect(details.images, hasLength(1));
    expect(details.variants.single.availableQuantity, 7);
  });

  test('return summary converts numeric workflow status', () {
    final item = ReturnSummary.fromJson({
      'id': 'return',
      'orderId': 'order',
      'publicNumber': 'RET-100',
      'status': 1,
      'reason': 'Wrong size',
      'itemCount': 1,
      'createdUtc': '2026-08-30T10:00:00Z',
    });

    expect(item.status, 'Approved');
    expect(item.orderId, 'order');
  });

  test('refund-pending return status preserves enum position', () {
    final item = ReturnSummary.fromJson({
      'id': 'return',
      'orderId': 'order',
      'publicNumber': 'RET-101',
      'status': 4,
      'reason': 'Damaged',
      'itemCount': 1,
      'createdUtc': '2026-08-30T10:00:00Z',
    });
    expect(item.status, 'RefundPending');
  });

  test('return details preserve lines and workflow timeline', () {
    final details = ReturnDetails.fromJson({
      'id': 'return',
      'orderId': 'order',
      'publicNumber': 'RET-102',
      'status': 'Received',
      'reason': 'Wrong size',
      'items': [
        {'productName': 'Dress', 'sku': 'MAR-1', 'quantity': 2},
      ],
      'timeline': [
        {
          'status': 'Requested',
          'createdUtc': '2026-08-30T10:00:00Z',
          'note': 'Submitted',
        },
      ],
    });
    expect(details.items.single.quantity, 2);
    expect(details.timeline.single.status, 'Requested');
  });

  test('catalog brand decodes localized discovery contract', () {
    final brand = CatalogBrand.fromJson({
      'id': 'brand',
      'name': 'MARINA Essentials',
      'slug': 'marina-essentials',
    });
    expect(brand.name, 'MARINA Essentials');
    expect(brand.slug, 'marina-essentials');
  });

  test('catalog option decodes filter code and localized name', () {
    final option = CatalogOption.fromJson({'code': 'BLU', 'name': 'Blue'});
    expect(option.code, 'BLU');
    expect(option.name, 'Blue');
  });
}
