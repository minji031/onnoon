import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

enum Period { daily, weekly, monthly }

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key}); // ✅ const 생성자

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  Period _period = Period.daily;

  // TODO: 실제 데이터로 교체
  List<FlSpot> get _series {
    switch (_period) {
      case Period.daily:
        return const [
          FlSpot(0, 43), FlSpot(1, 58), FlSpot(2, 62),
          FlSpot(3, 71), FlSpot(4, 66), FlSpot(5, 80), FlSpot(6, 75),
        ];
      case Period.weekly:
        return List.generate(8, (i) => FlSpot(i.toDouble(), (50 + i * 4).toDouble()));
      case Period.monthly:
        return const [
          FlSpot(0, 60), FlSpot(1, 68), FlSpot(2, 72),
          FlSpot(3, 65), FlSpot(4, 78), FlSpot(5, 82),
        ];
    }
  }

  List<String> get _xLabels {
    switch (_period) {
      case Period.daily:
        return const ['월', '화', '수', '목', '금', '토', '일'];
      case Period.weekly:
        return List.generate(8, (i) => '${i + 1}주');
      case Period.monthly:
        return const ['3월', '4월', '5월', '6월', '7월', '8월'];
    }
  }

  ({int index, double value}) get _minPoint {
    final s = _series;
    int idx = 0; double v = s.first.y;
    for (var i = 1; i < s.length; i++) {
      if (s[i].y < v) { v = s[i].y; idx = i; }
    }
    return (index: idx, value: v);
  }

  ({int index, double value}) get _maxPoint {
    final s = _series;
    int idx = 0; double v = s.first.y;
    for (var i = 1; i < s.length; i++) {
      if (s[i].y > v) { v = s[i].y; idx = i; }
    }
    return (index: idx, value: v);
  }

  double _avg(List<FlSpot> s) =>
      s.isEmpty ? 0 : s.map((e) => e.y).reduce((a, b) => a + b) / s.length;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('기록 및 통계'),
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF111111),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          _PeriodSelector(
            period: _period,
            onChanged: (p) => setState(() => _period = p),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('평균 피로도',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
              const SizedBox(width: 12),
              Text(
                _avg(_series).toStringAsFixed(0),
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 6),
              const Text('점', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          _ChartCard(width: w, series: _series, labels: _xLabels),
          const SizedBox(height: 16),
          _SummaryRow(
            bestLabel: '가장 편안했던 날',
            bestValue: _maxPoint.value.toInt(),
            bestWhen: _xLabels[_maxPoint.index],
            worstLabel: '가장 피로했던 날',
            worstValue: _minPoint.value.toInt(),
            worstWhen: _xLabels[_minPoint.index],
          ),
          const SizedBox(height: 24),
          const Divider(thickness: 10, color: Color(0xFFF3F3F3)),
          const SizedBox(height: 16),
          const Text('이전 진단 기록 요약',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _RecordItem(
            dateText: '2025년 4월 1일',
            score: 65,
            onTapRecord: () => Navigator.pushNamed(context, '/analysis'),
          ),
          const SizedBox(height: 10),
          _RecordItem(
            dateText: '2025년 3월 31일',
            score: 43,
            onTapRecord: () => Navigator.pushNamed(context, '/analysis'),
          ),
          const SizedBox(height: 10),
          _RecordItem(
            dateText: '2025년 3월 30일',
            score: 65,
            onTapRecord: () => Navigator.pushNamed(context, '/analysis'),
          ),
        ],
      ),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  final Period period;
  final ValueChanged<Period> onChanged;
  const _PeriodSelector({required this.period, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const items = {
      Period.daily: '일간',
      Period.weekly: '주간',
      Period.monthly: '월간',
    };
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6FF),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(6),
      child: Row(
        children: items.entries.map((e) {
          final selected = period == e.key;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(e.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFF5A6BFF) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  e.value,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : const Color(0xFF111111),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final double width;
  final List<FlSpot> series;
  final List<String> labels;
  const _ChartCard({required this.width, required this.series, required this.labels});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 260,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FF),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 100,
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i >= 0 && i < labels.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Text(
                        labels[i],
                        style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: series,
              isCurved: true,
              barWidth: 3,
              color: const Color(0xFF5A6BFF),
              dotData: FlDotData(
                show: true,
                getDotPainter: (s, p, b, i) => FlDotCirclePainter(
                  radius: 4,
                  color: const Color(0xFF5A6BFF),
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF5A6BFF).withOpacity(0.18),
                    const Color(0xFF5A6BFF).withOpacity(0.02),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String bestLabel;
  final int bestValue;
  final String bestWhen;
  final String worstLabel;
  final int worstValue;
  final String worstWhen;
  const _SummaryRow({
    required this.bestLabel,
    required this.bestValue,
    required this.bestWhen,
    required this.worstLabel,
    required this.worstValue,
    required this.worstWhen,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryTile(
            title: bestLabel, value: bestValue, sub: bestWhen,
            icon: Icons.trending_up_rounded, color: const Color(0xFF12B886),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryTile(
            title: worstLabel, value: worstValue, sub: worstWhen,
            icon: Icons.trending_down_rounded, color: const Color(0xFFFA5252),
          ),
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String title; final int value; final String sub;
  final IconData icon; final Color color;
  const _SummaryTile({required this.title, required this.value, required this.sub, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white, borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 8, offset: Offset(0, 4))],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(sub, style: TextStyle(color: Colors.grey[700])),
                ],
              ),
            ),
            Text('$value점', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _RecordItem extends StatelessWidget {
  final String dateText;
  final int score;
  final VoidCallback onTapRecord;
  const _RecordItem({required this.dateText, required this.score, required this.onTapRecord});

  String _statusOf(int v) {
    if (v >= 80) return '매우 좋음';
    if (v >= 60) return '양호';
    if (v >= 40) return '주의';
    return '위험';
  }

  @override
  Widget build(BuildContext context) {
    final status = _statusOf(score);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [BoxShadow(color: Color(0x3F656565), blurRadius: 5, offset: Offset(2, 1), spreadRadius: 1)],
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 24,
              backgroundColor: Color(0xFFEFF1FF),
              child: Icon(Icons.health_and_safety_outlined),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dateText,
                      style: const TextStyle(color: Color(0xFFBDB6B6), fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Text('눈 건강 테스트', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 6),
                      Text('($status, $score점)',
                          style: const TextStyle(color: Color(0xFF515151), fontSize: 16, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 32,
              child: ElevatedButton(
                onPressed: onTapRecord,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4548FF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: const Text('진단 기록',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
