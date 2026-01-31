import 'package:flutter/material.dart';
import 'package:messenger_clone/core/utils/custom_theme_extension.dart';

import 'package:messenger_clone/core/widgets/custom_text_style.dart';

import 'package:get_it/get_it.dart';
import 'package:messenger_clone/features/friend/domain/repositories/friend_repository.dart';
// import '../../../../core/services/friend_service.dart'; // Removed
import 'package:messenger_clone/core/local/hive_storage.dart';

class ListFriendsPage extends StatefulWidget {
  const ListFriendsPage({super.key});

  @override
  State<ListFriendsPage> createState() => _ListFriendsPageState();
}

class _ListFriendsPageState extends State<ListFriendsPage>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _friendsList = [];
  bool _isLoading = false;
  String? _errorMessage;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String _currentUserId = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _fetchFriendsList();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchFriendsList() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final currentUser = await HiveService.instance.getCurrentUserId();
      _currentUserId = currentUser;

      final friendsResult = await GetIt.I<FriendRepository>().getFriendsList(
        _currentUserId,
      );
      final friends = friendsResult.fold(
        (l) => throw Exception(l.message),
        (r) => r,
      );
      setState(() {
        _friendsList = friends;
        _isLoading = false;
      });
      _animationController.forward(from: 0.0);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _removeFriend(String friendId) {
    setState(() {
      _friendsList =
          _friendsList.where((friend) => friend['userId'] != friendId).toList();
    });
    _animationController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.bg,
      appBar: AppBar(
        backgroundColor: context.theme.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          color: context.theme.textColor,
        ),
        title: const TitleText(
          'Friends List',
          fontSize: 25,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildFriendsList(context),
        ),
      ),
    );
  }

  Widget _buildFriendsList(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: TitleText(
          _errorMessage!,
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: context.theme.red,
        ),
      );
    }

    if (_friendsList.isEmpty) {
      return Center(
        child: TitleText(
          'You have no friends yet.',
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: context.theme.textColor.withOpacity(0.7),
        ),
      );
    }

    return ListView.builder(
      itemCount: _friendsList.length,
      itemBuilder: (context, index) {
        final friend = _friendsList[index];
        return FadeTransition(
          opacity: _fadeAnimation,
          child: _buildFriendCard(context, friend),
        );
      },
    );
  }

  Widget _buildFriendCard(BuildContext context, Map<String, dynamic> friend) {
    return Card(
      color: context.theme.grey,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          radius: 25,
          backgroundImage:
              friend['photoUrl'] != null &&
                      friend['photoUrl'].startsWith('http')
                  ? NetworkImage(friend['photoUrl'])
                  : const AssetImage('assets/images/avatar.png'),
        ),
        title: TitleText(
          friend['name'] ?? 'Unknown',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: context.theme.textColor,
        ),
        subtitle: TitleText(
          friend['aboutMe']?.isNotEmpty == true
              ? friend['aboutMe']
              : 'No description',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: context.theme.textColor.withOpacity(0.7),
        ),
        trailing: OutlinedButton(
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: context.theme.red),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          ),
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder:
                  (context) => AlertDialog(
                    title: const Text('Unfriend'),
                    content: Text(
                      'Are you sure you want to unfriend ${friend['name']}?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          'Unfriend',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
            );

            if (confirmed == true) {
              try {
                await GetIt.I<FriendRepository>()
                    .cancelFriendRequest(friend['requestId'])
                    .then(
                      (result) => result.fold(
                        (l) => throw Exception(l.message),
                        (_) => null,
                      ),
                    );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Unfriended ${friend['name']}')),
                  );
                  _removeFriend(friend['userId']);
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to unfriend: $e')),
                  );
                }
              }
            }
          },
          child: const Text(
            'Unfriend',
            style: TextStyle(fontSize: 12, color: Colors.red),
          ),
        ),
      ),
    );
  }
}

