import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/odin_colors.dart';
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
import '../shell/preparateur_shell.dart';
import '../shell/responsable_shell.dart';
import '../shell/medecin_shell.dart';
import '../shell/coach_shell.dart';
import '../screens/coach/coach_dashboard_screen.dart';
import '../screens/coach/coach_entrainements_screen.dart';
import '../screens/coach/coach_presences_screen.dart';
import '../screens/coach/coach_composition_screen.dart';
import '../screens/coach/coach_analyse_match_screen.dart';
import '../screens/coach/coach_messages_screen.dart';
import '../screens/coach/coach_ai_screen.dart';
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
import '../screens/preparateur/prep_dashboard_screen.dart';
import '../screens/preparateur/prep_programmes_screen.dart';
import '../screens/preparateur/prep_charge_screen.dart';
import '../screens/preparateur/prep_condition_screen.dart';
import '../screens/preparateur/prep_notifications_screen.dart';
import '../screens/preparateur/prep_ai_screen.dart';
import '../screens/preparateur/prep_menu_screen.dart';
import '../screens/responsable/resp_dashboard_screen.dart';
import '../screens/responsable/resp_validation_screen.dart';
import '../screens/responsable/resp_notifications_screen.dart';
import '../screens/responsable/resp_teams_screen.dart';
import '../screens/responsable/resp_menu_screen.dart';
import '../screens/profile/staff_profile_screen.dart';
import '../screens/medecin/medecin_dashboard_screen.dart';
import '../screens/medecin/medecin_dossiers_screen.dart';
import '../screens/medecin/medecin_blessures_screen.dart';
import '../screens/medecin/medecin_traitements_screen.dart';
import '../screens/medecin/medecin_rendezvous_screen.dart';
import '../screens/medecin/medecin_ai_screen.dart';
import '../screens/staff/club_notifications_screen.dart';
final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _playerShellKey = GlobalKey<NavigatorState>(debugLabel: 'playerShell');
final GlobalKey<NavigatorState> _preparateurShellKey = GlobalKey<NavigatorState>(debugLabel: 'preparateurShell');
final GlobalKey<NavigatorState> _responsableShellKey = GlobalKey<NavigatorState>(debugLabel: 'responsableShell');
final GlobalKey<NavigatorState> _medecinShellKey =
    GlobalKey<NavigatorState>(debugLabel: 'medecinShell');
