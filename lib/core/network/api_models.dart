enum ApiOrderStatus {
  pending, confirmed, preparing, ready, shipped, outForDelivery,
  delivered, cancelled, returned, refunded;

  String get wireName => name[0].toUpperCase() + name.substring(1);
  static ApiOrderStatus parse(Object? value) => values.firstWhere(
    (status) => status.wireName == value,
    orElse: () => throw FormatException('Unknown order status: $value'),
  );
}

enum ApiDiscountType {
  percentage, fixedAmount;

  String get wireName => name[0].toUpperCase() + name.substring(1);
  static ApiDiscountType parse(Object? value) => values.firstWhere(
    (type) => type.wireName == value,
    orElse: () => throw FormatException('Unknown discount type: $value'),
  );
}

class ApiPage<T> {
  const ApiPage({required this.items, required this.page, required this.pageSize, required this.total});
  final List<T> items;
  final int page, pageSize, total;
  bool get hasMore => page * pageSize < total;

  factory ApiPage.fromJson(Object? value, T Function(Map<String, dynamic>) decode) {
    final json = value as Map<String, dynamic>;
    return ApiPage(
      items: (json['items'] as List).map((item) => decode(item as Map<String, dynamic>)).toList(),
      page: (json['page'] as num).toInt(),
      pageSize: (json['pageSize'] as num).toInt(),
      total: (json['total'] as num).toInt(),
    );
  }
}
