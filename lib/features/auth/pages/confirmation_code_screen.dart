import 'package:flutter/material.dart';
import 'package:messenger_clone/features/auth/pages/register_password.dart';
import 'package:get_it/get_it.dart';
import 'package:messenger_clone/features/auth/domain/repositories/auth_repository.dart';
import 'package:messenger_clone/features/auth/data/datasources/otp_service.dart';
import 'package:messenger_clone/core/local/secure_storage.dart';
import 'package:messenger_clone/core/widgets/dialog/custom_alert_dialog.dart';
import '../../../core/widgets/dialog/loading_dialog.dart';
import '../../main_page/main_page.dart';
import 'login_screen.dart';

class ConfirmationCodeScreen extends StatefulWidget {
  final String email;
  final Widget Function()? nextScreen;
  final Function()? action;
  const ConfirmationCodeScreen({
    super.key,
    required this.email,
    this.nextScreen,
    this.action,
  });

  @override
  State<ConfirmationCodeScreen> createState() => _ConfirmationCodeScreenState();
}

class _ConfirmationCodeScreenState extends State<ConfirmationCodeScreen> {
  final TextEditingController _codeController = TextEditingController();

  String? _codeError;
  void _validateInputs() {
    setState(() {
      _codeError =
          _codeController.text.isEmpty
              ? 'Please enter your confirmation code'
              : null;
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
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () async {
            final userId = await GetIt.I<AuthRepository>().isLoggedIn();
            if (userId == null) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            } else {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const MainPage()),
                (route) => false,
              );
            }
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              "Enter the confirmation code",
              style: TextStyle(
                fontSize: 29,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "To confirm your account, enter the 6-digit code we sent to ${widget.email}. Code will expire in 5 minutes.",
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,

              maxLength: 6,
              decoration: InputDecoration(
                labelText: 'Confirmation code',
                isDense: true,
                labelStyle: TextStyle(
                  color:
                      _codeError != null ? Colors.red : const Color(0xFF9eabb3),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(15)),
                  borderSide: BorderSide(color: Colors.blue),
                ),
                errorText: _codeError,
                suffixIcon:
                    _codeError != null
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
                  _codeError = null;
                });
              },
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  _validateInputs();
                  if (_codeController.text.isNotEmpty) {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder:
                          (context) =>
                              const LoadingDialog(message: "Checking..."),
                    );
                    try {
                      final remainingAttempts =
                          await OTPEmailService.getRemainingAttempts(
                            widget.email,
                          );
                      if (remainingAttempts <= 0) {
                        Navigator.of(context).pop();
                        await CustomAlertDialog.show(
                          context: context,
                          title: "Error ",
                          message:
                              "You entered the wrong verification code too many times, please try again later.",
                        );
                      } else {
                        bool isVerified = await OTPEmailService.verifyOTP(
                          widget.email,
                          _codeController.text,
                        );
                        if (isVerified) {
                          widget.nextScreen == null
                              ? Store.setEmailRegistered(widget.email)
                              : null;

                          final nextPage =
                              widget.nextScreen != null
                                  ? widget.nextScreen!()
                                  : CreatePasswordScreen();
                          widget.action != null ? widget.action!() : null;

                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => nextPage),
                            (route) => false,
                          );
                        } else {
                          Navigator.of(context).pop();
                          await CustomAlertDialog.show(
                            context: context,
                            title: "Error ",
                            message:
                                "Invalid or expired code. Remaining attempts: $remainingAttempts",
                          );
                        }
                      }
                    } catch (e) {
                      Navigator.of(context).pop();
                      await CustomAlertDialog.show(
                        context: context,
                        title: "System error",
                        message:
                            "Unable to verify OTP. Please try again later.",
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
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () async {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder:
                        (context) =>
                            const LoadingDialog(message: "Sending OTP..."),
                  );
                  try {
                    final otp = OTPEmailService.generateOTP();
                    await OTPEmailService.sendOTPEmail(widget.email, otp);
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => ConfirmationCodeScreen(
                              email: widget.email,
                              nextScreen: widget.nextScreen,
                              action: widget.action,
                            ),
                      ),
                      (route) => false,
                    );
                  } catch (e) {
                    Navigator.of(context).pop();
                    await CustomAlertDialog.show(
                      context: context,
                      title: "System error",
                      message: "Unable to send OTP. Please try again later.",
                    );
                  }
                },
                child: const Text(
                  "I didn't get the code. Resend code?",
                  style: TextStyle(fontSize: 16, color: Colors.blue),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

