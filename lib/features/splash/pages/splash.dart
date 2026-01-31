import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:messenger_clone/features/main_page/main_page.dart';

import 'package:messenger_clone/app.dart';
import 'package:messenger_clone/core/local/hive_storage.dart';
import 'package:messenger_clone/core/notifications/notification_helper.dart';
import 'package:messenger_clone/core/widgets/dialog/custom_alert_dialog.dart';
import '../../auth/pages/login_screen.dart';
import 'package:permission_handler/permission_handler.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    redirect();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset(
          "assets/images/aeck_logo.png",
          width: MediaQuery.of(context).size.width * 0.6,
        ),
      ),
    );
  }

  Future<void> redirect() async {
    await Future.delayed(const Duration(seconds: 1));
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
    NotificationService().initializeNotifications();
    NotificationService().setNavigatorKey(navigatorKey);
    try {
      final currentUser = await HiveService.instance.getCurrentUserId();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder:
              (BuildContext context) =>
                  currentUser.isNotEmpty ? MainPage() : LoginScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      await CustomAlertDialog.show(
        context: context,
        title: "Error System",
        message: "An error occurred : $e.",
      );
      SystemNavigator.pop();
    }
  }
}
