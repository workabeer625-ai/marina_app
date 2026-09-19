import '../../../core/network/api_models.dart';
import '../../../shared/widgets/page_controls.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../products/domain/product.dart';

class CustomerProfile {
  const CustomerProfile({
    required this.id,
    required this.email,
    required this.displayName,
    this.phone,
  });
  final String id, email, displayName;
  final String? phone;

  factory CustomerProfile.fromJson(Map<String, dynamic> json) =>
      CustomerProfile(
        id: json['id'].toString(),
        email: (json['email'] ?? '').toString(),
        displayName: (json['displayName'] ?? '').toString(),
        phone: json['phoneNumber']?.toString(),
      );
}

class CustomerAddress {
  const CustomerAddress({
    required this.id,
    required this.label,
    required this.recipient,
    required this.phone,
    required this.city,
    required this.line1,
    required this.isDefault,
    this.postalCode,
  });
  final String id, label, recipient, phone, city, line1;
  final bool isDefault;
  final String? postalCode;

  factory CustomerAddress.fromJson(Map<String, dynamic> json) =>
      CustomerAddress(
        id: json['id'].toString(),
        label: (json['label'] ?? '').toString(),
        recipient: (json['recipient'] ?? '').toString(),
        phone: (json['phone'] ?? '').toString(),
        city: (json['city'] ?? '').toString(),
        line1: (json['line1'] ?? '').toString(),
        postalCode: json['postalCode']?.toString(),
        isDefault: json['isDefault'] == true,
      );

  Map<String, dynamic> toJson() => {
    'label': label,
    'recipient': recipient,
    'phone': phone,
    'city': city,
    'line1': line1,
    'postalCode': postalCode,
    'isDefault': isDefault,
  };
}

class CustomerNotification {
  const CustomerNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdUtc,
    this.deepLink,
    this.readUtc,
  });
  final String id, title, body;
  final String? deepLink;
  final DateTime createdUtc;
  final DateTime? readUtc;

  factory CustomerNotification.fromJson(Map<String, dynamic> json) =>
      CustomerNotification(
        id: json['id'].toString(),
        title: (json['title'] ?? '').toString(),
        body: (json['body'] ?? '').toString(),
        deepLink: json['deepLink']?.toString(),
        createdUtc:
            DateTime.tryParse((json['createdUtc'] ?? '').toString()) ??
            DateTime.now(),
        readUtc: DateTime.tryParse((json['readUtc'] ?? '').toString()),
      );
}

class CustomerRepository {
  CustomerRepository(this.client);
  final ApiClient client;

  Future<CustomerProfile> profile() async => CustomerProfile.fromJson(
    (await client.dio.get('/customer/profile')).data as Map<String, dynamic>,
  );

  Future<void> updateProfile(String displayName, String? phone) async =>
      client.dio.put(
        '/customer/profile',
        data: {'displayName': displayName, 'phone': phone},
      );

  Future<List<CustomerAddress>> addresses() async =>
      ((await client.dio.get('/customer/addresses')).data as List)
          .map((x) => CustomerAddress.fromJson(x as Map<String, dynamic>))
          .toList();

  Future<void> saveAddress(CustomerAddress address) async {
    if (address.id.isEmpty) {
      await client.dio.post('/customer/addresses', data: address.toJson());
    } else {
      await client.dio.put(
        '/customer/addresses/${address.id}',
        data: address.toJson(),
      );
    }
  }

  Future<void> deleteAddress(String id) async =>
      client.dio.delete('/customer/addresses/$id');

  Future<List<Product>> favorites(String culture) async =>
      ((await client.dio.get(
                '/customer/favorites',
                queryParameters: {'culture': culture},
              )).data
              as List)
          .map((x) => Product.fromJson(x as Map<String, dynamic>))
          .toList();

  Future<void> removeFavorite(String productId) async =>
      client.dio.delete('/customer/favorites/$productId');

  Future<void> addFavorite(String productId) async =>
      client.dio.post('/customer/favorites/$productId');

  Future<ApiPage<CustomerNotification>> notifications({int page = 1}) async => ApiPage.fromJson(
    (await client.dio.get('/customer/notifications', queryParameters: {'page': page, 'pageSize': 20})).data,
    CustomerNotification.fromJson,
  );

  Future<void> readNotification(String id) async =>
      client.dio.post('/customer/notifications/$id/read');

  Future<void> readAllNotifications() async =>
      client.dio.post('/customer/notifications/read-all');
}

final customerRepositoryProvider = Provider(
  (_) => CustomerRepository(apiClient),
);
final customerProfileProvider = FutureProvider<CustomerProfile>(
  (ref) => ref.watch(customerRepositoryProvider).profile(),
);
final customerAddressesProvider = FutureProvider<List<CustomerAddress>>(
  (ref) => ref.watch(customerRepositoryProvider).addresses(),
);
final customerFavoritesProvider = FutureProvider.family<List<Product>, String>(
  (ref, culture) => ref.watch(customerRepositoryProvider).favorites(culture),
);
final customerNotificationsProvider =
    FutureProvider<ApiPage<CustomerNotification>>(
      (ref) => ref.watch(customerRepositoryProvider).notifications(page: ref.watch(pageSelectionProvider('/customer/notifications'))),
    );
