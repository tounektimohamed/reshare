// // lib/features/marketplace/presentation/screens/add_product_screen.dart
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:provider/provider.dart';
// import 'package:reshare/features/auth/presentation/providers/auth_provider.dart';
// import 'package:reshare/features/auth/presentation/providers/marketplace_provider.dart';
// import 'package:uuid/uuid.dart';
// import '../../../../core/constants/app_colors.dart';
// import '../../../../data/models/product_model.dart';
// import '../../../../data/repositories/product_repository.dart';


// class AddProductScreen extends StatefulWidget {
//   const AddProductScreen({super.key});

//   @override
//   State<AddProductScreen> createState() => _AddProductScreenState();
// }

// class _AddProductScreenState extends State<AddProductScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _titleController = TextEditingController();
//   final _descriptionController = TextEditingController();
//   final _priceController = TextEditingController();
//   final _cpcBudgetController = TextEditingController();
//   final _targetClicksController = TextEditingController();

//   final ImagePicker _imagePicker = ImagePicker();
//   List<String> _selectedImages = [];
//   String _selectedCategory = 'أخرى';
//   ProductType _selectedType = ProductType.cpc;
//   bool _isMarketplace = false;
//   bool _isLoading = false;

//   // Options CPC
//   double _cpcRate = 0.06;
//   int _maxClicksPerUser = 3;

//   @override
//   Widget build(BuildContext context) {
//     final authProvider = Provider.of<AuthProvider>(context);
//     final marketplaceProvider = Provider.of<MarketplaceProvider>(context);

//     return Scaffold(
//       backgroundColor: AppColors.background,
//       appBar: AppBar(
//         title: const Text('إضافة منتج جديد'),
//         backgroundColor: Colors.white,
//         foregroundColor: AppColors.textPrimary,
//         elevation: 1,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.help_rounded),
//             onPressed: _showHelpDialog,
//             tooltip: 'مساعدة',
//           ),
//         ],
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Type de produit
//               _buildProductTypeSection(),
//               const SizedBox(height: 20),

//               // Informations de base
//               _buildBasicInfoSection(),
//               const SizedBox(height: 20),

//               // Images
//               _buildImagesSection(),
//               const SizedBox(height: 20),

//               // Options CPC (si applicable)
//               if (_selectedType == ProductType.cpc || _selectedType == ProductType.hybrid)
//                 _buildCpcSection(),
//               const SizedBox(height: 20),

//               // Options Marketplace (si applicable)
//               if (_isMarketplace || _selectedType == ProductType.marketplace)
//                 _buildMarketplaceSection(),
//               const SizedBox(height: 20),

//               // Résumé et coût
//               _buildSummarySection(),
//               const SizedBox(height: 20),

//               // Bouton de soumission
//               _buildSubmitButton(authProvider, marketplaceProvider),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildProductTypeSection() {
//     return Card(
//       elevation: 2,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'نوع العرض',
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//                 fontFamily: 'Tajawal',
//               ),
//             ),
//             const SizedBox(height: 12),
            
//             // Type de produit
//             DropdownButtonFormField<ProductType>(
//               value: _selectedType,
//               decoration: const InputDecoration(
//                 labelText: 'نوع المنتج',
//                 border: OutlineInputBorder(),
//                 prefixIcon: Icon(Icons.category_rounded),
//               ),
//               items: const [
//                 DropdownMenuItem(
//                   value: ProductType.cpc,
//                   child: Text('ربح من النقرات (CPC)'),
//                 ),
//                 DropdownMenuItem(
//                   value: ProductType.marketplace,
//                   child: Text('عرض في السوق المباشر'),
//                 ),
//                 DropdownMenuItem(
//                   value: ProductType.hybrid,
//                   child: Text('مختلط (CPC + سوق)'),
//                 ),
//               ],
//               onChanged: (value) {
//                 setState(() {
//                   _selectedType = value!;
//                   _isMarketplace = value == ProductType.marketplace || value == ProductType.hybrid;
//                 });
//               },
//             ),
//             const SizedBox(height: 12),
            
