import 'package:flutter/material.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/navigation/app_navigation.dart';
import 'package:grjoffice_apps/widgets/app_back_button.dart';
import 'package:grjoffice_apps/widgets/app_logo.dart';

/// Shows a back button when opened above [MainShell], otherwise opens the drawer.
class ShellTopLead extends StatelessWidget {
  const ShellTopLead({
    super.key,
    required this.scaffoldKey,
    this.logoSize = 38,
  });

  final GlobalKey<ScaffoldState> scaffoldKey;
  final double logoSize;

  @override
  Widget build(BuildContext context) {
    if (shellCanPop(context)) {
      return const AppBackButton(useShellPop: true);
    }

    return GestureDetector(
      onTap: () => scaffoldKey.currentState?.openDrawer(),
      child: AppLogo(size: logoSize),
    );
  }
}

/// Menu-style leading for screens that use a hamburger icon.
class ShellMenuLead extends StatelessWidget {
  const ShellMenuLead({super.key, required this.scaffoldKey});

  final GlobalKey<ScaffoldState> scaffoldKey;

  @override
  Widget build(BuildContext context) {
    if (shellCanPop(context)) {
      return const AppBackButton(useShellPop: true);
    }

    return SizedBox(
      width: 40,
      height: 40,
      child: IconButton(
        onPressed: () => scaffoldKey.currentState?.openDrawer(),
        icon: const Icon(Icons.menu_rounded, color: AppColors.headingBlack, size: 26),
        padding: EdgeInsets.zero,
        alignment: Alignment.centerLeft,
        constraints: const BoxConstraints.tightFor(width: 40, height: 40),
        visualDensity: VisualDensity.compact,
        style: IconButton.styleFrom(
          padding: EdgeInsets.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          alignment: Alignment.centerLeft,
          minimumSize: const Size(40, 40),
          maximumSize: const Size(40, 40),
        ),
      ),
    );
  }
}
