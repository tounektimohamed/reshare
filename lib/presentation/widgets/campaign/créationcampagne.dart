
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reshare/features/auth/presentation/providers/auth_provider.dart';
import 'package:reshare/features/campaigns/presentation/providers/campaign_provider.dart';

class CreateCampaignScreen extends StatefulWidget {
  const CreateCampaignScreen({super.key});

  @override
  State<CreateCampaignScreen> createState() => _CreateCampaignScreenState();
}

class _CreateCampaignScreenState extends State<CreateCampaignScreen> {
  final _formKey = GlobalKey<FormState>();

  // Données du formulaire
  String _title = '';
  String _description = '';
  String _targetUrl = '';
  double _budget = 60.0;
  double _cpc = 0.06;
  String _selectedType = 'open';
  int _maxClicksPerUser = 3;

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final campaignProvider = Provider.of<CampaignProvider>(context);

    // Vérifier si l'utilisateur est une entreprise
    if (!authProvider.isBusiness && !authProvider.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('إنشاء حملة إعلانية')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.business_center, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'هذه الخاصية متاحة فقط للشركات',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'يجب أن يكون لديك حساب شركة لإنشاء حملات إعلانية',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('إنشاء حملة إعلانية'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Bouton pour créer des campagnes de test
          if (authProvider.isAdmin) ...[
            IconButton(
              icon: const Icon(Icons.bug_report),
              onPressed: _createTestCampaigns,
              tooltip: 'إنشاء حملات تجريبية',
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titre de la campagne
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'عنوان الحملة *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.campaign),
                  hintText: 'أدخل عنوان الحملة الإعلانية',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال عنوان الحملة';
                  }
                  if (value.length < 5) {
                    return 'العنوان يجب أن يكون 5 أحرف على الأقل';
                  }
                  return null;
                },
                onChanged: (value) => _title = value,
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'وصف الحملة *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                  hintText: 'وصف مختصر للحملة الإعلانية',
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال وصف الحملة';
                  }
                  if (value.length < 10) {
                    return 'الوصف يجب أن يكون 10 أحرف على الأقل';
                  }
                  return null;
                },
                onChanged: (value) => _description = value,
              ),
              const SizedBox(height: 16),

              // URL cible
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'رابط الوجهة *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                  hintText: 'https://example.com',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال رابط الوجهة';
                  }
                  if (!value.startsWith('http')) {
                    return 'يرجى إدخال رابط صالح يبدأ بـ http أو https';
                  }
                  return null;
                },
                onChanged: (value) => _targetUrl = value,
              ),
              const SizedBox(height: 16),

              // Type de campagne
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'نوع الحملة',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedType,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'اختر نوع الحملة',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'open',
                            child: Text('حملة مفتوحة - جميع المناطق'),
                          ),
                          DropdownMenuItem(
                            value: 'regional',
                            child: Text('حملة إقليمية - مناطق محددة'),
                          ),
                          DropdownMenuItem(
                            value: 'precise',
                            child: Text('حملة دقيقة - مواقع محددة'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedType = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Budget
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الميزانية *',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_budget.toStringAsFixed(0)} دينار',
                        style: const TextStyle(
                          fontSize: 24,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Slider(
                        value: _budget,
                        min: 10,
                        max: 1000,
                        divisions: 99,
                        label: _budget.toStringAsFixed(0),
                        onChanged: (value) {
                          setState(() {
                            _budget = value;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '10 د',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            '1000 د',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '~ ${(_budget / _cpc).round()} نقرة متوقعة',
                        style: TextStyle(fontSize: 12, color: Colors.green),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // CPC
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'سعر النقرة',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_cpc.toStringAsFixed(3)} دينار للنقرة',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Slider(
                        value: _cpc,
                        min: 0.01,
                        max: 0.10,
                        divisions: 9,
                        label: _cpc.toStringAsFixed(3),
                        onChanged: (value) {
                          setState(() {
                            _cpc = value;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '0.01 د',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            '0.10 د',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'سعر تنافسي - أرخص من إعلانات فيسبوك',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Max clicks per user
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الحد الأقصى للنقرات لكل مستخدم',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$_maxClicksPerUser نقرة',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Slider(
                        value: _maxClicksPerUser.toDouble(),
                        min: 1,
                        max: 10,
                        divisions: 9,
                        label: _maxClicksPerUser.toString(),
                        onChanged: (value) {
                          setState(() {
                            _maxClicksPerUser = value.toInt();
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '1',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            '10',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Résumé
              Card(
                color: Colors.blue[50],
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ملخص الحملة',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildSummaryRow(
                        'عدد النقرات المتوقعة',
                        '${(_budget / _cpc).round()} نقرة',
                      ),
                      _buildSummaryRow(
                        'التكلفة الكلية',
                        '${_budget.toStringAsFixed(0)} دينار',
                      ),
                      _buildSummaryRow(
                        'للمشاركين',
                        '${(_budget * 0.6).toStringAsFixed(0)} دينار',
                      ),
                      _buildSummaryRow(
                        'ربح المنصة',
                        '${(_budget * 0.4).toStringAsFixed(0)} دينار',
                      ),
                      _buildSummaryRow(
                        'ربح النقرة للمشارك',
                        '${(_cpc * 0.6).toStringAsFixed(3)} دينار',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Boutons d'action
              Row(
                children: [
                  // Bouton de création directe
                  Expanded(
                    child: SizedBox(
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _createCampaignDirect,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'إنشاء الحملة مباشرة',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Bouton d'annulation
                  SizedBox(
                    width: 100,
                    height: 55,
                    child: OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('إلغاء'),
                    ),
                  ),
                ],
              ),

              // Information sur le mode développement
              if (_isLoading) ...[
                const SizedBox(height: 16),
                const Center(child: CircularProgressIndicator()),
              ],

              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.orange[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'في وضع التطوير: سيتم إنشاء الحملة مباشرة بدون عملية دفع',
                        style: TextStyle(
                          color: Colors.orange[800],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 14)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Future<void> _createCampaignDirect() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final campaignProvider = Provider.of<CampaignProvider>(
        context,
        listen: false,
      );

      // Préparer les données adaptées au modèle CampaignModel
      final campaignData = {
        'title': _title,
        'description': _description,
        'targetUrl': _targetUrl,
        'budget': _budget,
        'cpc': _cpc,
        'type': _getCampaignTypeIndex(_selectedType), // Convertir en index
        'maxClicksPerUser': _maxClicksPerUser,
        // Les autres champs seront gérés par la Cloud Function
      };

      await campaignProvider.createCampaignDirect(campaignData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إنشاء الحملة بنجاح وتم تفعيلها فوراً'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );

        // Retourner au dashboard
        Navigator.of(context).pop();
      }
    } catch (error) {
      print('Error creating campaign: $error');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في إنشاء الحملة: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Helper pour convertir le type de campagne en index
  int _getCampaignTypeIndex(String type) {
    switch (type) {
      case 'open':
        return 0;
      case 'regional':
        return 1;
      case 'precise':
        return 2;
      default:
        return 0;
    }
  }

  // Helper pour convertir l'index en type de campagne
  String _getCampaignTypeString(int index) {
    switch (index) {
      case 0:
        return 'open';
      case 1:
        return 'regional';
      case 2:
        return 'precise';
      default:
        return 'open';
    }
  }

  Future<void> _createTestCampaigns() async {
    try {
      final campaignProvider = Provider.of<CampaignProvider>(
        context,
        listen: false,
      );

      await campaignProvider.createTestCampaigns(3);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إنشاء 3 حملات تجريبية بنجاح'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في إنشاء الحملات التجريبية: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}