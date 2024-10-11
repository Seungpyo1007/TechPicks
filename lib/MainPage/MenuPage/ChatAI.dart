import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase once
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat with AI',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomeScreen(), // 홈 화면으로 이동
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Screen'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            _openChatScreen(context); // 채팅 화면 열기
          },
          child: const Text('Open Chat'),
        ),
      ),
    );
  }

  void _openChatScreen(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // 배경을 투명하게 설정
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7, // 초기 높이 비율 (0.0 ~ 1.0)
          minChildSize: 0.4, // 최소 높이 비율
          maxChildSize: 1.0, // 최대 높이 비율
          expand: false, // 화면을 확장하지 않음
          builder: (_, scrollController) {
            return ChatAIScreen(scrollController: scrollController); // scrollController 인수 전달
          },
        );
      },
    );
  }
}

class ChatAIScreen extends StatefulWidget {
  final ScrollController scrollController; // scrollController 매개변수 추가
  const ChatAIScreen({Key? key, required this.scrollController}) : super(key: key);

  @override
  _ChatAIScreenState createState() => _ChatAIScreenState();
}

class _ChatAIScreenState extends State<ChatAIScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<String> _messages = []; // 메시지 저장할 리스트
  GenerativeModel? _model;

  @override
  void initState() {
    super.initState();
    _initializeModel();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initializeModel() async {
    setState(() {
      _model = FirebaseVertexAI.instance.generativeModel(model: 'gemini-flash-experimental'); // Model ID 설정
    });
  }

  Future<void> _sendMessage(String message) async {
    if (_model == null) {
      setState(() {
        _messages.add('Model is not initialized yet.');
      });
      return;
    }

    try {
      final prompt = [Content.text(message)]; // 텍스트 프롬프트 생성
      final response = await _model!.generateContent(prompt); // generateContent 호출
      setState(() {
        _messages.add('You: $message'); // 사용자 메시지 추가
        _messages.add('AI: ${response.text ?? 'No response'}'); // AI 응답 메시지 추가
      });
    } catch (e) {
      setState(() {
        _messages.add('An error occurred. Please try again later.');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // 상단의 닫기 핸들러 (회색 막대)
          Container(
            height: 30,
            alignment: Alignment.center,
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: widget.scrollController, // DraggableScrollableSheet의 scrollController 사용
              physics: const BouncingScrollPhysics(), // iOS 스타일의 탄성 스크롤 효과 추가
              reverse: false, // 위에서 아래로 메시지 표시
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
                  child: _buildMessageBubble(_messages[index]),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Enter your message',
                      hintStyle: const TextStyle(color: Colors.black54),
                      filled: true,
                      fillColor: Colors.grey[200], // 텍스트 필드 배경 흰색 설정
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: () {
                    if (_controller.text.isNotEmpty) {
                      _sendMessage(_controller.text);
                      _controller.clear();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 채팅 메시지를 표시하는 버블 위젯 생성
  Widget _buildMessageBubble(String message) {
    bool isUserMessage = message.startsWith('You:'); // 사용자 메시지 여부 확인
    return Align(
      alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        padding: const EdgeInsets.all(12.0),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUserMessage ? Colors.blueAccent.withOpacity(0.7) : Colors.grey.withOpacity(0.7),
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
