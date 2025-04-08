import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
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
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.camera);
      if (pickedFile == null) {
        print("이미지를 선택하지 않았습니다.");
        return;
      }

      if (question.isEmpty) {
        print("질문이 없습니다.");
        await flutterTts.speak("먼저 질문을 말해주세요.");
        return;
      }

      final bytes = await pickedFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final uri = Uri.parse('http://192.0.0.2:8000/analyze'); // 실제 IP 주소 사용
      print("서버에 요청 보냄...");

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'image_base64': base64Image, 'question': question}),
      );

      print('응답 코드: ${response.statusCode}');
      print('응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final result = jsonDecode(decodedBody);
        final summary = result['summary'] ?? '요약 응답이 없습니다.';
        setState(() => responseText = summary);
        await flutterTts.speak(summary);
      } else {
        await flutterTts.speak('서버에서 응답을 받지 못했어요.');
      }
    } catch (e, stackTrace) {
      print("예외 발생: $e");
      print(stackTrace);
      await flutterTts.speak("앱에서 오류가 발생했어요.");
    }
  }

  Future<void> _sendTestQuestionWithImage() async {
    try {
      final bytes = await rootBundle.load('assets/test_image.png');
      final base64Image = base64Encode(bytes.buffer.asUint8List());
      final testQuestion = '이 상품의 정보를 알려줘';

      final uri = Uri.parse('http://192.0.0.2:8000/analyze'); // 실제 IP 주소 사용

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'image_base64': base64Image,
          'question': testQuestion,
        }),
      );

      print('응답 코드: ${response.statusCode}');
      print('응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final result = jsonDecode(decodedBody);
        final summary = result['summary'] ?? '요약 응답이 없습니다.';
        setState(() => responseText = summary);
        await flutterTts.speak(summary);
      } else {
        await flutterTts.speak('서버에서 응답을 받지 못했어요.');
      }
    } catch (e) {
      print("예외 발생: $e");
      await flutterTts.speak("앱에서 오류가 발생했어요.");
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
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _sendTestQuestionWithImage,
              child: const Text('테스트 질문 보내기'),
            ),
          ],
        ),
      ),
    );
  }
}
