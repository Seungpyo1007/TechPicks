import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart'; // google_ml_kit 패키지
import 'package:image_picker/image_picker.dart'; // 이미지 선택 패키지
import 'dart:io';

class PhoneModelRecognitionPage extends StatefulWidget {
  @override
  _PhoneModelRecognitionPageState createState() =>
      _PhoneModelRecognitionPageState();
}

class _PhoneModelRecognitionPageState extends State<PhoneModelRecognitionPage> {
  File? _selectedImage;
  String _recognizedModel = 'No model detected';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Phone Model Recognition'),
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
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickImageAndRecognizeModel,
              child: Text('Select Image and Recognize Model'),
            ),
          ],
        ),
      ),
    );
  }

  // 이미지 선택 및 핸드폰 기종 예측
  Future<void> _pickImageAndRecognizeModel() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);

    if (pickedImage == null) return;

    final imageFile = File(pickedImage.path);
    setState(() {
      _selectedImage = imageFile;
    });

    await _recognizePhoneModel(imageFile);
  }

  // 핸드폰 기종 인식
  Future<void> _recognizePhoneModel(File imageFile) async {
    // google_ml_kit의 ImageLabeler 사용
    final inputImage = InputImage.fromFile(imageFile);
    final imageLabeler = GoogleMlKit.vision.imageLabeler();

    try {
      // 이미지 분석 시작
      final List<ImageLabel> labels = await imageLabeler.processImage(inputImage);

      // 예측된 라벨과 신뢰도 출력
      if (labels.isNotEmpty) {
        final ImageLabel bestLabel = labels.first;
        setState(() {
          _recognizedModel = 'Model: ${bestLabel.label} \nConfidence: ${bestLabel.confidence.toStringAsFixed(2)}';
        });
      } else {
        setState(() {
          _recognizedModel = 'No model detected';
        });
      }
    } catch (e) {
      setState(() {
        _recognizedModel = 'Error: $e';
      });
    } finally {
      imageLabeler.close();
    }
  }
}
