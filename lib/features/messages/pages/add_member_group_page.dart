import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:messenger_clone/core/utils/custom_theme_extension.dart';
import 'package:messenger_clone/core/widgets/custom_text_style.dart';
import 'package:messenger_clone/features/chat/model/group_message.dart';
import 'package:messenger_clone/features/messages/bloc/add_member_group_bloc.dart';
import 'package:messenger_clone/features/messages/bloc/add_member_group_event.dart';
import 'package:messenger_clone/features/messages/bloc/add_member_group_state.dart';
import 'package:messenger_clone/features/messages/presentation/bloc/message_bloc.dart';

class AddMemberGroupPage extends StatelessWidget {
  final GroupMessage groupMessage;

  const AddMemberGroupPage({super.key, required this.groupMessage});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AddMemberGroupBloc(groupMessage: groupMessage),
      child: _AddMemberGroupView(groupMessage: groupMessage),
    );
  }
}

class _AddMemberGroupView extends StatefulWidget {
  final GroupMessage groupMessage;

  const _AddMemberGroupView({required this.groupMessage});

  @override
  State<_AddMemberGroupView> createState() => _AddMemberGroupViewState();
}

class _AddMemberGroupViewState extends State<_AddMemberGroupView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<AddMemberGroupBloc>().add(
      LoadFriendsEvent(
        widget.groupMessage.users.map((user) => user.id).toList(),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.bg,
      appBar: AppBar(
        iconTheme: IconThemeData(color: context.theme.textColor),
        centerTitle: true,
        title: const TitleText(
          'Add Members',
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: context.theme.appBar,
      ),
      body: BlocListener<AddMemberGroupBloc, AddMemberGroupState>(
        listenWhen:
            (previous, current) =>
                current is AddMemberGroupLoaded &&
                current.status == AddMemberGroupStatus.success,
        listener: (context, state) {
          if (state is AddMemberGroupLoaded &&
              state.status == AddMemberGroupStatus.success) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Members added successfully'),
                backgroundColor: Colors.green,
              ),
            );
            context.read<MessageBloc>().add(
              MessageAddGroupMemberEvent(state.groupMessage!),
            );

            Navigator.pop(context);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                  vertical: 4.0,
                ),
                decoration: BoxDecoration(
                  color: context.theme.grey,
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search,
                      color: context.theme.textColor.withOpacity(0.5),
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
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
                        onChanged: (value) {
                          context.read<AddMemberGroupBloc>().add(
                            SearchFriendsEvent(value),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: BlocBuilder<AddMemberGroupBloc, AddMemberGroupState>(
                  builder: (context, state) {
                    if (state is AddMemberGroupLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is AddMemberGroupLoaded) {
                      final friendsToShow =
                          state.filteredFriends ?? state.friends;
                      return ListView.builder(
                        itemCount: friendsToShow.length,
                        itemBuilder: (context, index) {
                          final friend = friendsToShow[index];
                          final isSelected = state.selectedFriends.contains(
                            friend.id,
                          );
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage:
                                  friend.photoUrl.isNotEmpty &&
                                          friend.photoUrl.startsWith('http')
                                      ? NetworkImage(friend.photoUrl)
                                      : const AssetImage(
                                            'assets/images/avatar.png',
                                          )
                                          as ImageProvider,
                            ),
                            title: Text(
                              friend.name.isNotEmpty ? friend.name : 'Unknown',
                            ),
                            trailing:
                                isSelected
                                    ? const Icon(
                                      Icons.check_circle,
                                      color: Colors.blue,
                                    )
                                    : const Icon(Icons.radio_button_unchecked),
                            onTap: () {
                              if (isSelected) {
                                context.read<AddMemberGroupBloc>().add(
                                  DeselectFriendEvent(friend.id),
                                );
                              } else {
                                context.read<AddMemberGroupBloc>().add(
                                  SelectFriendEvent(friend.id),
                                );
                              }
                            },
                          );
                        },
                      );
                    } else if (state is AddMemberGroupError) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              state.message,
                              style: TextStyle(color: context.theme.white),
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      });
                      return const SizedBox.shrink();
                    }
                    return const Center(
                      child: Text(
                        'Search and select friends to add to the group.',
                      ),
                    );
                  },
                ),
              ),
              BlocBuilder<AddMemberGroupBloc, AddMemberGroupState>(
                builder: (context, state) {
                  final isEnabled =
                      state is AddMemberGroupLoaded &&
                      state.selectedFriends.isNotEmpty;
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          isEnabled
                              ? () {
                                context.read<AddMemberGroupBloc>().add(
                                  const SubmitAddMembersEvent(),
                                );
                              }
                              : null,
                      child:
                          state is AddMemberGroupLoaded &&
                                  state.status == AddMemberGroupStatus.adding
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : const Text('Add Members'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}


