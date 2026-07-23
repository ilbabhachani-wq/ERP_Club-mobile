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
import '../shell/player_shell.dart';

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
    initialLocation: '/splash',
    refreshListenable: sessionNotifier,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final publicRoutes = {'/splash', '/onboarding', '/login'};
      if (publicRoutes.contains(loc)) return null;

      final loggedIn = auth.isAuthenticated;
      if (!loggedIn) return '/login';
      if (loggedIn && loc == '/login') return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (_, state) => _fadeSlidePage(
          key: state.pageKey,
          child: const SplashScreen(),
          type: SharedAxisTransitionType.scaled,
        ),
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (_, state) => _fadeSlidePage(
          key: state.pageKey,
          child: const OnboardingScreen(),
          type: SharedAxisTransitionType.scaled,
        ),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (_, state) => _fadeSlidePage(
          key: state.pageKey,
          child: const LoginScreen(),
          type: SharedAxisTransitionType.scaled,
        ),
      ),
      ShellRoute(
        builder: (context, state, child) => PlayerShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (_, state) => _fadeSlidePage(key: state.pageKey, child: const JoueurDashboardScreen()),
          ),
          GoRoute(
            path: '/performances',
            pageBuilder: (_, state) => _fadeSlidePage(key: state.pageKey, child: const JoueurPerformancesScreen()),
          ),
          GoRoute(
            path: '/planning',
            pageBuilder: (_, state) => _fadeSlidePage(key: state.pageKey, child: const JoueurPlanningScreen()),
          ),
          GoRoute(
            path: '/ai',
            pageBuilder: (_, state) => _fadeSlidePage(key: state.pageKey, child: const JoueurAiScreen()),
          ),
          GoRoute(
            path: '/menu',
            pageBuilder: (_, state) => _fadeSlidePage(key: state.pageKey, child: const MenuScreen()),
          ),
          GoRoute(
            path: '/medical',
            pageBuilder: (_, state) => _fadeSlidePage(key: state.pageKey, child: const JoueurMedicalScreen()),
          ),
          GoRoute(
            path: '/profil',
            pageBuilder: (_, state) => _fadeSlidePage(key: state.pageKey, child: const JoueurProfileScreen()),
          ),
          GoRoute(
            path: '/messages',
            pageBuilder: (_, state) => _fadeSlidePage(key: state.pageKey, child: const MessagesScreen()),
          ),
          GoRoute(
            path: '/liste',
            pageBuilder: (_, state) => _fadeSlidePage(key: state.pageKey, child: const JoueurListScreen()),
          ),
          GoRoute(
            path: '/comparer',
            pageBuilder: (_, state) => _fadeSlidePage(key: state.pageKey, child: const JoueurCompareScreen()),
          ),
          GoRoute(
            path: '/formation',
            pageBuilder: (_, state) => _fadeSlidePage(key: state.pageKey, child: const JoueurFormationScreen()),
          ),
          GoRoute(
            path: '/transferts',
            pageBuilder: (_, state) => _fadeSlidePage(key: state.pageKey, child: const JoueurTransfersScreen()),
          ),
          GoRoute(
            path: '/documents',
            pageBuilder: (_, state) => _fadeSlidePage(key: state.pageKey, child: const JoueurDocumentsScreen()),
          ),
          GoRoute(
            path: '/entrainement',
            pageBuilder: (_, state) => _fadeSlidePage(key: state.pageKey, child: const JoueurTrainingScreen()),
          ),
          GoRoute(
            path: '/analyse',
            pageBuilder: (_, state) => _fadeSlidePage(key: state.pageKey, child: const JoueurAnalysisScreen()),
          ),
          GoRoute(
            path: '/recompenses',
            pageBuilder: (_, state) => _fadeSlidePage(key: state.pageKey, child: const JoueurAwardsScreen()),
          ),
          GoRoute(
            path: '/chimie',
            pageBuilder: (_, state) => _fadeSlidePage(key: state.pageKey, child: const JoueurChemistryScreen()),
          ),
          GoRoute(
            path: '/viiv',
            pageBuilder: (_, state) => _fadeSlidePage(key: state.pageKey, child: const ViivSmartwatchScreen()),
          ),
        ],
      ),
    ],
  );
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
