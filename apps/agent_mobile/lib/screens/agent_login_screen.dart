import 'package:flutter/material.dart';
import '../services/agent_api_service.dart';

class AgentLoginScreen extends StatefulWidget {
  const AgentLoginScreen({super.key});

  @override
  State<AgentLoginScreen> createState() => _AgentLoginScreenState();
}

class _AgentLoginScreenState extends State<AgentLoginScreen> {
  final _agentIdController = TextEditingController();
  final _api = AgentApiService();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _api.init().then((_) {
      // If already logged in, go to home
      _agentIdController.text = 'agent_1'; // Default for demo
    });
  }

  Future<void> _login() async {
    if (_agentIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Agent ID')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      // Verify agent exists
      await _api.getAgentInfo(_agentIdController.text);
      await _api.setAgentId(_agentIdController.text);
      
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: $e')),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.business_center, size: 80, color: Colors.blue),
              const SizedBox(height: 24),
              const Text(
                'YOLE Agent',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _agentIdController,
                decoration: const InputDecoration(
                  labelText: 'Agent ID',
                  hintText: 'agent_1',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.badge),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Note: Agents are created by admin. Use agent_1 for demo.\n'
                'Agent auth uses X-Agent-Id header.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : _login,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
