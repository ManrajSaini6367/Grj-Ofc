import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/core/app_date_time.dart';
import 'package:grjoffice_apps/core/app_navigator.dart';
import 'package:grjoffice_apps/core/preference.dart';
import 'package:grjoffice_apps/firebase_options.dart';
import 'package:grjoffice_apps/services/push_notification_service.dart';
import 'package:grjoffice_apps/spleshscreen/spleshscreen.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await PushNotificationService.firebaseMessagingBackgroundHandler(message);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Must be registered before runApp / other async work.
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await PushNotificationService.initialize();

  AppDateTime.init();
  await Preference.init();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  runApp(const MyApp());
}

/// Unfocuses the active input only when the pointer lands outside it.
void _dismissKeyboardIfTapOutsideFocusedInput(PointerDownEvent event) {
  final focus = FocusManager.instance.primaryFocus;
  if (focus == null || !focus.hasFocus) return;

  final focusContext = focus.context;
  if (focusContext == null) {
    focus.unfocus();
    return;
  }

  final renderObject = focusContext.findRenderObject();
  if (renderObject is! RenderBox || !renderObject.hasSize) {
    focus.unfocus();
    return;
  }

  final local = renderObject.globalToLocal(event.position);
  if (!renderObject.paintBounds.contains(local)) {
    focus.unfocus();
  }
}

/// Shrinks every text `fontSize` by 1px, then applies the platform scaler.
class _MinusOnePxTextScaler extends TextScaler {
  const _MinusOnePxTextScaler(this.parent);

  final TextScaler parent;

  @override
  double scale(double fontSize) {
    final reduced = fontSize > 1 ? fontSize - 1 : fontSize;
    return parent.scale(reduced);
  }

  @override
  // ignore: deprecated_member_use
  double get textScaleFactor => parent.textScaleFactor;

  @override
  TextScaler clamp({
    double minScaleFactor = 0,
    double maxScaleFactor = double.infinity,
  }) {
    return _MinusOnePxTextScaler(
      parent.clamp(
        minScaleFactor: minScaleFactor,
        maxScaleFactor: maxScaleFactor,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is _MinusOnePxTextScaler && other.parent == parent;
  }

  @override
  int get hashCode => Object.hash(runtimeType, parent);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: appNavigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'GRJ Office App',
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();
        final media = MediaQuery.of(context);
        final content = media.textScaler is _MinusOnePxTextScaler
            ? child
            : MediaQuery(
                data: media.copyWith(
                  textScaler: _MinusOnePxTextScaler(media.textScaler),
                ),
                child: child,
              );

        // Global: tap/press outside the focused input dismisses the keyboard.
        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: _dismissKeyboardIfTapOutsideFocusedInput,
          child: content,
        );
      },
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryRed,
        ),
        scaffoldBackgroundColor: AppColors.backgroundGray,
        textTheme: GoogleFonts.poppinsTextTheme(),
        appBarTheme: const AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
