// lib/features/security/presentation/screens/security_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../providers/security_provider.dart';
import 'pin_screen.dart';

class SecuritySettingsScreen extends StatelessWidget {
  const SecuritySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الأمان والتطبيق'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Consumer<SecurityProvider>(
            builder: (context, securityProvider, child) {
              return FutureBuilder<bool>(
                future: securityProvider.isPinEnabled(),
                builder: (context, snapshot) {
                  final isPinEnabled = snapshot.data ?? false;
                  
                  return Column(
                    children: [
                      // PIN Setting
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.lock_rounded, color: AppColors.primary),
                          title: const Text('قفل التطبيق بالرمز السري'),
                          subtitle: Text(
                            isPinEnabled ? 'مفعل - مطلوب رمز سري لفتح التطبيق' : 'معطل - يمكن فتح التطبيق مباشرة',
                          ),
                          trailing: Switch(
                            value: isPinEnabled,
                            onChanged: (value) {
                              if (value) {
                                // Activer le PIN
                                _showPinSetupScreen(context);
                              } else {
                                // Désactiver le PIN
                                _showDisablePinDialog(context);
                              }
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Biometric Setting - Version corrigée
                      _buildBiometricSection(context, securityProvider, isPinEnabled),

                      // Information Text
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'تفعيل قفل التطبيق يضمن حماية بياناتك عند مشاركة الجهاز أو في حالة فقدانه',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            fontFamily: 'Tajawal',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBiometricSection(BuildContext context, SecurityProvider securityProvider, bool isPinEnabled) {
    return FutureBuilder<bool>(
      future: securityProvider.isBiometricAvailable(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: ListTile(
              leading: CircularProgressIndicator(),
              title: Text('جاري التحقق...'),
              subtitle: Text('التحقق من توفر المصادقة البيومترية'),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data!) {
          return FutureBuilder<bool>(
            future: securityProvider.isBiometricEnabled(),
            builder: (context, biometricEnabledSnapshot) {
              final isBiometricEnabled = biometricEnabledSnapshot.data ?? false;
              
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.fingerprint_rounded, color: AppColors.primary),
                  title: const Text('المصادقة البيومترية'),
                  subtitle: const Text('استخدم البصمة أو التعرف على الوجه'),
                  trailing: Switch(
                    value: isBiometricEnabled,
                    onChanged: isPinEnabled 
                        ? (value) {
                            if (value) {
                              securityProvider.enableBiometric();
                            } else {
                              securityProvider.disableBiometric();
                            }
                          }
                        : null,
                  ),
                ),
              );
            },
          );
        } else {
          // Sur Web ou quand la biométrie n'est pas disponible
          return Card(
            child: ListTile(
              leading: const Icon(Icons.fingerprint_rounded, color: Colors.grey),
              title: const Text('المصادقة البيومترية'),
              subtitle: const Text('غير متاحة على هذا الجهاز'),
              trailing: const Switch(value: false, onChanged: null),
            ),
          );
        }
      },
    );
  }

  void _showPinSetupScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PinScreen(
          isSetupMode: true,
          onPinVerified: (pin) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تم تفعيل قفل التطبيق بنجاح'),
                backgroundColor: Colors.green,
              ),
            );
          },
        ),
      ),
    );
  }

  void _showDisablePinDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعطيل قفل التطبيق'),
        content: const Text('هل أنت متأكد من تعطيل قفل التطبيق؟ هذا قد يقلل من أمان بياناتك.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final securityProvider = Provider.of<SecurityProvider>(context, listen: false);
              
              final success = await securityProvider.togglePin(
                pin: '',
                enable: false,
              );
              
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم تعطيل قفل التطبيق'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('خطأ: ${securityProvider.error}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('تعطيل'),
          ),
        ],
      ),
    );
  }
}