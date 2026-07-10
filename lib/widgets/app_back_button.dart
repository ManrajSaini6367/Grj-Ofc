import 'package:flutter/material.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/navigation/app_navigation.dart';

/// Consistent back button aligned to the screen's left content edge.
class AppBackButton extends StatelessWidget {
  const AppBackButton({
    super.key,
    this.onPressed,
    this.color = AppColors.headingBlack,
    this.size = 40,
    this.iconSize = 18,
    this.useShellPop = false,
  });

  final VoidCallback? onPressed;
  final Color color;
  final double size;
  final double iconSize;

  /// When true, pops the [MainShell] nested navigator first.
  final bool useShellPop;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: IconButton(
        onPressed: onPressed ??
            () {
              if (useShellPop) {
                popShellRoute(context);
              } else {
                Navigator.of(context).maybePop();
              }
            },
        icon: Icon(Icons.arrow_back_ios_new_rounded, size: iconSize, color: color),
        padding: EdgeInsets.zero,
        alignment: Alignment.centerLeft,
        constraints: BoxConstraints.tightFor(width: size, height: size),
        visualDensity: VisualDensity.compact,
        style: IconButton.styleFrom(
          padding: EdgeInsets.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          alignment: Alignment.centerLeft,
          minimumSize: Size(size, size),
          maximumSize: Size(size, size),
        ),
      ),
    );
  }
}
