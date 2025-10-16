import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:reshare/data/models/campaign_model.dart';
import 'package:reshare/core/constants/app_colors.dart';
import 'package:reshare/features/auth/presentation/providers/auth_provider.dart';
import '../providers/campaign_provider.dart';
import 'dart:html' as html;

class CreateCampaignWithImageScreen extends StatefulWidget {
  const CreateCampaignWithImageScreen({super.key});

  @override
  State<CreateCampaignWithImageScreen> createState() => _CreateCampaignWithImageScreenState();
}

class _CreateCampaignWithImageScreenState extends State<CreateCampaignWithImageScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _targetUrlController = TextEditingController();

  double _budget = 60.0;
  double _cpc = 0.06;
  String _selectedType = 'open';
  int _maxClicksPerUser = 5;
  int _targetClicks = 1000;

  CampaignType _campaignType = CampaignType.open;
  File? _selectedImage;
  Uint8List? _imageBytes;
  String? _imageExtension;
  bool _isLoading = false;

  final ImagePicker _imagePicker = ImagePicker();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (!authProvider.isBusiness && !authProvider.isAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('إنشاء حملة إعلانية'),
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
        ),
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
              _buildImageSection(),
              const SizedBox(height: 24),
              _buildCampaignDetailsSection(),
              const SizedBox(height: 16),
              _buildCampaignTypeSection(),
              const SizedBox(height: 16),
              _buildBudgetSection(),
              const SizedBox(height: 16),
              _buildCPCSection(),
              const SizedBox(height: 16),
              _buildMaxClicksSection(),
              const SizedBox(height: 16),
              _buildSummarySection(),
              const SizedBox(height: 24),
              _buildActionButtons(),
              if (_isLoading) ...[
                const SizedBox(height: 16),
                const Center(child: CircularProgressIndicator()),
              ],
              const SizedBox(height: 16),
              _buildDevelopmentInfo(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'صورة الحملة',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _selectImage,
              child: Container(
                width: double.infinity,
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey[300]!,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[100],
                ),
                child: _selectedImage == null && _imageBytes == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_rounded,
                            size: 40,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'إضافة صورة للحملة',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            'انقر لاختيار صورة',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      )
                    : Stack(
                        children: [
                          kIsWeb && _imageBytes != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.memory(
                                    _imageBytes!,
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : _selectedImage != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(
                                        _selectedImage!,
                                        width: double.infinity,
                                        height: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Container(),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.close, color: Colors.white, size: 18),
                                onPressed: () {
                                  setState(() {
                                    _selectedImage = null;
                                    _imageBytes = null;
                                    _imageExtension = null;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            if (_selectedImage != null || _imageBytes != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'تم اختيار صورة بصيغة $_imageExtension',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCampaignDetailsSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'تفاصيل الحملة *',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _titleController,
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
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'وصف الحملة *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
                hintText: 'وصف مختصر للحملة الإعلانية',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'يرجى إدخال وصف الحملة';
                }
                if (value.length < 10) {
                  return 'الوصف يجب أن يكون 10 أحرف على الأقل';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _targetUrlController,
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCampaignTypeSection() {
    return Card(
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
                  _campaignType = _getCampaignTypeFromString(value);
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetSection() {
    return Card(
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
                  _targetClicks = (_budget / _cpc).round();
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
              style: const TextStyle(fontSize: 12, color: Colors.green),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCPCSection() {
    return Card(
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
              '${_cpc.toStringAsFixed(2)} دينار للنقرة',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Slider(
              value: _cpc,
              min: 0.05,
              max: 0.07,
              divisions: 2,
              label: _cpc.toStringAsFixed(2),
              onChanged: (value) {
                setState(() {
                  _cpc = value;
                  _targetClicks = (_budget / _cpc).round();
                });
              },
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '0.05 د',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  '0.07 د',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green),
              ),
              child: Row(
                children: [
                  Icon(Icons.thumb_up, color: Colors.green[700], size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'السعر المثالي: 0.05 دينار - يوازن بين الجذب والربحية',
                      style: TextStyle(
                        color: Colors.green[800],
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
    );
  }

  Widget _buildMaxClicksSection() {
    return Card(
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
              min: 5,
              max: 100,
              divisions: 19,
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
                  '5',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  '100',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue[700], size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'يسمح للمستخدمين بالمشاركة بشكل أكبر مع الحفاظ على فرص للآخرين',
                      style: TextStyle(
                        color: Colors.blue[800],
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
    );
  }

  Widget _buildSummarySection() {
    final totalClicks = (_budget / _cpc).round();
    final participantEarnings = _budget * 0.6;
    final platformEarnings = _budget * 0.4;
    final earningsPerClick = _cpc * 0.6;

    return Card(
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
              '$totalClicks نقرة',
            ),
            _buildSummaryRow(
              'التكلفة الكلية',
              '${_budget.toStringAsFixed(0)} دينار',
            ),
            _buildSummaryRow(
              'للمشاركين',
              '${participantEarnings.toStringAsFixed(0)} دينار',
            ),
            _buildSummaryRow(
              'ربح المنصة',
              '${platformEarnings.toStringAsFixed(0)} دينار',
            ),
            _buildSummaryRow(
              'ربح النقرة للمشارك',
              '${earningsPerClick.toStringAsFixed(3)} دينار',
            ),
          ],
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

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 55,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _createCampaign,
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
    );
  }

  Widget _buildDevelopmentInfo() {
    return Container(
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
    );
  }

  Future<void> _selectImage() async {
    try {
      if (kIsWeb) {
        _pickImageForWeb();
      } else {
        final XFile? image = await _imagePicker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1200,
          maxHeight: 1200,
          imageQuality: 80,
        );

        if (image != null) {
          setState(() {
            _selectedImage = File(image.path);
            _imageExtension = image.path.split('.').last.toLowerCase();
          });
        }
      }
    } catch (e) {
      _showError('فشل في اختيار الصورة: $e');
    }
  }

  void _pickImageForWeb() {
    final html.FileUploadInputElement input = html.FileUploadInputElement();
    input.accept = 'image/*';
    input.click();

    input.onChange.listen((e) {
      final files = input.files;
      if (files != null && files.isNotEmpty) {
        final file = files[0];
        final reader = html.FileReader();

        reader.onLoadEnd.listen((e) {
          setState(() {
            _imageBytes = reader.result as Uint8List;
            _imageExtension = file.name.split('.').last.toLowerCase();
          });
        });

        reader.readAsArrayBuffer(file);
      }
    });
  }

  Future<void> _createCampaign() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedImage == null && _imageBytes == null) {
      _showError('الرجاء اختيار صورة للحملة');
      return;
    }

    final totalCost = _cpc * _targetClicks;
    if (totalCost > _budget) {
      _showError('الميزانية غير كافية للتكلفة الإجمالية');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      String imageData;
      
      // Convertir l'image en base64
      if (kIsWeb && _imageBytes != null) {
        imageData = _convertToBase64(_imageBytes!, _imageExtension!);
      } else if (_selectedImage != null) {
        final bytes = await _selectedImage!.readAsBytes();
        imageData = _convertToBase64(bytes, _imageExtension!);
      } else {
        throw Exception('لا توجد صورة مرفوعة');
      }

      // Vérifier la taille de l'image base64
      if (imageData.length > 1000000) { // ~1MB
        _showError('حجم الصورة كبير جداً. يرجى اختيار صورة أصغر');
        return;
      }

      // Préparer les données de la campagne
      final campaignData = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'targetUrl': _targetUrlController.text,
        'type': _getCampaignTypeIndex(_selectedType),
        'budget': _budget,
        'cpc': _cpc,
        'targetClicks': _targetClicks,
        'maxClicksPerUser': _maxClicksPerUser,
        'imageUrl': imageData, // Base64
        'imageExtension': _imageExtension,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'status': CampaignStatus.pending.index,
        'isActive': true,
        'spent': 0.0,
        'achievedClicks': 0,
        'uniqueClicks': 0,
        'conversionRate': 0.0,
        'conversions': 0,
        'userId': authProvider.user?.id,
        'userEmail': authProvider.user?.email,
        'userName': authProvider.user?.displayName,
    //    'companyName': authProvider.companyName,
      };

      // Créer la campagne
      final campaignProvider = Provider.of<CampaignProvider>(context, listen: false);
      await campaignProvider.createCampaignDirect(campaignData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إنشاء الحملة بنجاح وتم تفعيلها فوراً'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );

        Navigator.of(context).pop();
      }

    } catch (e) {
      _showError('فشل في إنشاء الحملة: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _convertToBase64(Uint8List imageBytes, String extension) {
    try {
      final base64String = base64.encode(imageBytes);
      
      String mimeType;
      switch (extension.toLowerCase()) {
        case 'jpg':
        case 'jpeg':
          mimeType = 'jpeg';
          break;
        case 'png':
          mimeType = 'png';
          break;
        case 'gif':
          mimeType = 'gif';
          break;
        case 'webp':
          mimeType = 'webp';
          break;
        case 'bmp':
          mimeType = 'bmp';
          break;
        default:
          mimeType = 'jpeg';
      }
      
      return 'data:image/$mimeType;base64,$base64String';
    } catch (e) {
      throw Exception('فشل في تحويل الصورة إلى base64: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

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

  CampaignType _getCampaignTypeFromString(String type) {
    switch (type) {
      case 'open':
        return CampaignType.open;
      case 'regional':
        return CampaignType.regional;
      case 'precise':
        return CampaignType.precise;
      default:
        return CampaignType.open;
    }
  }

  Future<void> _createTestCampaigns() async {
    try {
      final campaignProvider = Provider.of<CampaignProvider>(context, listen: false);
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

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _targetUrlController.dispose();
    super.dispose();
  }
}

// Classe utilitaire pour la gestion des images base64
class Base64ImageHelper {
  static String convertToBase64(Uint8List imageBytes, {String format = 'jpeg'}) {
    try {
      final base64String = base64.encode(imageBytes);
      return 'data:image/$format;base64,$base64String';
    } catch (e) {
      print('Error converting image to base64: $e');
      return '';
    }
  }

  static Uint8List? convertFromBase64(String base64String) {
    try {
      String data = base64String;
      if (base64String.startsWith('data:image/')) {
        final parts = base64String.split(',');
        if (parts.length > 1) data = parts[1];
      }
      return base64.decode(data);
    } catch (e) {
      print('Error converting base64 to image: $e');
      return null;
    }
  }

  static bool isValidBase64Image(String data) {
    if (data.isEmpty) return false;
    try {
      if (data.startsWith('data:image/')) {
        final parts = data.split(',');
        if (parts.length != 2) return false;
        base64.decode(parts[1]);
        return true;
      } else {
        base64.decode(data);
        return true;
      }
    } catch (e) {
      return false;
    }
  }

  static String getImageFormat(String base64String) {
    if (base64String.startsWith('data:image/')) {
      final parts = base64String.split(';');
      if (parts.isNotEmpty) {
        final format = parts[0].replaceAll('data:image/', '');
        return format;
      }
    }
    return 'jpeg';
  }

  static int getBase64Size(String base64String) {
    try {
      String data = base64String;
      if (base64String.startsWith('data:image/')) {
        final parts = base64String.split(',');
        if (parts.length > 1) data = parts[1];
      }
      return data.length;
    } catch (e) {
      return 0;
    }
  }

  static double getBase64SizeInKB(String base64String) {
    final size = getBase64Size(base64String);
    return size / 1024;
  }

  static double getBase64SizeInMB(String base64String) {
    final size = getBase64Size(base64String);
    return size / (1024 * 1024);
  }
}