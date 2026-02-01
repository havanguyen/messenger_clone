import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:messenger_clone/features/auth/domain/repositories/auth_repository.dart';
import 'package:messenger_clone/core/utils/custom_theme_extension.dart';

import 'package:messenger_clone/features/user/domain/repositories/user_repository.dart';
import 'package:messenger_clone/core/widgets/custom_text_style.dart';
import 'package:messenger_clone/features/auth/pages/login_screen.dart';
import 'package:messenger_clone/features/menu/pages/create_grop_page.dart';
import 'package:messenger_clone/features/settings/pages/settings_page.dart';
import 'package:messenger_clone/core/widgets/dialog/custom_alert_dialog.dart';
import 'package:messenger_clone/core/widgets/dialog/loading_dialog.dart';
import 'package:messenger_clone/features/menu/dialog/dialog_utils.dart';
import 'package:messenger_clone/features/menu/pages/edit_profile_page.dart';
import 'package:messenger_clone/features/menu/pages/find_friend_page.dart';
import 'package:messenger_clone/features/friend/domain/repositories/friend_repository.dart';
import 'package:messenger_clone/core/local/hive_storage.dart';
import 'friends_request_pagee.dart';
import 'list_friends_page.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  String? userName;
  String? userId;
  String? email;
  String? aboutMe;
  String? photoUrl;
  bool isLoading = true;
  String? errorMessage;
  int? _pendingMessagesCount;
  int? _friendRequestsCount;

  @override
  void initState() {
    super.initState();
    _fetchNotificationCounts();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final currentUserId = await HiveService.instance.getCurrentUserId();
    final userResult = await GetIt.I<UserRepository>().fetchUserDataById(
      currentUserId,
    );

    if (!mounted) return;

    userResult.fold(
      (failure) {
        setState(() {
          errorMessage = failure.message;
          isLoading = false;
        });
      },
      (result) {
        setState(() {
          if (result.containsKey('error')) {
            errorMessage = result['error'] as String?;
          } else {
            userName = result['userName'] as String?;
            userId = result['userId'] as String?;
            email = result['email'] as String?;
            aboutMe = result['aboutMe'] as String?;
            photoUrl = result['photoUrl'] as String?;
          }
          isLoading = false;
        });
      },
    );
  }

  Future<void> _fetchNotificationCounts() async {
    try {
      final userId = await HiveService.instance.getCurrentUserId();
      final result = await GetIt.I<FriendRepository>()
          .getPendingFriendRequestsCount(userId);
      final friendRequestsCount = result.fold((l) => 0, (r) => r);
      if (!mounted) return;
      setState(() {
        _friendRequestsCount = friendRequestsCount;
        _pendingMessagesCount = 2; // TODO: Replace with actual API call
      });
    } catch (e) {
      print('Error fetching notification counts: $e');
    }
  }

  Future<void> _onRefresh() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    await Future.wait([_fetchUserData(), _fetchNotificationCounts()]);
  }

  Future<String?> _promptForPassword() async {
    final controller = TextEditingController();
    final password = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => AlertDialog(
            title: const Text("Enter Password"),
            content: TextField(
              controller: controller,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password"),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, controller.text),
                child: const Text("Confirm"),
              ),
            ],
          ),
    );

    if (password == null || password.isEmpty) {
      if (!mounted) return null;
      await CustomAlertDialog.show(
        context: context,
        title: "Password Required",
        message: "Please enter your current password to proceed.",
      );
      return null;
    }
    return password;
  }

  Future<bool> _verifyPassword(String password) async {
    try {
      final result = await GetIt.I<AuthRepository>().reauthenticate(password);
      return result.fold((failure) {
        print('Password verification failed: ${failure.message}');
        return false;
      }, (_) => true);
    } catch (e) {
      print('Password verification failed: $e');
      return false;
    }
  }

  Future<void> _deleteAccount() async {
    final password = await _promptForPassword();
    if (password == null) return;

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const LoadingDialog(message: "Checking..."),
    );

    try {
      final user = await GetIt.I<AuthRepository>().getCurrentUser();
      if (user == null) throw Exception("User not logged in.");
      if (await _verifyPassword(password)) {
        if (!mounted) return;
        Navigator.pop(context);
        await DialogUtils.executeWithLoading(
          context: context,
          action: () async {
            final result = await GetIt.I<AuthRepository>().deleteAccount();
            result.fold(
              (failure) => throw Exception(failure.message),
              (_) => null,
            );
          },
          loadingMessage: 'Deleting account...',
          errorMessage: 'Failed to delete account.',
          onSuccess: () async {
            if (!mounted) return;
            await DialogUtils.showConfirmationDialog(
              context: context,
              title: 'Notification',
              message:
                  'Your request has been submitted. The account will be deleted shortly.',
              confirmText: 'Close',
            );
            if (!mounted) return;
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          },
        );
      } else {
        if (!mounted) return;
        Navigator.pop(context);
        await CustomAlertDialog.show(
          context: context,
          title: "Incorrect Password",
          message: "The password you entered is incorrect. Please try again.",
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      if (e.toString().contains("Rate limit exceeded")) {
        await CustomAlertDialog.show(
          context: context,
          title: "Rate Limit Exceeded",
          message: "Too many requests. Please try again after some time.",
        );
      } else {
        await CustomAlertDialog.show(
          context: context,
          title: "Error",
          message:
              "An error occurred: $e. Please try again or contact support.",
        );
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
          'Menu',
          fontSize: 25,
          fontWeight: FontWeight.bold,
        ),
        actions: [
          IconButton(icon: const Icon(Icons.qr_code), onPressed: () {}),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: _onRefresh,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildUserInfo(context),
                    const SizedBox(height: 16),
                    _buildMenuItem(context, Icons.settings, 'Settings', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingsPage()),
                      );
                    }),
                    _buildMenuItem(
                      context,
                      Icons.chat_bubble,
                      'Pending Messages',
                      () {},
                      notificationCount: _pendingMessagesCount,
                    ),
                    _buildMenuItem(context, Icons.archive, 'Archive', () {}),
                    const SizedBox(height: 16),
                    TitleText(
                      'More Options',
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: context.theme.textColor.withOpacity(0.7),
                    ),
                    const SizedBox(height: 8),
                    _buildMenuItem(
                      context,
                      Icons.group,
                      'Friend Requests',
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const FriendRequestPage(),
                          ),
                        );
                      },
                      notificationCount: _friendRequestsCount,
                    ),
                    _buildMenuItem(
                      context,
                      Icons.group_add,
                      'Find Friends',
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const FindFriendsPage(),
                          ),
                        );
                      },
                    ),
                    _buildMenuItem(context, Icons.star, 'List Friends', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ListFriendsPage(),
                        ),
                      );
                    }),
                    _buildMenuItem(context, Icons.group, 'Create Group', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CreateGroupPage(),
                        ),
                      );
                    }),
                    TitleText(
                      'Danger Zone',
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: context.theme.textColor.withOpacity(0.7),
                    ),
                    const SizedBox(height: 16),
                    _buildMenuGroupActions(context),
                  ],
                ),
              ),
            ),
            if (isLoading)
              Center(
                child: CircularProgressIndicator(color: context.theme.grey),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfo(BuildContext context) {
    if (isLoading) return const SizedBox.shrink();
    if (errorMessage != null) {
      return TitleText(
        errorMessage!,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: context.theme.red,
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: context.theme.grey,
        borderRadius: BorderRadius.circular(15),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage:
                photoUrl != null
                    ? (photoUrl!.startsWith('http')
                        ? NetworkImage(photoUrl!)
                        : const AssetImage('assets/images/avatar.png'))
                    : const AssetImage('assets/images/avatar.png'),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TitleText(
                  userName ?? 'No Name',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: context.theme.textColor,
                ),
                TitleText(
                  '@${userId ?? 'No ID'}',
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: context.theme.textColor.withOpacity(0.7),
                ),
                TitleText(
                  aboutMe?.isNotEmpty == true ? aboutMe! : 'Ruby chan (>ω<)',
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: context.theme.textColor.withOpacity(0.7),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => EditProfilePage(
                          initialName: userName,
                          initialEmail: email,
                          initialAboutMe: aboutMe,
                          initialPhotoUrl: photoUrl,
                          userId: userId ?? '',
                        ),
                  ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap, {
    int? notificationCount,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              color: context.theme.textColor.withOpacity(0.7),
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TitleText(
                title,
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: context.theme.textColor,
              ),
            ),
            if (notificationCount != null && notificationCount > 0)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: context.theme.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TitleText(
                    notificationCount.toString(),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: context.theme.white,
                  ),
                ),
              ),
            Icon(
              Icons.arrow_forward_ios,
              color: context.theme.textColor.withOpacity(0.7),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuGroupActions(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.theme.grey,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          _buildMenuItem(context, Icons.logout, 'Log Out', () async {
            if (await DialogUtils.showConfirmationDialog(
              context: context,
              title: 'Confirm',
              message: 'Are you sure you want to log out?',
              confirmText: 'Log Out',
              cancelText: 'Cancel',
            )) {
              await DialogUtils.executeWithLoading(
                context: context,
                action: () async {
                  final result = await GetIt.I<AuthRepository>().signOut();
                  result.fold(
                    (failure) => throw Exception(failure.message),
                    (_) => null,
                  );
                },
                loadingMessage: 'Logging out...',
                errorMessage: 'Failed to log out.',
                onSuccess: () {
                  if (!mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
              );
            }
          }),
          Padding(
            padding: const EdgeInsets.only(left: 72),
            child: Divider(
              color: context.theme.textColor.withOpacity(0.3),
              thickness: 0.5,
            ),
          ),
          _buildMenuItem(
            context,
            Icons.delete_forever,
            'Delete Account',
            () async {
              if (await DialogUtils.showConfirmationDialog(
                context: context,
                title: 'Confirm',
                message:
                    'Are you sure you want to delete your account? This action cannot be undone.',
                confirmText: 'Next',
                cancelText: 'Cancel',
              )) {
                await _deleteAccount();
              }
            },
          ),
        ],
      ),
    );
  }
}

