import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:messenger_clone/core/constants/ai_chat_constants.dart';
import 'package:messenger_clone/core/utils/custom_theme_extension.dart';
import 'package:messenger_clone/core/widgets/custom_text_style.dart';
import 'package:messenger_clone/core/widgets/dialog/custom_alert_dialog.dart';
import '../presentation/bloc/meta_ai_bloc.dart';
import '../presentation/bloc/meta_ai_event.dart';
import '../presentation/bloc/meta_ai_state.dart';

class MetaAiPage extends StatelessWidget {
  const MetaAiPage({super.key});

  void _showCreateConversationDialog(BuildContext context) {
    String selectedAiMode = 'friend';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: TitleText(
            'Create new conversation',
            color: context.theme.titleHeaderColor,
            fontSize: 20,
          ),
          backgroundColor: context.theme.appBar,
          content: StatefulBuilder(
            builder: (context, setState) {
              return DropdownButton<String>(
                dropdownColor: context.theme.appBar,
                value: selectedAiMode,
                items:
                    AIConfig.aiModeLabels.entries
                        .map(
                          (entry) => DropdownMenuItem(
                            value: entry.key,
                            child: Text(
                              entry.value,
                              style: TextStyle(color: context.theme.textColor),
                            ),
                          ),
                        )
                        .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selectedAiMode = value);
                  }
                },
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: TitleText(
                'Cancel',
                color: context.theme.red,
                fontSize: 16,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.read<MetaAiBloc>().add(
                  CreateConversation(selectedAiMode),
                );
              },
              child: TitleText(
                'Create',
                color: context.theme.blue,
                fontSize: 16,
              ),
            ),
          ],
        );
      },
    );
  }

  void _deleteConversationWithConfirmation(
    BuildContext context,
    String conversationId,
  ) {
    CustomAlertDialog.show(
      context: context,
      title: 'Confirm delete',
      message: 'Are you sure you want to delete this conversation?',
      buttonText: 'Delete',
      onPressed: () {
        Navigator.of(context).pop();
        context.read<MetaAiBloc>().add(DeleteConversation(conversationId));
      },
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: TitleText(
          message,
          color: context.theme.textColor,
          fontSize: 14,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MetaAiBloc, MetaAiState>(
      listener: (context, state) {
        if (state is MetaAiError) {
          _showErrorSnackBar(context, state.error);
        }
      },
      builder: (context, state) {
        if (state is MetaAiInitial || state is MetaAiLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final conversations =
            state is MetaAiLoaded
                ? state.conversations
                : state is MetaAiError
                ? state.conversations
                : state is MetaAiSyncing
                ? state.conversations
                : state is MetaAiConnectivityChanged
                ? state.conversations
                : const [];
        final messages =
            state is MetaAiLoaded
                ? state.messages
                : state is MetaAiError
                ? state.messages
                : state is MetaAiSyncing
                ? state.messages
                : state is MetaAiConnectivityChanged
                ? state.messages
                : const [];
        final currentConversationId =
            state is MetaAiLoaded
                ? state.currentConversationId
                : state is MetaAiError
                ? state.currentConversationId
                : state is MetaAiSyncing
                ? state.currentConversationId
                : state is MetaAiConnectivityChanged
                ? state.currentConversationId
                : null;
        final aiMode =
            state is MetaAiLoaded
                ? state.aiMode
                : state is MetaAiError
                ? state.aiMode
                : state is MetaAiSyncing
                ? state.aiMode
                : state is MetaAiConnectivityChanged
                ? state.aiMode
                : 'friend';
        final isSyncing = state is MetaAiSyncing;

        return Scaffold(
          appBar: AppBar(
            title: TitleText(
              AIConfig.aiModeLabels[aiMode] ?? 'Unknown',
              color: context.theme.titleHeaderColor,
              fontSize: 22,
            ),
            backgroundColor: context.theme.appBar,
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _showCreateConversationDialog(context),
              ),
              if (currentConversationId != null)
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed:
                      () => _deleteConversationWithConfirmation(
                        context,
                        currentConversationId,
                      ),
                ),
              IconButton(
                icon:
                    isSyncing
                        ? const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        )
                        : const Icon(Icons.refresh),
                onPressed:
                    isSyncing
                        ? null
                        : () => context.read<MetaAiBloc>().add(
                          const InitializeMetaAi(forceSync: true),
                        ),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh:
                () async => context.read<MetaAiBloc>().add(
                  const InitializeMetaAi(forceSync: true),
                ),
            child: Column(
              children: [
                if (conversations.isNotEmpty)
                  Container(
                    height: 60,
                    color: context.theme.grey,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: conversations.length,
                      itemBuilder: (context, index) {
                        final conv = conversations[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: TitleText(
                              AIConfig.aiModeLabels[conv['aiMode']] ??
                                  'Unknown',
                              color: context.theme.textColor,
                              fontSize: 16,
                            ),
                            selected: currentConversationId == conv['id'],
                            selectedColor: context.theme.blue,
                            backgroundColor: context.theme.bg,
                            onSelected: (selected) {
                              if (selected) {
                                context.read<MetaAiBloc>().add(
                                  LoadConversation(conv['id']),
                                );
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),
                Expanded(
                  child: Container(
                    color: context.theme.bg,
                    child: ListView.builder(
                      controller: context.read<MetaAiBloc>().scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      reverse: true,
                      itemBuilder: (context, index) {
                        final message = messages[messages.length - 1 - index];
                        final isUser = message['role'] == 'user';
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisAlignment:
                                isUser
                                    ? MainAxisAlignment.end
                                    : MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!isUser)
                                const CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Colors.blue,
                                  child: Icon(
                                    Icons.smart_toy,
                                    color: Colors.white,
                                  ),
                                ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Column(
                                  crossAxisAlignment:
                                      isUser
                                          ? CrossAxisAlignment.end
                                          : CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 10,
                                      ),
                                      constraints: BoxConstraints(
                                        maxWidth:
                                            MediaQuery.of(context).size.width *
                                            0.7,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            isUser
                                                ? context.theme.blue
                                                : context.theme.tileColor,
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.1,
                                            ),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: TitleText(
                                        message['content']!,
                                        color:
                                            isUser
                                                ? context.theme.white
                                                : context.theme.textColor,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    TitleText(
                                      message['timestamp']!,
                                      color: context.theme.textGrey,
                                      fontSize: 12,
                                    ),
                                  ],
                                ),
                              ),
                              if (isUser) const SizedBox(width: 8),
                              if (isUser)
                                const CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Colors.grey,
                                  child: Icon(
                                    Icons.person,
                                    color: Colors.white,
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Container(
                  color: context.theme.bg,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller:
                              context.read<MetaAiBloc>().messageController,
                          cursorColor: context.theme.blue,
                          style: TextStyle(color: context.theme.textColor),
                          decoration: InputDecoration(
                            hintText: 'Enter message...',
                            hintStyle: TextStyle(color: context.theme.textGrey),
                            labelStyle: TextStyle(
                              color: context.theme.textColor,
                            ),
                            filled: true,
                            fillColor: context.theme.grey,
                            border: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(30),
                              ),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FloatingActionButton(
                        onPressed:
                            currentConversationId == null
                                ? null
                                : () => context.read<MetaAiBloc>().add(
                                  SendMessage(
                                    context
                                        .read<MetaAiBloc>()
                                        .messageController
                                        .text,
                                  ),
                                ),
                        backgroundColor: context.theme.blue,
                        child: Icon(Icons.send, color: context.theme.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

