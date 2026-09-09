import 'package:flutter/material.dart';
import 'package:grjoffice_apps/core/app_colors.dart';

/// Builds a form field caption, adding the red `*` that marks a mandatory
/// field.
///
/// Screens keep their own label styling and simply pass it in, so the asterisk
/// looks the same everywhere without forcing one label design on every form.
Widget fieldLabelText(
  String text, {
  required TextStyle style,
  bool isRequired = false,
  TextAlign? textAlign,
}) {
  if (!isRequired) return Text(text, style: style, textAlign: textAlign);
  return Text.rich(
    TextSpan(
      text: text,
      style: style,
      children: [
        TextSpan(
          text: ' *',
          style: style.copyWith(
            color: AppColors.primaryRed,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
    textAlign: textAlign,
  );
}

/// Same marker for fields whose caption sits inside an [InputDecoration].
///
/// Use it with `InputDecoration(label: ...)` instead of `labelText:`.
Widget inputDecorationLabel(
  String text, {
  TextStyle? style,
  bool isRequired = false,
}) {
  final base = style ?? const TextStyle();
  return fieldLabelText(text, style: base, isRequired: isRequired);
}
