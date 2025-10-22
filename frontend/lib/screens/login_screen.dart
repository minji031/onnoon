import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // 텍스트 필드의 값을 가져오기 위한 컨트롤러
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final storage = const FlutterSecureStorage();

  // 오류 팝업을 위한 헬퍼 함수 추가
  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('로그인 실패'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: const Text('확인'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          )
        ],
      ),
    );
  }

  // _login 함수 전체 수정
  void _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // --- ✅ 수정: API 경로를 가이드에 맞게 변경 ---
    final url = Uri.parse('https://onnoon.onrender.com/api/auth/login');

    try {
      final response = await http.post(
        url,
        // http.post에 Map을 body로 넘기면 'application/x-www-form-urlencoded'로 자동 설정됨
        body: {
          'username': email, // API 명세에 따라 'username' 사용
          'password': password,
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        // 성공 시
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        final String accessToken = responseData['access_token'];

        // 토큰을 'jwt_token' 키로 저장
        await storage.write(key: 'jwt_token', value: accessToken);

        // 토큰 저장 후 홈 화면으로 이동
        Navigator.pushReplacementNamed(context, '/');
      } else {
        // 실패 시 (서버에서 보낸 에러 메시지 표시)
        final errorData = jsonDecode(utf8.decode(response.bodyBytes));
        _showErrorDialog(errorData['detail'] ?? '알 수 없는 오류가 발생했습니다.');
      }
    } catch (e) {
      // 네트워크 연결 오류 등
      _showErrorDialog('서버에 연결할 수 없습니다. 인터넷 연결을 확인해주세요.');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.1),
              const Text(
                'onnoon에 오신 것을\n환영합니다!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 48),

              // 이메일 입력 필드
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: '이메일',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 16),

              // 비밀번호 입력 필드
              TextField(
                controller: _passwordController,
                obscureText: true, // 비밀번호 가리기
                decoration: const InputDecoration(
                  labelText: '비밀번호',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 32),

              // 로그인 버튼
              ElevatedButton(
                onPressed: _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2F43FF),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '로그인',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),

              // 회원가입 화면으로 이동하는 버튼
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('계정이 없으신가요?'),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/signup');
                    },
                    child: const Text(
                      '회원가입',
                      style: TextStyle(
                        color: Color(0xFF2F43FF),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}