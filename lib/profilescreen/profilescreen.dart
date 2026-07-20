import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/navigation/app_navigation.dart';
import 'package:grjoffice_apps/profilescreen/contractor.dart';
import 'package:grjoffice_apps/profilescreen/edit_profile_screen.dart';
import 'package:grjoffice_apps/profilescreen/notifications_screen.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/core/preference.dart';
import 'package:grjoffice_apps/drawer/app_end_drawer.dart';
import 'package:grjoffice_apps/drawer/drawer.dart';
import 'package:grjoffice_apps/models/user_model.dart';
import 'package:grjoffice_apps/services/api_auth.dart';
import 'package:grjoffice_apps/services/permission_service.dart';
import 'package:grjoffice_apps/services/user_session.dart';
import 'package:grjoffice_apps/widgets/app_top_bar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.isActive = false});

  final bool isActive;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  UserModel? _profile;
  bool _isLoading = false;
  bool _startedLoad = false;

  double _hPad(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w < 360) return 14;
    if (w < 600) return 18;
    return 22;
  }

  double _avatarSize(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w < 360 ? 88.0 : w < 600 ? 96.0 : 104.0;
  }

  bool _isWide(BuildContext context) => MediaQuery.sizeOf(context).width >= 520;

  @override
  void initState() {
    super.initState();
    UserSession.instance.addListener(_onSessionChanged);
    PermissionService.instance.addListener(_onSessionChanged);
    if (widget.isActive) _scheduleInitialLoad();
  }

  @override
  void dispose() {
    UserSession.instance.removeListener(_onSessionChanged);
    PermissionService.instance.removeListener(_onSessionChanged);
    super.dispose();
  }

  void _onSessionChanged() {
    if (!mounted) return;
    final sessionUser = UserSession.instance.user;
    if (sessionUser != null) {
      setState(() => _profile = sessionUser);
    } else {
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _startedLoad = false;
      _scheduleInitialLoad();
    }
  }

  void _scheduleInitialLoad() {
    if (_startedLoad) return;
    _startedLoad = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadProfile();
    });
  }

  Future<void> _loadProfile({bool showLoader = true}) async {
    if (showLoader) setState(() => _isLoading = true);
    final profile = await profileApi(context);
    if (!mounted) return;
    setState(() {
      _profile = profile ?? UserSession.instance.user ?? cachedUser();
      _isLoading = false;
    });
  }

  String get _name =>
      _profile?.name ??
      UserSession.instance.user?.name ??
      Preference.pref.getString('name') ??
      '-';
  String get _email =>
      _profile?.email ??
      UserSession.instance.user?.email ??
      Preference.pref.getString('email') ??
      '-';
  String get _phone =>
      _profile?.mobile ??
      UserSession.instance.user?.mobile ??
      Preference.pref.getString('phone') ??
      '-';
  String get _role {
    final fromPerms = PermissionService.instance.roles;
    if (fromPerms.isNotEmpty) {
      final role = fromPerms.first;
      return role.isEmpty
          ? 'User'
          : role[0].toUpperCase() + role.substring(1);
    }
    return _profile?.roleLabel ??
        UserSession.instance.user?.roleLabel ??
        'User';
  }
  String get _userId =>
      _profile?.id.toString() ??
      UserSession.instance.user?.id.toString() ??
      Preference.pref.getString('userId') ??
      '-';
  String? get _designation => _profile?.designation;
  String get _avatarUrl => mediaUrl(_profile?.avatar);

  @override
  Widget build(BuildContext context) {
    final hPad = _hPad(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.backgroundGray,
      drawer: AppDrawer(
        selectedIndex: -1,
        onItemTap: (index) => navigateFromDrawer(context, index),
      ),
      endDrawer: const AppEndDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar.tab(
              title: 'Profile',
              scaffoldKey: _scaffoldKey,
              showProfile: false,
              horizontalPadding: hPad,
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primaryRed),
                    )
                  : RefreshIndicator(
                      color: AppColors.primaryRed,
                      onRefresh: () => _loadProfile(showLoader: false),
                      child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 16),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildProfileCard(context),
                            const SizedBox(height: 12),
                            _buildSectionLabel('Account Information'),
                            const SizedBox(height: 8),
                            _buildAccountCard(),
                            const SizedBox(height: 14),
                            _buildSectionLabel('Security & Access', isCaps: true),
                            const SizedBox(height: 8),
                            _buildSecurityCard(),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    final avatar = _avatarSize(context);
    final wide = _isWide(context);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(wide ? 18 : 14, 14, wide ? 18 : 14, 14),
            child: wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildAvatar(avatar),
                      const SizedBox(width: 16),
                      Expanded(child: _buildProfileDetails(alignCenter: false)),
                    ],
                  )
                : Column(
                    children: [
                      _buildAvatar(avatar),
                      const SizedBox(height: 10),
                      _buildProfileDetails(alignCenter: true),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(double size) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primaryRed, width: 2),
            color: const Color(0xFFE5E7EB),
          ),
            child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: _avatarUrl.isNotEmpty
                ? Image.network(
                    _avatarUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.person,
                      size: size * 0.45,
                      color: AppColors.textSecondary,
                    ),
                  )
                : Icon(
                    Icons.person,
                    size: size * 0.45,
                    color: AppColors.textSecondary,
                  ),
          ),
        ),
        Positioned(
          right: -3,
          bottom: -3,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primaryRed,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.cardWhite, width: 2),
            ),
            child: const Icon(Icons.camera_alt_outlined, color: AppColors.white, size: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileDetails({required bool alignCenter}) {
    return Column(
      crossAxisAlignment: alignCenter ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          _name,
          textAlign: alignCenter ? TextAlign.center : TextAlign.start,
          style: GoogleFonts.poppins(
            color: AppColors.headingBlack,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.primaryRed,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            _role,
            style: GoogleFonts.poppins(
              color: AppColors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: alignCenter ? MainAxisSize.min : MainAxisSize.max,
          children: [
            Icon(Icons.badge_outlined, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                'User ID: $_userId',
                style: GoogleFonts.poppins(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 42,
          child: ElevatedButton.icon(
            onPressed: () => pushInShell(context, const EditProfileScreen()),
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: Text(
              'Edit Profile',
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRed,
              foregroundColor: AppColors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String title, {bool isCaps = false}) {
    return Text(
      isCaps ? title.toUpperCase() : title,
      style: GoogleFonts.poppins(
        color: isCaps ? AppColors.textSecondary : AppColors.headingBlack,
        fontSize: isCaps ? 11 : 16,
        fontWeight: FontWeight.w700,
        letterSpacing: isCaps ? 0.7 : 0,
      ),
    );
  }

  Widget _buildAccountCard() {
    return _surfaceCard(
      child: Column(
        children: [
          _buildInfoRow(Icons.person_outline, 'Full Name', _name),
          _divider(),
          _buildInfoRow(
            Icons.email_outlined,
            'Email Address',
            _email,
            trailing: _primaryTag(),
          ),
          _divider(),
          _buildInfoRow(Icons.phone_outlined, 'Phone Number', _phone),
          _divider(),
          _buildInfoRow(
            Icons.work_outline,
            'Department',
            _designation?.isNotEmpty == true ? _designation! : _role,
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityCard() {
    return _surfaceCard(
      child: Column(
        children: [
          _buildSecurityTile(Icons.shield_outlined, 'Security Settings'),
          _divider(),
          _buildSecurityTile(Icons.notifications_outlined, 'Notifications'),
        ],
      ),
    );
  }

  Widget _surfaceCard({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.35)),
      ),
      child: child,
    );
  }

  Widget _divider() {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 14,
      endIndent: 14,
      color: AppColors.borderGray.withValues(alpha: 0.45),
    );
  }

  Widget _primaryTag() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primaryRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'Primary',
        style: GoogleFonts.poppins(
          color: AppColors.primaryRed,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primaryRed.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 17, color: AppColors.primaryRed),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: GoogleFonts.poppins(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    color: AppColors.headingBlack,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityTile(IconData icon, String title) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (title == 'Security Settings') {
            pushInShell(context, const Contractor());
          } else if (title == 'Notifications') {
            pushInShell(context, const NotificationsScreen());
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primaryRed.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 17, color: AppColors.primaryRed),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: AppColors.headingBlack,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
