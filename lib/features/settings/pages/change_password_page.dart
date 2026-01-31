import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:messenger_clone/common/extensions/custom_theme_extension.dart';
import 'package:messenger_clone/common/widgets/custom_text_style.dart';
import 'package:messenger_clone/common/widgets/dialog/custom_alert_dialog.dart';
import 'package:messenger_clone/common/widgets/dialog/loading_dialog.dart';

import '../../../common/services/auth_service.dart';
import '../../main_page/main_page.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _errorMessage;
  bool _obscureOldPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLengthValid = false;
  bool _isNoUsernameValid = true;
  bool _isSpecialCharValid = false;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _validateNewPassword(String value) {
    setState(() {
      _isLengthValid = value.length >= 8 && value.length <= 50;
      _isNoUsernameValid = true;
      _isSpecialCharValid =
          RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value) &&
          RegExp(r'[a-z]').hasMatch(value) &&
          RegExp(r'\d').hasMatch(value);
    });
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    final oldPassword = _oldPasswordController.text;
    final newPassword = _newPasswordController.text;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const LoadingDialog(message: "Updating password..."),
    );

    try {
      final user = await AuthService.getCurrentUser();
      if (user == null) throw Exception("User not logged in.");

      await AuthService.reauthenticate(oldPassword);
      await AuthService.updateUserAuth(userId: user.uid, password: newPassword);

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainPage()),
          (route) => false,
        );
        await CustomAlertDialog.show(
          context: context,
          title: "Success",
          message: "Your password has been updated successfully.",
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        setState(() {
          if (e is FirebaseAuthException) {
            if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
              _errorMessage =
                  "The old password is incorrect. Please try again.";
            } else if (e.code == 'too-many-requests') {
              _errorMessage = "Too many requests. Please try again later.";
            } else {
              _errorMessage = "Error updating password: ${e.message}";
            }
          } else {
            _errorMessage = "Error updating password: $e";
          }
        });
      }
    }
  }

  InputDecoration _buildInputDecoration(
    String label,
    bool obscureText,
    VoidCallback onToggle,
  ) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: context.theme.textColor.withOpacity(0.7)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      suffixIcon: IconButton(
        icon: Icon(
          obscureText ? Icons.visibility : Icons.visibility_off,
          color: context.theme.textColor.withOpacity(0.7),
        ),
        onPressed: onToggle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.bg,
      appBar: AppBar(
        backgroundColor: context.theme.bg,
        elevation: 0,
        title: const TitleText(
          'Change Password',
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.theme.textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              CircleAvatar(
                radius: 40,
                backgroundColor: context.theme.blue.withOpacity(0.1),
                child: Icon(Icons.lock, size: 40, color: context.theme.blue),
              ),
              const SizedBox(height: 30),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: TitleText(
                    _errorMessage!,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: context.theme.red,
                  ),
                ),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _oldPasswordController,
                      obscureText: _obscureOldPassword,
                      decoration: _buildInputDecoration(
                        'Old Password',
                        _obscureOldPassword,
                        () => setState(
                          () => _obscureOldPassword = !_obscureOldPassword,
                        ),
                      ),
                      style: TextStyle(color: context.theme.textColor),
                      validator:
                          (value) =>
                              value == null || value.isEmpty
                                  ? 'Please enter your old password'
                                  : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _newPasswordController,
                      obscureText: _obscureNewPassword,
                      onChanged: _validateNewPassword,
                      decoration: _buildInputDecoration(
                        'New Password',
                        _obscureNewPassword,
                        () => setState(
                          () => _obscureNewPassword = !_obscureNewPassword,
                        ),
                      ),
                      style: TextStyle(color: context.theme.textColor),
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'Please enter a new password';
                        if (value == _oldPasswordController.text)
                          return 'New password must be different from the old password';
                        if (value.length < 8 || value.length > 50)
                          return 'Password must be between 8-50 characters';
                        if (!RegExp(r'[a-z]').hasMatch(value))
                          return 'Password must contain at least 1 lowercase letter';
                        if (!RegExp(r'\d').hasMatch(value))
                          return 'Password must contain at least 1 number';
                        if (!RegExp(
                          r'[!@#$%^&*(),.?":{}|<>]',
                        ).hasMatch(value)) {
                          return 'Password must contain at least 1 special character';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      decoration: _buildInputDecoration(
                        'Confirm Password',
                        _obscureConfirmPassword,
                        () => setState(
                          () =>
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword,
                        ),
                      ),
                      style: TextStyle(color: context.theme.textColor),
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'Please confirm your password';
                        if (value != _newPasswordController.text)
                          return 'Passwords do not match';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildPasswordRequirements(),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _changePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.theme.blue,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const TitleText(
                  'Save',
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordRequirements() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TitleText(
          'Password must be between 8-50 characters',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color:
              _isLengthValid
                  ? context.theme.green
                  : context.theme.textColor.withOpacity(0.5),
        ),
        const SizedBox(height: 4),
        TitleText(
          'Password must not match your phone number/username',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color:
              _isNoUsernameValid
                  ? context.theme.green
                  : context.theme.textColor.withOpacity(0.5),
        ),
        const SizedBox(height: 4),
        TitleText(
          'Password must contain at least 1 lowercase letter, 1 number, and 1 special character',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color:
              _isSpecialCharValid
                  ? context.theme.green
                  : context.theme.textColor.withOpacity(0.5),
        ),
      ],
    );
  }
}
