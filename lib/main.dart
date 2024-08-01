import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:optimus_opost/Pages/login_screen/login_screen.dart';
import 'package:optimus_opost/Pages/splash_screen/splash_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'Pages/shipments/shipments.dart';

void main() {
  runApp(const Optimus());
}

Locale locale = Locale("ar", "AE");

class Optimus extends StatefulWidget {
  const Optimus({super.key});

  @override
  State<Optimus> createState() => _OptimusState();
  static _OptimusState? of(BuildContext context) =>
      context.findAncestorStateOfType<_OptimusState>();
}

class _OptimusState extends State<Optimus> {
  // This widget is the root of your application.
  @override
  void setLocale(Locale value) {
    setState(() {
      locale = value;
    });
  }

  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        Locale('en', ''),
        Locale("ar", "AE"),
      ],
      locale: locale,
      debugShowCheckedModeBanner: false,
      title: 'Optimus',
      theme: ThemeData(
        textTheme:
            GoogleFonts.notoKufiArabicTextTheme(Theme.of(context).textTheme),
        primarySwatch: Colors.blue,
      ),
      home: LoginScreen(),
    );
  }
}
