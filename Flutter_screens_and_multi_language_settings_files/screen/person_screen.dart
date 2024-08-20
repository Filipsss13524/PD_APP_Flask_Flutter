import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localization.dart';

class PersonData extends StatefulWidget {
  final Function(Locale) onLanguageChanged;
  final Locale currentLocale;
  final String? restorationId;

  const PersonData({super.key, this.restorationId, required this.onLanguageChanged,
    required this.currentLocale,});

  @override
  State<PersonData> createState() => _PersonDataState();
}

class _PersonDataState extends State<PersonData>
    with RestorationMixin {

  @override
  String? get restorationId => widget.restorationId;

  final RestorableDateTime _selectedDate =
      RestorableDateTime(DateTime(2024, 1, 1));
  late final RestorableRouteFuture<DateTime?> _restorableDatePickerRouteFuture =
      RestorableRouteFuture<DateTime?>(
    onComplete: _selectDate,
    onPresent: (NavigatorState navigator, Object? arguments) {
      return navigator.restorablePush(
        _datePickerRoute,
        arguments: _selectedDate.value.millisecondsSinceEpoch,
      );
    },
  );
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _surname = TextEditingController();

  @pragma('vm:entry-point')
  static Route<DateTime> _datePickerRoute(
    BuildContext context,
    Object? arguments,
  ) {
    return DialogRoute<DateTime>(
      context: context,
      builder: (BuildContext context) {
        return DatePickerDialog(
          restorationId: 'date_picker_dialog',
          initialEntryMode: DatePickerEntryMode.calendarOnly,
          initialDate: DateTime.fromMillisecondsSinceEpoch(arguments! as int),
          firstDate: DateTime(1900),
          lastDate: DateTime(2025),
        );
      },
    );
  }

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_selectedDate, 'selected_date');
    registerForRestoration(
        _restorableDatePickerRouteFuture, 'date_picker_route_future');
  }

  void _selectDate(DateTime? newSelectedDate) {
    if (newSelectedDate != null) {
      setState(() {
        _selectedDate.value = newSelectedDate;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Selected: ${_selectedDate.value.day}/${_selectedDate.value.month}/${_selectedDate.value.year}'),
        ));
      });
    }
  }

  bool _isMaleSelected = false;
  bool _isFemaleSelected = false;
  String _gender = "M";
  bool _genderSelected = true;

  void _handleMaleChanged(bool? value) {
    setState(() {
      _isMaleSelected = value!;
      if (_isMaleSelected) {
        _isFemaleSelected = false;
        _gender = "M";
      }
    });
  }

  void _handleFemaleChanged(bool? value) {
    setState(() {
      _isFemaleSelected = value!;
      if (_isFemaleSelected) {
        _isMaleSelected = false;
        _gender = "F";
      }
    });
  }

  void _validateGender() {
    setState(() {
      _genderSelected = _isMaleSelected || _isFemaleSelected;
    });
  }

  @override
  void dispose() {
    // Zwalnianie zasobów kontrolera tekstowego
    _name.dispose();
    _surname.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        // title: const Text('', style: TextStyle(color: Colors.white)),
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
            IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Change IP Adress',
            onPressed: () {
                Navigator.pushNamed(context, "/server_ip_screen"); 
                },
            )
        ]
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text(
                loc!.personData,
                style: const TextStyle(
                  fontSize: 26
                )
              ),
              const SizedBox(height: 60),
              TextFormField(
                controller: _name,
                decoration: InputDecoration(
                  labelText: loc.name,
                  hintText: loc.here,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return loc.requiredField;
                  }
                  return null;
                  },
              ),
              TextFormField(
                controller: _surname,
                decoration: InputDecoration(
                  labelText: loc.surname,
                  hintText: loc.here,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return loc.requiredField;
                  }
                  return null;
                  },
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text(
                    loc.dateOfBirth,
                    style: const TextStyle(
                      fontSize: 16
                    )
                  ),
                  const SizedBox(width: 20),
                  Text(
                    '${_selectedDate.value.day}/${_selectedDate.value.month}/${_selectedDate.value.year}',
                    style: const TextStyle(
                        fontSize: 16
                    )
                  ),
                  const SizedBox(width: 20),
                  OutlinedButton(
                    onPressed: () {
                      _restorableDatePickerRouteFuture.present();
                    },
                    child: Text(loc.selectDate),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Text(
                loc.selectGender,
                style: const TextStyle(
                  fontSize: 18
                )
              ),
              CheckboxListTile(
                title: Text(loc.man), 
                value: _isMaleSelected, 
                onChanged: (bool? value) {
                  _handleMaleChanged(value);
                  _validateGender();
                  },
                subtitle: !_genderSelected && !_isMaleSelected
                  ? Text(
                      loc.selectGender,
                      style: const TextStyle(color: Colors.red),
                    )
                  : null,
              ),
              CheckboxListTile(
                title: Text(loc.woman), 
                value: _isFemaleSelected, 
                onChanged: (bool? value) {
                  _handleFemaleChanged(value);
                  _validateGender();
                },
                subtitle: !_genderSelected && !_isFemaleSelected
                  ? Text(
                      loc.selectGender,
                      style: const TextStyle(color: Colors.red),
                    )
                  : null,
              ),
              const Spacer(),
              ElevatedButton(
                      onPressed: () {
                        _validateGender();
                        if ((_formKey.currentState?.validate() ?? false) & _genderSelected){
                          Navigator.pushNamed(context, "/audio_screen", arguments: {
                            "name": _name.text,
                            "surname": _surname.text,
                            "date": '${_selectedDate.value.day}/${_selectedDate.value.month}/${_selectedDate.value.year}',
                            "gender": _gender
                          });
                        }
                        },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 100,
                          vertical: 16
                        ),
                      ),
                      child: Text(
                        loc.makeRecord, 
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16
                          ))
                    ), 
              ]
            ),
          )
      )
    );
  }
}
