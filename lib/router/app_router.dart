import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_providers.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/dashboard/joueur_dashboard_screen.dart';
import '../screens/performances/joueur_performances_screen.dart';
import '../screens/medical/joueur_medical_screen.dart';
import '../screens/planning/joueur_planning_screen.dart';
import '../screens/ai/joueur_ai_screen.dart';
import '../screens/profile/joueur_profile_screen.dart';
import '../screens/messages/messages_screen.dart';
import '../screens/squad/joueur_list_screen.dart';
import '../screens/squad/joueur_compare_screen.dart';
import '../screens/squad/joueur_formation_screen.dart';
import '../screens/squad/joueur_chemistry_screen.dart';
import '../screens/transfers/joueur_transfers_screen.dart';
import '../screens/documents/joueur_documents_screen.dart';
import '../screens/training/joueur_training_screen.dart';
import '../screens/analysis/joueur_analysis_screen.dart';
import '../screens/awards/joueur_awards_screen.dart';
import '../screens/menu/menu_screen.dart';
import '../screens/viiv/viiv_smartwatch_screen.dart';
import '../screens/viiv/viiv_scan_screen.dart';
import '../screens/analyste/analyste_dashboard_screen.dart';
import '../screens/analyste/analyste_live_screen.dart';
import '../screens/analyste/analyste_ppi_screen.dart';
import '../screens/analyste/analyste_menu_screen.dart';
import '../screens/analyste/analyste_module_screen.dart';
import '../screens/analyste/analyste_prediction_screen.dart';
import '../screens/analyste/analyste_chemistry_screen.dart';
import '../screens/analyste/analyste_patterns_screen.dart';
import '../screens/analyste/analyste_fatigue_screen.dart';
import '../screens/analyste/analyste_injuries_screen.dart';
import '../screens/analyste/analyste_opponent_screen.dart';
import '../shell/player_shell.dart';
import '../shell/analyste_shell.dart';
import '../shell/scout_shell.dart';
import '../screens/scout/scout_dashboard_screen.dart';
import '../screens/scout/scout_map_screen.dart';
import '../screens/scout/scout_search_screen.dart';
import '../screens/scout/scout_watchlist_screen.dart';
import '../screens/scout/scout_menu_screen.dart';
import '../screens/scout/scout_prospects_screen.dart';
import '../screens/scout/scout_prospect_screen.dart';
import '../screens/scout/scout_workflow_screen.dart';
import '../screens/scout/scout_report_screen.dart';
import '../screens/scout/scout_reports_screen.dart';
import '../screens/scout/scout_missions_screen.dart';
import '../screens/scout/scout_ai_screen.dart';
import '../screens/scout/scout_agents_screen.dart';
import '../screens/scout/scout_shortlist_screen.dart';
import '../screens/scout/scout_settings_screen.dart';
final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _playerShellKey = GlobalKey<NavigatorState>(debugLabel: 'playerShell');

CustomTransitionPage<void> _fadeSlidePage({
  required LocalKey key,
  required Widget child,
  SharedAxisTransitionType type = SharedAxisTransitionType.horizontal,
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: 350.ms,
    reverseTransitionDuration: 280.ms,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SharedAxisTransition(
        animation: animation,
        secondaryAnimation: secondaryAnimation,
        transitionType: type,
        child: child,
      );
    },
  );
}

