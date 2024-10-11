import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rive/rive.dart'; // Rive 애니메이션 패키지 추가
import 'EmailLogin.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int _currentPage = 0;
  bool _isLoading = false; // 로딩 상태를 나타내는 변수 추가

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_validateInput()) {
      if (_currentPage < 3) {
        _pageController.nextPage(
          duration: Duration(milliseconds: 300),
          curve: Curves.ease,
        );
        setState(() {
          _currentPage++;
        });
      } else {
        _register();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("모든 필드를 입력해 주세요.")),
      );
    }
  }

  bool _validateInput() {
    switch (_currentPage) {
      case 0:
        return _nameController.text.isNotEmpty;
      case 1:
        return _emailController.text.isNotEmpty;
      case 2:
        return _passwordController.text.isNotEmpty;
      case 3:
        return _confirmPasswordController.text.isNotEmpty;
      default:
        return false;
    }
  }

  Future<void> _register() async {
    setState(() {
      _isLoading = true; // 로딩 상태로 설정
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          content: Container(
            width: 200,
            height: 200,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 150, // 애니메이션 너비
                  height: 150, // 애니메이션 높이
                  child: RiveAnimation.asset(
                    'assets/Rive/animgears.riv',
                    fit: BoxFit.contain,
                    alignment: Alignment.center,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "회원가입 중...",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _isLoading = false;
      });
      Navigator.of(context).pop(); // 다이얼로그 닫기
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("비밀번호가 일치하지 않습니다.")),
      );
      return;
    }

    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      await userCredential.user?.updateDisplayName(_nameController.text);

      await _firestore.collection('users').doc(userCredential.user?.uid).set({
        'email': _emailController.text,
        'gender': 'male',
        'phone_number': '',
        'profileImageUrl':
        'https://firebasestorage.googleapis.com/v0/b/techpicks-project.appspot.com/o/profile_images%2FJ4FTlllHs3g6z0pPj9VSmh9tcEC3?alt=media&token=77019dd1-7734-49ec-9922-2d3fa0283f8f',
        'pronouns': '',
        'user_id': 'rush94434',
        'username': _nameController.text,
      });

      Navigator.of(context).pop(); // 다이얼로그 닫기

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => _buildSuccessDialog(context), // 성공 애니메이션 다이얼로그 표시
      );

      Future.delayed(const Duration(seconds: 2), () {
        Navigator.of(context).pop(); // 성공 애니메이션 다이얼로그 닫기
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainLoginPage()),
        );
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      Navigator.of(context).pop(); // 다이얼로그 닫기
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("회원가입에 실패했습니다.")),
      );
    }
  }

  Widget _buildSuccessDialog(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      content: Container(
        width: 200,
        height: 200,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 150, // 애니메이션 너비
              height: 150, // 애니메이션 높이
              child: RiveAnimation.asset(
                'assets/Rive/LoginSuccess.riv',
                fit: BoxFit.contain,
                alignment: Alignment.center,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "회원가입 성공!",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // 페이지 내용
          PageView(
            controller: _pageController,
            physics: NeverScrollableScrollPhysics(),
            children: [
              _buildPage(
                context,
                size,
                title: "이름을 알려주세요",
                controller: _nameController,
                labelText: "이름",
              ),
              _buildPage(
                context,
                size,
                title: "이메일을 알려주세요",
                controller: _emailController,
                labelText: "이메일",
              ),
              _buildPage(
                context,
                size,
                title: "비밀번호를 알려주세요",
                controller: _passwordController,
                labelText: "비밀번호",
                obscureText: true,
              ),
              _buildPage(
                context,
                size,
                title: "비밀번호를 재입력해 주세요",
                controller: _confirmPasswordController,
                labelText: "비밀번호",
                obscureText: true,
              ),
            ],
          ),
          // 하단의 다음/완료 버튼
          Positioned(
            bottom: size.height * 0.4, // 화면 중간 정도 높이로 설정
            left: size.width * 0.25, // 화면의 25% 지점에서 시작
            right: size.width * 0.25, // 화면의 25% 지점에서 끝
            child: SizedBox(
              width: size.width * 0.5, // 화면의 절반 너비를 차지하도록 설정
              child: ElevatedButton(
                onPressed: _nextPage,
                child: Text(
                  _currentPage < 3 ? "다음" : "완료",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, // 버튼 색상 파란색으로 설정
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), // 모서리를 둥글게 설정
                  ),
                  padding: EdgeInsets.symmetric(vertical: 15), // 버튼 높이 조정
                ),
              ),
            ),
          ),
          // 로딩 애니메이션 (필요 시)
          if (_isLoading)
            Center(
              child: SizedBox(
                width: 150,
                height: 150,
                child: RiveAnimation.asset(
                  'assets/Rive/animgears.riv',
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPage(BuildContext context, Size size,
      {required String title,
        required TextEditingController controller,
        required String labelText,
        bool obscureText = false}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: size.height * 0.1), // 상단에 여백 추가
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            title,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(height: size.height * 0.05), // 제목과 입력 필드 사이 여백
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: labelText,
              labelStyle: TextStyle(color: Colors.grey, fontSize: 18), // 라벨 스타일 설정
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.blue),
              ),
            ),
            obscureText: obscureText,
          ),
        ),
      ],
    );
  }
}
