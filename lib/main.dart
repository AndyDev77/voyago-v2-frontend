import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/storage_service.dart';
import 'providers/auth_provider.dart';
import 'router.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.instance.init();
  runApp(const ProviderScope(child: VoyagoApp()));
}

class VoyagoApp extends ConsumerStatefulWidget {
  const VoyagoApp({super.key});

  @override
  ConsumerState<VoyagoApp> createState() => _VoyagoAppState();
}

class _VoyagoAppState extends ConsumerState<VoyagoApp> {
  @override
  void initState() {
    super.initState();
    // Load session on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).loadSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Voyago',
      theme: voyagoTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
