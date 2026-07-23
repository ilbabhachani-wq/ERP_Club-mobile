import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/odin_theme.dart';
import 'package:go_router/go_router.dart';
import 'providers/app_providers.dart';
import 'providers/viiv_provider.dart';
import 'router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr');
  await initializeDateFormatting('en');
  await initializeDateFormatting('ar');
  runApp(const ErpClubPlayerApp());
}

class ErpClubPlayerApp extends StatefulWidget {
  const ErpClubPlayerApp({super.key});

  @override
  State<ErpClubPlayerApp> createState() => _ErpClubPlayerAppState();
}

class _ErpClubPlayerAppState extends State<ErpClubPlayerApp> {
  late final AuthProvider _auth;
  late final AuthSessionNotifier _sessionNotifier;
  late final JoueurDataProvider _joueurData;
  late final ViivProvider _viiv;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _auth = AuthProvider();
    _sessionNotifier = AuthSessionNotifier(_auth);
    _joueurData = JoueurDataProvider(_auth.api);
    _viiv = ViivProvider(_auth.api);
    _router = createRouter(_auth, _sessionNotifier);
  }

  @override
  void dispose() {
    _sessionNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _auth),
        ChangeNotifierProvider.value(value: _joueurData),
        ChangeNotifierProvider.value(value: _viiv),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: MaterialApp.router(
        title: 'ODIN ERP — Joueur',
        debugShowCheckedModeBanner: false,
        theme: OdinTheme.dark(),
        routerConfig: _router,
      ),
    );
  }
}
