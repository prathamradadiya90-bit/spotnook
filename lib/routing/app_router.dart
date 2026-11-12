import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/discovery/domain/entities/place.dart';
import '../features/discovery/presentation/screens/home_screen.dart';
import '../features/discovery/presentation/screens/search_screen.dart';
import '../features/map/presentation/screens/map_screen.dart';
import '../features/place_detail/presentation/screens/place_detail_screen.dart';
import '../features/saved/presentation/screens/saved_screen.dart';
import '../features/settings/presentation/screens/privacy_policy_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import 'main_scaffold.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _exploreNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _mapNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _savedNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _settingsNavigatorKey = GlobalKey<NavigatorState>();

/// Declarative GoRouter configuration.
final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    // Shell Route with Persistent Bottom Navigation Bar
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainScaffold(navigationShell: navigationShell);
      },
      branches: [
        // Branch: Explore (Home)
        StatefulShellBranch(
          navigatorKey: _exploreNavigatorKey,
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),

        // Branch: Map View
        StatefulShellBranch(
          navigatorKey: _mapNavigatorKey,
          routes: [
            GoRoute(
              path: '/map',
              builder: (context, state) => const MapScreen(),
            ),
          ],
        ),

        // Branch: Saved / Bookmarks
        StatefulShellBranch(
          navigatorKey: _savedNavigatorKey,
          routes: [
            GoRoute(
              path: '/saved',
              builder: (context, state) => const SavedScreen(),
            ),
          ],
        ),

        // Branch: Settings & Compliance
        StatefulShellBranch(
          navigatorKey: _settingsNavigatorKey,
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),

    // Push Routes (Over the Shell)
    GoRoute(
      path: '/search',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final query = state.uri.queryParameters['q'];
        return SearchScreen(initialQuery: query);
      },
    ),

    GoRoute(
      path: '/place/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final place = state.extra as Place?;
        if (place != null) {
          return PlaceDetailScreen(place: place);
        }
        // When place extra is not provided (e.g. direct deep link without cache),
        // render an honest not-found screen rather than inventing dummy venue information.
        final id = state.pathParameters['id'] ?? '';
        return Scaffold(
          appBar: AppBar(title: const Text('Spot Details')),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_off_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'Place details unavailable',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Could not locate live information for spot ID "$id".',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => context.go('/'),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Return to Explore'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),

    GoRoute(
      path: '/privacy-policy',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const PrivacyPolicyScreen(),
    ),
  ],
);

