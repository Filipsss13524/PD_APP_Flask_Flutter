import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localization.dart';

class HomeScreen extends StatelessWidget {
  final Function(Locale) onLanguageChanged; // Funkcja zmiany języka

  const HomeScreen({super.key, required this.onLanguageChanged});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      body: Center(
        child: SelectionArea(
          child: Column(
            children: [
              const SizedBox(height: 60),
              Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  loc!.title,
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ), 
              ),), 
              Image.asset(
                'assets/logo_agh.png',
                width: 300,
                height: 300
              ),
              Image.asset(
                'assets/softserve_logo.png',
                width: 300,
                height: 100
              ),
              const Spacer(),
              ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, "/person_screen");
                      },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 100,
                        vertical: 20
                      ),
                    ),
                    child: Text(
                      loc.startHomeScreen, 
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20
                        ))
                  ),
              TextButton.icon(
                onPressed: () {
                  final newLocale = loc.localeName == 'en'
                      ? const Locale('pl')
                      : const Locale('en');
                  onLanguageChanged(newLocale); // Zmieniamy język aplikacji
                },
                icon: const Icon(Icons.language),
                label: Text(loc.languageLabel)
              ),
          ],),)
      )
    );
  }
}