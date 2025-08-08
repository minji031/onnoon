import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/guide_screen.dart';
import 'screens/records_screen.dart';
import 'screens/analysis_screen.dart';

void main() => runApp(const OnNoonApp());

class OnNoonApp extends StatelessWidget {
  const OnNoonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'OnNoon',
      theme: ThemeData(useMaterial3: true, fontFamily: 'Inter'),
      initialRoute: '/', // 여기와 아래 routes의 키 문자열은 네 현재 값 그대로 유지!
      routes: {
        '/': (_) => const HomeScreen(),
        '/guide': (_) => const GuideScreen(),
        '/records': (_) => const RecordsScreen(),
        '/analysis': (_) => const AnalysisScreen(), // or AnalysisDetailScreen(args)
      },
    );
  }
}
