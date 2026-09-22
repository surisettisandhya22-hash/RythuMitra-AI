import 'package:flutter/material.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/network_service.dart';
import '../../../profile/services/profile_storage_service.dart';
import '../../services/auth_service.dart';
import '../../../profile/presentation/screens/initial_profile_setup_screen.dart';
import '../../../foundation/presentation/screens/main_screen.dart';

class OtpScreen extends StatefulWidget {
  final StorageService storageService;
  final ProfileStorageService profileStorageService;
  final NetworkService networkService;
  final String contact;
  final AuthService authService;

  const OtpScreen({
    super.key,
    required this.storageService,
    required this.profileStorageService,
    required this.networkService,
    required this.contact,
    required this.authService,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final otp = _otpController.text.trim();
      final isValid = await widget.authService.verifyOtp(widget.contact, otp);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (isValid) {
          await widget.storageService.setLoggedIn(true);
          
          if (!mounted) return;

          final profile = widget.profileStorageService.getFarmerProfile();
          if (profile == null || profile.name.isEmpty || profile.location.isEmpty) {
            // First time login, setup profile
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => InitialProfileSetupScreen(
                  storageService: widget.storageService,
                  profileStorageService: widget.profileStorageService,
                  networkService: widget.networkService,
                ),
              ),
            );
          } else {
            // Returning user
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => MainScreen(
                  storageService: widget.storageService,
                  profileStorageService: widget.profileStorageService,
                  networkService: widget.networkService,
                ),
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid OTP. Please try again.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Verify OTP'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.green.shade900,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.message,
                  size: 80,
                  color: Colors.green.shade700,
                ),
                const SizedBox(height: 32),
                Text(
                  'Enter One Time Password',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sent to ${widget.contact}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  style: const TextStyle(fontSize: 24, letterSpacing: 8),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '----',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter the OTP';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleVerify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Verify & Login',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