GoRouter createRouter(AuthProvider auth, AuthSessionNotifier sessionNotifier) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: sessionNotifier,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final loggedIn = auth.isAuthenticated;
      final user = auth.user;
      const public = {'/splash', '/onboarding', '/login'};

      if (!loggedIn) {
        return public.contains(loc) ? null : '/login';
      }

      // Connecté → quitter les écrans publics
      if (public.contains(loc)) {
        return user?.homeRoute ?? '/';
      }

      if (user == null) return '/login';

      final onAnalyste = loc == '/analyste' || loc.startsWith('/analyste/');
      final onScout = loc == '/scout' || loc.startsWith('/scout/');

      if (user.isAnalyste && !onAnalyste) return '/analyste';
      if (!user.isAnalyste && onAnalyste) return user.homeRoute;

      if (user.isScout && !onScout) return '/scout';
      if (!user.isScout && onScout) return user.homeRoute;

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (_, state) => _fadeSlidePage(
          key: state.pageKey,
          child: const SplashScreen(),
          type: SharedAxisTransitionType.scaled,
        ),
      ),
      GoRoute(
        path: '/onboarding',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (_, state) => _fadeSlidePage(
          key: state.pageKey,
          child: const OnboardingScreen(),
          type: SharedAxisTransitionType.scaled,
        ),
      ),
      GoRoute(
        path: '/login',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (_, state) => _fadeSlidePage(
          key: state.pageKey,
          child: const LoginScreen(),
          type: SharedAxisTransitionType.scaled,
        ),
      ),

      // ── Joueur ───────────────────────────────────────────────────────────
      ShellRoute(
        navigatorKey: _playerShellKey,
        builder: (context, state, child) => PlayerShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (_, state) =>
                _fadeSlidePage(key: state.pageKey, child: const JoueurDashboardScreen()),
          ),
          GoRoute(
            path: '/performances',
            pageBuilder: (_, state) =>
                _fadeSlidePage(key: state.pageKey, child: const JoueurPerformancesScreen()),
          ),
          GoRoute(
            path: '/planning',
            pageBuilder: (_, state) =>
                _fadeSlidePage(key: state.pageKey, child: const JoueurPlanningScreen()),
          ),
          GoRoute(
            path: '/ai',
            pageBuilder: (_, state) =>
                _fadeSlidePage(key: state.pageKey, child: const JoueurAiScreen()),
          ),
          GoRoute(
            path: '/menu',
            pageBuilder: (_, state) =>
                _fadeSlidePage(key: state.pageKey, child: const MenuScreen()),
          ),
          GoRoute(
            path: '/medical',
            pageBuilder: (_, state) =>
                _fadeSlidePage(key: state.pageKey, child: const JoueurMedicalScreen()),
          ),
          GoRoute(
            path: '/profil',
            pageBuilder: (_, state) =>
                _fadeSlidePage(key: state.pageKey, child: const JoueurProfileScreen()),
          ),
          GoRoute(
            path: '/messages',
            pageBuilder: (_, state) =>
                _fadeSlidePage(key: state.pageKey, child: const MessagesScreen()),
          ),
          GoRoute(
            path: '/liste',
            pageBuilder: (_, state) =>
                _fadeSlidePage(key: state.pageKey, child: const JoueurListScreen()),
          ),
          GoRoute(
            path: '/comparer',
            pageBuilder: (_, state) =>
                _fadeSlidePage(key: state.pageKey, child: const JoueurCompareScreen()),
          ),
          GoRoute(
            path: '/formation',
            pageBuilder: (_, state) =>
                _fadeSlidePage(key: state.pageKey, child: const JoueurFormationScreen()),
          ),
          GoRoute(
            path: '/transferts',
            pageBuilder: (_, state) =>
                _fadeSlidePage(key: state.pageKey, child: const JoueurTransfersScreen()),
          ),
          GoRoute(
            path: '/documents',
            pageBuilder: (_, state) =>
                _fadeSlidePage(key: state.pageKey, child: const JoueurDocumentsScreen()),
          ),
          GoRoute(
            path: '/entrainement',
            pageBuilder: (_, state) =>
                _fadeSlidePage(key: state.pageKey, child: const JoueurTrainingScreen()),
          ),
          GoRoute(
            path: '/analyse',
            pageBuilder: (_, state) =>
                _fadeSlidePage(key: state.pageKey, child: const JoueurAnalysisScreen()),
          ),
          GoRoute(
            path: '/recompenses',
            pageBuilder: (_, state) =>
                _fadeSlidePage(key: state.pageKey, child: const JoueurAwardsScreen()),
          ),
          GoRoute(
            path: '/chimie',
            pageBuilder: (_, state) =>
                _fadeSlidePage(key: state.pageKey, child: const JoueurChemistryScreen()),
          ),
          GoRoute(
            path: '/viiv',
            pageBuilder: (_, state) =>
                _fadeSlidePage(key: state.pageKey, child: const ViivSmartwatchScreen()),
          ),
          GoRoute(
            path: '/viiv/scan',
            pageBuilder: (_, state) =>
                _fadeSlidePage(key: state.pageKey, child: const ViivScanScreen()),
          ),
        ],
      ),

      // ── Analyste: routes flat (siblings) — nesting + parentNavigatorKey
      // breake `/analyste` (GoException: no routes for location).
      ..._analysteFlatRoutes(),

      // ── Scout: same flat pattern as analyste
      ..._scoutFlatRoutes(),
    ],
  );
}

