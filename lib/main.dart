import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:optimus_opost/Pages/login_screen/login_screen.dart';
// DISABLED: Firebase imports causing crash
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:firebase_analytics/firebase_analytics.dart';
// import 'package:firebase_analytics/observer.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:optimus_opost/Pages/shipments/shipments.dart';
import 'package:optimus_opost/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:async';

void main() async {
  // Also suppress unhandled async errors from platform channels
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Suppress platform channel errors from appearing in console
      FlutterError.onError = (FlutterErrorDetails details) {
        final errorStr = details.exceptionAsString();
        if ((errorStr.contains('PlatformException') ||
                errorStr.contains('MissingPluginException')) &&
            (errorStr.contains('channel-error') ||
                errorStr.contains('Unable to establish connection') ||
                errorStr.contains('No implementation found'))) {
          // Silently suppress platform channel errors on startup
          return;
        }
        // Log other errors normally
        FlutterError.presentError(details);
      };

      runApp(const Optimus());
    },
    (error, stackTrace) {
      final errorStr = error.toString();
      if (!(errorStr.contains('PlatformException') ||
              errorStr.contains('MissingPluginException')) ||
          (!(errorStr.contains('channel-error') ||
              errorStr.contains('Unable to establish connection') ||
              errorStr.contains('No implementation found')))) {
        // Only log non-platform-channel errors
        FlutterError.presentError(
          FlutterErrorDetails(
            exception: error,
            stack: stackTrace,
            library: 'main.dart',
          ),
        );
      }
    },
  );
}

class Optimus extends StatefulWidget {
  const Optimus({super.key});

  @override
  State<Optimus> createState() => _OptimusState();
  static _OptimusState? of(BuildContext context) =>
      context.findAncestorStateOfType<_OptimusState>();
}

class _OptimusState extends State<Optimus> {
  Locale locale = const Locale("ar", "AE");
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  // DISABLED: Firebase references
  // late final FirebaseAnalytics? analytics;
  // late final FirebaseAnalyticsObserver? observer;
  bool signIn = false;
  String status = "";

  @override
  void initState() {
    super.initState();
    try {
      loadData();
      // DISABLED: All Firebase methods - plugins disabled
    } catch (e) {
      print("Error in initState: $e");
    }
  }

