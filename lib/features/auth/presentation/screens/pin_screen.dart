// lib/features/security/presentation/screens/pin_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../providers/security_provider.dart';

class PinScreen extends StatefulWidget {
  final bool isSetupMode;
  final Function(String)? onPinVerified;

  const PinScreen({
    super.key,
    this.isSetupMode = false,
    this.onPinVerified,
  });

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  final List<String> _enteredPin = [];
  String _confirmPin = '';
  bool _isConfirmStep = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Icon(
                Icons.lock_rounded,
                size: 80,
                color: AppColors.primary,
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                widget.isSetupMode
                    ? _isConfirmStep 
                        ? 'Confirmez votre PIN'
                        : 'Créez votre code PIN'
                    : 'Entrez votre code PIN',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Tajawal',
                ),
              ),
              const SizedBox(height: 8),

              // Subtitle
              Text(
                widget.isSetupMode
                    ? _isConfirmStep
                        ? 'Resaisissez votre code PIN pour confirmation'
                        : 'Choisissez un code PIN à 4 chiffres pour sécuriser votre application'
                    : 'Saisissez votre code PIN pour accéder à l\'application',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  fontFamily: 'Tajawal',
                ),
              ),
              const SizedBox(height: 32),

              // PIN Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index < _enteredPin.length
                          ? AppColors.primary
                          : Colors.grey.shade300,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 32),

              // Error Message
              Consumer<SecurityProvider>(
                builder: (context, securityProvider, child) {
                  if (securityProvider.error != null) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        securityProvider.error!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                          fontFamily: 'Tajawal',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),

              // PIN Pad
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                  ),
                  itemCount: 12, // 0-9 + delete + empty
                  itemBuilder: (context, index) {
                    if (index == 9) {
                      return const SizedBox(); // Empty space
                    } else if (index == 10) {
                      return _buildPinButton('0');
                    } else if (index == 11) {
                      return _buildDeleteButton();
                    } else {
                      return _buildPinButton('${index + 1}');
                    }
                  },
                ),
              ),

              // Biometric Option (only in unlock mode)
              if (!widget.isSetupMode) ...[
                const SizedBox(height: 16),
                _buildBiometricButton(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPinButton(String number) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(50),
        onTap: () => _onNumberPressed(number),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w500,
                fontFamily: 'Tajawal',
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(50),
        onTap: _onDeletePressed,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const Center(
            child: Icon(
              Icons.backspace_rounded,
              size: 24,
              color: Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

 Widget _buildBiometricButton() {
  return Consumer<SecurityProvider>(
    builder: (context, securityProvider, child) {
      return FutureBuilder<bool>(
        future: securityProvider.isBiometricAvailable(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!) {
            return TextButton.icon(
              onPressed: () async {
                final success = await securityProvider.unlockWithBiometric();
                if (success && widget.onPinVerified != null) {
                  widget.onPinVerified!('biometric');
                }
              },
              icon: const Icon(Icons.fingerprint_rounded),
              label: const Text('Utiliser la biométrie'),
            );
          } else {
            // Cacher le bouton sur Web
            return const SizedBox();
          }
        },
      );
    },
  );
}


  void _onNumberPressed(String number) {
    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin.add(number);
      });

      if (_enteredPin.length == 4) {
        _handleCompletePin();
      }
    }
  }

  void _onDeletePressed() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin.removeLast();
      });
    }
  }

  void _handleCompletePin() async {
    final pin = _enteredPin.join();

    if (widget.isSetupMode) {
      await _handleSetupMode(pin);
    } else {
      await _handleVerificationMode(pin);
    }
  }

  Future<void> _handleSetupMode(String pin) async {
    if (!_isConfirmStep) {
      // Première étape de configuration
      setState(() {
        _confirmPin = pin;
        _enteredPin.clear();
        _isConfirmStep = true;
      });
    } else {
      // Deuxième étape de confirmation
      if (pin == _confirmPin) {
        final securityProvider = 
            Provider.of<SecurityProvider>(context, listen: false);
        
        final success = await securityProvider.togglePin(
          pin: pin,
          enable: true,
        );

        if (success && widget.onPinVerified != null) {
          widget.onPinVerified!(pin);
        }
      } else {
        final securityProvider = 
            Provider.of<SecurityProvider>(context, listen: false);
        
        // CORRECTION : Utiliser la méthode publique
        securityProvider.setError('Les codes PIN ne correspondent pas');
        setState(() {
          _enteredPin.clear();
          _isConfirmStep = false;
          _confirmPin = '';
        });
      }
    }
  }

  Future<void> _handleVerificationMode(String pin) async {
    final securityProvider = 
        Provider.of<SecurityProvider>(context, listen: false);
    
    final isValid = await securityProvider.unlockWithPin(pin);
    
    if (isValid && widget.onPinVerified != null) {
      widget.onPinVerified!(pin);
    } else {
      setState(() {
        _enteredPin.clear();
      });
    }
  }
}