import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:messenger_clone/core/utils/custom_theme_extension.dart';

import 'package:messenger_clone/features/friend/domain/repositories/friend_repository.dart';
import 'package:messenger_clone/features/user/domain/repositories/user_repository.dart';
import 'package:messenger_clone/core/widgets/custom_text_style.dart';

import 'package:messenger_clone/core/local/hive_storage.dart';

class FriendRequestPage extends StatefulWidget {
  const FriendRequestPage({super.key});

  @override
  State<FriendRequestPage> createState() => _FriendRequestPageState();
}

class _FriendRequestPageState extends State<FriendRequestPage> {
  List<Map<String, dynamic>> _friendRequests = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _currentUserId = '';

  @override
  void initState() {
    super.initState();
    _fetchFriendRequests();
  }

  Future<void> _fetchFriendRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final currentUser = await HiveService.instance.getCurrentUserId();
      _currentUserId = currentUser;

      final requestsResult = await GetIt.I<FriendRepository>()
          .getPendingFriendRequests(_currentUserId);
      final requests = requestsResult.fold(
        (l) => throw Exception(l.message),
        (r) => r,
      );

      final detailedRequests = await Future.wait(
        requests.map((request) async {
          final userResult = await GetIt.I<UserRepository>().fetchUserDataById(
            request['userId'],
          );
          final userData = userResult.fold(
            (l) => <String, dynamic>{}, // Handle error gracefully or throw?
            // If user fetch fails, we might just return default/unknown or skip?
            // Existing logic threw error? existing logic: UserService threw exception.
            // Let's return empty map and handle display.
            (r) => r,
          );

          return {
            'requestId': request['requestId'],
            'userId': request['userId'],
            'name': userData['userName'] ?? 'Unknown',
            'photoUrl': userData['photoUrl'],
          };
        }).toList(),
      );

      setState(() {
        _friendRequests = detailedRequests;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load friend requests: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _acceptRequest(String requestId) async {
    try {
      final result = await GetIt.I<FriendRepository>().acceptFriendRequest(
        requestId,
        _currentUserId,
      );
      result.fold((l) => throw Exception(l.message), (_) => null);

      await _fetchFriendRequests();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Friend request accepted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to accept request: $e')));
      }
    }
  }

  Future<void> _declineRequest(String requestId) async {
    try {
      final result = await GetIt.I<FriendRepository>().declineFriendRequest(
        requestId,
      );
      result.fold((l) => throw Exception(l.message), (_) => null);

      await _fetchFriendRequests();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Friend request declined')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to decline request: $e')),
        );
      }
    }
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
          'Friend Requests',
          fontSize: 25,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [const SizedBox(height: 16), _buildContent(context)],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
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

    if (_friendRequests.isEmpty) {
      return const Center(
        child: TitleText(
          'No friend requests.',
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        itemCount: _friendRequests.length,
        itemBuilder: (context, index) {
          final request = _friendRequests[index];
          return _buildRequestCard(context, request);
        },
      ),
    );
  }

  Widget _buildRequestCard(BuildContext context, Map<String, dynamic> request) {
    return Card(
      color: context.theme.grey,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          radius: 25,
          backgroundImage:
              request['photoUrl'] != null &&
                      request['photoUrl'].startsWith('http')
                  ? NetworkImage(request['photoUrl'])
                  : const AssetImage('assets/images/avatar.png')
                      as ImageProvider,
        ),
        title: TitleText(
          request['name'] ?? 'Unknown',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: context.theme.textColor,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              onPressed: () => _acceptRequest(request['requestId']),
              child: const Text('Accept', style: TextStyle(fontSize: 12)),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: context.theme.textColor),
              ),
              onPressed: () => _declineRequest(request['requestId']),
              child: const Text('Decline', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}

