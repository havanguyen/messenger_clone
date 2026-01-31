import 'package:flutter/material.dart';
import 'package:messenger_clone/core/utils/custom_theme_extension.dart';

class CustomRoundAvatar extends StatelessWidget {
  final String? avatarUrl;
  final bool isActive;
  final double radius;
  final double? radiusOfActiveIndicator;

  const CustomRoundAvatar({
    super.key,
    this.avatarUrl,
    required this.isActive,
    required this.radius,
    this.radiusOfActiveIndicator = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CircleAvatar(
          radius: radius,
          child: ClipOval(
            child: Image.network(
              avatarUrl ?? '',
              fit: BoxFit.cover,
              width: radius * 2,
              height: radius * 2,
              errorBuilder: (context, error, stackTrace) {
                return Image.asset(
                  'assets/images/avatar.png',
                  fit: BoxFit.cover,
                  width: radius * 2,
                  height: radius * 2,
                );
              },
            ),
          ),
        ),
        if (isActive)
          Positioned(
            bottom: 1,
            right: 1,
            child: CircleAvatar(
              backgroundColor: context.theme.bg,
              radius: radiusOfActiveIndicator,
              child: CircleAvatar(
                radius: radiusOfActiveIndicator! - 2,
                backgroundColor: context.theme.green,
              ),
            ),
          ),
      ],
    );
  }
}


