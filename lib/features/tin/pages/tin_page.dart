import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:messenger_clone/core/utils/custom_theme_extension.dart';
import 'package:messenger_clone/core/widgets/custom_text_style.dart';

import 'package:messenger_clone/core/widgets/elements/custom_button.dart';
import 'package:messenger_clone/features/tin/pages/detail_tinPage.dart';
import 'package:messenger_clone/features/tin/pages/gallery_uploadTin.dart';
import 'package:messenger_clone/core/local/hive_storage.dart';
import '../../../core/widgets/dialog/custom_alert_dialog.dart';
import 'package:get_it/get_it.dart';
import 'package:messenger_clone/features/story/domain/repositories/story_repository.dart';
import 'package:messenger_clone/features/user/domain/repositories/user_repository.dart';
import '../widgets/story_item.dart';

class TinPage extends StatefulWidget {
  const TinPage({super.key});

  @override
  State<TinPage> createState() => _TinPageState();
}

class _TinPageState extends State<TinPage> {
  final List<StoryItem> stories = [];
  String? _currentUserAvatarUrl;
  bool _isRefreshing = false; // Tracks refresh state

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserData();
    _fetchStoriesFromAppwrite();
  }

  Future<void> _fetchCurrentUserData() async {
    try {
      final userId = await HiveService.instance.getCurrentUserId();
      final result = await GetIt.I<UserRepository>().fetchUserDataById(userId);
      final userData = result.fold((l) => throw Exception(l.message), (r) => r);
      setState(() {
        _currentUserAvatarUrl =
            userData['photoUrl'] as String? ??
            'https://images.hcmcpv.org.vn/res/news/2024/02/24-02-2024-ve-su-dung-co-dang-va-hinh-anh-co-dang-cong-san-viet-nam-FE119635-details.jpg?vs=24022024094023';
      });
    } catch (e) {
      if (mounted) {
        CustomAlertDialog.show(
          context: context,
          title: 'Lá»—i',
          message: 'KhÃ´ng thá»ƒ láº¥y thÃ´ng tin ngÆ°á»i dÃ¹ng: $e',
        );
      }
    }
  }

  Future<void> _fetchStoriesFromAppwrite() async {
    try {
      final userId = await HiveService.instance.getCurrentUserId();
      final result = await GetIt.I<StoryRepository>().fetchFriendsStories(
        userId,
      );
      final fetchedStories = result.fold(
        (l) => throw Exception(l.message),
        (r) => r,
      );

      final storyItems = await Future.wait(
        fetchedStories.map((data) async {
          final userResult = await GetIt.I<UserRepository>().fetchUserDataById(
            data['userId'] as String,
          );
          final userData = userResult.fold(
            (l) => <String, dynamic>{
              'userName': 'Unknown',
              'photoUrl': '',
            }, // Fallback or throw?
            (r) => r,
          );

          int totalStories = data['totalStories'] as int;
          if (data['mediaType'] == 'video') {
            totalStories = 10;
          }
          return StoryItem(
            userId: data['userId'] as String,
            title: userData['userName'] as String? ?? 'Unknown',
            imageUrl: data['mediaUrl'] as String,
            avatarUrl: userData['photoUrl'] as String? ?? '',
            isVideo: data['mediaType'] == 'video',
            postedAt: DateTime.parse(data['createdAt'] as String),
            totalStories: totalStories,
          );
        }).toList(),
      );

      if (mounted) {
        setState(() {
          stories.clear(); // Clear old stories
          stories.addAll(storyItems);
          stories.sort((a, b) => b.postedAt.compareTo(a.postedAt));
        });
      }
    } catch (e) {
      if (mounted) {
        CustomAlertDialog.show(
          context: context,
          title: 'Lá»—i',
          message: 'Lá»—i khi láº¥y DANH SÃCH TIN: $e',
        );
      }
    }
  }

  // Handle pull-to-refresh
  Future<void> _onRefresh() async {
    setState(() {
      _isRefreshing = true; // Show loading indicator
    });
    try {
      await _fetchStoriesFromAppwrite(); // Refresh stories
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false; // Hide loading indicator
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, List<StoryItem>> groupedStories = {};
    for (var story in stories) {
      if (groupedStories.containsKey(story.userId)) {
        groupedStories[story.userId]!.add(story);
      } else {
        groupedStories[story.userId] = [story];
      }
    }

    final displayStories = [
      StoryItem(
        userId: 'add_to_tin',
        title: 'ThÃªm vÃ o tin',
        imageUrl:
            _currentUserAvatarUrl ??
            'https://images.hcmcpv.org.vn/res/news/2024/02/24-02-2024-ve-su-dung-co-dang-va-hinh-anh-co-dang-cong-san-viet-nam-FE119635-details.jpg?vs=24022024094023',
        avatarUrl: '',
        notificationCount: 0,
        postedAt: DateTime.now(),
      ),
      ...groupedStories.entries.map((entry) => entry.value.first),
    ];

    return Scaffold(
      backgroundColor: context.theme.bg,
      appBar: AppBar(
        backgroundColor: context.theme.bg,
        elevation: 0,
        title: const TitleText("Tin"),
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _onRefresh,
            color: context.theme.grey, // Matches the loading indicator color
            child: GridView.builder(
              padding: const EdgeInsets.all(8.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
                childAspectRatio: 0.7,
              ),
              itemCount: displayStories.length,
              itemBuilder: (context, index) {
                final story = displayStories[index];
                final isFirst = index == 0;
                return GestureDetector(
                  onTap: () async {
                    if (isFirst) {
                      final newStory = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const GallerySelectionPage(),
                        ),
                      );
                      if (newStory != null &&
                          newStory is StoryItem &&
                          mounted) {
                        setState(() {
                          stories.add(newStory);
                          stories.sort(
                            (a, b) => b.postedAt.compareTo(a.postedAt),
                          );
                        });
                        CustomAlertDialog.show(
                          context: context,
                          title: 'ThÃ nh cÃ´ng',
                          message: 'ÄÃ£ thÃªm tin má»›i!',
                        );
                      }
                    } else {
                      final userStories =
                          stories
                              .where((s) => s.userId == story.userId)
                              .toList();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => StoryDetailPage(
                                stories: userStories,
                                initialIndex: 0,
                              ),
                        ),
                      );
                    }
                  },
                  child: StoryCard(story: story, isFirst: isFirst),
                );
              },
            ),
          ),
          if (_isRefreshing)
            Center(child: CircularProgressIndicator(color: context.theme.grey)),
        ],
      ),
    );
  }
}

