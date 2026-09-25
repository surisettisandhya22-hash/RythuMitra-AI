import 'dart:async';
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
  
  Timer? _timer;
  int _countdown = 45;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    setState(() {
      _countdown = 45;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        if (mounted) {
          setState(() {
            _countdown--;
          });
        }
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  String _maskContact(String contact) {
    if (contact.contains('@')) {
      final parts = contact.split('@');
      if (parts[0].length > 2) {
        return '${parts[0].substring(0, 2)}***@${parts[1]}';
      }
      return contact;
    } else {
      if (contact.length > 4) {
        return '******${contact.substring(contact.length - 4)}';
      }
      return contact;
    }
  }

  Future<void> _handleResend() async {
    setState(() {
      _isResending = true;
    });
    
    final errorCategory = await widget.authService.sendOtp(widget.contact);
    
    if (mounted) {
      setState(() {
        _isResending = false;
      });
      
      if (errorCategory == null) {
        _startTimer();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP resent successfully.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to resend OTP ($errorCategory).')),
        );
      }
    }
  }

  Future<void> _handleVerify() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final otp = _otpController.text.trim();
      final token = await widget.authService.verifyOtp(widget.contact, otp);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (token != null) {
          await widget.storageService.setAuthToken(token);
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
            const SnackBar(content: Text('Invalid or expired OTP. Please try again.')),
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
                  'Enter the OTP sent to',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _maskContact(widget.contact),
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
                    hintText: '------',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter the OTP';
                    }
                    if (value.trim().length != 6) {
                      return 'OTP must be 6 digits';
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
                          'Verify OTP',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                ),
                const SizedBox(height: 24),
                if (_countdown > 0)
                  Text(
                    'Resend OTP in $_countdown seconds',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600),
                  )
                else
                  TextButton(
                    onPressed: _isResending ? null : _handleResend,
                    child: _isResending 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(
                          'Resend OTP',
                          style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold),
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
