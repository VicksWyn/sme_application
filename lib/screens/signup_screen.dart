import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../services/auth_service.dart';
import '../services/analytics_service.dart';
import 'package:sme_application/services/phone_auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  String _fullName = '';
  String _email = '';
  String _password = '';
  String _phoneNumber = '';
  bool _isLoading = false;
  String? _verificationId;

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);
      try {
        await Provider.of<AuthService>(context, listen: false)
            .signUp(_email, _password, _fullName);
        Provider.of<AnalyticsService>(context, listen: false).logSignUp('email');
        _verifyPhoneNumber();
      } on CustomAuthException catch (e) {
        _showErrorDialog(e.toString());
        setState(() => _isLoading = false);
      }
    }
  }

  void _verifyPhoneNumber() async {
    final phoneService = Provider.of<PhoneAuthService>(context, listen: false);
    await phoneService.verifyPhoneNumber(
      _phoneNumber,
      (phoneAuthCredential) async {
        // Auto-retrieval of the SMS code on Android devices
        await _signInWithPhoneNumber(phoneAuthCredential);
      },
      (error) {
        _showErrorDialog(error.message ?? 'An error occurred during phone verification');
        setState(() => _isLoading = false);
      },
      (verificationId, resendToken) {
        setState(() {
          _verificationId = verificationId;
          _isLoading = false;
        });
        _showSmsCodeDialog();
      },
      (verificationId) {
        print('Auto-retrieval timeout');
      },
    );
  }

  void _showSmsCodeDialog() {
    String smsCode = '';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter SMS Code'),
        content: TextField(
          onChanged: (value) => smsCode = value,
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            child: const Text('Verify'),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _signInWithPhoneNumber(
                PhoneAuthProvider.credential(
                  verificationId: _verificationId!,
                  smsCode: smsCode,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _signInWithPhoneNumber(PhoneAuthCredential credential) async {
    setState(() => _isLoading = true);
    try {
      await Provider.of<PhoneAuthService>(context, listen: false)
          .signInWithPhoneNumber(_verificationId!, credential.smsCode!);
      Provider.of<AnalyticsService>(context, listen: false).logSignUp('phone');
      _showVerificationDialog();
    } catch (e) {
      _showErrorDialog('Failed to verify phone number. Please try again.');
    }
    setState(() => _isLoading = false);
  }

  void _showVerificationDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Account Created'),
        content: const Text('Your account has been created and your phone number has been verified. Please check your email to complete the email verification process.'),
        actions: <Widget>[
          TextButton(
            child: const Text('Okay'),
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pushReplacementNamed('/');
            },
          )
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('An Error Occurred'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: const Text('Okay'),
            onPressed: () => Navigator.of(ctx).pop(),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Your Account')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CustomTextField(
                    labelText: 'Full Name',
                    onSaved: (value) => _fullName = value!,
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter your full name' : null,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    labelText: 'Email',
                    onSaved: (value) => _email = value!,
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter your email' : null,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    labelText: 'Password',
                    onSaved: (value) => _password = value!,
                    validator: (value) =>
                        value!.length < 6 ? 'Password must be at least 6 characters' : null,
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    labelText: 'Phone Number',
                    onSaved: (value) => _phoneNumber = value!,
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter your phone number' : null,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 24),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : CustomButton(
                          text: 'SIGN UP',
                          onPressed: _submit,
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

extension on Object? {
  get message => null;
}