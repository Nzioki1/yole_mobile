import 'package:flutter/material.dart';
import '../services/core_api_service.dart';

class CreditScreen extends StatefulWidget {
  const CreditScreen({super.key});

  @override
  State<CreditScreen> createState() => _CreditScreenState();
}

class _CreditScreenState extends State<CreditScreen> {
  final _api = CoreApiService();
  bool _loading = false;
  Map<String, dynamic>? _eligibility;
  Map<String, dynamic>? _loan;

  @override
  void initState() {
    super.initState();
    _api.init();
    _checkEligibility();
  }

  Future<void> _checkEligibility() async {
    setState(() => _loading = true);
    try {
      final result = await _api.checkCreditEligibility(type: 'SALARY_ADVANCE');
      setState(() => _eligibility = result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _requestLoan() async {
    setState(() => _loading = true);
    try {
      final result = await _api.requestLoan(
        type: 'SALARY_ADVANCE',
        principalMinor: '10000',
        currency: 'USD',
        termMonths: 3,
      );
      setState(() => _loan = result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Loan disbursed successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Credit & Loans')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Salary Advance', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (_eligibility != null) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Eligible: ${_eligibility!['eligible']}'),
                          Text('Max Amount: ${_eligibility!['maxAmountMinor']} minor units'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _requestLoan,
                            child: const Text('Request \$100 Loan'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (_loan != null) ...[
                  const SizedBox(height: 16),
                  Card(
                    color: Colors.green[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('✅ Loan Approved', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('Loan ID: ${_loan!['loanId']}'),
                          Text('Amount: ${_loan!['principalMinor']} minor'),
                          Text('Status: ${_loan!['status']}'),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}
