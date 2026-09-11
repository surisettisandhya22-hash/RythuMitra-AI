import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import '../../../../core/services/backend_config_service.dart';

class BackendSettingsScreen extends StatefulWidget {
  const BackendSettingsScreen({super.key});

  @override
  State<BackendSettingsScreen> createState() => _BackendSettingsScreenState();
}

class _BackendSettingsScreenState extends State<BackendSettingsScreen> {
  final TextEditingController _urlController = TextEditingController();
  bool _isTesting = false;
  String _testResult = '';
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _urlController.text = BackendConfigService.getBackendUrl();
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _saveConfig() async {
    try {
      await BackendConfigService.setBackendUrl(_urlController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backend URL saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _testResult = 'Testing connection...';
      _isSuccess = false;
    });

    try {
      final url = _urlController.text.trim();
      final uri = Uri.parse('$url/health');
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == 'ok') {
          setState(() {
            _testResult = 'Connection successful';
            _isSuccess = true;
          });
        } else {
          setState(() {
            _testResult = 'Connected, but received unexpected response format.';
            _isSuccess = false;
          });
        }
      } else {
        setState(() {
          _testResult = 'Server returned error code: ${response.statusCode}';
          _isSuccess = false;
        });
      }
    } on TimeoutException {
      setState(() {
        _testResult = 'Unable to connect to the backend (Timeout). The backend server may not be running or is blocked by a firewall.';
        _isSuccess = false;
      });
    } on SocketException {
      setState(() {
        _testResult = 'Unable to connect to the backend. Check that your phone and computer are connected to the same network.';
        _isSuccess = false;
      });
    } catch (e) {
      setState(() {
        _testResult = 'Unable to connect: Invalid URL or unexpected error.';
        _isSuccess = false;
      });
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('⚙️ Backend Connection'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Development Backend URL',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'http://192.168.x.x:8000',
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveConfig,
                    child: const Text('Save URL'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _urlController.text = 'http://10.10.10.10:8000';
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade300),
                    child: const Text('Restore Default', style: TextStyle(color: Colors.black)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _isTesting ? null : _testConnection,
              icon: _isTesting 
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.wifi_tethering),
              label: const Text('Test Backend Connection'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            if (_testResult.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isSuccess ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isSuccess ? Colors.green : Colors.red.shade300,
                  ),
                ),
                child: Text(
                  _testResult,
                  style: TextStyle(
                    color: _isSuccess ? Colors.green.shade800 : Colors.red.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
