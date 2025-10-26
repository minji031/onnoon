import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
// import 'package:intl/intl.dart';

/// 홈 화면
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>(); // ← Drawer 열기용 키
  // --- storage 인스턴스 생성 ---
  final storage = const FlutterSecureStorage();
  bool _isLoggedIn = false;

  bool _isLoadingLatestResult = true;
  String? _latestResultErrorMessage;
  double? _latestScore;
  String? _latestGrade;
  DateTime? _latestCreatedAt;

  // --- initState 및 로그인 확인 로직 추가 ---
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _fetchLatestResult();
  }

  void _checkLoginStatus() async {
    // storage에서 'jwt_token'을 읽어옵니다.
    String? token = await storage.read(key: 'jwt_token');
    bool loggedIn = (token != null);

    if (mounted) {
      setState(() {
        _isLoggedIn = loggedIn;
      });
        // 로그인 상태이고, 아직 최신 결과 로딩 전이면 API 호출
      if (loggedIn && _isLoadingLatestResult) {
        _fetchLatestResult();
      } else if (!loggedIn) {
        setState(() {
          _isLoadingLatestResult = false;
        });
      }
    }
  }

  // --- 최신 결과 API 호출 함수 추가 ---
  Future<void> _fetchLatestResult() async {
    String? token = await storage.read(key: 'jwt_token');

    if (token == null) {
      if (mounted) {
        setState(() {
          _isLoadingLatestResult = false;
          _latestResultErrorMessage = '로그인이 필요합니다.';
        });
      }
      return;
    }

    final url = Uri.parse('https://onnoon.onrender.com/api/eye-fatigue/result');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (!mounted) return;

if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _latestScore = (data['fatigue_score'] as num?)?.toDouble();
          _latestGrade = data['fatigue_grade'] as String?;
          _latestCreatedAt = DateTime.tryParse(data['created_at'] ?? '');
          _isLoadingLatestResult = false;
          _latestResultErrorMessage = null;
        });
        // TODO: 그래프용 데이터 API 호출 또는 _latestScore 기반 업데이트
      } else if (response.statusCode == 404) {
         setState(() {
          _isLoadingLatestResult = false;
          _latestResultErrorMessage = '최근 진단 기록이 없습니다.';
          _latestScore = null;
          _latestGrade = null;
         });
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        // 인증 실패 시 로그아웃 처리
        await storage.delete(key: 'jwt_token');
        setState(() => _isLoggedIn = false);
        // build 이후에 네비게이션 실행
        WidgetsBinding.instance.addPostFrameCallback((_) {
            if(mounted) {
              Navigator.pushReplacementNamed(context, '/login');
            }
         });
      } else {
        setState(() {
          _isLoadingLatestResult = false;
          _latestResultErrorMessage = '데이터를 불러오는데 실패했습니다. (서버 오류 ${response.statusCode})';
        });
      }
    } catch (e) {
       if (mounted) {
        setState(() {
          _isLoadingLatestResult = false;
          _latestResultErrorMessage = '서버에 연결할 수 없습니다.';
        });
      }
    }
  }

  void _openMenu() => _scaffoldKey.currentState?.openEndDrawer();

  Future<void> _go(String route) async {
    if (_scaffoldKey.currentState?.isEndDrawerOpen ?? false) {
      Navigator.pop(context);
      await Future.delayed(const Duration(milliseconds: 150));
    }
    if (!mounted) return;

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
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      appBar: AppBar(
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
               // Navigator.pushNamed(context, '/notifications');
             },
           ),
           IconButton(
             icon: Icon(Icons.menu, color: Colors.grey[600]),
             onPressed: _openMenu, // EndDrawer 열기
           ),
         ],
      ),  

      endDrawer: _AppMenuDrawer(
        isLoggedIn: _isLoggedIn, 
        onGoLogin: () => _go('/login'),
        //onLogout: onLogout, 
        onGoHome: () => _go('/'), 
        onGoGuide: () => _go('/guide'),
        onGoStats: () => _go('/records'), 
        onGoAnalysis: () => _go('/analysis'), 
        onGoDiagnosis: () => _go('/diagnosis'), 
        onGoSettings: () => _go('/settings')
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              SizedBox(height: size.height * 0.02),
              _isLoadingLatestResult
                ? const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 50.0), child: CircularProgressIndicator()))
                : _latestResultErrorMessage != null
                  ? Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text(_latestResultErrorMessage!,textAlign: TextAlign.center,)))
                  : _latestScore != null
                    ? _buildMainFatigueSection(w, _latestScore!, _latestGrade ?? '')
                          : const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 50.0), child: Text('최근 진단 기록이 없습니다.'))),

              SizedBox(height: size.height * 0.04),
              _buildDiagnosisButton(w),
              SizedBox(height: size.height * 0.04),
              const _SectionDivider(),
              SizedBox(height: size.height * 0.03),
              _buildFatigueAlert(), // + 버튼 경로는 수정됨
              SizedBox(height: size.height * 0.03),
              // TODO: 그래프 부분도 로딩/오류/데이터 처리 및 실제 데이터 반영 필요
              _buildFatigueChart(size),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainFatigueSection(double screenW, double score, String grade) {
    final ring = screenW * 0.55;
    final gradeText = grade.split(' ').first;
    final gradeEmoji = grade.contains(' ') ? grade.split(' ').last : '🤔';

    String statusMsg;
    if (score >=80) statusMsg = '눈 상태가 매우 좋아요!';
    else if (score >= 50) statusMsg = '눈 상태가 양호해요!';
    else statusMsg = '눈이 많이 피곤해요.';

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: ring,
              height: ring,
              child: CircularProgressIndicator(
                value: score / 100,
                strokeWidth: 12,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2F43FF)),
              ),
            ),
            CircleAvatar(
              radius: ring * 0.28,
              backgroundColor: Colors.orange[300],
              child: Text(gradeEmoji, style: TextStyle(fontSize: ring * 0.28)),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          '${score.toStringAsFixed(0)}점',
          style: const TextStyle(
            color: Colors.black, fontSize: 36, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          gradeText.isNotEmpty ? '$gradeText $statusMsg' : statusMsg,
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
         onPressed: () => _go('/diagnosis'), // _go 함수 사용
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
             // TODO: API에서 사용자 이름 가져와서 표시 ('OOO 님')
             '사용자 님의 피로도 수치가\n감소하고 있습니다.', // API 데이터 연동 필요
             style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
           ),
         ),
         InkWell(
           onTap: () => _go('/records'), // --- ✅ 경로 수정됨 ---
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
    // 가짜 그래프 데이터 사용
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
      child: LineChart( // TODO: API 데이터(_recentSpots) 사용하도록 수정 필요
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
                interval: 1, // 모든 라벨 표시
                getTitlesWidget: (value, meta) {
                  // TODO: _recentSpots 데이터에 맞는 라벨 표시 로직 필요
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
              spots: const [ // TODO: API 데이터(_recentSpots) 사용하도록 수정 필요
                FlSpot(0, 45), FlSpot(1, 60), FlSpot(2, 55), FlSpot(3, 70),
                FlSpot(4, 65), FlSpot(5, 80), FlSpot(6, 87),
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

class _SectionDivider extends StatelessWidget {
  const _SectionDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(height: 10, color: const Color(0xFFF3F3F3));
  }
}

class _AppMenuDrawer extends StatelessWidget {
  final bool isLoggedIn;
  final VoidCallback onGoLogin;

  final VoidCallback onGoHome;
  final VoidCallback onGoGuide;
  final VoidCallback onGoStats;
  final VoidCallback onGoAnalysis;
  final VoidCallback onGoDiagnosis;
  final VoidCallback onGoSettings;

  const _AppMenuDrawer({
    required this.isLoggedIn,
    required this.onGoLogin,
    // onLogout 제거됨
    required this.onGoHome,
    required this.onGoGuide,
    required this.onGoStats,
    required this.onGoAnalysis,
    required this.onGoDiagnosis,
    required this.onGoSettings,
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
          elevation: 0,
          backgroundColor: Colors.white,
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
                // 로그아웃 버튼 없음
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