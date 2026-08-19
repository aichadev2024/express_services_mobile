import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/otp_screen.dart';
import '../features/home/screens/role_selector_screen.dart';
import '../features/livreur/screens/commande_detail_screen.dart';
import '../features/livreur/screens/livreur_home_screen.dart';
import '../features/livreur/screens/livreur_profile_screen.dart';
import '../features/partenaire/screens/partenaire_home_screen.dart';
import '../features/partenaire/screens/partenaire_select_screen.dart';
import '../features/particulier/screens/particulier_home_screen.dart';
import '../features/vitrine/screens/vitrine_screen.dart';
import '../models/partenaire.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      if (auth.isLoading) return null;

      final loc = state.matchedLocation;
      final onLivreurAuthScreens = loc == '/livreur/login' || loc == '/livreur/otp';
      final onLivreurProtected = loc.startsWith('/livreur') && !onLivreurAuthScreens;

      if (onLivreurProtected && !auth.isAuthenticated) {
        return '/livreur/login';
      }
      if (loc == '/livreur/login' && auth.isAuthenticated) {
        return '/livreur/home';
      }
      if (loc == '/' && auth.isAuthenticated && auth.role == 'ROLE_LIVREUR') {
        return '/livreur/home';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const VitrineScreen()),
      GoRoute(path: '/select-role', builder: (context, state) => const RoleSelectorScreen()),

      // --- Livreur ---
      GoRoute(
        path: '/livreur/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/livreur/otp',
        builder: (context, state) => OtpScreen(username: state.extra as String),
      ),
      GoRoute(
        path: '/livreur/home',
        builder: (context, state) => const LivreurHomeScreen(),
      ),
      GoRoute(
        path: '/livreur/profile',
        builder: (context, state) => const LivreurProfileScreen(),
      ),
      GoRoute(
        path: '/livreur/commande/:id',
        builder: (context, state) => CommandeDetailScreen(
          commandeId: int.parse(state.pathParameters['id']!),
        ),
      ),

      // --- Partenaire résident ---
      GoRoute(
        path: '/partenaire',
        builder: (context, state) => const PartenaireSelectScreen(),
      ),
      GoRoute(
        path: '/partenaire/select',
        builder: (context, state) => const PartenaireSelectScreen(),
      ),
      GoRoute(
        path: '/partenaire/home',
        builder: (context, state) => PartenaireHomeScreen(
          partenaire: state.extra as Partenaire,
        ),
      ),

      // --- Particulier ---
      GoRoute(
        path: '/particulier',
        builder: (context, state) => const ParticulierHomeScreen(),
      ),
    ],
  );
});
