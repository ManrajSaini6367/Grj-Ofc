import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/loginpage/loginpage.dart';
import 'package:grjoffice_apps/services/attendance_service.dart';
import 'package:grjoffice_apps/widgets/app_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scaleAnimation = Tween<double>(begin: 0.82, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();

    unawaited(AttendanceService.instance.load());
    _navigationTimer = Timer(const Duration(milliseconds: 2800), _goToLogin);
  }

  void _goToLogin() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (_, __, ___) => const LoginPage(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 450),
      ),
    );
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  double _logoSize(BoxConstraints constraints, Size screen) {
    final shortest = screen.shortestSide;
    final isLandscape = screen.width > screen.height;
    final base = shortest * (isLandscape ? 0.22 : 0.28);
    return base.clamp(88.0, 168.0);
  }

  double _titleSize(Size screen) {
    final width = screen.width;
    if (width < 360) return 20;
    if (width < 600) return 24;
    return 28;
  }

  double _subtitleSize(Size screen) {
    final width = screen.width;
    if (width < 360) return 12;
    if (width < 600) return 13;
    return 14;
  }

  double _horizontalPad(Size screen) {
    final width = screen.width;
    if (width < 360) return 24;
    if (width < 600) return 32;
    return 48;
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final padding = _horizontalPad(screen);

    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final logoSize = _logoSize(constraints, screen);
          final isCompact = screen.height < 560;

          return Stack(
            fit: StackFit.expand,
            children: [
              _buildBackground(screen),
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: padding,
                      vertical: isCompact ? 16 : 32,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight -
                            MediaQuery.paddingOf(context).vertical -
                            (isCompact ? 32 : 64),
                        maxWidth: 480,
                      ),
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildLogoCard(logoSize),
                              SizedBox(height: isCompact ? 20 : 28),
                              Text(
                                'Gulshan Rai Jain',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Georgia',
                                  color: AppColors.primaryRed,
                                  fontSize: _titleSize(screen),
                                  fontWeight: FontWeight.w700,
                                  height: 1.2,
                                ),
                              ),
                              SizedBox(height: isCompact ? 6 : 10),
                              Text(
                                'Gulshan Rai Jain - Class Contractor',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  color: AppColors.textSecondary,
                                  fontSize: _subtitleSize(screen),
                                  fontWeight: FontWeight.w400,
                                  height: 1.4,
                                ),
                              ),
                              SizedBox(height: isCompact ? 28 : 40),
                              _buildLoader(screen),
                              SizedBox(height: isCompact ? 12 : 16),
                              Text(
                                'Loading your workspace...',
                                style: GoogleFonts.poppins(
                                  color: AppColors.textSecondary,
                                  fontSize: screen.width < 360 ? 11 : 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBackground(Size screen) {
    final accentSize = screen.width * 0.75;
    return Stack(
      children: [
        Positioned(
          top: -accentSize * 0.35,
          right: -accentSize * 0.25,
          child: Container(
            width: accentSize,
            height: accentSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryRed.withValues(alpha: 0.06),
            ),
          ),
        ),
        Positioned(
          bottom: -accentSize * 0.4,
          left: -accentSize * 0.3,
          child: Container(
            width: accentSize * 0.85,
            height: accentSize * 0.85,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryRed.withValues(alpha: 0.04),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogoCard(double logoSize) {
    final ringSize = logoSize + 28;
    return Container(
      width: ringSize,
      height: ringSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.cardWhite,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryRed.withValues(alpha: 0.12),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: AppLogo(
          size: logoSize,
          showBorder: true,
        ),
      ),
    );
  }

  Widget _buildLoader(Size screen) {
    final size = screen.width < 360 ? 22.0 : 26.0;
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        color: AppColors.primaryRed,
        backgroundColor: AppColors.primaryRed.withValues(alpha: 0.12),
      ),
    );
  }
}
