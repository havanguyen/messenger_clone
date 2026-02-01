import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:messenger_clone/theme/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:messenger_clone/core/di/injection.dart' as di;
import 'package:messenger_clone/routes/app_router.dart';
import 'package:messenger_clone/theme/app_theme.dart';

import 'package:messenger_clone/features/meta_ai/presentation/bloc/meta_ai_bloc.dart';
import 'package:messenger_clone/features/meta_ai/presentation/bloc/meta_ai_event.dart';
import 'package:messenger_clone/features/chat/presentation/bloc/chat_item_bloc.dart';
import 'package:messenger_clone/features/auth/presentation/bloc/auth_bloc.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MessengerClone extends StatelessWidget {
  const MessengerClone({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => di.sl<MetaAiBloc>()..add(InitializeMetaAi()),
        ),
        BlocProvider(
          create: (context) => di.sl<ChatItemBloc>()..add(GetChatItemEvent()),
        ),
        BlocProvider(
          create:
              (context) => di.sl<AuthBloc>()..add(const CheckAuthStatusEvent()),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeNotifier.value,
            onGenerateRoute: AppRouter.onGenerateRoute,
            initialRoute: AppRouter.welcome,
            theme: lightTheme,
            darkTheme: darkTheme,
          );
        },
      ),
    );
  }
}