final GlobalKey<NavigatorState> _coachShellKey =
    GlobalKey<NavigatorState>(debugLabel: 'coachShell');

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

      // Stay on splash until it finishes restoring session + loading role data.
      // Otherwise GoRouter bounces to homeRoute with empty providers (cold start bug).
      if (loc == '/splash') return null;

      // Connecté → quitter login / onboarding
      if (loc == '/login' || loc == '/onboarding') {
        return user?.homeRoute ?? '/';
      }

      if (user == null) return '/login';

      final onAnalyste = loc == '/analyste' || loc.startsWith('/analyste/');
      final onScout = loc == '/scout' || loc.startsWith('/scout/');
      final onPreparateur = loc == '/preparateur' || loc.startsWith('/preparateur/');
      final onResponsable = loc == '/responsable' || loc.startsWith('/responsable/');
      final onMedecin = loc == '/medecin' || loc.startsWith('/medecin/');
      final onCoach = loc == '/coach' || loc.startsWith('/coach/');

      if (user.isAnalyste && !onAnalyste) return '/analyste';
      if (!user.isAnalyste && onAnalyste) return user.homeRoute;

      if (user.isScout && !onScout) return '/scout';
      if (!user.isScout && onScout) return user.homeRoute;

      if (user.isPreparateur && !onPreparateur) return '/preparateur';
      if (!user.isPreparateur && onPreparateur) return user.homeRoute;

      if (user.isResponsable && !onResponsable) return '/responsable';
      if (!user.isResponsable && onResponsable) return user.homeRoute;

      if (user.isMedecin && !onMedecin) return '/medecin';
      if (!user.isMedecin && onMedecin) return user.homeRoute;

      if (user.isCoach && !onCoach) return '/coach';
      if (!user.isCoach && onCoach) return user.homeRoute;

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

      // ── Médecin
      ShellRoute(
        navigatorKey: _medecinShellKey,
        builder: (context, state, child) => MedecinShell(child: child),
        routes: [
          GoRoute(
            path: '/medecin',
            pageBuilder: (_, state) =>
                _fadeSlidePage(key: state.pageKey, child: const MedecinDashboardScreen()),
          ),
          GoRoute(
            path: '/medecin/dossiers',
            pageBuilder: (_, state) =>
                _fadeSlidePage(key: state.pageKey, child: const MedecinDossiersScreen()),
          ),
          GoRoute(
            path: '/medecin/blessures',
            pageBuilder: (_, state) =>
                _fadeSlidePage(key: state.pageKey, child: const MedecinBlessuresScreen()),
          ),
          GoRoute(
            path: '/medecin/traitements',
            pageBuilder: (_, state) =>
                _fadeSlidePage(key: state.pageKey, child: const MedecinTraitementsScreen()),
          ),
          GoRoute(
            path: '/medecin/rendezvous',
            pageBuilder: (_, state) =>
                _fadeSlidePage(key: state.pageKey, child: const MedecinRendezVousScreen()),
          ),
          GoRoute(
            path: '/medecin/ia',
            pageBuilder: (_, state) =>
                _fadeSlidePage(key: state.pageKey, child: const MedecinAiScreen()),
          ),
          GoRoute(
            path: '/medecin/notifications',
            pageBuilder: (_, state) =>
                _fadeSlidePage(key: state.pageKey, child: const MedecinNotificationsScreen()),
          ),
          GoRoute(
            path: '/medecin/profil',
            pageBuilder: (_, state) => _fadeSlidePage(
              key: state.pageKey,
              child: const StaffProfileScreen(
                roleLabel: 'Médecin du club',
                accentColor: OdinColors.accent,
              ),
            ),
          ),
        ],
      ),

      // ── Coach
      ShellRoute(
        navigatorKey: _coachShellKey,
        builder: (context, state, child) => CoachShell(child: child),
        routes: [
          GoRoute(
            path: '/coach',
            pageBuilder: (_, state) =>
                _fadeSlidePage(key: state.pageKey, child: const CoachDashboardScreen()),
          ),
          GoRoute(
            path: '/coach/entrainements',
            pageBuilder: (_, state) =>
                _fadeSlidePage(key: state.pageKey, child: const CoachEntrainementsScreen()),
          ),
          GoRoute(
            path: '/coach/presences',
            pageBuilder: (_, state) =>
                _fadeSlidePage(key: state.pageKey, child: const CoachPresencesScreen()),
          ),
          GoRoute(
            path: '/coach/composition',
            pageBuilder: (_, state) =>
                _fadeSlidePage(key: state.pageKey, child: const CoachCompositionScreen()),
          ),
          GoRoute(
            path: '/coach/analyse-match',
            pageBuilder: (_, state) =>
                _fadeSlidePage(key: state.pageKey, child: const CoachAnalyseMatchScreen()),
          ),
          GoRoute(
            path: '/coach/ia',
            pageBuilder: (_, state) =>
                _fadeSlidePage(key: state.pageKey, child: const CoachAiScreen()),
          ),
          GoRoute(
            path: '/coach/messages',
            pageBuilder: (_, state) =>
                _fadeSlidePage(key: state.pageKey, child: const CoachMessagesScreen()),
          ),
          GoRoute(
            path: '/coach/notifications',
            pageBuilder: (_, state) =>
                _fadeSlidePage(key: state.pageKey, child: const CoachNotificationsScreen()),
          ),
          GoRoute(
            path: '/coach/profil',
            pageBuilder: (_, state) => _fadeSlidePage(
              key: state.pageKey,
              child: const StaffProfileScreen(
                roleLabel: 'Coach',
                accentColor: OdinColors.accent,
              ),
            ),
          ),
        ],
      ),

      // ── Préparateur Physique
      ShellRoute(
        navigatorKey: _preparateurShellKey,
        builder: (context, state, child) => PreparateurShell(child: child),
        routes: [
          GoRoute(
            path: '/preparateur',
            pageBuilder: (_, state) =>
                _fadeSlidePage(key: state.pageKey, child: const PrepDashboardScreen()),
          ),
          GoRoute(
            path: '/preparateur/programmes',
            pageBuilder: (_, state) =>
                _fadeSlidePage(key: state.pageKey, child: const PrepProgrammesScreen()),
          ),
          GoRoute(
            path: '/preparateur/charge',
            pageBuilder: (_, state) =>
                _fadeSlidePage(key: state.pageKey, child: const PrepChargeScreen()),
          ),
          GoRoute(
            path: '/preparateur/condition',
            pageBuilder: (_, state) =>
                _fadeSlidePage(key: state.pageKey, child: const PrepConditionScreen()),
          ),
          GoRoute(
            path: '/preparateur/ia',
            pageBuilder: (_, state) =>
                _fadeSlidePage(key: state.pageKey, child: const PrepAiScreen()),
          ),
          GoRoute(
            path: '/preparateur/menu',
            pageBuilder: (_, state) =>
                _fadeSlidePage(key: state.pageKey, child: const PrepMenuScreen()),
          ),
          GoRoute(
            path: '/preparateur/messages',
            pageBuilder: (_, state) => _fadeSlidePage(
              key: state.pageKey,
              child: const MessagesScreen(backRoute: '/preparateur', showBack: false),
            ),
          ),
          GoRoute(
            path: '/preparateur/notifications',
            pageBuilder: (_, state) =>
                _fadeSlidePage(key: state.pageKey, child: const PrepNotificationsScreen()),
          ),
          GoRoute(
            path: '/preparateur/profil',
            pageBuilder: (_, state) => _fadeSlidePage(
              key: state.pageKey,
              child: const StaffProfileScreen(
                roleLabel: 'Préparateur Physique',
                accentColor: Color(0xFF6366F1),
              ),
            ),
          ),
        ],
      ),

      // ── Responsable Club
      ShellRoute(
        navigatorKey: _responsableShellKey,
        builder: (context, state, child) => ResponsableShell(child: child),
        routes: [
          GoRoute(
            path: '/responsable',
            pageBuilder: (_, state) =>
                _fadeSlidePage(key: state.pageKey, child: const RespDashboardScreen()),
          ),
          GoRoute(
            path: '/responsable/validation',
            pageBuilder: (_, state) =>
                _fadeSlidePage(key: state.pageKey, child: const RespValidationScreen()),
          ),
          GoRoute(
            path: '/responsable/notifications',
            pageBuilder: (_, state) =>
                _fadeSlidePage(key: state.pageKey, child: const RespNotificationsScreen()),
          ),
          GoRoute(
            path: '/responsable/equipes',
            pageBuilder: (_, state) =>
                _fadeSlidePage(key: state.pageKey, child: const RespTeamsScreen()),
          ),
          GoRoute(
            path: '/responsable/menu',
            pageBuilder: (_, state) =>
                _fadeSlidePage(key: state.pageKey, child: const RespMenuScreen()),
          ),
          GoRoute(
            path: '/responsable/messages',
            pageBuilder: (_, state) => _fadeSlidePage(
              key: state.pageKey,
              child: const MessagesScreen(backRoute: '/responsable', showBack: false),
            ),
          ),
          GoRoute(
            path: '/responsable/profil',
            pageBuilder: (_, state) => _fadeSlidePage(
              key: state.pageKey,
              child: const StaffProfileScreen(
                roleLabel: 'Responsable Club',
                accentColor: Color(0xFF22C55E),
              ),
            ),
          ),
        ],
      ),
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
    GoRoute(
      path: '/analyste/profil',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (_, state) => _fadeSlidePage(
        key: state.pageKey,
        child: shell(
          const StaffProfileScreen(
            roleLabel: 'Analyste Performance',
            accentColor: OdinColors.accent,
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
  if (location.startsWith('/analyste/prediction')) return 4;
  if (location != '/analyste' && location.startsWith('/analyste/')) return 5;
  return 0;
}

void goToAnalysteShellTab(BuildContext context, int index) {
  const paths = [
    '/analyste',
    '/analyste/live',
    '/analyste/ppi',
    '/analyste/viiv',
    '/analyste/prediction',
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
  if (location.startsWith('/scout/ai')) return 4;
  if (location != '/scout' && location.startsWith('/scout/')) return 5;
  return 0;
}

void goToScoutShellTab(BuildContext context, int index) {
  const paths = [
    '/scout',
    '/scout/map',
    '/scout/search',
    '/scout/watchlist',
    '/scout/ai',
    '/scout/modules',
  ];
  context.go(paths[index]);
}

int preparateurShellIndexForLocation(String location) {
  if (location.startsWith('/preparateur/programmes')) return 1;
  if (location.startsWith('/preparateur/charge')) return 2;
  if (location.startsWith('/preparateur/condition')) return 3;
  if (location.startsWith('/preparateur/ia')) return 4;
  if (location.startsWith('/preparateur/messages')) return 5;
  return 0;
}

void goToPreparateurShellTab(BuildContext context, int index) {
  const paths = [
    '/preparateur',
    '/preparateur/programmes',
    '/preparateur/charge',
    '/preparateur/condition',
    '/preparateur/ia',
    '/preparateur/messages',
  ];
  context.go(paths[index]);
}

int responsableShellIndexForLocation(String location) {
  if (location.startsWith('/responsable/validation')) return 1;
  if (location.startsWith('/responsable/messages')) return 2;
  if (location.startsWith('/responsable/equipes')) return 3;
  return 0;
}

void goToResponsableShellTab(BuildContext context, int index) {
  const paths = [
    '/responsable',
    '/responsable/validation',
    '/responsable/messages',
    '/responsable/equipes',
  ];
  context.go(paths[index]);
}

int coachShellIndexForLocation(String location) {
  if (location.startsWith('/coach/entrainements')) return 1;
  if (location.startsWith('/coach/presences')) return 2;
  if (location.startsWith('/coach/composition')) return 3;
  if (location.startsWith('/coach/analyse-match')) return 4;
  if (location.startsWith('/coach/ia')) return 5;
  if (location.startsWith('/coach/messages')) return 6;
  return 0;
}

void goToCoachShellTab(BuildContext context, int index) {
  const paths = [
    '/coach',
    '/coach/entrainements',
    '/coach/presences',
    '/coach/composition',
    '/coach/analyse-match',
    '/coach/ia',
    '/coach/messages',
  ];
  context.go(paths[index]);
}

int medecinShellIndexForLocation(String location) {
  if (location.startsWith('/medecin/dossiers')) return 1;
  if (location.startsWith('/medecin/blessures')) return 2;
  if (location.startsWith('/medecin/traitements')) return 3;
  if (location.startsWith('/medecin/rendezvous')) return 4;
  if (location.startsWith('/medecin/ia')) return 5;
  return 0;
}

void goToMedecinShellTab(BuildContext context, int index) {
  const paths = [
    '/medecin',
    '/medecin/dossiers',
    '/medecin/blessures',
    '/medecin/traitements',
    '/medecin/rendezvous',
    '/medecin/ia',
  ];
  context.go(paths[index]);
}
