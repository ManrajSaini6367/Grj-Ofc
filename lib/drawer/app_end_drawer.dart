import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/core/app_navigator.dart';
import 'package:grjoffice_apps/core/preference.dart';
import 'package:grjoffice_apps/navigation/app_navigation.dart';
import 'package:grjoffice_apps/profilescreen/contractor.dart';
import 'package:grjoffice_apps/profilescreen/edit_profile_screen.dart';
import 'package:grjoffice_apps/profilescreen/notifications_screen.dart';
import 'package:grjoffice_apps/services/api_auth.dart';
import 'package:grjoffice_apps/services/user_session.dart';

class AppEndDrawer extends StatelessWidget {
  const AppEndDrawer({super.key});

  /// Close the drawer, then run [action] with a still-mounted host context.
  void _closeThen(BuildContext drawerContext, void Function(BuildContext host) action) {
    Navigator.of(drawerContext).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final host = appNavigatorKey.currentContext;
      if (host == null || !host.mounted) return;
      action(host);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final drawerWidth = (screenWidth * 0.58).clamp(220.0, 280.0);

    return Drawer(
      width: drawerWidth,
      backgroundColor: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      child: SafeArea(
        child: Align(
          alignment: Alignment.topRight,
          child: Material(
            elevation: 8,
            shadowColor: Colors.black.withValues(alpha: 0.15),
            color: AppColors.cardWhite,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: AnimatedBuilder(
              animation: UserSession.instance,
              builder: (context, _) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(),
                    Divider(
                      height: 1,
                      color: AppColors.borderGray.withValues(alpha: 0.5),
                    ),
                    _buildMenuItem(
                      icon: Icons.person_outline,
                      title: 'Profile',
                      onTap: (ctx) => _closeThen(ctx, (host) {
                        navigateToMainTab(host, MainTab.profile);
                      }),
                    ),
                    _buildMenuItem(
                      icon: Icons.edit_outlined,
                      title: 'Edit Profile',
                      onTap: (ctx) => _closeThen(ctx, (host) {
                        pushInShell(host, const EditProfileScreen());
                      }),
                    ),
                    _buildMenuItem(
                      icon: Icons.notifications_outlined,
                      title: 'Notifications',
                      onTap: (ctx) => _closeThen(ctx, (host) {
                        pushInShell(host, const NotificationsScreen());
                      }),
                    ),
                    _buildMenuItem(
                      icon: Icons.lock_outline,
                      title: 'Change Password',
                      onTap: (ctx) => _closeThen(ctx, (host) {
                        pushInShell(host, const Contractor());
                      }),
                    ),
                    Divider(
                      height: 1,
                      color: AppColors.borderGray.withValues(alpha: 0.5),
                    ),
                    _buildMenuItem(
                      icon: Icons.logout_rounded,
                      title: 'Logout',
                      isDestructive: true,
                      onTap: (ctx) => _confirmAndLogout(ctx),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmAndLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.cardWhite,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Text(
            'Logout',
            style: GoogleFonts.poppins(
              color: AppColors.headingBlack,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: GoogleFonts.poppins(
              color: AppColors.textDark,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                'Logout',
                style: GoogleFonts.poppins(
                  color: AppColors.primaryRed,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;

    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final host = appNavigatorKey.currentContext;
      if (host == null || !host.mounted) return;
      await logoutApi(host);
    });
  }

  Widget _buildHeader() {
    final user = UserSession.instance.user ?? cachedUser();
    final name = user?.name ?? Preference.pref.getString('name') ?? 'User';
    final department = user?.designation?.trim().isNotEmpty == true
        ? user!.designation!.trim()
        : (user?.roleLabel ?? 'User');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primaryRed.withValues(alpha: 0.1),
            child: const Icon(Icons.person, color: AppColors.primaryRed, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    color: AppColors.headingBlack,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  department,
                  style: GoogleFonts.poppins(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required void Function(BuildContext context) onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? AppColors.primaryRed : AppColors.headingBlack;

    return Builder(
      builder: (context) {
        return InkWell(
          onTap: () => onTap(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            child: Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
