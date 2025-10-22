import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 홈 화면
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>(); // ← Drawer 열기용 키
  int currentFatigueScore = 87;

  // --- 1. 수정: storage 인스턴스 생성 ---
  final storage = const FlutterSecureStorage();
  
  // _isLoggedIn 변수는 이미 있습니다.
  bool _isLoggedIn = false;

  // --- 2. 수정: initState 및 로그인 확인 로직 추가 ---
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  void _checkLoginStatus() async {
    // storage에서 'jwt_token'을 읽어옵니다.
    String? token = await storage.read(key: 'jwt_token');

    // 토큰이 존재하면 (null이 아니면)
    if (token != null) {
      setState(() {
        _isLoggedIn = true; // 로그인 상태를 true로 변경
      });
    }
  }
  // -------------------------------------------

  String _statusMsg(int score) {
    if (score >= 80) return '눈 상태가 매우 좋아요! 😄';
    if (score >= 50) return '눈 상태가 양호해요! 🙂';
    return '눈이 많이 피곤해요. 😣';
  }

  void _openMenu() => _scaffoldKey.currentState?.openEndDrawer();

  // --- 3. 수정: 로그아웃 함수 추가 ---
  void _logout() async {
    await storage.delete(key: 'jwt_token'); // 토큰 삭제
    setState(() {
      _isLoggedIn = false; // 로그인 상태를 false로 변경
    });
    
    if (!mounted) return;
    // (선택) 로그아웃 후 로그인 화면으로 이동
    if (_scaffoldKey.currentState?.isEndDrawerOpen ?? false) {
      Navigator.pop(context); // Drawer 닫기
    }
    Navigator.pushReplacementNamed(context, '/login');
  }
  // ----------------------------------

  Future<void> _go(String route) async {
    if(_scaffoldKey.currentState?.isEndDrawerOpen ?? false) {
      Navigator.pop(context); // Drawer 닫기
      await Future.delayed(const Duration(milliseconds: 150)); // 닫힘 애니 잠깐 대기(부드럽게)
    }
    if (!mounted) return;
    
    // 이미 홈 화면인데 홈으로 또 이동하는 것을 방지
    if (route == '/' && ModalRoute.of(context)?.settings.name == '/') {
      return; 
    }
    Navigator.pushNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final w = size.width;

    return Scaffold(
      key: _scaffoldKey, // ← 연결
      backgroundColor: Colors.white,
      appBar: AppBar(
        // ... (AppBar 코드는 동일) ...
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            const SizedBox(width: 16),
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFF2F43FF),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Text(
                'O',
                style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'onnoon',
              style: TextStyle(
                color: Color(0xFF2F43FF),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: Colors.grey[600]),
            onPressed: () {
              // 필요하면 알림 라우트 연결
              // Navigator.pushNamed(context, '/notifications');
            },
          ),
          IconButton(
            icon: Icon(Icons.menu, color: Colors.grey[600]),
            onPressed: _openMenu, // ← Drawer 열기
          ),
        ],
      ),

      // ===== 햄버거 메뉴(End Drawer) =====
      endDrawer: _AppMenuDrawer(
        isLoggedIn: _isLoggedIn,
        onGoLogin: () => _go('/login'),
        onLogout: _logout, // --- 4. 수정: 로그아웃 함수 전달 ---
        onGoHome:   () => _go('/'),
        onGoGuide:  () => _go('/guide'),
        onGoStats:  () => _go('/records'),     // 네가 쓰는 "기록/그래프" 경로
        onGoAnalysis: () => _go('/analysis'),  // 분석 상세(또는 결과)
        onGoDiagnosis: () => _go('/diagnosis'),// 진단 화면 경로 그대로 사용
        onGoSettings: () => _go('/settings') // '/settings' 경로는 실제 설정 화면 경로에 맞게 수정
      ),

      body: SafeArea(
        // ... (Body 코드는 동일) ...
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              SizedBox(height: size.height * 0.02),
              _buildMainFatigueSection(w),
              SizedBox(height: size.height * 0.04),
              _buildDiagnosisButton(w),
              SizedBox(height: size.height * 0.04),
              const _SectionDivider(),
              SizedBox(height: size.height * 0.03),
              _buildFatigueAlert(),
              SizedBox(height: size.height * 0.03),
              _buildFatigueChart(size),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ... (모든 _build... 위젯 함수는 동일) ...
  Widget _buildMainFatigueSection(double screenW) {
    final ring = screenW * 0.55;
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: ring,
              height: ring,
              child: CircularProgressIndicator(
                value: currentFatigueScore / 100,
                strokeWidth: 12,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2F43FF)),
              ),
            ),
            CircleAvatar(
              radius: ring * 0.28,
              backgroundColor: Colors.orange[300],
              child: Text('🤔', style: TextStyle(fontSize: ring * 0.28)),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          '$currentFatigueScore점',
          style: const TextStyle(
            color: Colors.black, fontSize: 36, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          _statusMsg(currentFatigueScore),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _buildDiagnosisButton(double screenW) {
    return SizedBox(
      width: screenW * 0.7,
      height: 56,
      child: ElevatedButton(
        onPressed: () => Navigator.pushNamed(context, '/diagnosis'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2F43FF),
          shape: const StadiumBorder(),
          elevation: 0,
        ),
        child: const Text(
          '다시 진단하기',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildFatigueAlert() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'OOO 님의 피로도 수치가\n감소하고 있습니다.',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
        InkWell(
          onTap: () => _go('/records'),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF2F43FF),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1),
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildFatigueChart(Size size) {
    final w = size.width * 0.9;
    final h = size.height * 0.28;

    return Container(
      width: w,
      height: h.clamp(200.0, 320.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7FA),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(20),
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 100,
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                getTitlesWidget: (value, meta) {
                  const days = ['월', '화', '수', '목', '금', '토', '일'];
                  final i = value.toInt();
                  if (i >= 0 && i < days.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(days[i],
                          style: const TextStyle(fontSize: 12, color: Color(0xFF666666))),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: const [
                FlSpot(0, 45),
                FlSpot(1, 60),
                FlSpot(2, 55),
                FlSpot(3, 70),
                FlSpot(4, 65),
                FlSpot(5, 80),
                FlSpot(6, 87),
              ],
              isCurved: true,
              color: const Color(0xFF2F43FF),
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                  radius: 4,
                  color: const Color(0xFF2F43FF),
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFF2F43FF).withOpacity(0.12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 회색 굵은 구분선
class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return Container(height: 10, color: const Color(0xFFF3F3F3));
  }
}

/// 앱 공용 메뉴 드로어
class _AppMenuDrawer extends StatelessWidget {
  final bool isLoggedIn;
  final VoidCallback onGoLogin;
  final VoidCallback onLogout; // --- 5. 수정: onLogout 변수 추가 ---

  final VoidCallback onGoHome;
  final VoidCallback onGoGuide;
  final VoidCallback onGoStats;
  final VoidCallback onGoAnalysis;
  final VoidCallback onGoDiagnosis;
  final VoidCallback onGoSettings;

  // 생성자 수정
  const _AppMenuDrawer({
    required this.isLoggedIn,
    required this.onGoLogin,
    required this.onLogout, // --- 5. 수정: onLogout을 required로 추가 ---
    required this.onGoHome,
    required this.onGoGuide,
    required this.onGoStats,
    required this.onGoAnalysis,
    required this.onGoDiagnosis,
    required this.onGoSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      elevation: 0,
      backgroundColor: Colors.white, // 배경색을 흰색으로 지정
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            isLoggedIn ? _buildProfileSection() : _buildLoginSection(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('홈'),
              onTap: onGoHome,
            ),
            ListTile(
              leading: const Icon(Icons.stacked_line_chart),
              title: const Text('기록 및 통계'),
              onTap: onGoStats,
            ),
            ListTile(
              leading: const Icon(Icons.analytics_outlined),
              title: const Text('분석 결과'),
              onTap: onGoAnalysis,
            ),
            ListTile(
              leading: const Icon(Icons.self_improvement_outlined),
              title: const Text('맞춤형 회복 가이드'),
              onTap: onGoGuide,
            ),
            ListTile(
              leading: const Icon(Icons.health_and_safety_outlined),
              title: const Text('진단하기'),
              onTap: onGoDiagnosis,
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('설정'),
              onTap: onGoSettings,
            ),
            // --- 6. 수정: 로그인 상태일 때 로그아웃 버튼 표시 ---
            if (isLoggedIn) ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('로그아웃'),
                onTap: onLogout,
              ),
            ]
            // ------------------------------------------
          ],
        ),
      ),
    );
  }

  // 로그인되지 않았을 때 보여줄 위젯
  Widget _buildLoginSection() {
    // ... (코드는 동일) ...
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 35,
            backgroundColor: Color(0xFFF3F3F3),
            child: Icon(Icons.person, size: 40, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          const Text(
            '로그인이 필요한 서비스입니다.\n로그인/회원가입 후 이용해주세요.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onGoLogin, // 전달받은 함수 사용
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2F43FF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              minimumSize: const Size(180, 44),
            ),
            child: const Text(
              '로그인 / 회원가입',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        ],
      ),
    );
  }

  // 로그인되었을 때 보여줄 위젯 (프로필)
  Widget _buildProfileSection() {
    // ... (코드는 동일) ...
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: Color(0xFF2F43FF),
            child: Text(
              '온눈',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '온눈님', // TODO: 추후 토큰에서 사용자 이름 파싱
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                '로그인되었습니다.', // TODO: 추후 토큰에서 이메일 파싱
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}