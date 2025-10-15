import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../providers/earnings_provider.dart';

class WithdrawalScreen extends StatefulWidget {
  const WithdrawalScreen({super.key});

  @override
  State<WithdrawalScreen> createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends State<WithdrawalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _recipientNameController = TextEditingController();

  String _selectedPaymentMethod = 'bank_transfer';
  double _availableBalance = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<EarningsProvider>(context, listen: false);
      _availableBalance = provider.stats.availableBalance;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سحب الأموال'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Available Balance
              _buildBalanceCard(),
              const SizedBox(height: 24),

              // Withdrawal Form
              _buildWithdrawalForm(),
              const SizedBox(height: 32),

              // Submit Button
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الرصيد المتاح للسحب',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    fontFamily: 'Tajawal',
                  ),
                ),
                Text(
                  '${_availableBalance.toStringAsFixed(3)} دينار',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontFamily: 'Tajawal',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWithdrawalForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'معلومات السحب',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              fontFamily: 'Tajawal',
            ),
          ),
          const SizedBox(height: 20),

          // Amount
          TextFormField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'المبلغ المطلوب (دينار)',
              prefixIcon: const Icon(Icons.attach_money_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: AppColors.background,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'يرجى إدخال المبلغ';
              }
              final amount = double.tryParse(value) ?? 0;
              if (amount < 100) {
                return 'الحد الأدنى للسحب هو 100 دينار';
              }
              if (amount > _availableBalance) {
                return 'المبلغ يتجاوز الرصيد المتاح';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Payment Method
          DropdownButtonFormField<String>(
            value: _selectedPaymentMethod,
            decoration: InputDecoration(
              labelText: 'طريقة السحب',
              prefixIcon: const Icon(Icons.payment_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: AppColors.background,
            ),
            items: const [
              DropdownMenuItem(
                value: 'bank_transfer',
                child: Text('تحويل بنكي'),
              ),
              DropdownMenuItem(
                value: 'mobile_money',
                child: Text('محفظة إلكترونية'),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _selectedPaymentMethod = value!;
              });
            },
          ),
          const SizedBox(height: 20),

          // Account Number
          TextFormField(
            controller: _accountNumberController,
            decoration: InputDecoration(
              labelText: 'رقم الحساب',
              prefixIcon: const Icon(Icons.numbers_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: AppColors.background,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'يرجى إدخال رقم الحساب';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Bank Name (for bank transfer)
          if (_selectedPaymentMethod == 'bank_transfer')
            TextFormField(
              controller: _bankNameController,
              decoration: InputDecoration(
                labelText: 'اسم البنك',
                prefixIcon: const Icon(Icons.account_balance_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppColors.background,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'يرجى إدخال اسم البنك';
                }
                return null;
              },
            ),
          if (_selectedPaymentMethod == 'bank_transfer') const SizedBox(height: 20),

          // Recipient Name
          TextFormField(
            controller: _recipientNameController,
            decoration: InputDecoration(
              labelText: 'اسم المستلم',
              prefixIcon: const Icon(Icons.person_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: AppColors.background,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'يرجى إدخال اسم المستلم';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Consumer<EarningsProvider>(
      builder: (context, earningsProvider, child) {
        return SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: earningsProvider.isLoading
                ? null
                : () async {
                    if (_formKey.currentState!.validate()) {
                      final amount = double.parse(_amountController.text);
                      
                      await earningsProvider.requestWithdrawal(
                        amount: amount,
                        paymentMethod: _selectedPaymentMethod,
                        accountNumber: _accountNumberController.text,
                        bankName: _bankNameController.text.isNotEmpty 
                            ? _bankNameController.text 
                            : null,
                        recipientName: _recipientNameController.text,
                      );

                      if (earningsProvider.error == null) {
                        _showSuccessDialog(context);
                      } else {
                        _showErrorDialog(context, earningsProvider.error!);
                      }
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: earningsProvider.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'تقديم طلب السحب',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Tajawal',
                    ),
                  ),
          ),
        );
      },
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تم تقديم الطلب بنجاح'),
        content: const Text('جاري معالجة طلب السحب، سيتم التحويل خلال 2-3 أيام عمل'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back
            },
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('خطأ'),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _accountNumberController.dispose();
    _bankNameController.dispose();
    _recipientNameController.dispose();
    super.dispose();
  }
}