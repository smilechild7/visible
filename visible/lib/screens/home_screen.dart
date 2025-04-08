import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final picker = ImagePicker();
  final FlutterTts flutterTts = FlutterTts();
  late stt.SpeechToText _speech;
  String question = '';
  bool isListening = false;
  String responseText = '';

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  Future<void> _startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() => isListening = true);
      _speech.listen(
        onResult: (result) {
          setState(() {
            question = result.recognizedWords;
          });
        },
      );
    }
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    setState(() => isListening = false);
  }

  Future<void> _pickImageAndSend() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null && question.isNotEmpty) {
      final bytes = await pickedFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final uri = Uri.parse('http://localhost:8000/analyze'); // ← 백엔드 주소
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'image_base64': base64Image, 'question': question}),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        setState(() => responseText = result['summary']);
        await flutterTts.speak(responseText);
      } else {
        await flutterTts.speak('서버에서 응답을 받지 못했어요.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Visible')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: isListening ? _stopListening : _startListening,
              child: Text(isListening ? '듣기 중지' : '음성 질문 시작'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickImageAndSend,
              child: const Text('사진 찍고 GPT에 전송'),
            ),
            const SizedBox(height: 20),
            Text(responseText, style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
