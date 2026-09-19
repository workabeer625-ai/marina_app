import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart';

class CartLine {
  const CartLine({
    required this.id,
    required this.variantId,
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.available,
    this.sku,
    this.image,
    this.color,
    this.size,
  });

  final String id, variantId, productId, name;
  final String? sku, image, color, size;
  final double price;
  final int quantity, available;

  factory CartLine.fromJson(Map<String, dynamic> json) => CartLine(
    id: json['id'].toString(),
    variantId: json['variantId'].toString(),
    productId: json['productId'].toString(),
    name: (json['name'] ?? '').toString(),
    sku: json['sku']?.toString(),
    image: json['image']?.toString(),
    color: json['color']?.toString(),
    size: json['size']?.toString(),
    price: (json['price'] as num?)?.toDouble() ?? 0,
    quantity: (json['quantity'] as num?)?.toInt() ?? 0,
    available: (json['available'] as num?)?.toInt() ?? 0,
  );
}

class CartQuote {
  const CartQuote({
    required this.subtotal,
    required this.discount,
    required this.shipping,
    required this.tax,
    required this.total,
    this.couponCode,
  });

  final double subtotal, discount, shipping, tax, total;
  final String? couponCode;

  factory CartQuote.fromJson(Map<String, dynamic> json) => CartQuote(
    subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
    discount: (json['discount'] as num?)?.toDouble() ?? 0,
    shipping: (json['shipping'] as num?)?.toDouble() ?? 0,
    tax: (json['tax'] as num?)?.toDouble() ?? 0,
    total: (json['total'] as num?)?.toDouble() ?? 0,
    couponCode: json['couponCode']?.toString(),
  );
}

class CartSnapshot {
  const CartSnapshot({required this.items, required this.subtotal, this.quote});
  final List<CartLine> items;
  final double subtotal;
  final CartQuote? quote;

  CartSnapshot copyWith({CartQuote? quote}) =>
      CartSnapshot(items: items, subtotal: subtotal, quote: quote);

  factory CartSnapshot.fromJson(Map<String, dynamic> json) => CartSnapshot(
    items: (json['items'] as List? ?? const [])
        .map((x) => CartLine.fromJson(x as Map<String, dynamic>))
        .toList(),
    subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
  );
}

class CartRepository {
  const CartRepository(this.client);
  final ApiClient client;

  Future<CartSnapshot> getCart() async => CartSnapshot.fromJson(
    (await client.dio.get('/cart')).data as Map<String, dynamic>,
  );

  Future<void> add(String variantId, {int quantity = 1}) => client.dio.post(
    '/cart/items',
    data: {'variantId': variantId, 'quantity': quantity},
  );

  Future<void> update(String itemId, int quantity) =>
      client.dio.put('/cart/items/$itemId', data: {'quantity': quantity});

  Future<void> clear() => client.dio.delete('/cart');

  Future<void> remove(String itemId) =>
      client.dio.delete('/cart/items/$itemId');

  Future<CartQuote> quote(String? couponCode) async => CartQuote.fromJson(
    (await client.dio.post(
          '/cart/quote',
          data: {'couponCode': couponCode?.trim()},
        )).data
        as Map<String, dynamic>,
  );
}

final cartRepositoryProvider = Provider((_) => CartRepository(apiClient));

class CartController extends AsyncNotifier<CartSnapshot> {
  CartRepository get _repository => ref.read(cartRepositoryProvider);

  @override
  Future<CartSnapshot> build() => _repository.getCart();

  Future<void> refreshCart() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_repository.getCart);
  }

  Future<void> add(String variantId) async {
    await _repository.add(variantId);
    state = AsyncData(await _repository.getCart());
  }

  Future<void> updateLine(CartLine line, int quantity) async {
    if (quantity <= 0) {
      await remove(line.id);
      return;
    }
    await _repository.update(line.id, quantity);
    state = AsyncData(await _repository.getCart());
  }

  Future<void> remove(String itemId) async {
    await _repository.remove(itemId);
    state = AsyncData(await _repository.getCart());
  }

  Future<CartQuote> applyCoupon(String? couponCode) async {
    final quote = await _repository.quote(couponCode);
    final current = state.value;
    if (current != null) state = AsyncData(current.copyWith(quote: quote));
    return quote;
  }

  Future<void> clear() async {
    await _repository.clear();
    state = AsyncData(await _repository.getCart());
  }

  Future<void> clearAfterOrder() => refreshCart();
}

final cartProvider = AsyncNotifierProvider<CartController, CartSnapshot>(
  CartController.new,
);
