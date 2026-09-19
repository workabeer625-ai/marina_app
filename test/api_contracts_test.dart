import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marina_app/core/network/api_client.dart';
import 'package:marina_app/core/network/api_models.dart';
import 'package:marina_app/core/state/commerce_state.dart';
import 'package:marina_app/features/auth/data/auth_repository.dart';
import 'package:marina_app/features/commerce/data/post_purchase_repository.dart';
import 'package:marina_app/main.dart';

class RecordingAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? stream, Future<void>? cancel) async {
    requests.add(options);
    return ResponseBody.fromString('', 204);
  }
  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('mutation repositories send JSON object contracts', () async {
    final client = ApiClient(baseUrl: 'https://test.invalid/api/v1');
    final adapter = RecordingAdapter();
    client.dio.httpClientAdapter = adapter;
    await AuthRepository(client).forgotPassword('a@example.test');
    await AuthRepository(client).resendVerification('a@example.test');
    await CartRepository(client).update('item-id', 2);
    await PostPurchaseRepository(client).cancelOrder('order-id', 'Changed mind');
    expect(adapter.requests.map((x) => x.data), [
      {'email': 'a@example.test'}, {'email': 'a@example.test'},
      {'quantity': 2}, {'reason': 'Changed mind'},
    ]);
    expect(adapter.requests.every((x) => x.contentType == Headers.jsonContentType), isTrue);
  });

  test('admin enums and page envelope match actual server responses', () {
    expect(ApiOrderStatus.parse('Preparing'), ApiOrderStatus.preparing);
    expect(ApiDiscountType.parse('Percentage'), ApiDiscountType.percentage);
    final page = ApiPage<Map<String, dynamic>>.fromJson(
      {'items': [{'delta': 2}], 'page': 1, 'pageSize': 1, 'total': 2}, (x) => x);
    expect(page.items.single['delta'], 2);
    expect(page.hasMore, isTrue);
    expect(() => ApiOrderStatus.parse('Unexpected'), throwsFormatException);
  });

  testWidgets('account boundary disposes cached private providers before showing B', (tester) async {
    var account = 'A';
    final privateData = Provider((ref) => 'Private data for $account');
    Map<String, dynamic> tokens(String id) => {
      'accessToken': 'header.${base64Url.encode(utf8.encode(jsonEncode({'sub': id, 'session_id': id})))}.signature',
      'refreshToken': 'test-refresh-$id',
    };
    await apiClient.saveSession(tokens('A'));
    await tester.pumpWidget(AccountScope(child: MaterialApp(home: Consumer(
      builder: (_, ref, _) => Text(ref.watch(privateData)),
    ))));
    expect(find.text('Private data for A'), findsOneWidget);
    await apiClient.clearSession();
    account = 'B';
    await apiClient.saveSession(tokens('B'));
    await tester.pump();
    expect(find.text('Private data for A'), findsNothing);
    expect(find.text('Private data for B'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await apiClient.clearSession();
  });
}
