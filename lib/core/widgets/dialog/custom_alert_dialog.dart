import 'package:flutter/material.dart';

class CustomAlertDialog extends StatelessWidget {
  final String title;
  final String message;
  final String buttonText;
  final VoidCallback? onPressed;

  const CustomAlertDialog({
    super.key,
    required this.title,
    required this.message,
    this.buttonText = "OK",
    this.onPressed,
  });

  static Future<void> show({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = "OK",
    VoidCallback? onPressed,
  }) async {
    await showDialog(
      context: context,
      builder: (context) => CustomAlertDialog(
        title: title,
        message: message,
        buttonText: buttonText,
        onPressed: onPressed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: onPressed ?? () => Navigator.of(context).pop(),
          child: Text(buttonText),
        ),
      ],
    );
  }
}