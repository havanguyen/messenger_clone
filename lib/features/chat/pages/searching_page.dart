import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:messenger_clone/core/utils/custom_theme_extension.dart';
import 'package:messenger_clone/routes/app_router.dart';
import 'package:messenger_clone/core/widgets/custom_text_style.dart';
import 'package:messenger_clone/core/widgets/elements/custom_round_avatar.dart';
import 'package:messenger_clone/features/chat/bloc/user_bloc.dart';
import 'package:messenger_clone/features/chat/data/data_sources/remote/chat_repository.dart';

class SearchingPage extends StatelessWidget {
  const SearchingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (context) =>
              UserBloc(chatRepository: ChatRepository())
                ..add(GetAllUsersEvent()),
      child: Scaffold(
        backgroundColor: context.theme.bg,
        appBar: AppBar(
          backgroundColor: context.theme.bg,
          leading: IconButton(
            icon: Icon(Icons.keyboard_arrow_left, color: context.theme.blue),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          title: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Container(
              decoration: BoxDecoration(
                color: context.theme.grey,
                borderRadius: BorderRadius.circular(20.0),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 10.0,
                vertical: 4.0,
              ),
              child: TextField(
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 0,
                  ),
                  hintText: 'Search',
                  hintStyle: TextStyle(
                    color: context.theme.textColor.withOpacity(0.5),
                    fontSize: 16.0,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                ),
                style: TextStyle(
                  color: context.theme.textColor,
                  fontSize: 16.0,
                ),
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.send, color: context.theme.blue),
              onPressed: () {},
            ),
          ],
        ),
        body: BlocBuilder<UserBloc, UserState>(
          builder: (context, state) {
            if (state is UserLoading) {
              return Center(child: CircularProgressIndicator());
            } else if (state is UserLoaded) {
              final users = state.users;
              return ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  return ListTile(
                    leading: CustomRoundAvatar(
                      isActive: true,
                      avatarUrl: user.photoUrl,
                      radius: 25,
                    ),
                    title: ContentText(user.name),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        AppRouter.chat,
                        arguments: user,
                      );
                    },
                  );
                },
              );
            } else if (state is UserError) {
              return Center(
                child: Text(
                  'Error: ${state.message}',
                  style: TextStyle(color: Colors.red),
                ),
              );
            } else {
              return Center(
                child: Text(
                  'No results found',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}

