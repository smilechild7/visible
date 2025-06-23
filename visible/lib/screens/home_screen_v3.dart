import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CameraController? _controller;

  bool isGuiding = false;
  Timer? guidingTimer;

  final FlutterTts flutterTts = FlutterTts();
  CameraImage? _latestFrame;
  bool _isSending = false;
  String ipAddress = 'https://visible-rjaw.onrender.com/analyze';

  @override
  void initState() {
    super.initState();
    _initCamera();
    flutterTts.setLanguage('ko-KR');
    flutterTts.setSpeechRate(0.8);
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final camera = cameras.first;
    _controller = CameraController(
      camera,
      ResolutionPreset.medium,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );
    await _controller!.initialize();
    await _controller!.startImageStream((CameraImage image) {
      _latestFrame = image; // 프레임 저장
    });
    setState(() {});
  }

  void toggleGuiding() {
    if (isGuiding) {
      guidingTimer?.cancel();
      setState(() {
        isGuiding = false;
      });
    } else {
      guidingTimer = Timer.periodic(
        Duration(seconds: 2),
        (_) => captureAndGuide(),
      );
      setState(() {
        isGuiding = true;
      });
    }
  }

  Future<void> captureAndGuide() async {
    if (_latestFrame == null) return;
    if (_isSending) return; // 중복 방지
    _isSending = true;

    try {
      Uint8List jpegBytes = await convertYUV420toJpeg(_latestFrame!);
      String base64Image = base64Encode(jpegBytes);

      final response = await http.post(
        Uri.parse(ipAddress),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "image_base64": base64Image,
          "question": "주변 상황을 설명하고 이동 방향을 알려주세요.",
        }),
      );

      final decoded = jsonDecode(response.body);
      final instruction = decoded['summary'];

      await flutterTts.speak(instruction);
    } catch (e) {
      print("Error during guiding: $e");
    } finally {
      _isSending = false;
    }
  }

  @override
  void dispose() {
    guidingTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: Stack(
        children: [
          CameraPreview(_controller!),
          Positioned(
            bottom: 50,
            left: 50,
            right: 50,
            child: ElevatedButton(
              onPressed: toggleGuiding,
              child: Text(isGuiding ? '안내 중지' : '안내 시작'),
            ),
          ),
        ],
      ),
    );
  }

  /// 🔑 YUV420 to JPEG 변환 예시
  /// 패키지: image (pubspec에 추가: image: ^4.0.0)
  Future<Uint8List> convertYUV420toJpeg(CameraImage image) async {
    final int width = image.width;
    final int height = image.height;

    final img.Image imgBuffer = img.Image(width: width, height: height);

    // YUV420 -> RGB 변환 (간단 버전)
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final uvIndex = (y >> 1) * (image.planes[1].bytesPerRow) + (x >> 1) * 2;
        final yValue =
            image.planes[0].bytes[y * image.planes[0].bytesPerRow + x];
        final uValue = image.planes[1].bytes[uvIndex];
        final vValue = image.planes[2].bytes[uvIndex];

        int r = (yValue + (1.370705 * (vValue - 128))).round();
        int g =
            (yValue - (0.698001 * (vValue - 128)) - (0.337633 * (uValue - 128)))
                .round();
        int b = (yValue + (1.732446 * (uValue - 128))).round();

        r = r.clamp(0, 255);
        g = g.clamp(0, 255);
        b = b.clamp(0, 255);

        imgBuffer.setPixel(x, y, img.ColorRgb8(r, g, b));
      }
    }

    final jpeg = img.encodeJpg(imgBuffer);
    return Uint8List.fromList(jpeg);
  }
}
