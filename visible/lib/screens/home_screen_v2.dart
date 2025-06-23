import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CameraController? _controller;

  bool isGuiding = false;
  Timer? guidingTimer;

  late stt.SpeechToText _speech;
  final FlutterTts flutterTts = FlutterTts();
  final picker = ImagePicker();
  String question = '';
  bool isListening = false;
  String responseText = '';
  String ipAddress =
      'https://visible-rjaw.onrender.com/analyze'; // ✅ 여기에 실제 서버 IP
  //final bool _isCapturing = false; // ✅ 중복 방지용

  @override
  void initState() {
    super.initState();
    _initCamera();
    _speech = stt.SpeechToText();
    flutterTts.setLanguage('ko-KR');
    flutterTts.setSpeechRate(0.8);
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        print("⚠️ 사용 가능한 카메라가 없습니다.");
        return;
      }
      final camera = cameras.first;
      _controller = CameraController(camera, ResolutionPreset.medium);
      await _controller!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      print("카메라 초기화 오류: $e");
    }
  }

  Future<void> toggleGuiding() async {
    if (isGuiding) {
      // Stop guiding
      guidingTimer?.cancel();
      setState(() {
        isGuiding = false;
      });
      await flutterTts.speak('안내를 중지합니다');
    } else {
      // Start guiding
      // 주기 : 4초
      guidingTimer = Timer.periodic(
        Duration(seconds: 4),
        (_) => captureAndGuide(),
      );
      setState(() {
        isGuiding = true;
      });
      await flutterTts.speak('안내를 시작합니다. 잠시만 기다려주십시오.');
    }
  }

  Future<void> captureAndGuide() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      final XFile file = await _controller!.takePicture();
      final Uint8List bytes = await file.readAsBytes();
      final String base64Image = base64Encode(bytes);

      final response = await http.post(
        Uri.parse(ipAddress),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "image_base64": base64Image,
          "question": """너가 보는 상황은 시각장애인의 전방 화면이야. 
              주변 상황을 짧게 설명해줘. 
              매우 간결하고 짧게 응답해야해.
              별다른 특징이 없으면 특별한 장애물이 없다고 해.
              ex)전방에 계단이 2칸 있습니다/전방에 복도가 있으며 장애물은 없습니다.""",
        }),
      );
      final decodedBody = utf8.decode(response.bodyBytes);

      final decoded = jsonDecode(decodedBody);
      final instruction = decoded['summary'];
      print(instruction);
      await flutterTts.speak(instruction);
    } catch (e) {
      print("Error during guiding: $e");
    }
  }

  @override
  void dispose() {
    guidingTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  // Future<void> takePictureAndSend({String? overrideQuestion}) async {
  //   if (_isCapturing) return; // ✅ 중복 캡처 방지
  //   _isCapturing = true;

  //   try {
  //     final image = await _controller!.takePicture();
  //     final bytes = await File(image.path).readAsBytes();
  //     final base64Image = base64Encode(bytes);
  //     final q = overrideQuestion ?? question;

  //     final response = await http.post(
  //       Uri.parse('$ipAddress/analyze'),
  //       headers: {'Content-Type': 'application/json'},
  //       body: jsonEncode({'image_base64': base64Image, 'question': q}),
  //     );

  //     if (response.statusCode == 200) {
  //       final decodedBody = utf8.decode(response.bodyBytes);
  //       final result = jsonDecode(decodedBody);
  //       final summary = result['summary'] ?? '요약 응답이 없습니다.';
  //       setState(() => responseText = summary);
  //       await flutterTts.speak(summary);
  //     } else {
  //       setState(() => responseText = '서버 응답 오류: ${response.statusCode}');
  //       await flutterTts.speak('서버 응답 오류');
  //     }
  //   } catch (e) {
  //     print("에러: $e");
  //     setState(() => responseText = '오류 발생: $e');
  //     await flutterTts.speak("오류가 발생했어요.");
  //   } finally {
  //     _isCapturing = false;
  //   }
  // }

  // Future<void> startListeningAndTakePicture() async {
  //   bool available = await _speech.initialize();
  //   if (available) {
  //     setState(() => isListening = true);
  //     await _speech.listen(
  //       localeId: 'ko_KR',
  //       onResult: (result) async {
  //         setState(() {
  //           question = result.recognizedWords;
  //         });
  //         await _speech.stop();
  //         setState(() => isListening = false);
  //         if (question.trim().isNotEmpty) {
  //           await takePictureAndSend();
  //         } else {
  //           setState(() => responseText = '질문이 인식되지 않았어요.');
  //           await flutterTts.speak("질문이 인식되지 않았어요.");
  //         }
  //       },
  //     );
  //   } else {
  //     setState(() => responseText = '음성 인식을 사용할 수 없습니다.');
  //     await flutterTts.speak("음성 인식을 사용할 수 없습니다.");
  //   }
  // }

  // Future<void> _sendTestQuestionWithImage() async {
  //   try {
  //     final bytes = await rootBundle.load('assets/test_image.png');
  //     final base64Image = base64Encode(bytes.buffer.asUint8List());
  //     const testQuestion = '이 상품의 정보를 알려줘';

  //     final response = await http.post(
  //       Uri.parse('$ipAddress/analyze'),
  //       headers: {'Content-Type': 'application/json'},
  //       body: jsonEncode({
  //         'image_base64': base64Image,
  //         'question': testQuestion,
  //       }),
  //     );

  //     if (response.statusCode == 200) {
  //       final decodedBody = utf8.decode(response.bodyBytes);
  //       final result = jsonDecode(decodedBody);
  //       final summary = result['summary'] ?? '요약 응답이 없습니다.';
  //       setState(() => responseText = summary);
  //       await flutterTts.speak(summary);
  //     } else {
  //       setState(() => responseText = '서버 응답 오류: ${response.statusCode}');
  //       await flutterTts.speak('서버 응답 오류');
  //     }
  //   } catch (e) {
  //     print("에러: $e");
  //     setState(() => responseText = '오류 발생: $e');
  //     await flutterTts.speak("앱에서 오류가 발생했어요.");
  //   }
  // }
  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: Column(
        children: [
          // 📸 카메라 화면은 위쪽 전체 영역
          Expanded(child: CameraPreview(_controller!)),

          // 🟢 큰 버튼은 아래 고정
          SizedBox(
            width: double.infinity,
            height: 300,
            child: ElevatedButton(
              onPressed: toggleGuiding,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero, // ✅ 모서리를 0으로 = 직사각형
                ),
                backgroundColor:
                    isGuiding
                        ? const Color.fromARGB(255, 255, 255, 255)
                        : const Color.fromARGB(255, 255, 255, 255),
              ),
              child: SizedBox(
                width: 150, // ✅ 원하는 이미지 너비
                height: 150, // ✅ 원하는 이미지 높이
                child: Image.asset(
                  isGuiding ? 'assets/A-EYE_2.png' : 'assets/A-EYE_1.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
