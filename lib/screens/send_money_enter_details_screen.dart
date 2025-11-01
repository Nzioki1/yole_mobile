import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_provider.dart';
import '../providers/api_providers.dart';
import '../providers/transaction_provider.dart';
import '../widgets/gradient_button.dart';
import '../models/api/country.dart';
import '../router_types.dart';
import '../l10n/app_localizations.dart';

class SendMoneyEnterDetailsScreen extends ConsumerStatefulWidget {
  const SendMoneyEnterDetailsScreen({super.key});

  @override
  ConsumerState<SendMoneyEnterDetailsScreen> createState() =>
      _SendMoneyEnterDetailsScreenState();
}

class _SendMoneyEnterDetailsScreenState
    extends ConsumerState<SendMoneyEnterDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String _selectedCurrency = 'USD';
  String? _selectedRecipient;
  String? _selectedRecipientPhone;
  String? _selectedRecipientCountry;
  String _selectedPaymentMethod = 'mobile_money'; // Default to mobile money
  bool _isFormValid = false;
  List<Country> _availableCountries = [];
  bool _isLoadingCountries = false;
  String? _countriesError;

  // State for charges
  double? _calculatedCharges;
  double? _totalAmount;
  bool _isCalculatingCharges = false;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_validateForm);
    _amountController.addListener(_onAmountOrCountryChanged);
    _selectedRecipient = null;
    _loadCountries();

    // Check for pre-selected recipient from arguments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['recipient'] != null) {
        setState(() {
          _selectedRecipient = args['recipient'] as String;
          _selectedRecipientCountry =
              args['recipientCountry'] as String? ?? 'CD'; // Default to DRC
        });
        _validateForm();
      }
    });
  }

  Future<void> _loadCountries() async {
    setState(() {
      _isLoadingCountries = true;
      _countriesError = null;
    });

    try {
      final dataService = ref.read(dataServiceProvider);
      final countries = await dataService.getCountries();

      setState(() {
        _availableCountries = countries;
        _isLoadingCountries = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingCountries = false;
        _countriesError = 'Failed to load countries: $e';
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _validateForm() {
    setState(() {
      _isFormValid = _amountController.text.isNotEmpty &&
          double.tryParse(_amountController.text) != null &&
          double.parse(_amountController.text) > 0 &&
          _selectedRecipient != null &&
          _selectedRecipientPhone != null &&
          _selectedRecipientPhone!.isNotEmpty &&
          _selectedRecipientCountry != null;
    });
  }

  void _onAmountOrCountryChanged() {
    if (_amountController.text.isNotEmpty &&
        _selectedRecipientCountry != null) {
      _calculateCharges();
    }
  }

  String _formatPhoneWithCountryCode(String phone, String? countryCode) {
    String cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.startsWith('0')) {
      cleaned = cleaned.substring(1);
    }

    final Map<String, String> countryDialCodes = {
      'CD': '243', // Congo (DRC)
      'KE': '254', // Kenya
      'UG': '256', // Uganda
      'TZ': '255', // Tanzania
    };

    final dialCode = countryDialCodes[countryCode] ?? '';

    if (dialCode.isEmpty) return '+$cleaned';

    if (cleaned.startsWith(dialCode)) {
      return '+$cleaned';
    }

    return '+$dialCode$cleaned';
  }

  Future<void> _calculateCharges() async {
    if (_amountController.text.isEmpty || _selectedRecipientCountry == null)
      return;

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) return;

    setState(() => _isCalculatingCharges = true);

    await ref.read(chargesProvider.notifier).calculateCharges(
          amount: amount,
          currency: _selectedCurrency,
          recipientCountry: _selectedRecipientCountry!,
        );

    final charges = ref.read(chargesProvider).charges;
    setState(() {
      _calculatedCharges = charges?.feeAmount;
      _totalAmount = amount + (charges?.feeAmount ?? 0);
      _isCalculatingCharges = false;
    });
  }

  List<DropdownMenuItem<String>> _buildCountryDropdownItems() {
    final l10n = AppLocalizations.of(context)!;
    if (_isLoadingCountries) {
      return [
        DropdownMenuItem(
          value: null,
          child: Text(l10n.loadingCountries),
        ),
      ];
    }

    if (_countriesError != null) {
      return [
        DropdownMenuItem(
          value: null,
          child: Text(l10n.errorLoadingCountries),
        ),
      ];
    }

    if (_availableCountries.isEmpty) {
      return [
        DropdownMenuItem(
          value: null,
          child: Text(l10n.noCountriesAvailable),
        ),
      ];
    }

    return _availableCountries.map((country) {
      return DropdownMenuItem<String>(
        value: country.code,
        child: Text(country.displayName),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = ref.watch(appProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Container(
        decoration: appState.isDark
            ? BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.colorScheme.surface,
                    theme.colorScheme.surface.withOpacity(0.8),
                  ],
                ),
              )
            : null,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(theme, appState),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 32),
                        _buildAmountSection(theme, appState),
                        const SizedBox(height: 24),
                        _buildCurrencySection(theme, appState),
                        const SizedBox(height: 24),
                        _buildRecipientSection(theme, appState),
                        const SizedBox(height: 24),
                        _buildRecipientCountrySection(theme, appState),
                        const SizedBox(height: 24),
                        _buildPaymentMethodSection(theme, appState),
                        const SizedBox(height: 24),
                        _buildNoteSection(theme, appState),
                        const SizedBox(height: 24),
                        if (_calculatedCharges != null || _isCalculatingCharges)
                          _buildChargesSection(theme, appState),
                        const SizedBox(height: 48),
                        _buildContinueButton(theme, appState),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, AppState appState) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_ios,
              color: theme.colorScheme.onSurface,
            ),
          ),
          Expanded(
            child: Text(
              l10n.sendMoney,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildAmountSection(ThemeData theme, AppState appState) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.amount,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _amountController,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            hintText: '0.00',
            hintStyle: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
              fontSize: 24,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.outline.withOpacity(0.5),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.outline.withOpacity(0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: theme.colorScheme.surface,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return l10n.amountMustBeGreaterThanZero;
            }
            final amount = double.tryParse(value);
            if (amount == null || amount <= 0) {
              return l10n.pleaseEnterValidAmount;
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCurrencySection(ThemeData theme, AppState appState) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.currency,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildCurrencyButton('USD', theme, appState),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCurrencyButton('EUR', theme, appState),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCurrencyButton(
      String currency, ThemeData theme, AppState appState) {
    final isSelected = _selectedCurrency == currency;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCurrency = currency;
        });
        _validateForm();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withOpacity(0.5),
          ),
        ),
        child: Text(
          currency,
          style: TextStyle(
            color: isSelected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildRecipientSection(ThemeData theme, AppState appState) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.recipient,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final result =
                await Navigator.of(context).pushNamed(RouteNames.favorites);
            if (result != null && result is Map<String, dynamic>) {
              setState(() {
                _selectedRecipient = result['recipient'];
                final rawPhone = result['recipientPhone'];
                final countryCode = result['recipientCountry'];

                if (countryCode != null) {
                  _selectedRecipientCountry = countryCode;
                }

                if (rawPhone != null) {
                  _selectedRecipientPhone = _formatPhoneWithCountryCode(
                    rawPhone,
                    _selectedRecipientCountry,
                  );
                }
              });
              _validateForm();
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.5),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.person_outline,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedRecipient != null
                        ? (_selectedRecipientPhone != null
                            ? '$_selectedRecipient\n$_selectedRecipientPhone'
                            : _selectedRecipient!)
                        : l10n.selectRecipient,
                    style: TextStyle(
                      color: _selectedRecipient != null
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 16,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecipientCountrySection(ThemeData theme, AppState appState) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.recipientCountry,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedRecipientCountry,
          decoration: InputDecoration(
            hintText: l10n.selectRecipientCountry,
            hintStyle: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.outline.withOpacity(0.5),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.outline.withOpacity(0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: theme.colorScheme.surface,
          ),
          style: TextStyle(
            color: theme.colorScheme.onSurface,
          ),
          items: _buildCountryDropdownItems(),
          onChanged: (value) {
            setState(() {
              _selectedRecipientCountry = value;
            });
            _validateForm();
            _calculateCharges();
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return l10n.pleaseSelectRecipientCountry;
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPaymentMethodSection(ThemeData theme, AppState appState) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.paymentMethod,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedPaymentMethod,
          decoration: InputDecoration(
            hintText: l10n.selectPaymentMethod,
            hintStyle: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.outline.withOpacity(0.5),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.outline.withOpacity(0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: theme.colorScheme.surface,
          ),
          style: TextStyle(
            color: theme.colorScheme.onSurface,
          ),
          items: [
            DropdownMenuItem<String>(
              value: 'mobile_money',
              child: Row(
                children: [
                  Icon(
                    Icons.phone_android,
                    size: 20,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  const SizedBox(width: 8),
                  Text(l10n.mobileMoney),
                ],
              ),
            ),
            DropdownMenuItem<String>(
              value: 'pesapal',
              child: Row(
                children: [
                  Icon(
                    Icons.credit_card,
                    size: 20,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  const SizedBox(width: 8),
                  Text(l10n.pesapalCardPayment),
                ],
              ),
            ),
          ],
          onChanged: (value) {
            setState(() {
              _selectedPaymentMethod = value!;
            });
          },
        ),
      ],
    );
  }

  Widget _buildNoteSection(ThemeData theme, AppState appState) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.noteOptional,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _noteController,
          maxLines: 3,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            hintText: l10n.addMessageForRecipient,
            hintStyle: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.outline.withOpacity(0.5),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.outline.withOpacity(0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: theme.colorScheme.surface,
          ),
        ),
      ],
    );
  }

  Widget _buildChargesSection(ThemeData theme, AppState appState) {
    final l10n = AppLocalizations.of(context)!;
    if (_isCalculatingCharges) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              l10n.calculatingCharges,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (_calculatedCharges == null || _totalAmount == null) {
      return const SizedBox.shrink();
    }

    final amount = double.parse(_amountController.text);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.summary,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildSummaryRow(
              l10n.amount,
              '${_selectedCurrency == 'USD' ? '\$' : '€'}${amount.toStringAsFixed(2)}',
              theme),
          _buildSummaryRow(
              l10n.fees,
              '${_selectedCurrency == 'USD' ? '\$' : '€'}${_calculatedCharges!.toStringAsFixed(2)}',
              theme),
          Divider(
            color: theme.colorScheme.outline.withOpacity(0.3),
          ),
          _buildSummaryRow(
              l10n.total,
              '${_selectedCurrency == 'USD' ? '\$' : '€'}${_totalAmount!.toStringAsFixed(2)}',
              theme,
              isTotal: true),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, ThemeData theme,
      {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              fontSize: 14,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 14,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton(ThemeData theme, AppState appState) {
    final l10n = AppLocalizations.of(context)!;
    return GradientButton(
      height: 48,
      borderRadius: 16,
      onPressed: _isFormValid
          ? () {
                print('=== CONTINUE CLICKED ===');
                print('Amount: ${_amountController.text}');
                print('Recipient: $_selectedRecipient');
                print('Phone: $_selectedRecipientPhone');
                print('Country: $_selectedRecipientCountry');
                print('Payment: $_selectedPaymentMethod');
                print('Charges: $_calculatedCharges');
                print('Total: $_totalAmount');

                final isValid = _formKey.currentState?.validate() ?? false;
                print('Form validate result: $isValid');

                if (isValid) {
                  print('Navigating to review screen...');
                  Navigator.pushNamed(
                    context,
                    RouteNames.sendMoneyReview,
                    arguments: {
                      'amount': double.parse(_amountController.text),
                      'currency': _selectedCurrency,
                      'recipient': _selectedRecipient,
                      'recipientPhone': _selectedRecipientPhone,
                      'recipientCountry': _selectedRecipientCountry,
                      'paymentMethod': _selectedPaymentMethod,
                      'note': _noteController.text,
                      'calculatedCharges': _calculatedCharges,
                      'totalAmount': _totalAmount,
                    },
                  );
                } else {
                  print('Form validation FAILED');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.checkAllFields),
                      backgroundColor: theme.colorScheme.error,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              }
          : null,
      enabled: _isFormValid,
      child: Text(l10n.continueButton),
    );
  }
}
