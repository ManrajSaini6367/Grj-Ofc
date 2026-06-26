import 'package:flutter/material.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/core/app_navigator.dart';

void message(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(text),
      backgroundColor: AppColors.primaryRed,
    ),
  );
}

void pushAndRevoveUntil(BuildContext context, Widget screen) {
  navigateToScreenAndClearStack(screen);
}