//             // Catégorie
//             DropdownButtonFormField<String>(
//               value: _selectedCategory,
//               decoration: const InputDecoration(
//                 labelText: 'التصنيف',
//                 border: OutlineInputBorder(),
//                 prefixIcon: Icon(Icons.label_rounded),
//               ),
//               items: const [
//                 DropdownMenuItem(value: 'الإلكترونيات', child: Text('الإلكترونيات')),
//                 DropdownMenuItem(value: 'الملابس والأزياء', child: Text('الملابس والأزياء')),
//                 DropdownMenuItem(value: 'المنزل والحديقة', child: Text('المنزل والحديقة')),
//                 DropdownMenuItem(value: 'الجمال والعناية', child: Text('الجمال والعناية')),
//                 DropdownMenuItem(value: 'الرياضة والترفيه', child: Text('الرياضة والترفيه')),
//                 DropdownMenuItem(value: 'السيارات', child: Text('السيارات')),
//                 DropdownMenuItem(value: 'الكتب والتعليم', child: Text('الكتب والتعليم')),
//                 DropdownMenuItem(value: 'الأغذية', child: Text('الأغذية')),
//                 DropdownMenuItem(value: 'الصحة', child: Text('الصحة')),
//                 DropdownMenuItem(value: 'الأطفال', child: Text('الأطفال')),
//                 DropdownMenuItem(value: 'الهدايا', child: Text('الهدايا')),
//                 DropdownMenuItem(value: 'أخرى', child: Text('أخرى')),
//               ],
//               onChanged: (value) {
//                 setState(() {
//                   _selectedCategory = value!;
//                 });
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildBasicInfoSection() {
//     return Card(
//       elevation: 2,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'المعلومات الأساسية',
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//                 fontFamily: 'Tajawal',
//               ),
//             ),
//             const SizedBox(height: 12),
            
//             // Titre
//             TextFormField(
//               controller: _titleController,
//               decoration: const InputDecoration(
//                 labelText: 'عنوان المنتج *',
//                 border: OutlineInputBorder(),
//                 prefixIcon: Icon(Icons.title_rounded),
//                 hintText: 'أدخل عنوان واضح للمنتج',
//               ),
//               validator: (value) {
//                 if (value == null || value.isEmpty) {
//                   return 'يرجى إدخال عنوان المنتج';
//                 }
//                 if (value.length < 5) {
//                   return 'العنوان يجب أن يكون 5 أحرف على الأقل';
//                 }
//                 return null;
//               },
//             ),
//             const SizedBox(height: 12),
            
//             // Description
//             TextFormField(
//               controller: _descriptionController,
//               decoration: const InputDecoration(
//                 labelText: 'وصف المنتج *',
//                 border: OutlineInputBorder(),
//                 prefixIcon: Icon(Icons.description_rounded),
//                 hintText: 'وصف مفصل للمنتج ومميزاته',
//               ),
//               maxLines: 4,
//               validator: (value) {
//                 if (value == null || value.isEmpty) {
//                   return 'يرجى إدخال وصف المنتج';
//                 }
//                 if (value.length < 10) {
//                   return 'الوصف يجب أن يكون 10 أحرف على الأقل';
//                 }
//                 return null;
//               },
//             ),
//             const SizedBox(height: 12),
            
//             // Prix
//             TextFormField(
//               controller: _priceController,
//               keyboardType: TextInputType.number,
//               decoration: const InputDecoration(
//                 labelText: 'سعر المنتج (دينار) *',
//                 border: OutlineInputBorder(),
//                 prefixIcon: Icon(Icons.attach_money_rounded),
//                 hintText: '0.00',
//               ),
//               validator: (value) {
//                 if (value == null || value.isEmpty) {
//                   return 'يرجى إدخال سعر المنتج';
//                 }
//                 final price = double.tryParse(value);
//                 if (price == null || price <= 0) {
//                   return 'يرجى إدخال سعر صحيح';
//                 }
//                 return null;
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildImagesSection() {
//     return Card(
//       elevation: 2,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'صور المنتج',
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//                 fontFamily: 'Tajawal',
//               ),
//             ),
//             const SizedBox(height: 12),
            
//             Text(
//               'أضف صور واضحة للمنتج (1-5 صور)',
//               style: TextStyle(
//                 color: AppColors.textSecondary,
//                 fontFamily: 'Tajawal',
//               ),
//             ),
//             const SizedBox(height: 12),
            
//             // Grille d'images
//             GridView.builder(
//               shrinkWrap: true,
//               physics: const NeverScrollableScrollPhysics(),
//               gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                 crossAxisCount: 3,
//                 crossAxisSpacing: 8,
//                 mainAxisSpacing: 8,
//               ),
//               itemCount: _selectedImages.length + 1,
//               itemBuilder: (context, index) {
//                 if (index == _selectedImages.length) {
//                   return _buildAddImageButton();
//                 }
//                 return _buildImageItem(_selectedImages[index], index);
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildAddImageButton() {
//     return GestureDetector(
//       onTap: _pickImage,
//       child: Container(
//         decoration: BoxDecoration(
//           color: AppColors.background,
//           borderRadius: BorderRadius.circular(8),
//           border: Border.all(color: AppColors.outline),
//         ),
//         child: const Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.add_photo_alternate_rounded, color: AppColors.textSecondary),
//             SizedBox(height: 4),
//             Text(
//               'إضافة صورة',
//               style: TextStyle(
//                 fontSize: 10,
//                 color: AppColors.textSecondary,
//                 fontFamily: 'Tajawal',
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildImageItem(String imagePath, int index) {
//     return Stack(
//       children: [
//         Container(
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(8),
//             image: DecorationImage(
//               image: NetworkImage(imagePath),
//               fit: BoxFit.cover,
//             ),
//           ),
//         ),
//         Positioned(
//           top: 4,
//           right: 4,
//           child: GestureDetector(
//             onTap: () => _removeImage(index),
//             child: Container(
//               padding: const EdgeInsets.all(4),
//               decoration: const BoxDecoration(
//                 color: Colors.red,
//                 shape: BoxShape.circle,
//               ),
//               child: const Icon(Icons.close_rounded, size: 12, color: Colors.white),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildCpcSection() {
//     return Card(
//       elevation: 2,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'إعدادات الربح من النقرات',
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//                 fontFamily: 'Tajawal',
//               ),
//             ),
//             const SizedBox(height: 12),
            
//             // Budget CPC
//             TextFormField(
//               controller: _cpcBudgetController,
//               keyboardType: TextInputType.number,
//               decoration: const InputDecoration(
//                 labelText: 'ميزانية النقرات (دينار)',
//                 border: OutlineInputBorder(),
//                 prefixIcon: Icon(Icons.account_balance_wallet_rounded),
//                 hintText: '50',
//               ),
//               onChanged: (value) => _updateCpcSummary(),
//             ),
//             const SizedBox(height: 12),
            
//             // Clicks cibles
//             TextFormField(
//               controller: _targetClicksController,
//               keyboardType: TextInputType.number,
//               decoration: const InputDecoration(
//                 labelText: 'عدد النقرات المستهدفة',
//                 border: OutlineInputBorder(),
//                 prefixIcon: Icon(Icons.touch_app_rounded),
//                 hintText: '1000',
//               ),
//               onChanged: (value) => _updateCpcSummary(),
//             ),
//             const SizedBox(height: 12),
            
//             // Taux CPC
//             ListTile(
//               leading: const Icon(Icons.percent_rounded),
//               title: Text('سعر النقرة: ${_cpcRate.toStringAsFixed(3)} د'),
//               subtitle: Slider(
//                 value: _cpcRate,
//                 min: 0.01,
//                 max: 0.10,
//                 divisions: 9,
//                 label: _cpcRate.toStringAsFixed(3),
//                 onChanged: (value) {
//                   setState(() {
//                     _cpcRate = value;
//                     _updateCpcSummary();
//                   });
//                 },
//               ),
//             ),
            
//             // Clicks max par utilisateur
//             ListTile(
//               leading: const Icon(Icons.person_rounded),
//               title: Text('الحد الأقصى للنقرات لكل مستخدم: $_maxClicksPerUser'),
//               subtitle: Slider(
//                 value: _maxClicksPerUser.toDouble(),
//                 min: 1,
//                 max: 10,
//                 divisions: 9,
//                 label: _maxClicksPerUser.toString(),
//                 onChanged: (value) {
//                   setState(() {
//                     _maxClicksPerUser = value.toInt();
//                   });
//                 },
//               ),
//             ),
            
//             // Résumé CPC
//             if (_cpcBudgetController.text.isNotEmpty && _targetClicksController.text.isNotEmpty)
//               _buildCpcSummary(),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildCpcSummary() {
//     final budget = double.tryParse(_cpcBudgetController.text) ?? 0;
//     final targetClicks = int.tryParse(_targetClicksController.text) ?? 0;
//     final totalCost = targetClicks * _cpcRate;
//     final isValid = totalCost <= budget;

//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: isValid ? AppColors.success.withOpacity(0.1) : AppColors.error.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(
//           color: isValid ? AppColors.success : AppColors.error,
//         ),
//       ),
//       child: Column(
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               const Text('التكلفة الإجمالية:', style: TextStyle(fontFamily: 'Tajawal')),
//               Text('${totalCost.toStringAsFixed(2)} د', style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 color: isValid ? AppColors.success : AppColors.error,
//               )),
//             ],
//           ),
//           const SizedBox(height: 4),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               const Text('الميزانية المتاحة:', style: TextStyle(fontFamily: 'Tajawal')),
//               Text('${budget.toStringAsFixed(2)} د', style: const TextStyle(fontWeight: FontWeight.bold)),
//             ],
//           ),
//           const SizedBox(height: 4),
//           Text(
//             isValid ? 'الميزانية كافية ✅' : 'الميزانية غير كافية ❌',
//             style: TextStyle(
//               color: isValid ? AppColors.success : AppColors.error,
//               fontWeight: FontWeight.bold,
//               fontFamily: 'Tajawal',
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildMarketplaceSection() {
//     return Card(
//       elevation: 2,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'إعدادات السوق المباشر',
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//                 fontFamily: 'Tajawal',
//               ),
//             ),
//             const SizedBox(height: 12),
            
//             // Frais du marketplace
//             Container(
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: AppColors.info.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: const Row(
//                 children: [
//                   Icon(Icons.info_rounded, color: AppColors.info),
//                   SizedBox(width: 8),
//                   Expanded(
//                     child: Text(
//                       'رسوم عرض المنتج في السوق: 2 دينار\nسيتم خصمها من رصيدك عند إضافة المنتج',
//                       style: TextStyle(
//                         fontSize: 12,
//                         color: AppColors.info,
//                         fontFamily: 'Tajawal',
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildSummarySection() {
//     double totalCost = 0;
//     String details = '';

//     if (_selectedType == ProductType.cpc) {
//       final targetClicks = int.tryParse(_targetClicksController.text) ?? 0;
//       totalCost = targetClicks * _cpcRate;
//       details = 'ميزانية النقرات: ${totalCost.toStringAsFixed(2)} د';
//     } else if (_selectedType == ProductType.marketplace) {
//       totalCost = 2.0;
//       details = 'رسوم السوق: 2.0 د';
//     } else if (_selectedType == ProductType.hybrid) {
//       final targetClicks = int.tryParse(_targetClicksController.text) ?? 0;
//       totalCost = (targetClicks * _cpcRate) + 2.0;
//       details = 'ميزانية النقرات + رسوم السوق: ${totalCost.toStringAsFixed(2)} د';
//     }

//     return Card(
//       elevation: 2,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'ملخص التكلفة',
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//                 fontFamily: 'Tajawal',
//               ),
//             ),
//             const SizedBox(height: 12),
            
//             Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: AppColors.primary.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Column(
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       const Text('التكلفة الإجمالية:', style: TextStyle(fontFamily: 'Tajawal')),
//                       Text('${totalCost.toStringAsFixed(2)} د', style: const TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                         color: AppColors.primary,
//                       )),
//                     ],
//                   ),
//                   const SizedBox(height: 8),
//                   Text(details, style: const TextStyle(
//                     color: AppColors.textSecondary,
//                     fontFamily: 'Tajawal',
//                   )),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildSubmitButton(AuthProvider authProvider, MarketplaceProvider marketplaceProvider) {
//     return SizedBox(
//       width: double.infinity,
//       height: 55,
//       child: ElevatedButton(
//         onPressed: _isLoading ? null : () => _submitProduct(authProvider, marketplaceProvider),
//         style: ElevatedButton.styleFrom(
//           backgroundColor: AppColors.primary,
//           foregroundColor: Colors.white,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//           elevation: 2,
//         ),
//         child: _isLoading
//             ? const SizedBox(
//                 height: 20,
//                 width: 20,
//                 child: CircularProgressIndicator(
//                   strokeWidth: 2,
//                   color: Colors.white,
//                 ),
//               )
//             : const Text(
//                 'إضافة المنتج',
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                   fontFamily: 'Tajawal',
//                 ),
//               ),
//       ),
//     );
//   }

//   // Méthodes d'interaction
//   Future<void> _pickImage() async {
//     try {
//       final XFile? image = await _imagePicker.pickImage(
//         source: ImageSource.gallery,
//         maxWidth: 800,
//         maxHeight: 800,
//         imageQuality: 80,
//       );

//       if (image != null) {
//         // En production, il faudrait uploader l'image vers Firebase Storage
//         setState(() {
//           _selectedImages.add(image.path);
//         });
//       }
//     } catch (e) {
//       _showError('فشل في اختيار الصورة: $e');
//     }
//   }

//   void _removeImage(int index) {
//     setState(() {
//       _selectedImages.removeAt(index);
//     });
//   }

//   void _updateCpcSummary() {
//     setState(() {});
//   }

//   Future<void> _submitProduct(AuthProvider authProvider, MarketplaceProvider marketplaceProvider) async {
//     if (!_formKey.currentState!.validate()) {
//       return;
//     }

//     if (_selectedImages.isEmpty) {
//       _showError('يرجى إضافة صورة واحدة على الأقل');
//       return;
//     }

//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       final product = ProductModel(
//         id: const Uuid().v4(),
//         sellerId: authProvider.user!.id,
//         title: _titleController.text,
//         description: _descriptionController.text,
//         price: double.parse(_priceController.text),
//         images: _selectedImages,
//         category: _selectedCategory,
//         type: _selectedType,
//         createdAt: DateTime.now(),
//         cpcBudget: _selectedType == ProductType.cpc || _selectedType == ProductType.hybrid
//             ? double.tryParse(_cpcBudgetController.text)
//             : null,
//         targetClicks: _selectedType == ProductType.cpc || _selectedType == ProductType.hybrid
//             ? int.tryParse(_targetClicksController.text)
//             : null,
//         cpcRate: _cpcRate,
//         isMarketplace: _selectedType == ProductType.marketplace || _selectedType == ProductType.hybrid,
//         marketplaceFee: 2.0,
//       );

//       await marketplaceProvider.addProduct(product);

//       if (mounted) {
//         Navigator.pop(context);
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('تم إضافة المنتج بنجاح!'),
//             backgroundColor: Colors.green,
//           ),
//         );
//       }
//     } catch (e) {
//       _showError('فشل في إضافة المنتج: $e');
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   void _showHelpDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('مساعدة', style: TextStyle(fontFamily: 'Tajawal')),
//         content: const SingleChildScrollView(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 'أنواع المنتجات:',
//                 style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Tajawal'),
//               ),
//               Text('• ربح من النقرات: تربح من كل نقرة على منتجك', style: TextStyle(fontFamily: 'Tajawal')),
//               Text('• سوق مباشر: عرض المنتج للبيع المباشر', style: TextStyle(fontFamily: 'Tajawal')),
//               Text('• مختلط: الجمع بين النظامين', style: TextStyle(fontFamily: 'Tajawal')),
//               SizedBox(height: 12),
//               Text(
//                 'نصائح:',
//                 style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Tajawal'),
//               ),
//               Text('• استخدم صور واضحة وعالية الجودة', style: TextStyle(fontFamily: 'Tajawal')),
//               Text('• اكتب وصفاً مفصلاً وجذاباً', style: TextStyle(fontFamily: 'Tajawal')),
//               Text('• حدد سعراً تنافسياً', style: TextStyle(fontFamily: 'Tajawal')),
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('حسناً', style: TextStyle(fontFamily: 'Tajawal')),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showError(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.red,
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _titleController.dispose();
//     _descriptionController.dispose();
//     _priceController.dispose();
//     _cpcBudgetController.dispose();
//     _targetClicksController.dispose();
//     super.dispose();
//   }
// }