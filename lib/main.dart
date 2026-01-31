import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:messenger_clone/common/services/notification_service.dart';
import 'package:messenger_clone/common/services/user_status_service.dart';
import 'package:messenger_clone/common/themes/app_theme.dart';
import 'package:messenger_clone/features/chat/bloc/chat_item_bloc.dart';
import 'package:messenger_clone/features/chat/data/data_sources/remote/chat_repository.dart';
import 'package:messenger_clone/features/chat/model/user.dart' as app_user;
import 'package:messenger_clone/features/messages/domain/models/message_model.dart';
import 'package:messenger_clone/features/messages/enum/message_status.dart';

import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:messenger_clone/common/routes/routes.dart';
import 'package:messenger_clone/common/themes/theme_provider.dart';
import 'features/meta_ai/bloc/meta_ai_bloc.dart';
import 'features/meta_ai/bloc/meta_ai_event.dart';
import 'features/meta_ai/data/meta_ai_message_model.dart';
import 'features/splash/pages/splash.dart';
import 'firebase_options.dart';
import 'package:permission_handler/permission_handler.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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

  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }
  NotificationService().initializeNotifications();
  NotificationService().setNavigatorKey(navigatorKey);
  await UserStatusService().initialize();

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

class MessengerClone extends StatefulWidget {
  const MessengerClone({super.key});

  @override
  State<MessengerClone> createState() => _MessengerCloneState();
}

class _MessengerCloneState extends State<MessengerClone> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    // Repositories
    final chatRepository = ChatRepository();

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => MetaAiBloc()..add(InitializeMetaAi()),
        ),
        BlocProvider(
          create:
              (context) =>
                  ChatItemBloc(chatRepository: chatRepository)
                    ..add(GetChatItemEvent()),
        ),
        // Add other Blocs as needed if they are global
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        themeMode: themeProvider.themeNotifier.value,
        onGenerateRoute: Routes.onGenerateRoute,
        theme: lightTheme,
        darkTheme: darkTheme,
        home: const SplashPage(),
      ),
    );
  }
}
