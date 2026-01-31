import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:messenger_clone/features/settings/pages/system_theme_settings_page.dart';
import 'package:messenger_clone/features/settings/pages/change_password_page.dart';
import 'package:messenger_clone/core/utils/custom_theme_extension.dart';
import 'package:messenger_clone/features/settings/domain/repositories/device_repository.dart';
import 'package:messenger_clone/core/local/hive_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:messenger_clone/features/user/domain/repositories/user_repository.dart';

import '../../../core/widgets/custom_text_style.dart';
import '../../menu/pages/edit_profile_page.dart';
import 'device_management.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? userName;
  String? userId;
  String? email;
  String? aboutMe;
  String? photoUrl;
  int _devicesCount = 0;
  bool isLoading = true;
  String? errorMessage;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final currentUserId = await HiveService.instance.getCurrentUserId();
      final userResult = await GetIt.I<UserRepository>().fetchUserDataById(
        currentUserId,
      );
      final result = userResult.fold(
        (l) => throw Exception(l.message),
        (r) => r,
      );

      userName = result['userName'] as String?;
      userId = result['userId'] as String?;
      email = result['email'] as String?;
      aboutMe = result['aboutMe'] as String?;
      photoUrl = result['photoUrl'] as String?;

      if (userId != null) {
        final devicesResult = await GetIt.I<DeviceRepository>().getUserDevices(
          userId!,
        );
        _devicesCount = devicesResult.fold(
          (l) => 0, // Fallback to 0 on error
          (r) => r.length,
        );
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Error fetching data: $e";
        isLoading = false;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        final result = await GetIt.I<UserRepository>().updatePhotoUrl(
          imageFile: File(image.path),
          userId: userId!,
        );
        final newPhotoUrl = result.fold(
          (l) => throw Exception(l.message),
          (r) => r,
        );
        setState(() {
          photoUrl = newPhotoUrl;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error uploading image: $e";
      });
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.bg,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.theme.textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const TitleText(
          "Settings",
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: context.theme.bg,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildUserInfo(),
                const SizedBox(height: 24),
                _buildSettingsGroup1(),
                const SizedBox(height: 16),
                _buildSettingsGroup2(),
                const SizedBox(height: 16),
                _buildSettingsGroup3(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfo() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (errorMessage != null) {
      return TitleText(
        errorMessage!,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: context.theme.red,
      );
    }
    return Row(
      children: [
        GestureDetector(
          onTap: _showImageOptions,
          child: CircleAvatar(
            radius: 30,
            backgroundImage:
                photoUrl != null
                    ? (photoUrl!.startsWith('http')
                        ? NetworkImage(photoUrl!)
                        : FileImage(File(photoUrl!)) as ImageProvider)
                    : const AssetImage('assets/images/avatar.png'),
            child:
                photoUrl == null
                    ? const Icon(Icons.camera_alt, color: Colors.grey)
                    : null,
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TitleText(
              userName ?? "No Name",
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: context.theme.textColor,
            ),
            TitleText(
              "@${userId ?? 'No ID'}",
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: context.theme.textColor.withOpacity(0.7),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSettingsGroup1() {
    return Container(
      decoration: BoxDecoration(
        color: context.theme.grey,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          _buildSettingItem(
            icon: Icons.account_box,
            title: "Account",
            subtitle: userId ?? "No ID",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => EditProfilePage(
                        initialName: userName,
                        initialEmail: email,
                        initialAboutMe: aboutMe,
                        initialPhotoUrl: photoUrl,
                        userId: userId ?? '',
                      ),
                ),
              );
            },
          ),
          _buildSettingItem(
            icon: Icons.shield,
            title: "Device Management",
            notificationCount:
                _devicesCount == 0
                    ? null
                    : _devicesCount, // Hiá»ƒn thá»‹ sá»‘ lÆ°á»£ng thiáº¿t bá»‹
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DeviceManagementPage(),
                ),
              );
            },
          ),
          _buildSettingItem(
            icon: Icons.person_outline,
            title: "Password",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChangePasswordPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup2() {
    return Container(
      decoration: BoxDecoration(
        color: context.theme.grey,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          _buildSettingItem(
            icon: Icons.brightness_6,
            title: "Dark Mode",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SystemThemeSettingsPage(),
                ),
              );
            },
          ),
          _buildSettingItem(
            icon: Icons.notifications,
            title: "Notifications and Sounds",
            subtitle: "On",
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup3() {
    return Container(
      decoration: BoxDecoration(
        color: context.theme.grey,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          _buildSettingItem(
            icon: Icons.gavel,
            title: "Legal and Policies",
            onTap: () {},
          ),
          _buildSettingItem(
            icon: Icons.report,
            title: "Report an Issue",
            onTap: () {},
          ),
          _buildSettingItem(icon: Icons.help, title: "Help", onTap: () {}),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    String? subtitle,
    int? notificationCount,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Icon(
              icon,
              color: context.theme.textColor.withOpacity(0.7),
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TitleText(
                    title,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: context.theme.textColor,
                  ),
                  if (subtitle != null)
                    TitleText(
                      subtitle,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: context.theme.textColor.withOpacity(0.7),
                    ),
                ],
              ),
            ),
            if (notificationCount != null)
              Container(
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
            const SizedBox(width: 8),
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
}

