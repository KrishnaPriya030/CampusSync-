import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/organizer_activation_screen.dart';

void main() {
  runApp(const CampusSyncApp());
}

class CampusSyncApp extends StatefulWidget {
  const CampusSyncApp({super.key});

  @override
  State<CampusSyncApp> createState() =>
      _CampusSyncAppState();
}

class _CampusSyncAppState
    extends State<CampusSyncApp> {
  final AppLinks _appLinks = AppLinks();

  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();

    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    // ----------------------------------------------------------
    // APP OPENED FROM A DEEP LINK
    // ----------------------------------------------------------

    try {
      final initialUri =
          await _appLinks.getInitialLink();

      if (initialUri != null) {
        _handleDeepLink(initialUri);
      }
    } catch (e) {
      debugPrint(
        'Initial deep link error: $e',
      );
    }

    // ----------------------------------------------------------
    // APP ALREADY RUNNING / BACKGROUND
    // ----------------------------------------------------------

    _linkSubscription =
        _appLinks.uriLinkStream.listen(
      (Uri uri) {
        _handleDeepLink(uri);
      },
      onError: (error) {
        debugPrint(
          'Deep link stream error: $error',
        );
      },
    );
  }

  void _handleDeepLink(Uri uri) {
    debugPrint(
      'CampusSync deep link received: $uri',
    );

    // Expected:
    //
    // campussync://organizer/activate?token=ABC123
    //

    if (uri.scheme != 'campussync') {
      return;
    }

    if (uri.host != 'organizer') {
      return;
    }

    if (uri.path != '/activate') {
      return;
    }

    final token =
        uri.queryParameters['token'];

    if (token == null || token.isEmpty) {
      return;
    }

    _openActivationScreen(token);
  }

  void _openActivationScreen(
    String token,
  ) {
    final navigator =
        navigatorKey.currentState;

    if (navigator == null) {
      return;
    }

    navigator.pushNamedAndRemoveUntil(
      '/organizer/activate',
      (route) => false,
      arguments: token,
    );
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,

      debugShowCheckedModeBanner: false,

      title: 'CampusSync',

      theme: ThemeData(
        useMaterial3: true,
        colorScheme:
            ColorScheme.fromSeed(
          seedColor:
              const Color(0xFF8B5CF6),
        ),
      ),

      routes: {
        '/login': (context) =>
            const LoginScreen(),

        '/organizer/activate':
            (context) {
          final arguments =
              ModalRoute.of(context)
                  ?.settings
                  .arguments;

          String? token;

          if (arguments is String) {
            token = arguments;
          } else if (arguments is Uri) {
            token =
                arguments.queryParameters[
                    'token'];
          }

          if (token == null ||
              token.isEmpty) {
            return const InvalidActivationScreen();
          }

          return OrganizerActivationScreen(
            token: token,
          );
        },
      },

      home: const SplashScreen(),
    );
  }
}

// ================================================================
// GLOBAL NAVIGATOR KEY
// ================================================================

final GlobalKey<NavigatorState>
    navigatorKey =
    GlobalKey<NavigatorState>();

// ================================================================
// INVALID ACTIVATION SCREEN
// ================================================================

class InvalidActivationScreen
    extends StatelessWidget {
  const InvalidActivationScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFF060917),

      body: Center(
        child: Padding(
          padding:
              const EdgeInsets.all(24),

          child: Column(
            mainAxisSize:
                MainAxisSize.min,

            children: [
              const Icon(
                Icons.link_off_rounded,
                size: 64,
                color:
                    Colors.redAccent,
              ),

              const SizedBox(
                height: 20,
              ),

              const Text(
                'Invalid Activation Link',
                textAlign:
                    TextAlign.center,

                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              Text(
                'The organizer activation token '
                'is missing or invalid.',

                textAlign:
                    TextAlign.center,

                style: TextStyle(
                  color: Colors.white
                      .withOpacity(0.55),
                  fontSize: 14,
                ),
              ),

              const SizedBox(
                height: 24,
              ),

              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                    (route) => false,
                  );
                },

                child: const Text(
                  'Go to Login',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}