class StoryCard extends StatefulWidget {
  final StoryItem story;
  final bool isFirst;

  const StoryCard({super.key, required this.story, required this.isFirst});

  @override
  State<StoryCard> createState() => _StoryCardState();
}

class _StoryCardState extends State<StoryCard> {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16.0),
      child: Stack(
        children: [
          CachedNetworkImage(
            imageUrl:
                widget.isFirst
                    ? widget.story.imageUrl
                    : (widget.story.isVideo)
                    ? 'https://images.hcmcpv.org.vn/res/news/2024/02/24-02-2024-ve-su-dung-co-dang-va-hinh-anh-co-dang-cong-san-viet-nam-FE119635-details.jpg?vs=24022024094023'
                    : widget.story.imageUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorWidget:
                (context, error, stackTrace) =>
                    const Icon(Icons.error, color: Colors.red),
          ),
          if (!widget.isFirst)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      widget.story.hasBorder
                          ? context.theme.blue
                          : Colors.transparent,
                ),
                child: CircleAvatar(
                  radius: 18,
                  backgroundImage: CachedNetworkImageProvider(
                    widget.story.avatarUrl,
                  ),
                ),
              ),
            ),
          if (widget.isFirst)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.theme.white.withOpacity(0.9),
                ),
                child: Icon(Icons.add, size: 36, color: context.theme.blue),
              ),
            ),
          if (widget.story.notificationCount > 0)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: context.theme.grey.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.story.notificationCount.toString(),
                  style: TextStyle(
                    color: context.theme.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          if ((widget.story.isVideo) && !widget.isFirst)
            Positioned(
              child: Center(
                child: Icon(
                  Icons.play_circle_outline,
                  color: context.theme.white.withOpacity(0.7),
                  size: 40,
                ),
              ),
            ),
          Positioned(
            bottom: 8,
            left: 8,
            right: 8,
            child: Text(
              widget.story.title,
              style: TextStyle(
                color: context.theme.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
