import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'services/storage_service.dart';
import 'router.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);
  await initializeDateFormatting('fr', null);
  await StorageService.instance.init();
  runApp(const ProviderScope(child: VoyagoApp()));
}

class VoyagoApp extends ConsumerWidget {
  const VoyagoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Voyago',
      theme: voyagoTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
