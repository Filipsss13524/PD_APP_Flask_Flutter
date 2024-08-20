import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localization.dart';

class ServerIpScreen extends StatefulWidget {
  final Function(String) onAdressChanged;
  final String currentAdress;
  final Function(Locale) onLanguageChanged;
  final Locale currentLocale;

  const ServerIpScreen({super.key, required this.onAdressChanged, required this.currentAdress, required this.onLanguageChanged, required this.currentLocale});

  @override
  State<ServerIpScreen> createState() => _ServerIpScreenState();
}

class _ServerIpScreenState extends State<ServerIpScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _ip_server;

  @override
  void initState() {
    super.initState();
    // Inicjalizowanie kontrolera w initState
    _ip_server = TextEditingController(text: widget.currentAdress);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc!.serverIp),
        backgroundColor: Colors.blue,
        elevation: 0,
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.language),
            tooltip: 'Change language',
            onPressed: () {
                  final newLocale = widget.currentLocale.languageCode == 'en'
                      ? const Locale('pl')
                      : const Locale('en');
                  widget.onLanguageChanged(newLocale); // Zmieniamy język aplikacji
                },
            ),
        ]
        ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _ip_server,
                decoration: InputDecoration(
                  labelText: loc.serverIp,
                  hintText: "XXX.XXX.XXX.XXX",
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return loc.serverhelp;
                  }
                  final ipRegExp = RegExp(
                      r'^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$');
                  if (!ipRegExp.hasMatch(value)) {
                    return loc.servervalid;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // Process the IP address, e.g., connect to the server
                    final String newCurrentAdress = _ip_server.text;
                    widget.onAdressChanged(newCurrentAdress);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(loc.savecomfirmed)),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 50,
                        vertical: 16
                      ),
                ),
                child: Text(
                      loc.save, 
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16
                        ))
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// void main() {
//   runApp(MaterialApp(
//     home: ServerIPScreen(),
//   ));
// }

