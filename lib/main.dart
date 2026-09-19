import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/network/api_client.dart';

void main() => runApp(const AccountScope());

/// Replace the entire provider container at an account boundary. This includes
/// family providers and admin caches, so no previous-account value is retained.
class AccountScope extends StatelessWidget {
  const AccountScope({super.key, this.child = const MarinaApp()});
  final Widget child;
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
    valueListenable: apiClient.accountRevision,
    builder: (_, revision, _) => ProviderScope(
      key: ValueKey(revision),
      child: child,
    ),
  );
}