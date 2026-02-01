import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:messenger_clone/features/chat/model/group_message.dart';
import 'package:messenger_clone/features/chat/model/user.dart';
import 'package:messenger_clone/features/messages/presentation/bloc/message_bloc.dart';
import 'package:messenger_clone/features/messages/pages/messages_page.dart';
import 'package:page_transition/page_transition.dart';
import 'package:get_it/get_it.dart';
import 'package:messenger_clone/features/messages/domain/repositories/message_repository.dart';
import 'package:messenger_clone/features/messages/domain/usecases/load_messages_usecase.dart';
import 'package:messenger_clone/features/messages/domain/usecases/send_message_usecase.dart';

import 'package:messenger_clone/features/splash/pages/splash.dart';

class AppRouter {
  static const String welcome = "home";
  static const String chat = "chat";
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case welcome:
        return PageTransition(
          type: PageTransitionType.fade,
          settings: settings,
          child: const SplashPage(),
        );
      case chat:
        Widget pageChat = const Scaffold(
          body: Center(child: Text('Invalid arguments for chat page')),
        );
        if (settings.arguments is GroupMessage) {
          final GroupMessage groupMessage = settings.arguments as GroupMessage;
          pageChat = MessagesPage(groupMessage: groupMessage);
        } else if (settings.arguments is User) {
          final User user = settings.arguments as User;
          pageChat = MessagesPage(otherUser: user);
        }
        return PageTransition(
          type: PageTransitionType.rightToLeft,
          settings: settings,
          child: BlocProvider(
            create: (context) {
              return MessageBloc(
                chatRepository: GetIt.I<MessageRepository>(),
                loadMessagesUseCase: GetIt.I<LoadMessagesUseCase>(),
                sendMessageUseCase: GetIt.I<SendMessageUseCase>(),
              )..add(
                MessageLoadEvent(
                  (settings.arguments is User)
                      ? settings.arguments as User
                      : null,
                  (settings.arguments is GroupMessage)
                      ? settings.arguments as GroupMessage
                      : null,
                ),
              );
            },
            child: pageChat,
          ),
        );

      default:
        return MaterialPageRoute(
          builder:
              (context) => const Scaffold(
                body: Center(child: Text('No page route provided')),
              ),
        );
    }
  }
}
