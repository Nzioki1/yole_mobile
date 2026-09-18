import 'package:flutter/material.dart';
import '../services/core_api_service.dart';
import '../services/offline_demo_repository.dart';
import '../constants/insurance_products.dart';
import '../models/insurance_product.dart';

class ActivatePolicyScreen extends StatefulWidget {
  const ActivatePolicyScreen({super.key});

  @override
  State<ActivatePolicyScreen> createState() => _ActivatePolicyScreenState();
}

class _ActivatePolicyScreenState extends State<ActivatePolicyScreen> {
  final _api = CoreApiService();
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _pinController = TextEditingController();

  late InsuranceProduct _product;
  PremiumMode _premiumMode = PremiumMode.FIXED;
  FixedSchedule _fixedSchedule = FixedSchedule.MONTHLY;
  DeductFrom _deductFrom = DeductFrom.BOTH;
  bool _loading = false;
  bool _initialized = false;
  bool _isEditMode = false;
  Map<String, dynamic>? _existingPolicy;

  @override
  void initState() {
    super.initState();
    _api.init();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    if (_initialized) return;
    _initialized = true;

    _initializeForm();
  }

  Future<void> _initializeForm() async {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final productId = args['productId'] as String;
    _product = kInsuranceProducts.firstWhere((p) => p.id == productId);

    // Fetch customer's policies to check if this product is already active
    final policies = await _api.getInsurancePolicies('cust_kasee');
    final existingPolicy = policies.firstWhere(
      (p) => p['productId'] == productId && p['active'] == true,
      orElse: () => <String, dynamic>{},
    );

    if (existingPolicy.isNotEmpty) {
      // Edit mode: prefill from existing policy
      _isEditMode = true;
      _existingPolicy = existingPolicy;
      
      final mode = existingPolicy['premiumMode'] as String;
      _premiumMode = PremiumMode.values.firstWhere((e) => e.name == mode);
      
      if (_premiumMode == PremiumMode.PERCENT) {
        final bps = existingPolicy['percentBps'] as int;
        _amountController.text = (bps / 100).toStringAsFixed(1);
      } else {
        final minor = existingPolicy['fixedMinor'] as int;
        _amountController.text = (minor / 100).toStringAsFixed(0);
        
        final schedule = existingPolicy['fixedSchedule'] as String;
        _fixedSchedule = FixedSchedule.values.firstWhere((e) => e.name == schedule);
      }
      
      final deductFrom = existingPolicy['deductFrom'] as String;
      _deductFrom = DeductFrom.values.firstWhere((e) => e.name == deductFrom);
    } else {
      // Activate mode: prefill from product defaults
      _isEditMode = false;
      _premiumMode = _product.defaults.premiumMode;
      _fixedSchedule = _product.defaults.fixedSchedule ?? FixedSchedule.MONTHLY;
      _deductFrom = _product.defaults.deductFrom;

      if (_premiumMode == PremiumMode.PERCENT) {
        final bps = _product.defaults.percentBps ?? 0;
        _amountController.text = (bps / 100).toStringAsFixed(1);
      } else {
        final minor = _product.defaults.fixedMinor ?? 0;
        _amountController.text = (minor / 100).toStringAsFixed(0);
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Verify PIN
    if (_pinController.text != OfflineDemoRepository.demoPin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid PIN'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final amountStr = _amountController.text.trim();
      final amount = double.tryParse(amountStr) ?? 0;

      int? fixedMinor;
      int? percentBps;
      String? fixedSchedule;

      if (_premiumMode == PremiumMode.PERCENT) {
        percentBps = (amount * 100).round();
      } else {
        fixedMinor = (amount * 100).round();
        fixedSchedule = _fixedSchedule.name;
      }

      await _api.activateInsurance(
        customerId: 'cust_kasee',
        productId: _product.id,
        premiumMode: _premiumMode.name,
        fixedSchedule: fixedSchedule,
        fixedMinor: fixedMinor,
        percentBps: percentBps,
        deductFrom: _deductFrom.name,
      );

      if (mounted) {
        final action = _isEditMode ? 'updated' : 'activated';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Insurance ${_product.nameFr} $action successfully. Your coverage is effective immediately.',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to ${_isEditMode ? 'update' : 'activate'}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Show loading until initialization completes
    if (!_initialized) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Loading...'),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final titleAction = _isEditMode ? 'Edit' : 'Activate';

    return Scaffold(
      appBar: AppBar(
        title: Text('$titleAction ${_product.nameFr}'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Premium Type',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<PremiumMode>(
                      title: const Text('Percentage'),
                      value: PremiumMode.PERCENT,
                      groupValue: _premiumMode,
                      onChanged: (value) {
                        setState(() {
                          _premiumMode = value!;
                          _amountController.clear();
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<PremiumMode>(
                      title: const Text('Fixed amount'),
                      value: PremiumMode.FIXED,
                      groupValue: _premiumMode,
                      onChanged: (value) {
                        setState(() {
                          _premiumMode = value!;
                          _amountController.clear();
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (_premiumMode == PremiumMode.FIXED) ...[
                Text(
                  'Schedule',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<FixedSchedule>(
                        title: const Text('Per transaction'),
                        value: FixedSchedule.PER_TXN,
                        groupValue: _fixedSchedule,
                        onChanged: (value) {
                          setState(() => _fixedSchedule = value!);
                        },
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<FixedSchedule>(
                        title: const Text('Monthly'),
                        value: FixedSchedule.MONTHLY,
                        groupValue: _fixedSchedule,
                        onChanged: (value) {
                          setState(() => _fixedSchedule = value!);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              Text(
                _premiumMode == PremiumMode.PERCENT
                    ? 'Percentage'
                    : 'Amount (CDF)',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: _premiumMode == PremiumMode.PERCENT
                      ? 'e.g., 0.3 for 0.3%'
                      : 'e.g., 2500',
                  border: const OutlineInputBorder(),
                  suffixText: _premiumMode == PremiumMode.PERCENT ? '%' : 'CDF',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Must be positive';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              Text(
                'Deduct from',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Column(
                children: [
                  RadioListTile<DeductFrom>(
                    title: const Text('Bills'),
                    value: DeductFrom.BILL,
                    groupValue: _deductFrom,
                    onChanged: (value) {
                      setState(() => _deductFrom = value!);
                    },
                  ),
                  RadioListTile<DeductFrom>(
                    title: const Text('Send money'),
                    value: DeductFrom.SEND,
                    groupValue: _deductFrom,
                    onChanged: (value) {
                      setState(() => _deductFrom = value!);
                    },
                  ),
                  RadioListTile<DeductFrom>(
                    title: const Text('Both'),
                    value: DeductFrom.BOTH,
                    groupValue: _deductFrom,
                    onChanged: (value) {
                      setState(() => _deductFrom = value!);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Text(
                'Confirm PIN',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(
                  hintText: '6-digit PIN',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.length < 4) {
                    return 'PIN must be at least 4 digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _loading ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF008A8A),
                        foregroundColor: Colors.white,
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Confirm'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
