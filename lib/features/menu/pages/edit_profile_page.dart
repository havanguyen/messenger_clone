import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:messenger_clone/features/auth/data/datasources/otp_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get_it/get_it.dart';
import 'package:messenger_clone/features/auth/domain/repositories/auth_repository.dart';
import 'package:messenger_clone/features/user/domain/repositories/user_repository.dart';
import 'package:messenger_clone/core/utils/custom_theme_extension.dart';
import 'package:messenger_clone/core/widgets/custom_text_style.dart';
import 'package:messenger_clone/features/main_page/main_page.dart';
import 'package:messenger_clone/features/menu/pages/menu_page.dart';

import 'package:messenger_clone/core/widgets/dialog/custom_alert_dialog.dart';
import '../../../core/widgets/dialog/loading_dialog.dart';
import '../../auth/pages/confirmation_code_screen.dart';

class EditProfilePage extends StatefulWidget {
  final String? initialName;
  final String? initialEmail;
  final String? initialAboutMe;
  final String? initialPhotoUrl;
  final String userId;

  const EditProfilePage({
    super.key,
    this.initialName,
    this.initialEmail,
    this.initialAboutMe,
    this.initialPhotoUrl,
    required this.userId,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  String? _name;
  String? _email;
  String? _aboutMe;
  String? _photoUrl;
  File? _selectedImage;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _name = widget.initialName;
    _email = widget.initialEmail;
    _aboutMe = widget.initialAboutMe;
    _photoUrl = widget.initialPhotoUrl;
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  Future<String?> _promptForPassword() async {
    TextEditingController passwordController = TextEditingController();
    String? password;

    while (true) {
      password = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => AlertDialog(
              title: const Text("Enter Password"),
              content: TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Password"),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, passwordController.text);
                  },
                  child: const Text("Confirm"),
                ),
              ],
            ),
      );

