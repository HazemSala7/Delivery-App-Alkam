import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:optimus_opost/Pages/login_screen/login_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:optimus_opost/Pages/shipments/shipments.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isIOS) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyDXBSsEvwOzWFqjPnsPXBHXM-xLcxuYwl8',
        appId: '1:547928555422:ios:bdbbab935d336aab44208f',
        messagingSenderId: '547928555422',
        projectId: 'j-food-2a4d7',
        storageBucket: 'j-food-2a4d7.firebasestorage.app',
      ),
    );
  } else {
    await Firebase.initializeApp();
  }
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(const Optimus());
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Background message received: ${message.notification!.title}");
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
  late final FirebaseAnalytics analytics;
  late final FirebaseAnalyticsObserver observer;
  bool signIn = false;
  String status = "";

  @override
  void initState() {
    super.initState();
    analytics = FirebaseAnalytics.instance;
    observer = FirebaseAnalyticsObserver(analytics: analytics);
    loadData();
    requestFirebasePermissions();
    setupFirebaseMessaging();
    getToken();
  }

  Future<void> loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      signIn = prefs.getBool('login') ?? false;
      status = prefs.getString('active') ?? "";
    });
  }

  void setLocale(Locale value) {
    setState(() {
      locale = value;
    });
  }

  getToken() async {
    String? mytoken = await FirebaseMessaging.instance.getToken();
    print(mytoken);
  }

  Future<void> requestFirebasePermissions() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
      FirebaseMessaging.instance.subscribeToTopic('Jfood');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print('User granted provisional permission');
    } else {
      print('User declined or has not accepted permission');
    }
  }

  void setupFirebaseMessaging() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        print("Message received: ${message.notification!.title}");
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showDialog(
            context: navigatorKey.currentState!.overlay!.context,
            builder: (context) => AlertDialog(
              title: Text(message.notification!.title!),
              content: Text(message.notification!.body!),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('حسنا'),
                ),
              ],
            ),
          );
        });
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("Message opened app: ${message.notification?.title}");
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: navigatorKey.currentState!.overlay!.context,
          builder: (context) => AlertDialog(
            title: Text(message.notification!.title!),
            content: Text(message.notification!.body!),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('حسنا'),
              ),
            ],
          ),
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      navigatorObservers: <NavigatorObserver>[observer],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('ar', 'AE'),
      ],
      locale: locale,
      debugShowCheckedModeBanner: false,
      title: 'Optimus',
      theme: ThemeData(
        textTheme:
            GoogleFonts.notoKufiArabicTextTheme(Theme.of(context).textTheme),
        primarySwatch: Colors.blue,
      ),
      home: signIn ? Shipments(status: status) : const LoginScreen(),
    );
  }
}
