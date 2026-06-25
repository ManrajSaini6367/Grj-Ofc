import 'package:flutter/material.dart';
import 'package:grjoffice_apps/core/app_colors.dart';

void message(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(text),
      backgroundColor: AppColors.primaryRed,
    ),
  );
}

void pushAndRevoveUntil(BuildContext context, Widget screen) {
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => screen),
    (route) => false,
  );
}
