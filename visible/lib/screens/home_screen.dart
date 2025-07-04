// import 'dart:convert';
// import 'dart:io';
// import 'dart:typed_data';
// import 'package:camera/camera.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart' show rootBundle;
// import 'package:flutter_tts/flutter_tts.dart';
// import 'package:http/http.dart' as http;
// import 'package:image_picker/image_picker.dart';
// import 'package:speech_to_text/speech_to_text.dart' as stt;

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   CameraController? _cameraController;
//   late stt.SpeechToText _speech;
//   final FlutterTts flutterTts = FlutterTts();
//   final picker = ImagePicker();
//   String question = '';
//   bool isListening = false;
//   String responseText = '';
//   String ipAddress = 'https://visible-rjaw.onrender.com'; // ✅ 여기에 실제 서버 IP
//   bool _isCapturing = false; // ✅ 중복 방지용

//   @override
//   void initState() {
//     super.initState();
//     _initCamera();
//     _speech = stt.SpeechToText();
//     flutterTts.setLanguage('ko-KR');
//     flutterTts.setSpeechRate(0.8);
//   }

//   Future<void> _initCamera() async {
//     try {
//       final cameras = await availableCameras();
//       if (cameras.isEmpty) {
//         print("⚠️ 사용 가능한 카메라가 없습니다.");
//         return;
//       }
//       _cameraController = CameraController(cameras[0], ResolutionPreset.medium);
//       await _cameraController!.initialize();
//       if (mounted) setState(() {});
//     } catch (e) {
//       print("카메라 초기화 오류: $e");
//     }
//   }

//   Future<void> takePictureAndSend({String? overrideQuestion}) async {
//     if (_isCapturing) return; // ✅ 중복 캡처 방지
//     _isCapturing = true;

//     try {
//       final image = await _cameraController!.takePicture();
//       final bytes = await File(image.path).readAsBytes();
//       final base64Image = base64Encode(bytes);
//       final q = overrideQuestion ?? question;

//       final response = await http.post(
//         Uri.parse('$ipAddress/analyze'),
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode({'image_base64': base64Image, 'question': q}),
//       );

//       if (response.statusCode == 200) {
//         final decodedBody = utf8.decode(response.bodyBytes);
//         final result = jsonDecode(decodedBody);
//         final summary = result['summary'] ?? '요약 응답이 없습니다.';
//         setState(() => responseText = summary);
//         await flutterTts.speak(summary);
//       } else {
//         setState(() => responseText = '서버 응답 오류: ${response.statusCode}');
//         await flutterTts.speak('서버 응답 오류');
//       }
//     } catch (e) {
//       print("에러: $e");
//       setState(() => responseText = '오류 발생: $e');
//       await flutterTts.speak("오류가 발생했어요.");
//     } finally {
//       _isCapturing = false;
//     }
//   }

//   Future<void> startListeningAndTakePicture() async {
//     bool available = await _speech.initialize();
//     if (available) {
//       setState(() => isListening = true);
//       await _speech.listen(
//         localeId: 'ko_KR',
//         onResult: (result) async {
//           setState(() {
//             question = result.recognizedWords;
//           });
//           await _speech.stop();
//           setState(() => isListening = false);
//           if (question.trim().isNotEmpty) {
//             await takePictureAndSend();
//           } else {
//             setState(() => responseText = '질문이 인식되지 않았어요.');
//             await flutterTts.speak("질문이 인식되지 않았어요.");
//           }
//         },
//       );
//     } else {
//       setState(() => responseText = '음성 인식을 사용할 수 없습니다.');
//       await flutterTts.speak("음성 인식을 사용할 수 없습니다.");
//     }
//   }

//   // Future<void> _sendTestQuestionWithImage() async {
//   //   try {
//   //     final bytes = await rootBundle.load('assets/test_image.png');
//   //     final base64Image = base64Encode(bytes.buffer.asUint8List());
//   //     const testQuestion = '이 상품의 정보를 알려줘';

