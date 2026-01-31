import 'package:flutter/material.dart';
import 'package:messenger_clone/features/auth/pages/register_email.dart';
import 'package:messenger_clone/core/local/secure_storage.dart';
import 'login_screen.dart';

class NameInputScreen extends StatefulWidget {
  const NameInputScreen({super.key});

  @override
  State<NameInputScreen> createState() => _NameInputScreenState();
}

class _NameInputScreenState extends State<NameInputScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  String? _firstNameError;
  String? _lastNameError;

  void _validateInputs() {
    setState(() {
      _firstNameError =
          _firstNameController.text.isEmpty
              ? 'Please enter your first name'
              : null;
      _lastNameError =
          _lastNameController.text.isEmpty
              ? 'Please enter your last name'
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
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "What's your name?",
              style: TextStyle(
                fontSize: 29,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Enter the name you use in real life.",
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: TextField(
                    controller: _lastNameController,
                    decoration: InputDecoration(
                      labelText: 'Last name',
                      isDense: true,
                      labelStyle: TextStyle(
                        color:
                            _lastNameError != null
                                ? Colors.red
                                : const Color(0xFF9eabb3),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.blue),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 20,
                      ),
                      errorText: _lastNameError,
                      suffixIcon:
                          _lastNameError != null
                              ? const Icon(Icons.error, color: Colors.red)
                              : null,
                      errorStyle: const TextStyle(color: Colors.red),
                    ),
                    style: const TextStyle(color: Colors.white),
                    onChanged: (value) {
                      setState(() {
                        _lastNameError = null;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: TextField(
                    controller: _firstNameController,
                    decoration: InputDecoration(
                      labelText: 'First name',
                      isDense: true,
                      labelStyle: TextStyle(
                        color:
                            _firstNameError != null
                                ? Colors.red
                                : const Color(0xFF9eabb3),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.blue),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 20,
                      ),
                      errorText: _firstNameError,
                      suffixIcon:
                          _firstNameError != null
                              ? const Icon(Icons.error, color: Colors.red)
                              : null,
                      errorStyle: const TextStyle(color: Colors.red),
                    ),
                    style: const TextStyle(color: Colors.white),
                    onChanged: (value) {
                      setState(() {
                        _firstNameError = null;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  _validateInputs();
                  if (_firstNameError == null && _lastNameError == null) {
                    Store.setNameRegistered(
                      "${_firstNameController.text} ${_lastNameController.text}",
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EmailInputScreen(),
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
}
