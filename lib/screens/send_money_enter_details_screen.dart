import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_provider.dart';

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
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_validateForm);
    _selectedRecipient = null;
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
          _selectedRecipient != null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = ref.watch(appProvider);

    return Scaffold(
      backgroundColor: appState.isDark ? null : Colors.white,
      body: Container(
        decoration: appState.isDark
            ? const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0B0F19), Color(0xFF19173D)],
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
                        _buildNoteSection(theme, appState),
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
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_ios,
              color: appState.isDark ? Colors.white : Colors.black,
            ),
          ),
          Expanded(
            child: Text(
              'Send Money',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: appState.isDark ? Colors.white : Colors.black,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Amount',
          style: theme.textTheme.titleMedium?.copyWith(
            color: appState.isDark ? Colors.white : Colors.black,
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
            color: appState.isDark ? Colors.white : Colors.black,
          ),
          decoration: InputDecoration(
            hintText: '0.00',
            hintStyle: TextStyle(
              color: appState.isDark ? Colors.white54 : Colors.grey[600],
              fontSize: 24,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: appState.isDark ? Colors.white24 : Colors.grey[300]!,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: appState.isDark ? Colors.white24 : Colors.grey[300]!,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF3B82F6)),
            ),
            filled: true,
            fillColor: appState.isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.grey[50],
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Amount must be greater than 0';
            }
            final amount = double.tryParse(value);
            if (amount == null || amount <= 0) {
              return 'Please enter a valid amount';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCurrencySection(ThemeData theme, AppState appState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Currency',
          style: theme.textTheme.titleMedium?.copyWith(
            color: appState.isDark ? Colors.white : Colors.black,
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
              ? const Color(0xFF3B82F6)
              : appState.isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF3B82F6)
                : appState.isDark
                    ? Colors.white24
                    : Colors.grey[300]!,
          ),
        ),
        child: Text(
          currency,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : appState.isDark
                    ? Colors.white
                    : Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildRecipientSection(ThemeData theme, AppState appState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recipient',
          style: theme.textTheme.titleMedium?.copyWith(
            color: appState.isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            // TODO: Navigate to recipient selection
            setState(() {
              _selectedRecipient = 'Marie Koffi';
            });
            _validateForm();
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: appState.isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: appState.isDark ? Colors.white24 : Colors.grey[300]!,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.person_outline,
                  color: appState.isDark ? Colors.white54 : Colors.grey[600],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedRecipient ?? 'Select recipient',
                    style: TextStyle(
                      color: _selectedRecipient != null
                          ? (appState.isDark ? Colors.white : Colors.black)
                          : (appState.isDark
                              ? Colors.white54
                              : Colors.grey[600]),
                      fontSize: 16,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: appState.isDark ? Colors.white54 : Colors.grey[600],
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoteSection(ThemeData theme, AppState appState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Note (Optional)',
          style: theme.textTheme.titleMedium?.copyWith(
            color: appState.isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _noteController,
          maxLines: 3,
          style: TextStyle(
            color: appState.isDark ? Colors.white : Colors.black,
          ),
          decoration: InputDecoration(
            hintText: 'Add a message for the recipient',
            hintStyle: TextStyle(
              color: appState.isDark ? Colors.white54 : Colors.grey[600],
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: appState.isDark ? Colors.white24 : Colors.grey[300]!,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: appState.isDark ? Colors.white24 : Colors.grey[300]!,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF3B82F6)),
            ),
            filled: true,
            fillColor: appState.isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.grey[50],
          ),
        ),
      ],
    );
  }

  Widget _buildContinueButton(ThemeData theme, AppState appState) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: _isFormValid
            ? () {
                if (_formKey.currentState!.validate()) {
                  // Navigate to review screen with data
                  Navigator.pushNamed(
                    context,
                    '/send-money-review',
                    arguments: {
                      'amount': double.parse(_amountController.text),
                      'currency': _selectedCurrency,
                      'recipient': _selectedRecipient,
                      'note': _noteController.text,
                    },
                  );
                }
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isFormValid ? const Color(0xFF3B82F6) : Colors.grey,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Continue',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
