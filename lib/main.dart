import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/odin_theme.dart';
import 'package:go_router/go_router.dart';
import 'providers/app_providers.dart';
import 'providers/analyste_provider.dart';
import 'providers/avatar_provider.dart';
import 'providers/scout_provider.dart';
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
  late final AnalysteDataProvider _analysteData;
  late final ScoutDataProvider _scoutData;
  late final ViivProvider _viiv;
  late final AvatarProvider _avatar;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _auth = AuthProvider();
    _sessionNotifier = AuthSessionNotifier(_auth);
    _joueurData = JoueurDataProvider(_auth.api);
    _analysteData = AnalysteDataProvider(_auth.api);
    _scoutData = ScoutDataProvider(_auth.api);
    _viiv = ViivProvider(_auth.api);
    _avatar = AvatarProvider();
    _router = createRouter(_auth, _sessionNotifier);
    _auth.addListener(_syncAvatarUser);
  }

  void _syncAvatarUser() {
    _avatar.bindUser(_auth.user?.email);
  }

  @override
  void dispose() {
    _auth.removeListener(_syncAvatarUser);
    _sessionNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _auth),
        ChangeNotifierProvider.value(value: _joueurData),
        ChangeNotifierProvider.value(value: _analysteData),
        ChangeNotifierProvider.value(value: _scoutData),
        ChangeNotifierProvider.value(value: _viiv),
        ChangeNotifierProvider.value(value: _avatar),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: MaterialApp.router(
        title: 'ODIN ERP Club',
        debugShowCheckedModeBanner: false,
        theme: OdinTheme.dark(),
        routerConfig: _router,
      ),
    );
  }
}