List<RouteBase> _analysteFlatRoutes() {
  Widget shell(Widget child) => AnalysteShell(child: child);

  return [
    GoRoute(
      path: '/analyste',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (_, state) => _fadeSlidePage(
        key: state.pageKey,
        child: shell(const AnalysteDashboardScreen()),
      ),
    ),
    GoRoute(
      path: '/analyste/live',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (_, state) => _fadeSlidePage(
        key: state.pageKey,
        child: shell(const AnalysteLiveScreen()),
      ),
    ),
    GoRoute(
      path: '/analyste/ppi',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (_, state) => _fadeSlidePage(
        key: state.pageKey,
        child: shell(const AnalystePpiScreen()),
      ),
    ),
    GoRoute(
      path: '/analyste/viiv',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (_, state) => _fadeSlidePage(
        key: state.pageKey,
        child: shell(const ViivSmartwatchScreen()),
      ),
    ),
    GoRoute(
      path: '/analyste/viiv/scan',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (_, state) => _fadeSlidePage(
        key: state.pageKey,
        child: shell(const ViivScanScreen()),
      ),
    ),
    GoRoute(
      path: '/analyste/modules',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (_, state) => _fadeSlidePage(
        key: state.pageKey,
        child: shell(const AnalysteMenuScreen()),
      ),
    ),
    GoRoute(
      path: '/analyste/prediction',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (_, state) => _fadeSlidePage(
        key: state.pageKey,
        child: shell(const AnalystePredictionScreen()),
      ),
    ),
    GoRoute(
      path: '/analyste/chemistry',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (_, state) => _fadeSlidePage(
        key: state.pageKey,
        child: shell(const AnalysteChemistryScreen()),
      ),
    ),
    GoRoute(
      path: '/analyste/patterns',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (_, state) => _fadeSlidePage(
        key: state.pageKey,
        child: shell(const AnalystePatternsScreen()),
      ),
    ),
    GoRoute(
      path: '/analyste/fatigue',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (_, state) => _fadeSlidePage(
        key: state.pageKey,
        child: shell(const AnalysteFatigueScreen()),
      ),
    ),
    GoRoute(
      path: '/analyste/blessures',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (_, state) => _fadeSlidePage(
        key: state.pageKey,
        child: shell(const AnalysteInjuriesScreen()),
      ),
    ),
    GoRoute(
      path: '/analyste/adversaire',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (_, state) => _fadeSlidePage(
        key: state.pageKey,
        child: shell(const AnalysteOpponentScreen()),
      ),
    ),
    GoRoute(
      path: '/analyste/executive',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (_, state) => _fadeSlidePage(
        key: state.pageKey,
        child: shell(
          AnalysteModuleScreen(
            title: 'Executive',
            subtitle: 'KPIs direction',
            accent: const Color(0xFF22C55E),
            loader: (p) => p.api.getExecutive(),
          ),
        ),
      ),
    ),
  ];
}

int shellIndexForLocation(String location) {
  if (location.startsWith('/performances')) return 1;
  if (location.startsWith('/planning')) return 2;
  if (location.startsWith('/ai')) return 3;
  if (location.startsWith('/menu')) return 4;
  return 0;
}

void goToShellTab(BuildContext context, int index) {
  const paths = ['/', '/performances', '/planning', '/ai', '/menu'];
  context.go(paths[index]);
}

