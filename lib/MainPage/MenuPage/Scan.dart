import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Firebase 초기화
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Phone Model Recognition with Gemini',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ScanPage(), // ScanPage로 설정
    );
  }
}

class ScanPage extends StatefulWidget {
  const ScanPage({Key? key}) : super(key: key);

  @override
  _ScanPageState createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  File? _selectedImage; // 선택한 이미지 파일
  String _recognizedModel = 'No model detected'; // 예측된 핸드폰 기종
  GenerativeModel? _model; // Firebase Vertex AI 모델

  @override
  void initState() {
    super.initState();
    _initializeModel(); // Firebase Vertex AI 모델 초기화
  }

  // Firebase Vertex AI 모델 초기화 함수
  Future<void> _initializeModel() async {
    setState(() {
      _model = FirebaseVertexAI.instance.generativeModel(model: 'gemini-flash-experimental'); // 모델 ID 설정
    });
  }

  // 이미지 선택 및 핸드폰 기종 예측
  Future<void> _pickImageAndPredict() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.gallery); // 갤러리에서 이미지 선택

    if (pickedImage == null) return;

    final imageFile = File(pickedImage.path);
    setState(() {
      _selectedImage = imageFile;
    });

    await _predictPhoneModel(imageFile);
  }

  // 핸드폰 기종 예측 함수
  Future<void> _predictPhoneModel(File image) async {
    if (_model == null) {
      setState(() {
        _recognizedModel = 'Model is not initialized yet.';
      });
      return;
    }

    try {
      // 이미지를 base64로 인코딩하여 전송
      final bytes = image.readAsBytesSync();
      final encodedImage = base64Encode(bytes);
      final prompt = [Content.text('Predict the phone model based on this image: $encodedImage')];

      // Firebase Vertex AI를 사용하여 이미지 예측 (텍스트 기반 설명 요청)
      final response = await _model!.generateContent(prompt);

      setState(() {
        _recognizedModel = 'Predicted Model: ${response.text ?? 'No response'}';
      });
    } catch (e) {
      setState(() {
        _recognizedModel = "Error during prediction: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phone Model Recognition with Gemini'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _selectedImage != null
                ? Image.file(
              _selectedImage!,
              height: 200,
              width: 200,
              fit: BoxFit.cover,
            )
                : Container(
              height: 200,
              width: 200,
              color: Colors.grey[300],
              child: Icon(
                Icons.image,
                size: 100,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _recognizedModel,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickImageAndPredict,
              child: const Text('Select Image and Predict Phone Model'),
            ),
          ],
        ),
      ),
    );
  }
}
