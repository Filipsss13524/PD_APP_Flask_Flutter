import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localization.dart';
import 'package:intl/intl.dart';

// Map<String, String> diagnosis = {'PD': 'Parkinson Disease', 'HC': 'Health Client'};
Map<String, String> diagnosis = {'PD': 'Choroba Parkinsona', 'HC': 'Osoba zdrowa'};
Map<String, String> gender_dict = {'M': 'Mężczyzna', 'F': 'Kobieta'};

class Data {
    final String result_text;
    final image;

    Data(this.result_text, this.image);
  }

class ResultScreen extends StatefulWidget {
  final Locale currentLocale;
  final String currentAdress;
  const ResultScreen({super.key, required this.currentLocale, required this.currentAdress});

  @override
  _ResultScreenState createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late Future<Data> _fetchDataFuture;
  bool showButton = false;
  String text_oczekiwania = "";
  String errortext = "";

  @override
  Future<Data> _sendRequest(String name, String surname, String date, String gender, String filePath) async {
    final imageUrl = 'http://${widget.currentAdress}:5000/api_image';
    final recordUrl = 'http://${widget.currentAdress}:5000/upload';
    // const imageUrl = 'http://192.168.0.183:5000/api_image';
    // const recordUrl = 'http://192.168.0.183:5000/upload';

    final file = File(filePath);
    var stream = http.ByteStream(file.openRead());
    var length = await file.length();
    var uriFile = Uri.parse(recordUrl);
    var request = http.MultipartRequest('POST', uriFile);
    var multipartFile = http.MultipartFile(
      'file',
      stream,
      length,
      filename: basename(file.path),
      contentType: MediaType('audio', 'wav'),
    );

    DateTime now = DateTime.now();
    request.files.add(multipartFile);
    request.fields['text'] = '$name-$surname-$date-$gender-${DateFormat('yyyy-MM-dd-HH-mm-ss').format(now)}';

    var responseRecord = await request.send();

    final imageResponse = await http.post(
      Uri.parse(imageUrl),
      headers: {'Content-Type': 'application/json', 'Cache-Control': 'no-cache'},
      body: jsonEncode({'query': '$name-$surname-$date-$gender-${DateFormat('yyyy-MM-dd-HH-mm-ss').format(now)}'}),
    );

    if (imageResponse.statusCode == 200) {
      final responseBody = await responseRecord.stream.bytesToString();
      final decodedResponse = jsonDecode(responseBody);
      String result = decodedResponse['predicted_class'];

      final directory = await getApplicationDocumentsDirectory();
      final imagePath = join(directory.path, 'downloaded_image_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await File(imagePath).writeAsBytes(imageResponse.bodyBytes); 

      // Usuń stary plik, jeśli istnieje
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      print('Old image deleted');
      }

      await file.writeAsBytes(imageResponse.bodyBytes);
      print('New image saved at: $imagePath');

      return Data(result, imagePath);
    } else {
      throw Exception('Failed to fetch image or text');
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final Map<String, dynamic> args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final name = args['name'];
    final surname = args['surname'];
    final date = args['date'];
    final gender = args['gender'];
    final filePath = args['record_path'];

    _fetchDataFuture = _sendRequest(name, surname, date, gender, filePath);

    if (widget.currentLocale.languageCode == 'en'){
    text_oczekiwania = "Analyzing the recording, please wait!";
    diagnosis = {'PD': 'Parkinson Disease', 'HC': 'Health Client'};
    gender_dict = {'M': 'Male', 'F': 'Female'};
    } else {
    text_oczekiwania = "Trwa analiza nagrania, czekaj!";
    diagnosis = {'PD': 'Choroba Parkinsona', 'HC': 'Osoba zdrowa'};
    gender_dict = {'M': 'Mężczyzna', 'F': 'Kobieta'};
    }

    return FutureBuilder<Data>(
      future: _fetchDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                Text(text_oczekiwania),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: FutureBuilder(
                  future: Future.delayed(const Duration(seconds: 15)), 
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      return Text(loc!.helpText);
                    } else {
                    return const SizedBox.shrink();
                  }
                  }))
                ]
            )
            )
          );
        } else if (snapshot.hasError) {
          RegExp dataerror = RegExp(r'PathNotFoundException');
          RegExp timeerror = RegExp(r'Connection timed out');
          RegExpMatch? matchdataerror = dataerror.firstMatch('${snapshot.error}');
          RegExpMatch? matchtimeerror = timeerror.firstMatch('${snapshot.error}');
          if (matchdataerror != null) {
            errortext = loc!.dataerrortext;
          } else if (matchtimeerror != null) {
            errortext = loc!.timeerrortext;
          } else {
            errortext = '${snapshot.error}';
          }
          return Scaffold(
              body: Center(
                child: Padding (
                  padding: const EdgeInsets.all(30.0),
                  child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                  Text(loc!.error + errortext),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () { 
                      Navigator.pushNamed(context, "/audio_screen", arguments: {
                            "name": name,
                            "surname": surname,
                            "date": date,
                            "gender": gender
                          });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 100,
                        vertical: 16
                      ),
                    ),
                    child: Text(
                      loc.back, 
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16
                    ))
                  ),
                ]
              )
            )
          ));
        } else if (!snapshot.hasData) {
          return const Center(child: Text('Error: data'));
        } else {
          final data = snapshot.data!;
          String result = data.result_text;
          final image = data.image;
          return Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  Text(
                    loc!.testResult,
                    style: const TextStyle(
                      fontSize: 26
                    )
                  ),
                  const SizedBox(height: 40),
                  Text(
                    "$name $surname",
                    style: const TextStyle(
                        fontSize: 26
                      )
                  ),
                  Text(
                    "${loc.birth}$date",
                    style: const TextStyle(
                        fontSize: 26
                      )
                  ),
                  Text(
                    gender_dict[gender] ?? '',
                    style: const TextStyle(
                        fontSize: 26
                      )
                  ),
                  Text(
                    diagnosis[result] ?? '',
                    style: const TextStyle(
                        fontSize: 26
                      )
                  ),
                  const SizedBox(height: 60),
                  Text(
                    loc.spectrogramMel,
                    style: const TextStyle(
                        fontSize: 26
                      )
                  ),
                  Image.file(File(image)),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.pushNamed(context, "/");
                      },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 100,
                        vertical: 16
                      ),
                    ),
                    child: Text(
                      loc.backToMenu, 
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16
                        ))
                  ),
                ],)
              )
            );
        }
      },
    );
  }
}

