import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/odin_colors.dart';
import 'core/theme/odin_theme.dart';
import 'package:go_router/go_router.dart';
import 'providers/app_providers.dart';
import 'providers/analyste_provider.dart';
import 'providers/avatar_provider.dart';
import 'providers/medecin_provider.dart';
import 'providers/coach_provider.dart';
import 'providers/preparateur_provider.dart';
import 'providers/responsable_provider.dart';
import 'providers/scout_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/viiv_provider.dart';
import 'router/app_router.dart';
import 'services/medecin_api.dart';
import 'services/coach_api.dart';

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
  late final PreparateurDataProvider _preparateurData;
  late final MedecinProvider _medecinData;
  late final CoachProvider _coachData;
  late final ResponsableDataProvider _responsableData;
  late final ViivProvider _viiv;
  late final AvatarProvider _avatar;
  late final ThemeProvider _theme;
  late final LocaleProvider _locale;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _auth = AuthProvider();
    _sessionNotifier = AuthSessionNotifier(_auth);
    _joueurData = JoueurDataProvider(_auth.api);
    _analysteData = AnalysteDataProvider(_auth.api);
    _scoutData = ScoutDataProvider(_auth.api);
    _preparateurData = PreparateurDataProvider(_auth.api);
    _medecinData = MedecinProvider(MedecinApi(_auth.api));
    _coachData = CoachProvider(CoachApi(_auth.api));
    _responsableData = ResponsableDataProvider(_auth.api);
    _viiv = ViivProvider(_auth.api);
    _avatar = AvatarProvider();
    _theme = ThemeProvider();
    _locale = LocaleProvider();
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
        ChangeNotifierProvider.value(value: _preparateurData),
        ChangeNotifierProvider.value(value: _medecinData),
        ChangeNotifierProvider.value(value: _coachData),
        ChangeNotifierProvider.value(value: _responsableData),
        ChangeNotifierProvider.value(value: _viiv),
        ChangeNotifierProvider.value(value: _avatar),
        ChangeNotifierProvider.value(value: _theme),
        ChangeNotifierProvider.value(value: _locale),
      ],
      child: Consumer2<ThemeProvider, LocaleProvider>(
        builder: (context, theme, locale, _) {
          // Apply palette BEFORE the tree builds so OdinColors getters are correct
          // on the first frame after a theme toggle (no need to change screen).
          final mode = theme.mode;
          if (mode == ThemeMode.light) {
            OdinColors.apply(OdinPalette.light);
          } else if (mode == ThemeMode.dark) {
            OdinColors.apply(OdinPalette.dark);
          }

          return MaterialApp.router(
            title: 'ODIN ERP',
            debugShowCheckedModeBanner: false,
            theme: OdinTheme.light(),
            darkTheme: OdinTheme.dark(),
            themeMode: mode,
            locale: locale.flutterLocale,
            supportedLocales: const [
              Locale('fr'),
              Locale('en'),
              Locale('ar'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            routerConfig: _router,
            builder: (context, child) {
              final brightness = Theme.of(context).brightness;
              OdinColors.applyBrightness(brightness);
              theme.applyOverlay(context);
              // Force a full subtree rebuild when theme or locale changes so every
              // widget reading OdinColors / AppColors / DateFormat refreshes immediately.
              return KeyedSubtree(
                key: ValueKey('skin-${mode.name}-$brightness-${locale.locale}'),
                child: Directionality(
                  textDirection: locale.locale == 'ar' ? TextDirection.rtl : TextDirection.ltr,
                  child: child ?? const SizedBox.shrink(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
