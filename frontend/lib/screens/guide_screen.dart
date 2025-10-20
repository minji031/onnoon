import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class GuideScreen extends StatefulWidget {
  const GuideScreen({super.key});

  @override
  State<GuideScreen> createState() => _GuideScreenState();
}

class _GuideScreenState extends State<GuideScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('맞춤형 회복 가이드'),
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF111111),
      ),
      body: Column(
        children: [
          // 탭
          TabBar(
            controller: _tab,
            labelColor: const Color(0xFF5A6BFF),
            unselectedLabelColor: const Color(0xFFC8C8C8),
            indicatorColor: const Color(0xFF634FFF),
            indicatorWeight: 3,
            tabs: const [
              Tab(text: '스트레칭'),
              Tab(text: '휴식 타이머'),
              Tab(text: '제품 추천'),
            ],
          ),
          const Divider(height: 1, color: Color(0xFFD6D6D6)),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: const [
                _StretchingTab(),
                _PomodoroTab(),
                _ProductTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --------------------------- 스트레칭 탭 ---------------------------
class _StretchingTab extends StatelessWidget {
  const _StretchingTab();

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      // 실패 시 스낵바
      // ignore: use_build_context_synchronously
      // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('링크를 열 수 없어요')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final cardW = w * 0.78;

    final items = [
      (
        title: '눈 스트레칭 1',
        desc: '3분 루틴으로 시작해요.',
        url: 'https://www.youtube.com/results?search_query=eye+stretch'
      ),
      (
        title: '눈 깜빡임 훈련',
        desc: '건조감 완화에 도움.',
        url: 'https://www.youtube.com/results?search_query=blink+exercise'
      ),
      (
        title: '초점 전환 운동',
        desc: '근거리/원거리 번갈아 보기.',
        url: 'https://www.youtube.com/results?search_query=focus+exercise+eyes'
      ),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      children: [
        Text(
          'OOO 님의 눈 건강을 위한 회복 스트레칭이에요.',
          style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        const Text(
          '눈 건강 스트레칭',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final it = items[i];
              return Container(
                width: cardW,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x3F656565),
                      blurRadius: 5,
                      offset: Offset(2, 1),
                      spreadRadius: 1,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // 썸네일 자리(임시)
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF1FF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.play_circle_outline),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(it.title,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          Text(it.desc,
                              style: TextStyle(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w600)),
                          const Spacer(),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: SizedBox(
                              height: 32,
                              child: ElevatedButton(
                                onPressed: () => _open(it.url),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4548FF),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  '시작',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        const _SectionDivider(),
        const SizedBox(height: 16),
        Text(
          '눈 관련 영상',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text('눈 건강을 위해 몇 가지 영상을 추천해드려요.',
            style:
                TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: List.generate(
            4,
            (i) => _VideoTile(
              title: '추천 영상 ${i + 1}',
              onTap: () => _open(
                  'https://www.youtube.com/results?search_query=eye+health+${i + 1}'),
            ),
          ),
        ),
      ],
    );
  }
}

class _VideoTile extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  const _VideoTile({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 170,
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Container(
                height: 90,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF1FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.ondemand_video_outlined),
              ),
              const SizedBox(height: 8),
              Text(title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return Container(height: 10, color: const Color(0xFFF3F3F3));
  }
}

// --------------------------- 포모도로 탭 ---------------------------
class _PomodoroTab extends StatefulWidget {
  const _PomodoroTab();

  @override
  State<_PomodoroTab> createState() => _PomodoroTabState();
}

class _PomodoroTabState extends State<_PomodoroTab> {
  static const workMinutes = 25;
  static const breakMinutes = 5;

  bool isWorking = true; // true: 25분 집중, false: 5분 휴식
  Duration remaining = const Duration(minutes: workMinutes);
  Timer? _timer;

  void _start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (remaining.inSeconds <= 1) {
        setState(() {
          isWorking = !isWorking;
          remaining = Duration(
              minutes: isWorking ? workMinutes : breakMinutes);
        });
      } else {
        setState(() => remaining -= const Duration(seconds: 1));
      }
    });
  }

  void _pause() {
    _timer?.cancel();
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      isWorking = true;
      remaining = const Duration(minutes: workMinutes);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total =
        Duration(minutes: isWorking ? workMinutes : breakMinutes).inSeconds;
    final progress = 1 - (remaining.inSeconds / total);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(isWorking ? '집중 세션' : '휴식 세션',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            SizedBox(
              width: 220,
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 220,
                    height: 220,
                    child: CircularProgressIndicator(
                      value: progress.clamp(0, 1),
                      strokeWidth: 14,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation(Color(0xFF5A6BFF)),
                    ),
                  ),
                  Text(
                    _format(remaining),
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              isWorking
                  ? '25분 집중 → 5분 휴식'
                  : '5분 휴식 후 25분 집중으로 전환',
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _pillButton('시작', _start),
                const SizedBox(width: 10),
                _pillButton('일시정지', _pause),
                const SizedBox(width: 10),
                _pillButton('초기화', _reset),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Widget _pillButton(String text, VoidCallback onTap) {
    return SizedBox(
      height: 44,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF5A6BFF),
          shape: const StadiumBorder(),
          elevation: 0,
        ),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

// --------------------------- 제품 추천 탭 ---------------------------
class _ProductTab extends StatelessWidget {
  const _ProductTab();

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final products = [
      (
        name: '인공눈물',
        desc: '장시간 화면 사용 후 건조감 완화',
        url: 'https://www.google.com/search?q=best+artificial+tears'
      ),
      (
        name: '루테인',
        desc: '황반 건강에 도움',
        url: 'https://www.google.com/search?q=lutein+supplement'
      ),
      (
        name: '블루라이트 차단 안경',
        desc: '야간 작업 시 피로도 감소',
        url:
            'https://www.google.com/search?q=blue+light+blocking+glasses'
      ),
      (
        name: '온열 아이마스크',
        desc: '눈꺼풀 위생/순환 도움',
        url: 'https://www.google.com/search?q=heated+eye+mask'
      ),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      children: [
        const Text('제품 추천',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: products
              .map((p) => _ProductCard(
                    title: p.name,
                    desc: p.desc,
                    onTap: () => _open(p.url),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class _ProductCard extends StatelessWidget {
  final String title;
  final String desc;
  final VoidCallback onTap;

  const _ProductCard({
    required this.title,
    required this.desc,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          width: 170,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                color: Color(0x3F656565),
                blurRadius: 5,
                offset: Offset(2, 1),
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 이미지 자리(임시)
              Container(
                height: 90,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF1FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(child: Icon(Icons.image_outlined)),
              ),
              const SizedBox(height: 10),
              Text(title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(
                desc,
                style: TextStyle(color: Colors.grey[700]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
