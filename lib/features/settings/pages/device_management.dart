import 'package:flutter/material.dart';
import 'package:messenger_clone/core/utils/custom_theme_extension.dart';
import 'package:messenger_clone/core/widgets/custom_text_style.dart';

import 'package:messenger_clone/features/settings/domain/repositories/device_repository.dart';
import 'package:get_it/get_it.dart';
import 'package:messenger_clone/core/local/hive_storage.dart';

class DeviceManagementPage extends StatefulWidget {
  const DeviceManagementPage({super.key});

  @override
  State<DeviceManagementPage> createState() => _DeviceManagementPageState();
}

class _DeviceManagementPageState extends State<DeviceManagementPage>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _devicesList = [];
  bool _isLoading = false;
  String? _errorMessage;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String _currentUserId = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _fetchDevicesList();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchDevicesList() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final currentUserId = await HiveService.instance.getCurrentUserId();
      _currentUserId = currentUserId;

      final devicesResult = await GetIt.I<DeviceRepository>().getUserDevices(
        _currentUserId,
      );
      final devices = devicesResult.fold(
        (l) => throw Exception(l.message),
        (r) => r,
      );

      setState(() {
        _devicesList = devices;
        _isLoading = false;
      });
      _animationController.forward(from: 0.0);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _removeDeviceFromList(String documentId) {
    setState(() {
      _devicesList =
          _devicesList
              .where((device) => device['documentId'] != documentId)
              .toList();
    });
    _animationController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.bg,
      appBar: AppBar(
        backgroundColor: context.theme.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          color: context.theme.textColor,
        ),
        title: const TitleText(
          'Device Management',
          fontSize: 25,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildDevicesList(context),
        ),
      ),
    );
  }

  Widget _buildDevicesList(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: TitleText(
          _errorMessage!,
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: context.theme.red,
        ),
      );
    }

    if (_devicesList.isEmpty) {
      return Center(
        child: TitleText(
          'No devices found.',
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: context.theme.textColor.withOpacity(0.7),
        ),
      );
    }

    return ListView.builder(
      itemCount: _devicesList.length,
      itemBuilder: (context, index) {
        final device = _devicesList[index];
        return FadeTransition(
          opacity: _fadeAnimation,
          child: _buildDeviceCard(context, device),
        );
      },
    );
  }

  Widget _buildDeviceCard(BuildContext context, Map<String, dynamic> device) {
    final isCurrentDevice = device['isCurrentDevice'] as bool;
    final lastLogin = DateTime.parse(device['lastLogin'] as String).toLocal();
    final formattedLastLogin =
        "${lastLogin.day}/${lastLogin.month}/${lastLogin.year} ${lastLogin.hour}:${lastLogin.minute.toString().padLeft(2, '0')}";

    return Card(
      color: context.theme.grey,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(
          device['platform'] == 'Android' ? Icons.android : Icons.apple,
          color: context.theme.textColor.withOpacity(0.7),
          size: 30,
        ),
        title: TitleText(
          device['platform'],
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: context.theme.textColor,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TitleText(
              'Device ID: ${device['deviceId']}',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: context.theme.textColor.withOpacity(0.7),
            ),
            TitleText(
              'Last Login: $formattedLastLogin',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: context.theme.textColor.withOpacity(0.7),
            ),
            if (isCurrentDevice)
              TitleText(
                'Current Device',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: context.theme.blue,
              ),
          ],
        ),
        trailing:
            isCurrentDevice
                ? null
                : OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: context.theme.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                  ),
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: const Text('Remove Device'),
                            content: const Text(
                              'Are you sure you want to remove this device?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text(
                                  'Remove',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                    );

                    if (confirmed == true) {
                      try {
                        final result = await GetIt.I<DeviceRepository>()
                            .removeDevice(device['documentId']);
                        result.fold((l) => throw Exception(l.message), (r) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Device removed successfully'),
                              ),
                            );
                            _removeDeviceFromList(device['documentId']);
                          }
                        });
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to remove device: $e'),
                            ),
                          );
                        }
                      }
                    }
                  },
                  child: const Text(
                    'Remove',
                    style: TextStyle(fontSize: 12, color: Colors.red),
                  ),
                ),
      ),
    );
  }
}