//   //     final response = await http.post(
//   //       Uri.parse('$ipAddress/analyze'),
//   //       headers: {'Content-Type': 'application/json'},
//   //       body: jsonEncode({
//   //         'image_base64': base64Image,
//   //         'question': testQuestion,
//   //       }),
//   //     );

//   //     if (response.statusCode == 200) {
//   //       final decodedBody = utf8.decode(response.bodyBytes);
//   //       final result = jsonDecode(decodedBody);
//   //       final summary = result['summary'] ?? '요약 응답이 없습니다.';
//   //       setState(() => responseText = summary);
//   //       await flutterTts.speak(summary);
//   //     } else {
//   //       setState(() => responseText = '서버 응답 오류: ${response.statusCode}');
//   //       await flutterTts.speak('서버 응답 오류');
//   //     }
//   //   } catch (e) {
//   //     print("에러: $e");
//   //     setState(() => responseText = '오류 발생: $e');
//   //     await flutterTts.speak("앱에서 오류가 발생했어요.");
//   //   }
//   // }

//   @override
//   void dispose() {
//     _cameraController?.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         child:
//             _cameraController == null || !_cameraController!.value.isInitialized
//                 ? const Center(child: CircularProgressIndicator())
//                 : Column(
//                   children: [
//                     AspectRatio(
//                       aspectRatio: 3 / 4,
//                       child: CameraPreview(_cameraController!),
//                     ),
//                     // const SizedBox(height: 12),
//                     // ElevatedButton(
//                     //   onPressed: _sendTestQuestionWithImage,
//                     //   child: const Text('testButton'),
//                     // ),
//                     const SizedBox(height: 12),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                       children: [
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                           children: [
//                             // 버튼1
//                             Row(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 // 버튼1: 대화하기 → 채팅 아이콘
//                                 SizedBox(
//                                   width: 180,
//                                   height: 200,
//                                   child: ElevatedButton(
//                                     onPressed: startListeningAndTakePicture,
//                                     style: ElevatedButton.styleFrom(
//                                       backgroundColor: Colors.blueAccent,
//                                       elevation: 4,
//                                       shape: RoundedRectangleBorder(
//                                         borderRadius: BorderRadius.circular(16),
//                                       ),
//                                     ),
//                                     child: const Icon(
//                                       Icons.chat_bubble_outline,
//                                       size: 64,
//                                       color: Colors.white,
//                                     ),
//                                   ),
//                                 ),

//                                 const SizedBox(width: 10),

//                                 // 버튼2: 대상 설명 듣기 → 정보 아이콘
//                                 SizedBox(
//                                   width: 180,
//                                   height: 200,
//                                   child: ElevatedButton(
//                                     onPressed:
//                                         () => takePictureAndSend(
//                                           overrideQuestion: '상품의 정보들을 쭉 말해줘',
//                                         ),
//                                     style: ElevatedButton.styleFrom(
//                                       backgroundColor: const Color.fromARGB(
//                                         255,
//                                         64,
//                                         198,
//                                         251,
//                                       ),
//                                       elevation: 4,
//                                       shape: RoundedRectangleBorder(
//                                         borderRadius: BorderRadius.circular(16),
//                                       ),
//                                     ),
//                                     child: const Icon(
//                                       Icons.hearing_outlined,
//                                       size: 64,
//                                       color: Colors.white,
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 12),
//                     // Expanded(
//                     //   child: SingleChildScrollView(
//                     //     padding: const EdgeInsets.symmetric(horizontal: 16.0),
//                     //     child: Text(
//                     //       responseText,
//                     //       style: const TextStyle(fontSize: 16),
//                     //       textAlign: TextAlign.center,
//                     //     ),
//                     //   ),
//                     // ),
//                   ],
//                 ),
//       ),
//     );
//   }
// }
