import 'package:audio_record_app/l10n/l10n.dart';
import 'package:audio_record_app/screen/home_screen.dart';
import 'package:audio_record_app/screen/person_screen.dart';
import 'package:audio_record_app/screen/record_screen.dart';
import 'package:audio_record_app/screen/result_screen.dart';
import 'package:audio_record_app/screen/server_ip_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localization.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale _locale = const Locale('pl');
  String _adress_ip = '192.168.0.183'; // zmień przed wygenerowanie aplikacji 192.168.0.183

  void _changeLanguage(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  void _changeAdressIP(String adress_ip) {
    setState(() {
      _adress_ip = adress_ip;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Record and Player',
      initialRoute: "/",
      routes:{
        "/": (context) => HomeScreen(onLanguageChanged: _changeLanguage),
        "/server_ip_screen": (context) => ServerIpScreen(onAdressChanged: _changeAdressIP, currentAdress: _adress_ip, onLanguageChanged: _changeLanguage, currentLocale: _locale),
        "/person_screen": (context) => PersonData(onLanguageChanged: _changeLanguage, currentLocale: _locale),
        "/audio_screen": (context) => AudioPage(onLanguageChanged: _changeLanguage, currentLocale: _locale),
        "/result_screen": (context) => ResultScreen(currentLocale: _locale, currentAdress: _adress_ip)
      },
      theme: ThemeData(
        primarySwatch:  Colors.blue,
      ),
      supportedLocales: L10n.all,
      // ignore: prefer_const_literals_to_create_immutables
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      locale: _locale,
    );
  }
}