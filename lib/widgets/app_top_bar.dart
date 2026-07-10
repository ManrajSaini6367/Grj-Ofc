import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/navigation/app_navigation.dart';
import 'package:grjoffice_apps/widgets/app_back_button.dart';
import 'package:grjoffice_apps/widgets/app_logo.dart';

/// Shared white app bar used across the app.
///
/// Layout: [leading] — centered [title] — [trailing / profile / actions]
class AppTopBar extends StatelessWidget {
  const AppTopBar({
    super.key,
    required this.title,
    this.scaffoldKey,
    this.onBack,
    this.useShellPop = false,
    this.showBack = false,
    this.showProfile = false,
    this.actions = const <Widget>[],
    this.horizontalPadding,
  });

  /// Bottom-tab style: logo opens drawer, optional profile.
  factory AppTopBar.tab({
    Key? key,
    required String title,
    required GlobalKey<ScaffoldState> scaffoldKey,
    bool showProfile = true,
    List<Widget> actions = const <Widget>[],
    double? horizontalPadding,
  }) {
    return AppTopBar(
      key: key,
      title: title,
      scaffoldKey: scaffoldKey,
      showProfile: showProfile,
      actions: actions,
      horizontalPadding: horizontalPadding,
    );
  }

  /// Shell-pushed list style: back when nested, else logo; optional profile.
  factory AppTopBar.shell({
    Key? key,
    required String title,
    required GlobalKey<ScaffoldState> scaffoldKey,
    bool showProfile = true,
    List<Widget> actions = const <Widget>[],
    double? horizontalPadding,
  }) {
    return AppTopBar(
      key: key,
      title: title,
      scaffoldKey: scaffoldKey,
      useShellPop: true,
      showProfile: showProfile,
      actions: actions,
      horizontalPadding: horizontalPadding,
    );
  }

  /// Secondary page style: always back, no profile by default.
  factory AppTopBar.page({
    Key? key,
    required String title,
    VoidCallback? onBack,
    bool useShellPop = false,
    bool showProfile = false,
    GlobalKey<ScaffoldState>? scaffoldKey,
    List<Widget> actions = const <Widget>[],
    double? horizontalPadding,
  }) {
    return AppTopBar(
      key: key,
      title: title,
      onBack: onBack,
      useShellPop: useShellPop,
      showBack: true,
      showProfile: showProfile,
      scaffoldKey: scaffoldKey,
      actions: actions,
      horizontalPadding: horizontalPadding,
    );
  }

  final String title;
  final GlobalKey<ScaffoldState>? scaffoldKey;
  final VoidCallback? onBack;
  final bool useShellPop;
  final bool showBack;
  final bool showProfile;
  final List<Widget> actions;
  final double? horizontalPadding;

  static const double barHeight = 40;

  @override
  Widget build(BuildContext context) {
    final hPad = horizontalPadding ?? _defaultHPad(context);
    final leading = _buildLeading(context);
    final trailing = _buildTrailing(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(hPad, 10, hPad, 10),
      color: AppColors.cardWhite,
      child: SizedBox(
        height: barHeight,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                color: AppColors.headingBlack,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            Row(
              children: [
                leading,
                const Spacer(),
                trailing,
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeading(BuildContext context) {
    if (onBack != null) {
      return AppBackButton(onPressed: onBack);
    }

    if (useShellPop) {
      if (shellCanPop(context)) {
        return const AppBackButton(useShellPop: true);
      }
      if (scaffoldKey != null) {
        return GestureDetector(
          onTap: () => scaffoldKey!.currentState?.openDrawer(),
          child: const AppLogo(size: 38),
        );
      }
    }

    if (showBack) {
      return AppBackButton(useShellPop: useShellPop);
    }

    if (scaffoldKey != null) {
      return GestureDetector(
        onTap: () => scaffoldKey!.currentState?.openDrawer(),
        child: const AppLogo(size: 38),
      );
    }

    return const AppLogo(size: 38);
  }

  Widget _buildTrailing(BuildContext context) {
    final trailingChildren = <Widget>[
      ...actions,
      if (showProfile && scaffoldKey != null) _profileButton(scaffoldKey!),
    ];

    if (trailingChildren.isEmpty) {
      return const SizedBox(width: barHeight);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < trailingChildren.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          trailingChildren[i],
        ],
      ],
    );
  }

  Widget _profileButton(GlobalKey<ScaffoldState> key) {
    return GestureDetector(
      onTap: () => key.currentState?.openEndDrawer(),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.iconBgGray,
          border: Border.all(color: AppColors.borderGray),
        ),
        child: const Icon(
          Icons.person_outline,
          color: AppColors.textSecondary,
          size: 20,
        ),
      ),
    );
  }

  double _defaultHPad(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 360) return 14;
    if (width < 600) return 18;
    return 20;
  }
}
