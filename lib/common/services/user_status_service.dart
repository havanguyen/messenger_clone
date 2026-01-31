import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';

class UserStatusService with WidgetsBindingObserver {
  static final UserStatusService _instance = UserStatusService._internal();
  factory UserStatusService() => _instance;

  final SupabaseClient _supabase = Supabase.instance.client;
  Timer? _updateTimer;
  bool _isInitialized = false;

  UserStatusService._internal();

  Future<void> initialize() async {
    if (_isInitialized) return;
    WidgetsBinding.instance.addObserver(this);
    _isInitialized = true;
    _startPeriodicUpdates();
  }

  void _startPeriodicUpdates() {
    _updateTimer = Timer.periodic(const Duration(seconds: 600), (timer) {
      _updateUserStatus(true);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _updateUserStatus(true);
        _startPeriodicUpdates();
        break;
      case AppLifecycleState.paused:
        _updateUserStatus(false);
        _updateTimer?.cancel();
        break;
      case AppLifecycleState.detached:
        _updateUserStatus(false);
        _updateTimer?.cancel();
        break;
      default:
        break;
    }
  }

  Future<void> _updateUserStatus(bool isActive) async {
    try {
      final currentUser =
          await AuthService.getCurrentUser(); // Returns FirebaseUser or SupabaseUser info
      if (currentUser == null) return;

      // Assuming we can update 'users' table
      await _supabase
          .from('users')
          .update({
            'isActive': isActive,
            'lastSeen': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', currentUser.uid); // Firebase UID should match Supabase ID
    } catch (e) {
      debugPrint('Error updating user status: $e');
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _updateTimer?.cancel();
    _updateUserStatus(false);
  }
}
