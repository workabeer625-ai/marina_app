# MARINA Flutter application

Customer and responsive administration client for the MARINA platform.

```powershell
flutter pub get
flutter run --dart-define=API_URL=https://your-api/api/v1
```

The default Android-emulator URL is `https://10.0.2.2:7044/api/v1`. Authentication tokens are stored with `flutter_secure_storage`; cart, catalog, account, orders, returns, notifications, and administration data come from the API.
