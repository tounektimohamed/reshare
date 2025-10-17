// lib/app.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reshare/features/auth/presentation/screens/pin_screen.dart';

import 'core/constants/app_colors.dart';
import 'core/constants/app_strings.dart';
import 'presentation/themes/app_theme.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/presentation/providers/security_provider.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/welcome_screen.dart';
import 'features/dashboard/presentation/screens/dashboard_screen.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      home: const AppRoot(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  bool _initialSecurityCheck = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final securityProvider = Provider.of<SecurityProvider>(context, listen: false);

    print('🔄 Initializing app security...');

    // 1. Lier les providers
    authProvider.setSecurityProvider(securityProvider);

    // 2. Vérifier le statut d'authentification
    await authProvider.checkAuthStatus();

    // 3. Si l'utilisateur est authentifié, configurer la sécurité
    if (authProvider.isAuthenticated && authProvider.user != null) {
      final userId = authProvider.user!.id;
      print('🔐 User is authenticated: $userId');
      
      // Définir l'utilisateur courant dans SecurityProvider
      securityProvider.setCurrentUser(userId);
      
      // Vérifier si le PIN est activé pour cet utilisateur
      final pinEnabled = await securityProvider.isPinEnabled();
      
      if (pinEnabled) {
        print('🔒 PIN is enabled for user: $userId');
        // Le PIN est activé, on laisse le SecurityProvider gérer l'authentification
        // L'écran PIN sera affiché automatiquement si nécessaire
      } else {
        print('🔓 PIN is disabled for user: $userId');
        // Le PIN n'est pas activé, l'utilisateur est directement authentifié
        securityProvider.setAuthenticated(true);
      }
    } else {
      print('🚫 User is not authenticated');
      // Réinitialiser la sécurité si l'utilisateur n'est pas authentifié
      securityProvider.resetAuthentication();
    }

    setState(() {
      _initialSecurityCheck = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, SecurityProvider>(
      builder: (context, authProvider, securityProvider, child) {
        // Lier les providers à chaque rebuild
        authProvider.setSecurityProvider(securityProvider);

        // Écran de chargement initial pendant la vérification de sécurité
        if (!_initialSecurityCheck || authProvider.authStatus == AuthStatus.checking) {
          return const SplashScreen();
        }

        // Si non authentifié, forcer l'écran de login
        if (authProvider.authStatus == AuthStatus.unauthenticated) {
          return const LoginScreen();
        }

        // Si erreur d'authentification, montrer l'écran de login
        if (authProvider.authStatus == AuthStatus.error) {
          return const LoginScreen();
        }

        // Si authentifié mais pas d'utilisateur chargé (cas rare)
        if (authProvider.isAuthenticated && authProvider.user == null) {
          print('⚠️ Authenticated but no user data');
          return const SplashScreen();
        }

        // Si authentifié, vérifier la sécurité PIN
        if (authProvider.isAuthenticated && authProvider.user != null) {
          final userId = authProvider.user!.id;
          
          // S'assurer que SecurityProvider a l'utilisateur courant
          securityProvider.setCurrentUser(userId);
          
          final isSecurityAuthenticated = securityProvider.isAuthenticated;
          final pinEnabled = securityProvider.isPinEnabled();

          // Utiliser FutureBuilder pour attendre le résultat de isPinEnabled
          return FutureBuilder<bool>(
            future: pinEnabled,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SplashScreen();
              }

              final isPinEnabled = snapshot.data ?? false;

              // Afficher l'écran PIN si nécessaire
              if (isPinEnabled && !isSecurityAuthenticated) {
                print('🎯 Showing PIN screen for user: $userId');
                return PinScreen(
                  onPinVerified: (pin) {
                    // Le callback est géré dans le PinScreen
                    // L'état est mis à jour via le SecurityProvider
                    print('✅ PIN verified for user: $userId');
                  },
                );
              }

              // Si authentifié et sécurité validée, afficher le dashboard
              print('🚀 Showing dashboard for user: $userId');
              return const DashboardScreen();
            },
          );
        }

        // Fallback - normalement on ne devrait pas arriver ici
        return const LoginScreen();
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.share_rounded,
                size: 60,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppStrings.appName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                fontFamily: 'Tajawal',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.slogan,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontFamily: 'Tajawal',
              ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}