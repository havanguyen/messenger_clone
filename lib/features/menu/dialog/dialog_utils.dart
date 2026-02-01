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
    String cancelText = 'Hủy',
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
        detailedError = 'Lỗi kết nối mạng. Vui lòng kiểm tra kết nối của bạn.';
      } else if (e.toString().contains('unauthorized')) {
        detailedError = 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
      }
      await showConfirmationDialog(
        context: context,
        title: 'Lỗi',
        message: detailedError,
        confirmText: 'Đóng',
      );
    }
  }
}

