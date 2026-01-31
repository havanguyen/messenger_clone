import 'package:flutter/material.dart';

class CustomCallDialog {
  static void show({
    required BuildContext context,
    required String title,
    required String message,
    List<Widget>? actions,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: actions ??
            [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Đóng'),
              ),
            ],
      ),
    );
  }
}