import 'package:flutter_test/flutter_test.dart';
import 'package:marina_app/core/network/media_url_resolver.dart';

void main() {
  test('resolves backend-relative media against API origin', () {
    expect(
      MediaUrlResolver.resolve(
        '/uploads/demo-shoes-1.jpg',
        apiBaseUrl: 'http://localhost:5199/api/v1',
      ),
      'http://localhost:5199/uploads/demo-shoes-1.jpg',
    );
  });
  test('preserves production absolute media URLs', () {
    expect(
      MediaUrlResolver.resolve(
        'https://cdn.example.com/p/1.webp',
        apiBaseUrl: 'https://api.example.com/api/v1',
      ),
      'https://cdn.example.com/p/1.webp',
    );
  });
}
