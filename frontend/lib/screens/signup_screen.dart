import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// 회원가입 단계를 정의 (이 부분은 코드에 없었지만, 가독성을 위해 추가하면 좋습니다)
// enum SignupStep { terms, email, password }

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // PageView와 TextField를 컨트롤하기 위한 컨트롤러
  final _pageController = PageController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  // UI에 이름 입력 필드를 추가하고 이 컨트롤러를 연결해야 합니다. (현재는 이메일 페이지에서만 임시 사용)
  final _nameController = TextEditingController();

  // 약관 동의 상태
  bool _agreeAll = false;
  bool _agreeTerms1 = false;
  bool _agreeTerms2 = false;
  bool _agreeTerms3 = false;
  bool _agreeTerms4 = false;

  // 비밀번호 유효성 검사 상태
  bool _isPasswordLengthValid = false;
  bool _hasLetter = false;
  bool _hasNumber = false;
  bool _isPasswordMatch = false;

  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    // 컨트롤러에 리스너를 추가하여 텍스트 변경을 감지
    _emailController.addListener(() => setState(() {}));
    _passwordController.addListener(_validatePassword);
    _confirmPasswordController.addListener(_validatePassword);
  }

  // 다음 페이지로 이동
  void _nextPage() {
    if (_pageController.page! < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    }
  }

  // 비밀번호 유효성 실시간 검사
  void _validatePassword() {
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    setState(() {
      _isPasswordLengthValid = password.length >= 8 && password.length <= 20;
      _hasLetter = password.contains(RegExp(r'[a-zA-Z]'));
      _hasNumber = password.contains(RegExp(r'[0-9]'));
      _isPasswordMatch = password.isNotEmpty && password == confirmPassword;
    });
  }

  // '모두 동의' 상태 업데이트
  void _updateAgreeAllState() {
      if (_agreeTerms1 && _agreeTerms2 && _agreeTerms3 && _agreeTerms4) {
          _agreeAll = true;
      } else {
          _agreeAll = false;
      }
  }

  // 오류 발생 시 사용자에게 보여줄 대화상자(Dialog)
  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('오류 발생'),
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

  // 최종 회원가입 처리
  void _handleSignup() async {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();
    // TODO: UI에 이름 입력 필드를 추가하고 _nameController를 연결해야 합니다. 현재는 임시값 사용.
    final String name = _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : "사용자";

    // --- 1. API 경로를 가이드에 맞게 변경 ---
    final url = Uri.parse('https://onnoon.onrender.com/api/auth/register');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        // --- 2. 요청 본문에 name, email, password 포함 ---
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
        }),
      );

      if (!mounted) return;

      // 성공 코드는 201 (Created)로 가정 (가이드에는 명시되지 않았지만 일반적)
      if (response.statusCode == 201) {
        // 성공 시
        Navigator.of(context).pop(); // 로그인 화면으로 이동
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('회원가입이 완료되었습니다!')),
        );
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
    _pageController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (_pageController.page == 0) {
              Navigator.of(context).pop();
            } else {
              _pageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeIn,
              );
            }
          },
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 진행 상태 표시 바
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: LinearProgressIndicator(
              value: (_currentPage + 1) / 3,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2F43FF)),
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              children: [
                _buildTermsPage(),
                _buildEmailPage(), // 이름 입력 필드는 여기에 추가하는 것이 자연스러움
                _buildPasswordPage(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 페이지 빌더 위젯들 ---

  // 1. 약관 동의 페이지
  Widget _buildTermsPage() {
    bool canGoNext = _agreeTerms1 && _agreeTerms2 && _agreeTerms3;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('서비스 이용약관에\n동의해주세요.', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          _buildAgreementCheckbox(
            title: '모두 동의 (선택 정보 포함)',
            isBold: true,
            value: _agreeAll,
            onChanged: (value) {
              setState(() {
                _agreeAll = value!;
                _agreeTerms1 = value;
                _agreeTerms2 = value;
                _agreeTerms3 = value;
                _agreeTerms4 = value;
              });
            },
          ),
          const Divider(),
          _buildAgreementCheckbox(
            title: '[필수] 만 14세 이상',
            value: _agreeTerms1,
            onChanged: (value) => setState(() { _agreeTerms1 = value!; _updateAgreeAllState(); }),
          ),
          _buildAgreementCheckbox(
            title: '[필수] 이용약관 동의',
            value: _agreeTerms2,
            onChanged: (value) => setState(() { _agreeTerms2 = value!; _updateAgreeAllState(); }),
          ),
          _buildAgreementCheckbox(
            title: '[필수] 개인정보 처리방침 동의',
            value: _agreeTerms3,
            onChanged: (value) => setState(() { _agreeTerms3 = value!; _updateAgreeAllState(); }),
          ),
          _buildAgreementCheckbox(
            title: '[선택] 광고성 정보 수신 및 마케팅 활용 동의',
            value: _agreeTerms4,
            onChanged: (value) => setState(() { _agreeTerms4 = value!; _updateAgreeAllState(); }),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: canGoNext ? _nextPage : null,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: const Color(0xFF2F43FF),
              disabledBackgroundColor: Colors.grey[300],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('동의하고 가입하기', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // 2. 이메일 입력 페이지 (+이름 입력 추가 필요)
  Widget _buildEmailPage() {
    final email = _emailController.text;
    final name = _nameController.text;

    bool isEmailValid = email.contains('@') && email.contains('.');
    bool isNameValid = name.trim().isNotEmpty;
    bool canGoNext = isEmailValid && isNameValid; 

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('아이디를 입력해주세요.', 
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            // autofocus: true,
            decoration: const InputDecoration(
              labelText: '이메일 (아이디)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            keyboardType: TextInputType.name,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: '이름',
              border: OutlineInputBorder(),
            ),
          ),
          // ------------------------------------
          const Spacer(),
          ElevatedButton(
            onPressed: canGoNext ? _nextPage : null,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: const Color(0xFF2F43FF),
              disabledBackgroundColor: Colors.grey[300],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('다음', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // 3. 비밀번호 입력 페이지
  Widget _buildPasswordPage() {
    bool canSignup = _isPasswordLengthValid && _hasLetter && _hasNumber && _isPasswordMatch;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('로그인에 사용할\n비밀번호를 입력해주세요.', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          TextField(
            controller: _passwordController,
            obscureText: true,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: '비밀번호 입력',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _confirmPasswordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: '비밀번호 확인',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          _buildValidationCheck('영문 포함', _hasLetter),
          _buildValidationCheck('숫자 포함', _hasNumber),
          _buildValidationCheck('8-20자 이내', _isPasswordLengthValid),
          _buildValidationCheck('비밀번호 일치', _isPasswordMatch),
          const Spacer(),
          ElevatedButton(
            onPressed: canSignup ? _handleSignup : null,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: const Color(0xFF2F43FF),
              disabledBackgroundColor: Colors.grey[300],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('가입하기', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // --- 유틸리티 위젯들 ---

  Widget _buildAgreementCheckbox({
    required String title,
    required bool value,
    required ValueChanged<bool?> onChanged,
    bool isBold = false,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Row(
        children: [
          Checkbox(value: value, onChanged: onChanged, activeColor: const Color(0xFF2F43FF)),
          Text(
            title,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValidationCheck(String text, bool isValid) {
    final color = isValid ? const Color(0xFF2F43FF) : Colors.grey;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(Icons.check, size: 16, color: color),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: color)),
        ],
      ),
    );
  }
}