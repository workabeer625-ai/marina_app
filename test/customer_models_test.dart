import 'package:flutter_test/flutter_test.dart';
import 'package:marina_app/features/profile/data/customer_repository.dart';

void main() {
  test('customer address round-trips the server contract', () {
    final address = CustomerAddress.fromJson({
      'id': 'address-1',
      'label': 'Home',
      'recipient': 'Sara',
      'phone': '+966500000000',
      'city': 'Riyadh',
      'line1': 'Olaya Street',
      'postalCode': '12345',
      'isDefault': true,
    });

    expect(address.isDefault, isTrue);
    expect(address.toJson()['city'], 'Riyadh');
    expect(address.toJson()['isDefault'], isTrue);
  });

  test('notification parses unread state and deep link', () {
    final notification = CustomerNotification.fromJson({
      'id': 'notification-1',
      'title': 'Order shipped',
      'body': 'Your order is on the way.',
      'deepLink': '/orders/order-1',
      'createdUtc': '2026-08-30T12:00:00Z',
      'readUtc': null,
    });

    expect(notification.readUtc, isNull);
    expect(notification.deepLink, '/orders/order-1');
  });
}
