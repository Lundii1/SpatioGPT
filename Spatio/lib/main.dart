import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_sound/public/flutter_sound_recorder.dart';
import 'package:spatio/KeySingleton.dart';
import 'OpenAIService.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'SpatioGPT'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _textEditingController = TextEditingController();
  List<String> _messages = [];
  KeySingleton keySingleton = KeySingleton();
  String key = "";
  bool _isInputEnabled = true;
  //sound
  bool _isRecording = false;
  late StreamSubscription _recordingDataSubscription;
  FlutterSoundRecorder _audioRecorder = FlutterSoundRecorder();
  @override
  void initState() {
    super.initState();
    _loadKey();
  }

  Future<void> _loadKey() async {
    final loadedKey = await keySingleton.get();
    setState(() {
      this.key = loadedKey;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'SpatioGPT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.key),
              title: Text('API key'),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    final TextEditingController controller =
                        TextEditingController();
                    return AlertDialog(
                      title: Text("Enter your OpenAI API key"),
                      content: TextFormField(
                        controller: controller,
                        decoration: InputDecoration(
                          hintText: key.isNotEmpty ? key : "API key",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      actions: [
                        TextButton(
                          child: Text("Cancel"),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        TextButton(
                          child: Text("Save"),
                          onPressed: () {
                            setState(() {
                              key = controller.text;
                              keySingleton.save(controller.text);
                            });
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.delete),
              title: Text('Empty conversation'),
              onTap: () {
                setState(() {
                  _messages.clear();
                  Navigator.of(context).pop();
                });
              },
            ),
          ],
        ),
      ),
      body: Container(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: ListView.builder(
                itemCount: _messages.length,
                itemBuilder: (BuildContext context, int index) {
                  final parts = _messages[index].split(' ');
                  final title = parts.first == 'AI:' ? 'SpatioGPT' : 'User';
                  final avatar = parts.first == 'AI:'
                      ? Image.asset(
                          'assets/openai.png',
                          width: 30,
                          height: 30,
                        )
                      : Image.asset(
                          'assets/user.png',
                          width: 40,
                          height: 40,
                        );
                  return ListTile(
                    leading: CircleAvatar(
                      child: avatar,
                      radius: 18,
                      backgroundColor: Colors.blueAccent,
                    ),
                    title: Text(title),
                    subtitle: Text(_messages[index]
                        .substring(_messages[index].indexOf(' ') + 1)),
                  );
                },
              ),
            ),
            SizedBox(height: 16.0),
            Row(
              children: <Widget>[
                GestureDetector(
                  onLongPressStart: (_) {
                    _startRecording();
                  },
                  onLongPressEnd: (_) {
                    _stopRecording();
                  },
                  child: const IconButton(
                    icon: Icon(Icons.mic),
                    onPressed: null,
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: TextFormField(
                    controller: _textEditingController,
                    decoration: const InputDecoration(
                      hintText: 'Enter a message',
                      border: OutlineInputBorder(),
                    ),
                    enabled: _isInputEnabled,
                  ),
                ),
                const SizedBox(width: 16.0),
                FloatingActionButton(
                  onPressed: _isInputEnabled ? sendMessage : null,
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startRecording() async {
    if (_isRecording) {
      return;
    }

    await _audioRecorder.openRecorder();
    await _audioRecorder.startRecorder(toFile: 'temp.wav');

    _recordingDataSubscription = _audioRecorder.onProgress!.listen((e) {
      if (e != null && e.duration != null) {
        print('Recording: ${e.duration}');
      }
    });

    setState(() {
      _isRecording = true;
    });
  }

  Future<void> _stopRecording() async {
    await _audioRecorder.stopRecorder();
    await _audioRecorder.closeRecorder();
    _recordingDataSubscription.cancel();
    setState(() {
      _isRecording = false;
    });
  }

  void sendMessage() {
    if (key == "") {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("No API key"),
            content: Text("Please enter your OpenAI API key in the drawer"),
            actions: [
              TextButton(
                child: Text("OK"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
      return;
    }
    setState(() {
      _messages.add("User: " + _textEditingController.text);
    });
    _isInputEnabled = false;
    setState(() async {
      String APIkey = await key;
      OpenAIService()
          .message(APIkey, _textEditingController.text, _messages)
          .then((value) {
        setState(() {
          if (value.contains("Incorrect API key provided")) {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text("Incorrect API key"),
                  content: Text(
                      "You can find your API key at https://platform.openai.com/"),
                  actions: [
                    TextButton(
                      child: Text("OK"),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                );
              },
            );
          } else if (value.contains("401}")) {
            showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text("Unauthorized"),
                    content:
                        Text("Unauthorized, maybe your API key is incorrect?"),
                    actions: [
                      TextButton(
                        child: Text("OK"),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                });
          } else {
            _messages.add("AI: " + value);
          }
          _isInputEnabled = true;
        });
      });
      _textEditingController.clear();
    });
  }
}
