import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/contractor/contractor.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/loginpage/loginpage.dart';
import 'package:grjoffice_apps/profilescreen/profilescreen.dart';

class AppEndDrawer extends StatelessWidget {
  const AppEndDrawer({super.key});

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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                Divider(height: 1, color: AppColors.borderGray.withValues(alpha: 0.5)),
                _buildMenuItem(
                  icon: Icons.person_outline,
                  title: 'Profile',
                  onTap: (context) {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    );
                  },
                ),
                _buildMenuItem(
                  icon: Icons.lock_outline,
                  title: 'Change Password',
                  onTap: (context) {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const Contractor()),
                    );
                  },
                ),
                Divider(height: 1, color: AppColors.borderGray.withValues(alpha: 0.5)),
                _buildMenuItem(
                  icon: Icons.logout_rounded,
                  title: 'Logout',
                  isDestructive: true,
                  onTap: (context) {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                      (route) => false,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
                  'Gulshan Rai Jain',
                  style: GoogleFonts.poppins(
                    color: AppColors.headingBlack,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Director',
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