int analysteShellIndexForLocation(String location) {
  if (location.startsWith('/analyste/live')) return 1;
  if (location.startsWith('/analyste/ppi')) return 2;
  if (location.startsWith('/analyste/viiv')) return 3;
  if (location != '/analyste' && location.startsWith('/analyste/')) return 4;
  return 0;
}

void goToAnalysteShellTab(BuildContext context, int index) {
  const paths = [
    '/analyste',
    '/analyste/live',
    '/analyste/ppi',
    '/analyste/viiv',
    '/analyste/modules',
  ];
  context.go(paths[index]);
}

List<RouteBase> _scoutFlatRoutes() {
  Widget shell(Widget child) => ScoutShell(child: child);

  return [
    GoRoute(
      path: '/scout',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (_, state) => _fadeSlidePage(
        key: state.pageKey,
        child: shell(const ScoutDashboardScreen()),
      ),
    ),
    GoRoute(
      path: '/scout/map',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (_, state) => _fadeSlidePage(
        key: state.pageKey,
        child: shell(const ScoutMapScreen()),
      ),
    ),
    GoRoute(
      path: '/scout/search',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (_, state) => _fadeSlidePage(
        key: state.pageKey,
        child: shell(const ScoutSearchScreen()),
      ),
    ),
    GoRoute(
      path: '/scout/watchlist',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (_, state) => _fadeSlidePage(
        key: state.pageKey,
        child: shell(const ScoutWatchlistScreen()),
      ),
    ),
    GoRoute(
      path: '/scout/modules',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (_, state) => _fadeSlidePage(
        key: state.pageKey,
        child: shell(const ScoutMenuScreen()),
      ),
    ),
    GoRoute(
      path: '/scout/prospects',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (_, state) => _fadeSlidePage(
        key: state.pageKey,
        child: shell(const ScoutProspectsScreen()),
      ),
    ),
    GoRoute(
      path: '/scout/prospect/:id',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (_, state) => _fadeSlidePage(
        key: state.pageKey,
        child: shell(ScoutProspectRouteScreen(state: state)),
      ),
    ),
    GoRoute(
      path: '/scout/workflow',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (_, state) => _fadeSlidePage(
        key: state.pageKey,
        child: shell(const ScoutWorkflowScreen()),
      ),
    ),
    GoRoute(
      path: '/scout/report',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (_, state) => _fadeSlidePage(
        key: state.pageKey,
        child: shell(ScoutReportRouteScreen(state: state)),
      ),
    ),
    GoRoute(
      path: '/scout/reports',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (_, state) => _fadeSlidePage(
        key: state.pageKey,
        child: shell(const ScoutReportsScreen()),
      ),
    ),
    GoRoute(
      path: '/scout/missions',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (_, state) => _fadeSlidePage(
        key: state.pageKey,
        child: shell(const ScoutMissionsScreen()),
      ),
    ),
    GoRoute(
      path: '/scout/ai',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (_, state) => _fadeSlidePage(
        key: state.pageKey,
        child: shell(const ScoutAiScreen()),
      ),
    ),
    GoRoute(
      path: '/scout/agents',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (_, state) => _fadeSlidePage(
        key: state.pageKey,
        child: shell(const ScoutAgentsScreen()),
      ),
    ),
    GoRoute(
      path: '/scout/shortlist',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (_, state) => _fadeSlidePage(
        key: state.pageKey,
        child: shell(const ScoutShortlistScreen()),
      ),
    ),
    GoRoute(
      path: '/scout/settings',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (_, state) => _fadeSlidePage(
        key: state.pageKey,
        child: shell(const ScoutSettingsScreen()),
      ),
    ),
  ];
}

int scoutShellIndexForLocation(String location) {
  if (location.startsWith('/scout/map')) return 1;
  if (location.startsWith('/scout/search')) return 2;
  if (location.startsWith('/scout/watchlist')) return 3;
  if (location != '/scout' && location.startsWith('/scout/')) return 4;
  return 0;
}

void goToScoutShellTab(BuildContext context, int index) {
  const paths = [
    '/scout',
    '/scout/map',
    '/scout/search',
    '/scout/watchlist',
    '/scout/modules',
  ];
  context.go(paths[index]);
}
