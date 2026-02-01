import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:messenger_clone/core/utils/custom_theme_extension.dart';
import 'package:messenger_clone/core/widgets/custom_text_style.dart';
import 'package:messenger_clone/core/widgets/elements/custom_round_avatar.dart';
import 'package:messenger_clone/features/chat/model/group_message.dart';
import 'package:messenger_clone/features/messages/presentation/bloc/message_bloc.dart';
import 'package:messenger_clone/features/messages/pages/add_member_group_page.dart';

class GroupDetailPage extends StatefulWidget {
  final GroupMessage groupMessage;

  const GroupDetailPage({super.key, required this.groupMessage});

  @override
  State<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends State<GroupDetailPage> {
  late final TextEditingController _nameController;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.groupMessage.groupName,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      context.read<MessageBloc>().add(
        MessageUpdateGroupAvatarEvent(image.path),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const ContentText('Group Details'),
        backgroundColor: context.theme.appBar,
        iconTheme: IconThemeData(color: context.theme.blue),
      ),
      body: BlocListener<MessageBloc, MessageState>(
        listener: (context, state) {
          if (state is MessageLoaded && state.successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.successMessage!),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 1),
              ),
            );
          } else if (state is MessageError) {
            debugPrint('MessageError: ${state.error}');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Something went wrong. Please try again.'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
        child: BlocBuilder<MessageBloc, MessageState>(
          builder: (context, state) {
            if (state is MessageLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is MessageError) {
              debugPrint('MessageError: ${state.error}');
              return Center(
                child: ContentText(
                  'Something went wrong. Please try again.',
                  color: context.theme.red,
                ),
              );
            } else if (state is MessageLoaded) {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // Group Avatar
                    GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        children: [
                          CustomRoundAvatar(
                            radius: 50,
                            avatarUrl: state.groupMessage.avatarGroupUrl,
                            isActive: false,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: context.theme.blue,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Group Name
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Group Name',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.check),
                            onPressed: () {
                              context.read<MessageBloc>().add(
                                MessageUpdateGroupNameEvent(
                                  _nameController.text,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Members List
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const ContentText(
                            'Members',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          const SizedBox(height: 10),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: state.groupMessage.users.length,
                            itemBuilder: (context, index) {
                              final member = state.groupMessage.users[index];
                              final isAdmin =
                                  member.id == state.groupMessage.createrId;
                              final isCurrentUserAdmin =
                                  state.meId == state.groupMessage.createrId;

                              return ListTile(
                                leading: CustomRoundAvatar(
                                  radius: 20,
                                  avatarUrl: member.photoUrl,
                                  isActive: member.isActive,
                                ),
                                title: Row(
                                  children: [
                                    ContentText(member.name),
                                    if (isAdmin)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          left: 8.0,
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: context.theme.blue
                                                .withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: ContentText(
                                            'Admin',
                                            fontSize: 12,
                                            color: context.theme.blue,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                subtitle: ContentText(
                                  member.email,
                                  color: context.theme.textGrey,
                                ),
                                trailing:
                                    isCurrentUserAdmin && !isAdmin
                                        ? IconButton(
                                          icon: Icon(
                                            Icons.delete,
                                            color: context.theme.red,
                                          ),
                                          onPressed: () async {
                                            final shouldRemove = await showDialog<
                                              bool
                                            >(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  title: const ContentText(
                                                    'Remove Member',
                                                  ),
                                                  content: ContentText(
                                                    'Are you sure you want to remove ${member.name} from the group?',
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed:
                                                          () => Navigator.of(
                                                            context,
                                                          ).pop(false),
                                                      child: ContentText(
                                                        'Cancel',
                                                        color:
                                                            context
                                                                .theme
                                                                .textGrey,
                                                      ),
                                                    ),
                                                    TextButton(
                                                      onPressed:
                                                          () => Navigator.of(
                                                            context,
                                                          ).pop(true),
                                                      child: ContentText(
                                                        'Remove',
                                                        color:
                                                            context.theme.red,
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );

                                            if (shouldRemove == true) {
                                              context.read<MessageBloc>().add(
                                                MessageRemoveGroupMemberEvent(
                                                  member,
                                                ),
                                              );
                                            }
                                          },
                                        )
                                        : null,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    // Add Member Button
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: ElevatedButton(
                        onPressed: () {
                          final messageBloc = context.read<MessageBloc>();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => BlocProvider.value(
                                    value: messageBloc,
                                    child: AddMemberGroupPage(
                                      groupMessage: widget.groupMessage,
                                    ),
                                  ),
                            ),
                          );
                        },
                        child: const ContentText('Add Members'),
                      ),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }
}
