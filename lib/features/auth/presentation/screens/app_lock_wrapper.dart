// lib/core/widgets/app_lock_wrapper.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reshare/features/auth/presentation/providers/security_provider.dart';
import 'package:reshare/features/auth/presentation/screens/pin_screen.dart';


class AppLockWrapper extends StatefulWidget {
  final Widget child;

  const AppLockWrapper({super.key, required this.child});

  @override
  State<AppLockWrapper> createState() => _AppLockWrapperState();
}

class _AppLockWrapperState extends State<AppLockWrapper>
    with WidgetsBindingObserver {
  bool _isAppPaused = false;
  DateTime? _lastBackgroundTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    final securityProvider = 
        Provider.of<SecurityProvider>(context, listen: false);

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // L'application passe en arrière-plan
        _isAppPaused = true;
        _lastBackgroundTime = DateTime.now();
        securityProvider.resetAuthentication();
        break;
        
      case AppLifecycleState.resumed:
        // L'application revient au premier plan
        if (_isAppPaused) {
          _isAppPaused = false;
          // Vérifier si on doit demander le PIN (après plus de 30 secondes)
          final now = DateTime.now();
          final backgroundDuration = _lastBackgroundTime != null 
              ? now.difference(_lastBackgroundTime!).inSeconds 
              : 31;
          
          if (backgroundDuration > 30) {
            // Forcer la demande du PIN après 30 secondes en arrière-plan
            securityProvider.resetAuthentication();
          }
        }
        break;
        
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SecurityProvider>(
      builder: (context, securityProvider, child) {
        return FutureBuilder<bool>(
          future: securityProvider.isPinEnabled(),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data!) {
              // PIN activé - vérifier l'authentification
              if (!securityProvider.isAuthenticated) {
                return PinScreen(
                  onPinVerified: (pin) async {
                    // Authentification réussie
                    if (pin == 'biometric') {
                      // La biométrie a déjà authentifié dans le SecurityProvider
                      // L'état est déjà mis à jour, rien à faire
                    } else {
                      // Valider le PIN
                      final isValid = await securityProvider.validatePin(pin);
                      if (isValid) {
                        // L'état est mis à jour dans validatePin, rien à faire
                      } else {
                        // Le PIN est invalide, l'écran reste affiché
                        // L'erreur est déjà gérée dans le SecurityProvider
                      }
                    }
                  },
                );
              }
            }
            
            // PIN désactivé ou authentifié - afficher l'application normale
            return widget.child;
          },
        );
      },
    );
  }
}