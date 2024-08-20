import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:flutter_gen/gen_l10n/app_localization.dart';

// class AudioScreen extends StatelessWidget {
//   const AudioScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       theme: ThemeData(useMaterial3: true),
//       restorationScopeId: 'app',
//       home: const AudioPage(),
//     );
//   }
// }

class AudioPage extends StatefulWidget {
  final Function(Locale) onLanguageChanged;
  final Locale currentLocale;
  const AudioPage({super.key, required this.onLanguageChanged, required this.currentLocale,});

  @override
  // ignore: library_private_types_in_public_api
  _AudioPageState createState() => _AudioPageState();
}

class _AudioPageState extends State<AudioPage> {
  final AudioRecorder _record = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final TextEditingController _controller = TextEditingController();

  Timer? _timer;
  int _time = 0;
  bool _isRecording = false;
  String _filePath = '';
  double _currentPosition = 0;
  double _totalDuration = 0;


  // Obsługa zgody na nagrywanie dodatkowo zaminy w Android i IOS 
  @override
  void initState() {
    requestPermission();
    super.initState();
  }

  requestPermission() async {
    if (!kIsWeb){
      bool permissionStatus = await _audioQuery.permissionsStatus();
      if (!permissionStatus) {
        await _audioQuery.permissionsRequest();
      }
      setState(() {});
    }
  }

  void _startTimer(){
    const oneSec = Duration(seconds: 1);
    _timer = Timer.periodic(oneSec, (Timer timer){
      setState((){
        _time++;
      });
    });
  }

  Future<void> _start() async {
      final bool isPermissionGranted = await _record.hasPermission();
      if (!isPermissionGranted){
        return; 
      }

      Directory directory = await getApplicationDocumentsDirectory();

      String fileName = 'record_test.wav';
      _filePath = '${directory.path}/$fileName';

      const config = RecordConfig(
        encoder: AudioEncoder.aacLc,
        sampleRate: 44100,
        bitRate: 128000,
      );

      _startTimer();
      await _record.start(config, path: _filePath!);
      setState((){
        _isRecording = true;
    
      });
  }

  Future<void> _stop() async {
    final path = await _record.stop();
    _timer?.cancel();
    setState(() {
      _isRecording = false;
      _time = 0;
    });
  }

  Future<void> _play() async {
    if (_filePath != null) {
      await _audioPlayer.setFilePath(_filePath);
      _totalDuration = _audioPlayer.duration?.inSeconds.toDouble() ?? 0;
      _audioPlayer.play();

      _audioPlayer.positionStream.listen((position){
        setState(() {
          _currentPosition = position.inSeconds.toDouble();
        });
      });
    }
  }


  @override
    void dispose() {
      _timer?.cancel();
      _record.dispose();
      _controller.dispose();
      _audioPlayer.dispose();
      super.dispose();
    }


  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    final Map<String, dynamic> args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final _p_name = args["name"];
    final _p_surname = args["surname"];
    final _p_date = args["date"];
    final _p_gender = args["gender"];

    return Scaffold( 
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.info),
            tooltip: 'Info',
            onPressed: (){
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(loc!.info)));
            },
            ),
          IconButton(
            icon: const Icon(Icons.language),
            tooltip: 'Change language',
            onPressed: () {
                  final newLocale = widget.currentLocale.languageCode == 'en'
                      ? const Locale('pl')
                      : const Locale('en');
                  widget.onLanguageChanged(newLocale);
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
        child: Column(
          children: [
            Text(
                loc!.makeRecord,
                style: const TextStyle(
                  fontSize: 26
                )
              ),
            const SizedBox(height: 30),
            Text(
               loc.task,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold
                )
              ),
            Padding(
              padding: const EdgeInsets.only(left: 20.0),
              child: Text(
                loc.taskDescription,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 30),
            Text(formattedTime(timeInSecond: _time),
              style: const TextStyle(
                fontSize: 80,
                fontWeight: FontWeight.bold,
              ),
            ),
            Icon(
              _isRecording ? Icons.mic : Icons.mic_none,
              size: 100,
              color: _isRecording ? Colors.red : Colors.blue,
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _isRecording ? null : _start,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(
                      horizontal:  30,
                      vertical: 15
                    ),
                  ),
                  child: const Text('Start', style: TextStyle(color: Colors.white))
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: _isRecording ? _stop : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(
                      horizontal:  30,
                      vertical: 15
                    ),
                  ),
                  child: const Text('Stop', style: TextStyle(color: Colors.white))
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: !_isRecording ? _play : null, 
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(
                  horizontal:  30,
                  vertical: 15
                ),
              ),
              child: const Text('Play', style: TextStyle(color: Colors.white))
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(formattedTimeDouble(timeInSecond: _currentPosition)),
                Text(formattedTimeDouble(timeInSecond: _totalDuration)),
              ],
            ),
            Slider(
              value: _currentPosition,
              max: _totalDuration,
              activeColor: Colors.blue,
              onChanged: (value) {
                setState(() {
                  _currentPosition = value;
                });
                _audioPlayer.seek(Duration(seconds:value.toInt()));
              },
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, "/result_screen", arguments: {
                  "name": _p_name,
                  "surname": _p_surname,
                  "date": _p_date,
                  "gender": _p_gender,
                  "record_path": _filePath
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(
                  horizontal: 90,
                  vertical: 16
                ),
              ),
              child: Text(
                loc.makeTest, 
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16
                  ))
            ),
          ],
        ),
      ),
    );
  }
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('_filePath', _filePath));
  }
}

String formattedTime({required int timeInSecond}) {
  int sec = timeInSecond % 60;
  int min = (timeInSecond / 60).floor();
  String minute = min.toString().length <= 1 ? '0$min' : '$min';
  String seconds = sec.toString().length <= 1 ? '0$sec' : '$sec';
  return '$minute:$seconds';
}

String formattedTimeDouble({required double timeInSecond}) {
  int newTime = timeInSecond.toInt();
  int sec = newTime % 60;
  int min = (newTime / 60).floor();
  String minute = min.toString().length <= 1 ? '0$min' : '$min';
  String seconds = sec.toString().length <= 1 ? '0$sec' : '$sec';
  return '$minute:$seconds';
}