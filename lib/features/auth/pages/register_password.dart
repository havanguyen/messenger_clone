import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:messenger_clone/features/auth/pages/confirmation_code_screen.dart';

import '../../../common/services/auth_service.dart';
import '../../../common/services/store.dart';
import '../../../common/widgets/dialog/custom_alert_dialog.dart';
import '../../../common/widgets/dialog/loading_dialog.dart';
import 'login_screen.dart';

class CreatePasswordScreen extends StatefulWidget {
  const CreatePasswordScreen({super.key});

  @override
  State<CreatePasswordScreen> createState() => _CreatePasswordScreenState();
}

class _CreatePasswordScreenState extends State<CreatePasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  String? _passwordError;
  bool _obscurePassword = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF162127),
      appBar: AppBar(
        backgroundColor: const Color(0xFF162127),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () async {
            final email = await Store.getEmailRegistered();
            if (!context.mounted) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ConfirmationCodeScreen(email: email),
              ),
            );
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
              "Create a password",
              style: TextStyle(
                fontSize: 29,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Create a password with at least 8 characters including letters and numbers . It should be something others can't guess .",
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword ? false : true,
              decoration: InputDecoration(
                labelText: 'Password',
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
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 20,
                ),
                errorText: _passwordError,
                suffixIcon: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      if (_passwordError != null)
                        const Icon(Icons.error, color: Colors.red),
                    ],
                  ),
                ),
                errorStyle: const TextStyle(color: Colors.red),
              ),
              style: const TextStyle(color: Colors.white),
              onChanged: (value) {
                setState(() {
                  _passwordError = null;
                });
              },
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  _validatePassword();
                  if (_passwordError == null) {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder:
                          (context) => const LoadingDialog(
                            message: "Creating an account...",
                          ),
                    );

                    try {
                      await AuthService.signUp(
                        email: await Store.getEmailRegistered(),
                        password: _passwordController.text,
                        name: await Store.getNameRegistered(),
                      );
                      if (!context.mounted) return;
                      Navigator.of(context).pop();

                      await CustomAlertDialog.show(
                        context: context,
                        title: "Success",
                        message: "Account created successfully.",
                      );

                      await Store.setEmailRegistered("");
                      await Store.setNameRegistered("");
                      if (!context.mounted) return;
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => LoginScreen()),
                        (route) => false,
                      );
                    } on FirebaseAuthException catch (e) {
                      if (!context.mounted) return;
                      Navigator.of(context).pop();

                      String errorMessage = "Error creating account";
                      if (e.code == 'email-already-in-use') {
                        errorMessage = "Email has been registered";
                      } else if (e.code == 'weak-password') {
                        errorMessage = "Password is too weak";
                      } else if (e.code == 'invalid-email') {
                        errorMessage = "Invalid email";
                      }

                      await CustomAlertDialog.show(
                        context: context,
                        title: "Error",
                        message: errorMessage,
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      Navigator.of(context).pop();
                      await CustomAlertDialog.show(
                        context: context,
                        title: "Error ",
                        message:
                            "An unexpected error occurred. : ${e.toString()}",
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
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
                },
                child: const Text(
                  'I already have an account',
                  style: TextStyle(fontSize: 16, color: Colors.blue),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _validatePassword() {
    setState(() {
      if (_passwordController.text.isEmpty) {
        _passwordError = 'Password cannot be empty.';
      } else if (_passwordController.text.length <= 8) {
        _passwordError = 'Password must be greater than 8 characters long.';
      } else if (!_isStrongPassword(_passwordController.text)) {
        _passwordError =
            'Password must contain at least one uppercase letter, one lowercase letter, and one number.';
      } else {
        _passwordError = null;
      }
    });
  }

  bool _isStrongPassword(String password) {
    bool hasUpperCase = password.contains(RegExp(r'[A-Z]'));
    bool hasLowerCase = password.contains(RegExp(r'[a-z]'));
    bool hasNumber = password.contains(RegExp(r'[0-9]'));
    return hasUpperCase && hasLowerCase && hasNumber;
  }
}
