import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:messenger_clone/features/auth/domain/repositories/auth_repository.dart';
// import 'package:messenger_clone/core/services/auth_service.dart'; // Removed
import 'package:messenger_clone/features/auth/data/datasources/otp_service.dart';
import 'package:messenger_clone/core/widgets/dialog/custom_alert_dialog.dart';
import 'package:messenger_clone/core/widgets/dialog/loading_dialog.dart';
import 'package:messenger_clone/features/auth/pages/confirmation_code_screen.dart';
import 'package:messenger_clone/features/auth/pages/reset_password.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  String? _emailError;

  void _validateInputs() {
    setState(() {
      _emailError =
          _emailController.text.isEmpty ? 'Please enter your email' : null;
    });
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
              "Find Your Account",
              style: TextStyle(
                fontSize: 29,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Enter the email associated with your account to receive an OTP.",
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                isDense: true,
                labelStyle: TextStyle(
                  color:
                      _emailError != null
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
                errorText: _emailError,
                suffixIcon:
                    _emailError != null
                        ? const Icon(Icons.error, color: Colors.red)
                        : null,
                errorStyle: const TextStyle(color: Colors.red),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 20,
                ),
              ),
              style: const TextStyle(color: Colors.white),
              onChanged: (value) {
                setState(() {
                  _emailError = null;
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
                  if (_emailController.text.isNotEmpty) {
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(_emailController.text)) {
                      await CustomAlertDialog.show(
                        context: context,
                        title: "Invalid Email",
                        message: "Please enter a valid email format.",
                      );
                      return;
                    }
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder:
                          (context) =>
                              const LoadingDialog(message: "Checking email..."),
                    );
                    try {
                      final result = await GetIt.I<AuthRepository>()
                          .isEmailRegistered(_emailController.text);

                      if (!context.mounted) return;
                      Navigator.of(context).pop();

                      result.fold(
                        (failure) async {
                          await CustomAlertDialog.show(
                            context: context,
                            title: "System Error",
                            message:
                                "Unable to check email: ${failure.message}",
                          );
                        },
                        (isRegistered) async {
                          if (!isRegistered) {
                            await CustomAlertDialog.show(
                              context: context,
                              title: "Email Not Found",
                              message:
                                  "This email is not registered. Please use a different email or create a new account.",
                            );
                          } else {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder:
                                  (context) => const LoadingDialog(
                                    message: "Sending OTP...",
                                  ),
                            );
                            final otp = OTPEmailService.generateOTP();
                            await OTPEmailService.sendOTPEmail(
                              _emailController.text,
                              otp,
                            );
                            if (!context.mounted) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => ConfirmationCodeScreen(
                                      email: _emailController.text,
                                      nextScreen:
                                          () => ResetPasswordScreen(
                                            email: _emailController.text,
                                          ),
                                      action: () async {},
                                    ),
                              ),
                            );
                          }
                        },
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      Navigator.of(context).pop();
                      await CustomAlertDialog.show(
                        context: context,
                        title: "System Error",
                        message:
                            "Unable to check email. Please try again later.",
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Next',
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

