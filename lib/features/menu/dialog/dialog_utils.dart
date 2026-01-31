import 'package:flutter/material.dart';
import 'package:messenger_clone/core/utils/custom_theme_extension.dart';
import 'package:messenger_clone/core/widgets/custom_text_style.dart';
import 'package:messenger_clone/core/widgets/dialog/loading_dialog.dart';

class DialogUtils {
  const DialogUtils._();

  static Future<bool> showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'OK',
    String cancelText = 'Há»§y',
  }) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: context.theme.bg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              title: TitleText(
                title,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: context.theme.textColor,
              ),
              content: TitleText(
                message,
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: context.theme.textColor,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: TitleText(
                    cancelText,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: context.theme.textColor.withOpacity(0.7),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: TitleText(
                    confirmText,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: context.theme.blue,
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  static Future<void> executeWithLoading({
    required BuildContext context,
    required Future<void> Function() action,
    required String loadingMessage,
    required String errorMessage,
    VoidCallback? onSuccess,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LoadingDialog(message: loadingMessage),
    );
    try {
      await action();
      Navigator.of(context).pop();
      if (onSuccess != null) onSuccess();
    } catch (e) {
      Navigator.of(context).pop();
      String detailedError = errorMessage;
      if (e.toString().contains('network')) {
        detailedError = 'Lá»—i káº¿t ná»‘i máº¡ng. Vui lÃ²ng kiá»ƒm tra káº¿t ná»‘i cá»§a báº¡n.';
      } else if (e.toString().contains('unauthorized')) {
        detailedError = 'PhiÃªn Ä‘Äƒng nháº­p Ä‘Ã£ háº¿t háº¡n. Vui lÃ²ng Ä‘Äƒng nháº­p láº¡i.';
      }
      await showConfirmationDialog(
        context: context,
        title: 'Lá»—i',
        message: detailedError,
        confirmText: 'ÄÃ³ng',
      );
    }
  }
}

