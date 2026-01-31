import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:messenger_clone/features/auth/domain/repositories/auth_repository.dart';

import 'package:messenger_clone/core/widgets/dialog/custom_alert_dialog.dart';
import 'package:messenger_clone/core/widgets/dialog/loading_dialog.dart';
import 'package:messenger_clone/features/auth/pages/login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;

  const ResetPasswordScreen({super.key, required this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  String? _passwordError;
  String? _confirmPasswordError;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  void _validateInputs() {
    setState(() {
      _passwordError =
          _passwordController.text.isEmpty
              ? 'Please enter a password'
              : _passwordController.text.length < 8
              ? 'Password must be at least 8 characters long'
              : null;
      _confirmPasswordError =
          _confirmPasswordController.text.isEmpty
              ? 'Please confirm your password'
              : _confirmPasswordController.text != _passwordController.text
              ? 'Passwords do not match'
              : null;
    });
  }

  Future<void> _updatePassword() async {
    if (_passwordError != null || _confirmPasswordError != null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const LoadingDialog(message: "Updating password..."),
    );

    try {
      final userIdResult = await GetIt.I<AuthRepository>().getUserIdFromEmail(
        widget.email,
      );

      await userIdResult.fold(
        (failure) async {
          if (!context.mounted) return;
          Navigator.of(context).pop();
          await CustomAlertDialog.show(
            context: context,
            title: "Error",
            message: "Unable to verify account: ${failure.message}",
          );
        },
        (userId) async {
          if (userId == null) {
            if (!context.mounted) return;
            Navigator.of(context).pop();
            await CustomAlertDialog.show(
              context: context,
              title: "Error",
              message: "Unable to verify account. Please try again.",
            );
            return;
          }
          final resetResult = await GetIt.I<AuthRepository>().resetPassword(
            userId: userId,
            newPassword: _passwordController.text,
          );

          if (!context.mounted) return;
          Navigator.of(context).pop();

          resetResult.fold(
            (failure) async {
              await CustomAlertDialog.show(
                context: context,
                title: "Error",
                message: "Failed to update password: ${failure.message}",
              );
            },
            (_) async {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
              await CustomAlertDialog.show(
                context: context,
                title: "Success",
                message: "Your password has been updated. Please log in again.",
              );
            },
          );
        },
      );
    } catch (e) {
      if (!context.mounted) return;
      // Close dialog if still open (though we handled it above in most cases, but safety)
      // Navigator.of(context).pop(); // Might pop wrong thing if handled above.
      // Better to rely on folds popping. But 'catch' catches unexpected errors.
      if (Navigator.canPop(context)) Navigator.of(context).pop();

      await CustomAlertDialog.show(
        context: context,
        title: "Error",
        message: "An unexpected error occurred: $e",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF162127),
      appBar: AppBar(
        backgroundColor: const Color(0xFF162127),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              "Reset Password",
              style: TextStyle(
                fontSize: 29,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Enter a new password for your account.",
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'New Password',
                isDense: true,
                labelStyle: TextStyle(
                  color:
                      _passwordError != null
                          ? Colors.red
                          : const Color(0xFF9eabb3),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: Colors.blue),
                ),
                errorText: _passwordError,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                errorStyle: const TextStyle(color: Colors.red),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 20,
                ),
              ),
              style: const TextStyle(color: Colors.white),
              onChanged: (value) {
                setState(() {
                  _passwordError = null;
                });
              },
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                isDense: true,
                labelStyle: TextStyle(
                  color:
                      _confirmPasswordError != null
                          ? Colors.red
                          : const Color(0xFF9eabb3),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: Colors.blue),
                ),
                errorText: _confirmPasswordError,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
                errorStyle: const TextStyle(color: Colors.red),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 20,
                ),
              ),
              style: const TextStyle(color: Colors.white),
              onChanged: (value) {
                setState(() {
                  _confirmPasswordError = null;
                });
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  _validateInputs();
                  if (_passwordError == null && _confirmPasswordError == null) {
                    await _updatePassword();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Update Password',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