      if (password == null || password.isEmpty) {
        await CustomAlertDialog.show(
          context: context,
          title: "Password Required",
          message: "Please enter your current password to proceed.",
        );
        return null;
      }
      break;
    }

    return password;
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      try {
        final bool emailChanged = _email != widget.initialEmail;
        final bool nameChanged = _name != widget.initialName;

        if (emailChanged) {
          final password = await _promptForPassword();
          if (password == null) {
            return;
          }

          showDialog(
            context: context,
            barrierDismissible: false,
            builder:
                (context) => const LoadingDialog(message: "Checking email..."),
          );
          try {
            final result = await GetIt.I<AuthRepository>().isEmailRegistered(
              _email!,
            );
            if (!mounted) return;
            Navigator.of(context).pop();

            await result.fold(
              (failure) async {
                await CustomAlertDialog.show(
                  context: context,
                  title: "System error",
                  message: "Unable to check email: ${failure.message}",
                );
              },
              (isRegistered) async {
                if (isRegistered) {
                  await CustomAlertDialog.show(
                    context: context,
                    title: "Email already exists",
                    message:
                        "This email is already registered. Please use another email.",
                  );
                } else {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder:
                        (context) =>
                            const LoadingDialog(message: "Sending OTP..."),
                  );
                  final otp = OTPEmailService.generateOTP();
                  await OTPEmailService.sendOTPEmail(_email!, otp);

                  if (!mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => ConfirmationCodeScreen(
                            email: _email!,
                            nextScreen: () => MenuPage(),
                            action: () async {
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder:
                                    (context) => const LoadingDialog(
                                      message: "Updating profile...",
                                    ),
                              );
                              try {
                                final reauthResult =
                                    await GetIt.I<AuthRepository>()
                                        .reauthenticate(password);
                                await reauthResult.fold(
                                  (failure) async {
                                    throw FirebaseAuthException(
                                      code: 'wrong-password',
                                      message: failure.message,
                                    );
                                  },
                                  (_) async {
                                    final updateAuthResult =
                                        await GetIt.I<AuthRepository>()
                                            .updateUserAuth(
                                              userId: widget.userId,
                                              name: nameChanged ? _name : null,
                                              email:
                                                  emailChanged ? _email : null,
                                            );

                                    await updateAuthResult.fold(
                                      (failure) async {
                                        throw Exception(failure.message);
                                      },
                                      (_) async {
                                        if (_selectedImage != null) {
                                          final photoResult =
                                              await GetIt.I<UserRepository>()
                                                  .updatePhotoUrl(
                                                    imageFile: _selectedImage!,
                                                    userId: widget.userId,
                                                  );
                                          final newPhotoUrl = photoResult.fold(
                                            (l) => throw Exception(l.message),
                                            (r) => r,
                                          );
                                          setState(() {
                                            _photoUrl = newPhotoUrl;
                                            _selectedImage = null;
                                          });
                                        }
                                        final profileResult =
                                            await GetIt.I<UserRepository>()
                                                .updateUserProfile(
                                                  userId: widget.userId,
                                                  name: _name,
                                                  email: _email,
                                                  aboutMe: _aboutMe,
                                                  photoUrl: _photoUrl,
                                                );
                                        profileResult.fold(
                                          (l) => throw Exception(l.message),
                                          (_) => null,
                                        );
                                      },
                                    );
                                  },
                                );
                              } catch (e) {
                                if (mounted) Navigator.of(context).pop();
                                if (e is FirebaseAuthException &&
                                    (e.code == 'wrong-password' ||
                                        e.code == 'invalid-credential')) {
                                  await CustomAlertDialog.show(
                                    context: context,
                                    title: "Incorrect Password",
                                    message:
                                        "The password you entered is incorrect. Please try again.",
                                  );
                                  await _saveChanges();
                                  return;
                                }
                                rethrow;
                              }
                              if (mounted) {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MainPage(),
                                  ),
                                  (route) => false,
                                );
                              }
                            },
                          ),
                    ),
                    (route) => false,
                  );
                }
              },
            );
          } catch (e) {
            if (mounted) Navigator.of(context).pop();
            await CustomAlertDialog.show(
              context: context,
              title: "System error",
              message: "Unable to check email: $e",
            );
          }
        } else if (nameChanged) {
          final password = await _promptForPassword();
          if (password == null) {
            return;
          }
          showDialog(
            context: context,
            barrierDismissible: false,
            builder:
                (context) =>
                    const LoadingDialog(message: "Updating profile..."),
          );
          try {
            final reauthResult = await GetIt.I<AuthRepository>().reauthenticate(
              password,
            );

            await reauthResult.fold(
              (failure) async {
                throw FirebaseAuthException(
                  code: 'wrong-password',
                  message: failure.message,
                );
              },
              (_) async {
                final profileResult = await GetIt.I<UserRepository>()
                    .updateUserProfile(
                      userId: widget.userId,
                      name: _name,
                      email: _email,
                      aboutMe: _aboutMe,
                      photoUrl: _photoUrl,
                    );
                profileResult.fold(
                  (l) => throw Exception(l.message),
                  (_) => null,
                );
                final updateAuthResult = await GetIt.I<AuthRepository>()
                    .updateUserAuth(
                      userId: widget.userId,
                      name: nameChanged ? _name : null,
                      email: emailChanged ? _email : null,
                    );

                await updateAuthResult.fold((failure) async {
                  throw Exception(failure.message);
                }, (_) async {});
              },
            );
            if (_selectedImage != null) {
              final photoResult = await GetIt.I<UserRepository>()
                  .updatePhotoUrl(
                    imageFile: _selectedImage!,
                    userId: widget.userId,
                  );
              final newPhotoUrl = photoResult.fold(
                (l) => throw Exception(l.message),
                (r) => r,
              );
              setState(() {
                _photoUrl = newPhotoUrl;
                _selectedImage = null;
              });
            }
          } catch (e) {
            if (e is FirebaseAuthException &&
                (e.code == 'wrong-password' ||
                    e.code == 'invalid-credential')) {
              Navigator.of(context).pop();
              await CustomAlertDialog.show(
                context: context,
                title: "Incorrect Password",
                message:
                    "The password you entered is incorrect. Please try again.",
              );
              await _saveChanges();
              return;
            }
            rethrow;
          }
          Navigator.of(context).pop();
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => MainPage()),
            (route) => false,
          );
        } else {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder:
                (context) =>
                    const LoadingDialog(message: "Updating profile..."),
          );
          final profileResult = await GetIt.I<UserRepository>()
              .updateUserProfile(
                userId: widget.userId,
                name: _name,
                email: _email,
                aboutMe: _aboutMe,
                photoUrl: _photoUrl,
              );
          profileResult.fold((l) => throw Exception(l.message), (_) => null);
          if (_selectedImage != null) {
            final photoResult = await GetIt.I<UserRepository>().updatePhotoUrl(
              imageFile: _selectedImage!,
              userId: widget.userId,
            );
            final newPhotoUrl = photoResult.fold(
              (l) => throw Exception(l.message),
              (r) => r,
            );
            setState(() {
              _photoUrl = newPhotoUrl;
              _selectedImage = null;
            });
          }
          Navigator.of(context).pop();
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => MainPage()),
            (route) => false,
          );
        }
      } catch (e) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.bg,
      appBar: AppBar(
        backgroundColor: context.theme.bg,
        elevation: 0,
        title: const TitleText(
          'Edit Profile',
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.theme.textColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _saveChanges,
            child: TitleText(
              'Save',
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: context.theme.blue,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  GestureDetector(
                    onTap: () => _showImageOptions(),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage:
                          _selectedImage != null
                              ? FileImage(_selectedImage!)
                              : (_photoUrl != null &&
                                      _photoUrl!.startsWith('http')
                                  ? NetworkImage(_photoUrl!)
                                  : const AssetImage('assets/images/avatar.png')
                                      as ImageProvider),
                      child:
                          _selectedImage == null && _photoUrl == null
                              ? const Icon(Icons.camera_alt, color: Colors.grey)
                              : null,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    initialValue: _name,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      labelStyle: TextStyle(
                        color: context.theme.textColor.withOpacity(0.7),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    style: TextStyle(color: context.theme.textColor),
                    onSaved: (value) => _name = value,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: _email,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: TextStyle(
                        color: context.theme.textColor.withOpacity(0.7),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    style: TextStyle(color: context.theme.textColor),
                    onSaved: (value) => _email = value,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      ).hasMatch(value)) {
                        return 'Invalid email format';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: _aboutMe,
                    decoration: InputDecoration(
                      labelText: 'About Me',
                      labelStyle: TextStyle(
                        color: context.theme.textColor.withOpacity(0.7),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    style: TextStyle(color: context.theme.textColor),
                    onSaved: (value) => _aboutMe = value,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.theme.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera, color: context.theme.textColor),
              title: TitleText(
                "Take Photo",
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: context.theme.textColor,
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.photo_library,
                color: context.theme.textColor,
              ),
              title: TitleText(
                "Choose from Gallery",
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: context.theme.textColor,
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        );
      },
    );
  }
}
