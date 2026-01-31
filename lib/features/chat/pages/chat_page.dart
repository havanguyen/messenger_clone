import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:messenger_clone/core/utils/custom_theme_extension.dart';
import 'package:messenger_clone/routes/app_router.dart';

import 'package:messenger_clone/core/widgets/elements/custom_round_avatar.dart';
import 'package:messenger_clone/features/chat/bloc/chat_item_bloc.dart';

import 'package:messenger_clone/features/chat/pages/searching_page.dart';

import '../model/chat_item.dart';
import '../widgets/chat_item_widget.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  @override
  void initState() {
    super.initState();
  }

  Future<void> _refreshChats() async {
    BlocProvider.of<ChatItemBloc>(context).add(GetChatItemEvent());
  }

  @override
  void dispose() {
    super.dispose();
    BlocProvider.of<ChatItemBloc>(context).close();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              'messenger',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: context.theme.titleHeaderColor,
              ),
            ),
            SizedBox(width: 8),
            Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: context.theme.titleHeaderColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline,
                size: 20,
                color: Colors.blueAccent,
              ),
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: context.theme.bg,
        actions: [
          IconButton(
            icon: Icon(
              Icons.account_tree_outlined,
              color: context.theme.textColor.withOpacity(0.7),
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(
              Icons.facebook,
              color: context.theme.textColor.withOpacity(0.7),
            ),
            onPressed: () {},
          ),
        ],
      ),
      backgroundColor: context.theme.bg,
      body: RefreshIndicator(
        onRefresh: _refreshChats,
        color: Colors.blueAccent,
        backgroundColor: context.theme.bg,
        child: BlocBuilder<ChatItemBloc, ChatItemState>(
          builder: (context, state) {
            if (state is ChatItemLoading) {
              return const SizedBox.shrink();
            } else if (state is ChatItemError) {
              return Center(child: Text("Error loading chat items"));
            }
            final chatItems = state is ChatItemLoaded ? state.chatItems : [];
            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: chatItems.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildHeader(state);
                }

                final itemIndex = index - 1;
                final item = chatItems[itemIndex];

                if (item.groupMessage.lastMessage == null) {
                  return const SizedBox.shrink();
                }

                return ChatItemWidget(
                  item: item,
                  onTap: () {
                    Navigator.of(
                      context,
                    ).pushNamed(AppRouter.chat, arguments: item.groupMessage);
                  },
                  onLongPress: (item) {
                    _showChatOptionsBottomSheet(context, item);
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(ChatItemState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Container(
            decoration: BoxDecoration(
              color: context.theme.grey,
              borderRadius: BorderRadius.circular(20.0),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 10.0,
              vertical: 4.0,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  color: context.theme.textColor.withOpacity(0.5),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const SearchingPage(),
                        ),
                      );
                    },
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
                Icon(
                  Icons.qr_code,
                  color: context.theme.textColor.withOpacity(0.5),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          height: 100,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children:
                  (state as ChatItemLoaded).friends
                      .map(
                        (user) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.of(
                                context,
                              ).pushNamed(AppRouter.chat, arguments: user);
                            },
                            onLongPress: () {
                              debugPrint("LongPress");
                            },
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CustomRoundAvatar(
                                  radius: 32,
                                  isActive: user.isActive,
                                  avatarUrl: user.photoUrl,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  user.name,
                                  style: TextStyle(
                                    color: context.theme.textColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(),
            ),
          ),
        ),
      ],
    );
  }

  void _showChatOptionsBottomSheet(BuildContext context, ChatItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: context.theme.appBar,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                height: 6,
                width: 50,
                color: Colors.grey,
              ),

              ListTile(
                leading: Icon(Icons.archive, color: context.theme.textColor),
                title: Text(
                  'LÆ°u trá»¯',
                  style: TextStyle(color: context.theme.textColor),
                ),
                onTap: () {
                  Navigator.pop(context);
                },
              ),

              ListTile(
                leading: Icon(Icons.person_add, color: context.theme.textColor),
                title: Text(
                  'ThÃªm thÃ nh viÃªn',
                  style: TextStyle(color: context.theme.textColor),
                ),
                onTap: () {
                  Navigator.pop(context);
                },
              ),

              ListTile(
                leading: Icon(
                  Icons.notifications_off,
                  color: context.theme.textColor,
                ),
                title: Text(
                  'Táº¯t thÃ´ng bÃ¡o',
                  style: TextStyle(color: context.theme.textColor),
                ),
                onTap: () {
                  Navigator.pop(context);
                },
              ),

              ListTile(
                leading: Icon(Icons.markunread, color: context.theme.textColor),
                title: Text(
                  'ÄÃ¡nh dáº¥u lÃ  chÆ°a Ä‘á»c',
                  style: TextStyle(color: context.theme.textColor),
                ),
                onTap: () {
                  Navigator.pop(context);
                },
              ),

              ListTile(
                leading: Icon(
                  Icons.exit_to_app,
                  color: context.theme.textColor,
                ),
                title: Text(
                  'Rá»i nhÃ³m',
                  style: TextStyle(color: context.theme.textColor),
                ),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete, color: context.theme.red),
                title: Text('XÃ³a', style: TextStyle(color: context.theme.red)),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

