import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:messenger_clone/core/di/injection.dart' as di;

// Features - Chat
import 'package:messenger_clone/features/chat/model/user.dart' as app_user;

// Features - Messages
import 'package:messenger_clone/features/messages/domain/models/message_model.dart';
import 'package:messenger_clone/features/messages/enum/message_status.dart';

// Features - Meta AI
import 'features/meta_ai/data/meta_ai_message_model.dart';

import 'package:messenger_clone/app.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:messenger_clone/theme/theme_provider.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env
  await dotenv.load(fileName: ".env");

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // Initialize Dependency Injection
  await di.init();

  await Hive.initFlutter();
  Hive.registerAdapter(app_user.UserAdapter());
  Hive.registerAdapter(MessageModelAdapter());
  Hive.registerAdapter(MetaAiMessageHiveAdapter());
  Hive.registerAdapter(MessageStatusAdapter());

  await Hive.openBox<app_user.User>('userBox');
  await Hive.openBox<MessageModel>('chatBox');
  await Hive.openBox('metaAiBox');
  await Hive.openBox<MetaAiMessageHive>('metaAiMessagesBox');

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MessengerClone(),
    ),
  );
}