  Future<void> loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        signIn = prefs.getBool('login') ?? false;
        status = prefs.getString('active') ?? "";
      });
    } on Exception catch (e) {
      // Platform channel errors are normal on simulator startup - silently continue with defaults
      if (mounted) {
        setState(() {
          signIn = false;
          status = "";
        });
      }
    }
  }

  void setLocale(Locale value) {
    setState(() {
      locale = value;
    });
  }

  getToken() async {
    // DISABLED: Firebase - plugin disabled
    // String? mytoken = await FirebaseMessaging.instance.getToken();
    // print(mytoken);
  }

  Future<void> requestFirebasePermissions() async {
    // DISABLED: Firebase - plugin disabled
    // FirebaseMessaging messaging = FirebaseMessaging.instance;
    // NotificationSettings settings = await messaging.requestPermission(
    //   alert: true,
    //   announcement: false,
    //   badge: true,
    //   carPlay: false,
    //   criticalAlert: false,
    //   provisional: false,
    //   sound: true,
    // );

    // if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    //   print('User granted permission');
    //   FirebaseMessaging.instance.subscribeToTopic('Jfood');
    // } else if (settings.authorizationStatus ==
    //     AuthorizationStatus.provisional) {
    //   print('User granted provisional permission');
    // } else {
    //   print('User declined or has not accepted permission');
    // }
  }

  void setupFirebaseMessaging() {
    // DISABLED: Firebase - plugin disabled
    // FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    //   if (message.notification != null) {
    //     print("Message received: ${message.notification!.title}");
    //     WidgetsBinding.instance.addPostFrameCallback((_) {
    //       _showFancyOrderAlert(
    //         title: message.notification!.title ?? 'طلب جديد للتوصيل',
    //         body: message.notification!.body ?? '',
    //       );
    //     });
    //   }
    // });

    // FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    //   print("Message opened app: ${message.notification?.title}");
    //   WidgetsBinding.instance.addPostFrameCallback((_) {
    //     _showFancyOrderAlert(
    //       title: message.notification?.title ?? 'طلب جديد للتوصيل',
    //       body: message.notification?.body ?? '',
    //     );
    //   });
    // });
  }

  /// Beautiful in-app alert for incoming push notifications.
  /// Auto-dismisses after 8 seconds; the user can also tap "حسناً" or outside.
  void _showFancyOrderAlert({required String title, required String body}) {
    final ctx = navigatorKey.currentState?.overlay?.context;
    if (ctx == null) return;
    showGeneralDialog(
      context: ctx,
      barrierDismissible: true,
      barrierLabel: 'order-alert',
      barrierColor: Colors.black.withOpacity(0.55),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (context, anim, __, child) {
        final scale = Tween<double>(
          begin: 0.85,
          end: 1.0,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutBack));
        final fade = CurvedAnimation(parent: anim, curve: Curves.easeOut);
        return FadeTransition(
          opacity: fade,
          child: ScaleTransition(
            scale: scale,
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: _FancyOrderAlert(title: title, body: body),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get theme with fallback if GoogleFonts initialization fails
    TextTheme textTheme;
    try {
      textTheme = GoogleFonts.notoKufiArabicTextTheme();
    } catch (e) {
      // Fallback to default theme if GoogleFonts fails (silent fail)
      textTheme = const TextTheme();
    }

    return MaterialApp(
      navigatorKey: navigatorKey,
      navigatorObservers: <NavigatorObserver>[], // DISABLED: Firebase observer
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', ''), Locale('ar', 'AE')],
      locale: locale,
      debugShowCheckedModeBanner: false,
      title: 'Optimus',
      theme: ThemeData(
        textTheme: textTheme,
        primarySwatch: Colors.blue,
      ),
      home: signIn ? Shipments(status: status) : const LoginScreen(),
    );
  }
}

/// Polished new-order alert with gradient header, animated countdown ring,
/// auto-dismiss after [autoCloseSeconds] and a clean primary action.
class _FancyOrderAlert extends StatefulWidget {
  final String title;
  final String body;
  final int autoCloseSeconds;
  const _FancyOrderAlert({
    required this.title,
    required this.body,
    this.autoCloseSeconds = 8,
  });

  @override
  State<_FancyOrderAlert> createState() => _FancyOrderAlertState();
}

class _FancyOrderAlertState extends State<_FancyOrderAlert>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  Timer? _autoCloseTimer;
  bool _closed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.autoCloseSeconds),
    )..forward();
    _autoCloseTimer = Timer(Duration(seconds: widget.autoCloseSeconds), _close);
  }

  void _close() {
    if (_closed) return;
    _closed = true;
    _autoCloseTimer?.cancel();
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _autoCloseTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF1E88E5);
    const Color accent = Color(0xFF26C6DA);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 380),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.22),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Gradient header with countdown ring + icon
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 22,
                      horizontal: 18,
                    ),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [primary, accent],
                      ),
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 78,
                          width: 78,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              AnimatedBuilder(
                                animation: _ctrl,
                                builder: (_, __) => SizedBox(
                                  height: 78,
                                  width: 78,
                                  child: CircularProgressIndicator(
                                    value: 1.0 - _ctrl.value,
                                    strokeWidth: 5,
                                    backgroundColor: Colors.white.withOpacity(
                                      0.25,
                                    ),
                                    valueColor: const AlwaysStoppedAnimation(
                                      Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                height: 56,
                                width: 56,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.18),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.local_shipping_rounded,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          widget.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Body
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                    child: Text(
                      widget.body,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF2D3748),
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                  ),
                  // Live countdown text
                  AnimatedBuilder(
                    animation: _ctrl,
                    builder: (_, __) {
                      final remaining =
                          (widget.autoCloseSeconds * (1 - _ctrl.value))
                              .ceil()
                              .clamp(0, widget.autoCloseSeconds);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.timer_outlined,
                              size: 16,
                              color: Color(0xFF94A3B8),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'إغلاق تلقائي خلال $remaining ث',
                              style: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  // Linear progress bar at bottom
                  AnimatedBuilder(
                    animation: _ctrl,
                    builder: (_, __) => LinearProgressIndicator(
                      value: 1.0 - _ctrl.value,
                      minHeight: 3,
                      backgroundColor: const Color(0xFFE2E8F0),
                      valueColor: const AlwaysStoppedAnimation(primary),
                    ),
                  ),
                  // Actions
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _close,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'حسناً',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
