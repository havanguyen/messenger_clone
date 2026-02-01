import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:messenger_clone/routes/app_router.dart';

import 'package:messenger_clone/features/chat/model/group_message.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling background notification: ${message.messageId}');

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  String? type = message.data['type'];
  String? callId = message.data['callId'];
  int notificationId =
      message.messageId?.hashCode ?? Random().nextInt(0x7FFFFFFF);

  if (type == 'call_ended' && callId != null) {
    await flutterLocalNotificationsPlugin.cancel(callId.hashCode);
    debugPrint('Cancelled call notification for callId: $callId');
    return;
  }

  String title =
      type == 'video_call'
          ? 'Incoming Call'
          : (message.notification?.title ?? 'New Message');
  String body =
      type == 'video_call'
          ? 'From ${message.data['callerName'] ?? 'Unknown caller'}'
          : (message.notification?.body ?? '');

  if (type == 'video_call') {
    final androidDetails = AndroidNotificationDetails(
      'video_call_channel',
      'Video Call Channel',
      importance: Importance.max,
      priority: Priority.high,
      color: const Color(0xFF4CAF50), // Green color
      fullScreenIntent: true, // Full-screen intent
      timeoutAfter: 30000, // Cancel after 30 seconds
      styleInformation: const BigTextStyleInformation(''), // Compact display
      actions: const [
        AndroidNotificationAction('accept', 'Accept', showsUserInterface: true),
        AndroidNotificationAction('reject', 'Reject', cancelNotification: true),
      ],
    );

    await flutterLocalNotificationsPlugin.show(
      callId?.hashCode ?? notificationId,
      title,
      body,
      NotificationDetails(android: androidDetails),
      payload: jsonEncode({
        ...message.data,
        'notificationId': callId?.hashCode ?? notificationId,
      }),
    );
  } else {
    const androidDetails = AndroidNotificationDetails(
      'message_channel',
      'Message Channel',
      importance: Importance.high,
      priority: Priority.high,
    );

    await flutterLocalNotificationsPlugin.show(
      notificationId,
      title,
      body,
      const NotificationDetails(android: androidDetails),
      payload: jsonEncode({...message.data, 'notificationId': notificationId}),
    );
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  late final FlutterLocalNotificationsPlugin _localNotifications;
  late final FirebaseMessaging _firebaseMessaging;
  GlobalKey<NavigatorState>? navigatorKey;
  final Completer<void> _navigatorReady = Completer<void>();

  NotificationService._internal() {
    _localNotifications = FlutterLocalNotificationsPlugin();
    _firebaseMessaging = FirebaseMessaging.instance;
    _initializeFirebaseMessaging();
  }

  void setNavigatorKey(GlobalKey<NavigatorState> key) {
    navigatorKey = key;
    if (navigatorKey?.currentState != null && !_navigatorReady.isCompleted) {
      _navigatorReady.complete();
      debugPrint('NavigatorKey is ready');
    }
  }

  Future<void> _initializeFirebaseMessaging() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    debugPrint('Notification permission: ${settings.authorizationStatus}');

    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> initializeNotifications() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings),

      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );

    RemoteMessage? initialMessage =
        await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint(
        'Handling initial message in terminated state: ${initialMessage.messageId}',
      );
      await _handleInitialMessage(initialMessage);
    } else {
      debugPrint('No initial message found');
    }

    Future.delayed(Duration(seconds: 5), () async {
      RemoteMessage? retryMessage =
          await _firebaseMessaging.getInitialMessage();
      if (retryMessage != null && navigatorKey?.currentState != null) {
        debugPrint('Retry handling initial message: ${retryMessage.messageId}');
        await _handleInitialMessage(retryMessage);
      }
    });

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(
      _handleNotificationTapBackground,
    );
  }

  void _handleNotificationResponse(NotificationResponse response) {
    debugPrint(
      'Notification tapped: ${response.payload}, Action: ${response.actionId}',
    );
    debugPrint(
      'Notification tapped: ${response.payload}, Action: ${response.actionId}',
    );
    final payloadString = response.payload;
    if (payloadString != null) {
      try {
        final payload = Map<String, dynamic>.from(jsonDecode(payloadString));
        if (payload['type'] == 'video_call') {
          if (response.actionId == 'accept') {
            _navigateToCallPage(payload);
          } else if (response.actionId == 'reject') {
            if (payload['notificationId'] != null) {
              _localNotifications.cancel(payload['notificationId']);
              debugPrint('Cancelled call notification on reject');
            }
          }
        } else {
          _navigateToMessagePage(payload);
        }
      } catch (e) {
        debugPrint('Error parsing notification payload: $e');
      }
    }
  }

  void _handleNotificationTapBackground(RemoteMessage message) {
    debugPrint('Background notification tapped: ${message.messageId}');
    if (message.data['type'] == 'call_ended') {
      if (message.data['callId'] != null) {
        _localNotifications.cancel(message.data['callId'].hashCode);
        debugPrint(
          'Cancelled call notification for callId: ${message.data['callId']}',
        );
      }
      return;
    }
    if (message.data['type'] == 'video_call') {
      _navigateToCallPage(message.data);
    } else {
      _navigateToMessagePage(message.data);
    }
  }

  Future<void> _handleInitialMessage(RemoteMessage message) async {
    debugPrint(
      'Processing initial message: ${message.messageId}, type: ${message.data['type']}, payload: ${message.data}',
    );

    if (!_navigatorReady.isCompleted) {
      debugPrint('Waiting for navigatorKey to be ready...');
      bool isReady = false;
      for (int i = 0; i < 40; i++) {
        if (navigatorKey?.currentState != null) {
          isReady = true;
          if (!_navigatorReady.isCompleted) {
            _navigatorReady.complete();
          }
          break;
        }
        await Future.delayed(Duration(milliseconds: 500));
        debugPrint('Retry $i: Waiting for navigatorKey...');
      }
      if (!isReady) {
        debugPrint('NavigatorKey not ready after 20 seconds');
        return;
      }
    }

    if (message.data['type'] == 'call_ended') {
      if (message.data['callId'] != null) {
        _localNotifications.cancel(message.data['callId'].hashCode);
        debugPrint(
          'Cancelled call notification for callId: ${message.data['callId']}',
        );
      }
      return;
    }

    if (message.data['type'] == 'video_call') {
      debugPrint('Navigating to CallPage from terminated state');
      await _navigateToCallPage(message.data);
    } else {
      debugPrint('Navigating to MessagePage from terminated state');
      await _navigateToMessagePage(message.data);
    }
  }

  Future<void> _navigateToMessagePage(Map<String, dynamic> payload) async {
    if (navigatorKey?.currentState == null) {
      debugPrint('NavigatorKey not ready to navigate to message page');
      return;
    }

    try {

      final supabase = Supabase.instance.client;
      final response =
          await supabase
              .from('group_messages') // Assuming table name
              .select()
              .eq('id', payload['groupMessageId'])
              .single();
      GroupMessage groupMessage = GroupMessage.fromJson(response);

      navigatorKey!.currentState!.pushNamed(
        AppRouter.chat,
        arguments: groupMessage,
      );
    } catch (e) {
      debugPrint('Error navigating to message page: $e');
      if (navigatorKey?.currentState != null) {
        ScaffoldMessenger.of(
          navigatorKey!.currentState!.context,
        ).showSnackBar(SnackBar(content: Text('Cannot open message page: $e')));
      }
    }
  }

  Future<void> _navigateToCallPage(Map<String, dynamic> payload) async {
    debugPrint('Call feature disabled. Payload: $payload');
    if (navigatorKey?.currentState != null) {
      ScaffoldMessenger.of(navigatorKey!.currentState!.context).showSnackBar(
        SnackBar(content: Text('Video call is temporarily disabled')),
      );
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('Received foreground notification: ${message.messageId}');

    if (message.data['type'] == 'call_ended' &&
        message.data['callId'] != null) {
      await _localNotifications.cancel(message.data['callId'].hashCode);
      debugPrint(
        'Cancelled call notification for callId: ${message.data['callId']}',
      );
      return;
    }

    if (message.data['type'] == 'video_call') {
      await _showCallNotification(
        _localNotifications,
        message.notification?.title ?? 'Incoming Call',
        'From ${message.data['callerName'] ?? 'Unknown caller'}',
        message.data,
      );
    } else {
      await _showMessageNotification(
        _localNotifications,
        message.notification?.title ?? 'New Message',
        message.notification?.body ?? '',
        message.data,
      );
    }
  }

  Future<void> _showCallNotification(
    FlutterLocalNotificationsPlugin notifications,
    String title,
    String body,
    Map<String, dynamic> payload,
  ) async {
    int notificationId =
        payload['callId']?.hashCode ?? Random().nextInt(0x7FFFFFFF);
    final androidDetails = AndroidNotificationDetails(
      'video_call_channel',
      'Video Call Channel',
      importance: Importance.max,
      priority: Priority.high,
      color: const Color(
        0xFF4CAF50,
      ), // Green color/ Custom sound, will address beloion pattern
      fullScreenIntent: true, // Full-screen intent
      timeoutAfter: 30000, // Cancel after 30 seconds
      styleInformation: const BigTextStyleInformation(''), // Compact display
      actions: const [
        AndroidNotificationAction('accept', 'Accept', showsUserInterface: true),
        AndroidNotificationAction('reject', 'Reject', cancelNotification: true),
      ],
    );

    await notifications.show(
      notificationId,
      title,
      body,
      NotificationDetails(android: androidDetails),
      payload: jsonEncode({...payload, 'notificationId': notificationId}),
    );
  }

  Future<void> _showMessageNotification(
    FlutterLocalNotificationsPlugin notifications,
    String title,
    String body,
    Map<String, dynamic> payload,
  ) async {
    int notificationId =
        payload['messageId']?.hashCode ?? Random().nextInt(0x7FFFFFFF);
    const androidDetails = AndroidNotificationDetails(
      'message_channel',
      'Message Channel',
      importance: Importance.high,
      priority: Priority.high,
    );

    await notifications.show(
      notificationId,
      title,
      body,
      const NotificationDetails(android: androidDetails),
      payload: jsonEncode({...payload, 'notificationId': notificationId}),
    );
  }

  Future<String?> getFCMToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      debugPrint('FCM Token: $token');
      return token;
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }
}
