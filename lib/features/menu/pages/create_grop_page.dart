import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:messenger_clone/core/utils/custom_theme_extension.dart';
import 'package:messenger_clone/core/widgets/custom_text_style.dart';
import 'package:messenger_clone/features/menu/presentation/bloc/create_group_bloc.dart';
import 'package:messenger_clone/features/chat/model/user.dart';
import 'package:messenger_clone/routes/app_router.dart';

import 'package:get_it/get_it.dart';
import 'package:messenger_clone/features/menu/domain/usecases/create_group_usecase.dart';
import 'package:messenger_clone/features/chat/domain/usecases/get_friends_usecase.dart';
import 'package:messenger_clone/features/auth/domain/usecases/get_current_user_usecase.dart';

class CreateGroupPage extends StatelessWidget {
  const CreateGroupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (_) => CreateGroupBloc(
            getFriendsUseCase: GetIt.I<GetFriendsUseCase>(),
            createGroupUseCase: GetIt.I<CreateGroupUseCase>(),
            getCurrentUserUseCase: GetIt.I<GetCurrentUserUseCase>(),
          ),
      child: const _CreateGroupView(),
    );
  }
}

class _CreateGroupView extends StatefulWidget {
  const _CreateGroupView();

  @override
  State<_CreateGroupView> createState() => _CreateGroupViewState();
}

class _CreateGroupViewState extends State<_CreateGroupView> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _groupNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<CreateGroupBloc>().add(const LoadFriendsEvent());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _groupNameController.dispose();
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
          'Create Group',
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: context.theme.appBar,
      ),
      body: BlocListener<CreateGroupBloc, CreateGroupState>(
        listenWhen:
            (previous, current) =>
                current is CreateGroupLoaded &&
                current.status == CreateGroupStatus.success &&
                current.createdGroup != null,
        listener: (context, state) {
          if (state is CreateGroupLoaded && state.createdGroup != null) {
            Navigator.pushReplacementNamed(
              context,
              AppRouter.chat,
              arguments: state.createdGroup,
            );
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
                child: TextField(
                  controller: _groupNameController,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 0,
                    ),
                    hintText: 'Group Name',
                    hintStyle: TextStyle(
                      color: context.theme.textColor.withOpacity(0.5),
                      fontSize: 16.0,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onChanged: (value) {
                    context.read<CreateGroupBloc>().add(
                      UpdateGroupNameEvent(value),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
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
                          context.read<CreateGroupBloc>().add(
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
                child: BlocBuilder<CreateGroupBloc, CreateGroupState>(
                  builder: (context, state) {
                    if (state is CreateGroupLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is CreateGroupLoaded) {
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
                                context.read<CreateGroupBloc>().add(
                                  DeselectFriendEvent(friend.id),
                                );
                              } else {
                                context.read<CreateGroupBloc>().add(
                                  SelectFriendEvent(friend.id),
                                );
                              }
                            },
                          );
                        },
                      );
                    } else if (state is CreateGroupError) {
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
                        'Search and select friends to create a group.',
                      ),
                    );
                  },
                ),
              ),
              BlocBuilder<CreateGroupBloc, CreateGroupState>(
                builder: (context, state) {
                  final isEnabled =
                      state is CreateGroupLoaded &&
                      state.selectedFriends.isNotEmpty &&
                      state.selectedFriends.length > 1 &&
                      state.groupName.trim().isNotEmpty;
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          isEnabled
                              ? () {
                                context.read<CreateGroupBloc>().add(
                                  const SubmitCreateGroupEvent(),
                                );
                              }
                              : null,
                      child:
                          state is CreateGroupLoaded &&
                                  state.status == CreateGroupStatus.creating
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : const Text('Create Group'),
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
