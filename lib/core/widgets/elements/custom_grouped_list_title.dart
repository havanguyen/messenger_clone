import 'package:flutter/material.dart';

import 'package:messenger_clone/core/utils/custom_theme_extension.dart';

class CustomGroupedListTitle extends StatefulWidget {
  final bool isFirstTab;
  final bool isLastTab;
  final bool isMiddleTab;
  final bool isSingleTab;
  final Widget child;
  final void Function()? onTapFunc;

  const CustomGroupedListTitle({
    super.key,
    this.isFirstTab = false,
    this.isLastTab = false,
    this.isMiddleTab = false,
    this.isSingleTab = false,
    required this.child,
    this.onTapFunc,
  }) : assert(
         (isFirstTab ? 1 : 0) +
                 (isLastTab ? 1 : 0) +
                 (isMiddleTab ? 1 : 0) +
                 (isSingleTab ? 1 : 0) ==
             1,
         'Only one of isFirstTab, isLastTab, isMiddleTab, or isSingleTab can be true.',
       );

  @override
  State<CustomGroupedListTitle> createState() => _CustomGroupedListTitleState();
}

class _CustomGroupedListTitleState extends State<CustomGroupedListTitle> {
  bool switchValue = true;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.only(
        topLeft:
            widget.isFirstTab || widget.isSingleTab
                ? const Radius.circular(8)
                : Radius.zero,
        topRight:
            widget.isFirstTab || widget.isSingleTab
                ? const Radius.circular(8)
                : Radius.zero,
        bottomLeft:
            widget.isLastTab || widget.isSingleTab
                ? const Radius.circular(8)
                : Radius.zero,
        bottomRight:
            widget.isLastTab || widget.isSingleTab
                ? const Radius.circular(8)
                : Radius.zero,
      ),
      splashColor: context.theme.grey.withOpacity(0.2),
      highlightColor: context.theme.grey.withOpacity(0.1),
      onTap: widget.onTapFunc,
      child: Ink(
        padding: const EdgeInsets.all(0),
        decoration: BoxDecoration(
          color: context.theme.tileColor,
          borderRadius: BorderRadius.only(
            topLeft:
                widget.isFirstTab || widget.isSingleTab
                    ? const Radius.circular(8)
                    : Radius.zero,
            topRight:
                widget.isFirstTab || widget.isSingleTab
                    ? const Radius.circular(8)
                    : Radius.zero,
            bottomLeft:
                widget.isLastTab || widget.isSingleTab
                    ? const Radius.circular(8)
                    : Radius.zero,
            bottomRight:
                widget.isLastTab || widget.isSingleTab
                    ? const Radius.circular(8)
                    : Radius.zero,
          ),
        ),
        child: widget.child,
      ),
    );
  }
}


