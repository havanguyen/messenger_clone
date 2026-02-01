import 'package:flutter/material.dart';
import 'package:messenger_clone/features/auth/data/datasources/otp_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:messenger_clone/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:messenger_clone/features/settings/domain/repositories/device_repository.dart';
import 'package:get_it/get_it.dart';

import 'package:messenger_clone/features/auth/pages/register_name.dart';
import 'package:messenger_clone/features/main_page/main_page.dart';
import 'package:messenger_clone/core/widgets/dialog/custom_alert_dialog.dart';
import 'package:messenger_clone/core/widgets/dialog/loading_dialog.dart';
import 'confirmation_code_screen.dart';
import 'forgot_password.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF162127),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) async {
          if (state is AuthError) {
            Navigator.of(context).pop(); // Close loading dialog if open
            await CustomAlertDialog.show(
              context: context,
              title: "Login error",
              message: state.message,
            );
          } else if (state is AuthAuthenticated) {
            Navigator.of(context).pop(); // Close loading dialog
            final user = state.user;
            await GetIt.I<DeviceRepository>().saveLoginDeviceInfo(user.uid);
            if (!context.mounted) return;
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => MainPage()),
              (route) => false,
            );
          } else if (state is AuthCredentialsChecked) {
            if (state.isValid && state.userId != null) {
              final userID = state.userId!;
              final checkResult = await GetIt.I<DeviceRepository>()
                  .hasUserLoggedInFromThisDevice(userID);
              bool check = checkResult.fold((l) => false, (r) => r);
              if (!context.mounted) return;

              if (check) {
                context.read<AuthBloc>().add(
                  LoginEvent(
                    email: _emailController.text,
                    password: _passwordController.text,
                  ),
                );
              } else {
                Navigator.of(context).pop(); // Close loading dialog
                final otp = OTPEmailService.generateOTP();
                await OTPEmailService.sendOTPEmail(_emailController.text, otp);
                if (!context.mounted) return;

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => ConfirmationCodeScreen(
                          email: _emailController.text,
                          nextScreen: () => MainPage(),
                          action: () async {
                            context.read<AuthBloc>().add(
                              LoginEvent(
                                email: _emailController.text,
                                password: _passwordController.text,
                              ),
                            );
                          },
                        ),
                  ),
                  (route) => false,
                );
              }
            } else {
              Navigator.of(context).pop(); // Close loading dialog
              await CustomAlertDialog.show(
                context: context,
                title: "Login error",
                message: "Wrong email or password.",
              );
            }
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SizedBox(height: MediaQuery.of(context).size.height * 0.1),
              Image.asset(
                "assets/images/logo.png",
                width: 80,
                height: 80,
                fit: BoxFit.contain,
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.07),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Enter your email address',
                  isDense: true,
                  labelStyle: TextStyle(color: Color(0xFF9eabb3)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: Colors.blue),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 20,
                  ),
                ),
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(height: 15),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword ? false : true,
                decoration: InputDecoration(
                  labelText: 'Enter your password',
                  labelStyle: TextStyle(color: Color(0xFF9eabb3)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: Colors.blue),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 20,
                  ),
                  suffixIcon: IconButton(
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
                ),
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(height: 20),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (_emailController.text.isEmpty ||
                        _passwordController.text.isEmpty) {
                      CustomAlertDialog.show(
                        context: context,
                        title: "Warning",
                        message: "Please enter complete information.",
                      );
                    } else if (!RegExp(
                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                        ).hasMatch(_emailController.text) ||
                        _passwordController.text.length <= 8) {
                      CustomAlertDialog.show(
                        context: context,
                        title: "Login error",
                        message: "Wrong email or password.",
                      );
                    } else {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder:
                            (context) =>
                                const LoadingDialog(message: "Logging in..."),
                      );
                      context.read<AuthBloc>().add(
                        CheckCredentialsEvent(
                          email: _emailController.text,
                          password: _passwordController.text,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    'Login',
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                ),
              ),
              SizedBox(height: 10),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ForgotPasswordScreen(),
                    ),
                  );
                },
                child: const Center(
                  child: Text(
                    'Forgot your password?',
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Spacer(),
              SizedBox(height: 20),
              SizedBox(
                height: 50,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NameInputScreen(),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.blue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    'Create new account',
                    style: TextStyle(color: Colors.blue, fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
