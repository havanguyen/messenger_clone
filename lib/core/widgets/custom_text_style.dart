// ignore_for_file: constant_identifier_names
import 'package:flutter/material.dart';

import 'package:messenger_clone/core/utils/custom_theme_extension.dart';

const double DEFAULT_TITLE_FONT_SIZE = 28;
const double DEFAULT_HEADLINE_FONT_SIZE = 20;
const double DEFAULT_CONTENT_FONT_SIZE = 15;

class TitleText extends BaseText {
  const TitleText(
    super.text, {
    super.key,
    double? fontSize,
    FontWeight? fontWeight,
    super.color,
    TextAlign? textAlign,
    TextOverflow? overflow,
    super.maxLines,
    super.decoration,
  }) : super(
         fontSize: fontSize ?? DEFAULT_TITLE_FONT_SIZE,
         fontWeight: fontWeight ?? FontWeight.w900,
         textAlign: textAlign ?? TextAlign.left,
         overflow: overflow ?? TextOverflow.visible,
       );
}

class HeadlineText extends BaseText {
  const HeadlineText(
    super.text, {
    super.key,
    double? fontSize,
    FontWeight? fontWeight,
    super.color,
    TextAlign? textAlign,
    TextOverflow? overflow,
    super.maxLines,
    super.decoration,
  }) : super(
         fontSize: fontSize ?? DEFAULT_HEADLINE_FONT_SIZE,
         fontWeight: fontWeight ?? FontWeight.w700,
         textAlign: textAlign ?? TextAlign.left,
         overflow: overflow ?? TextOverflow.visible,
       );
}

class ContentText extends BaseText {
  const ContentText(
    super.text, {
    super.key,
    double? fontSize,
    FontWeight? fontWeight,
    super.color,
    TextAlign? textAlign,
    TextOverflow? overflow,
    super.maxLines,
    super.decoration,
  }) : super(
         fontSize: fontSize ?? DEFAULT_CONTENT_FONT_SIZE,
         fontWeight: fontWeight ?? FontWeight.w500,
         textAlign: textAlign ?? TextAlign.left,
         overflow: overflow ?? TextOverflow.visible,
       );
}

class BaseText extends StatefulWidget {
  final String? text;
  final double fontSize;
  final FontWeight fontWeight;
  final Color? color;
  final TextAlign textAlign;
  final TextOverflow overflow;
  final int? maxLines;
  final TextDecoration? decoration;

  const BaseText(
    this.text, {
    super.key,
    required this.fontSize,
    required this.fontWeight,
    this.color,
    required this.textAlign,
    required this.overflow,
    this.maxLines,
    this.decoration,
  });

  @override
  State<BaseText> createState() => _BaseTextState();
}

class _BaseTextState extends State<BaseText> {
  @override
  Widget build(BuildContext context) {
    return widget.text == null
        ? const SizedBox()
        : Text(
          widget.text!,
          style: TextStyle(
            decoration: widget.decoration,
            fontSize: widget.fontSize,
            fontWeight: widget.fontWeight,
            color: widget.color ?? context.theme.textColor,
          ),
          textScaler: const TextScaler.linear(1.0),
          textAlign: widget.textAlign,
          overflow: widget.overflow,
          maxLines: widget.maxLines,
        );
  }
}

