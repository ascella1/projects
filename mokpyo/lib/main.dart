import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/home/presentation/views/home_screen.dart';
import 'features/quest/data/repositories/quest_repository_impl.dart';
import 'features/quest/presentation/providers/quest_provider.dart';

void main() {
  runApp(
    ProviderScope(
      overrides: [
        // 추상 Repository 정의에 실제 Mock 구현체를 바인딩(의존성 주입)
        questRepositoryProvider.overrideWith((ref) => QuestRepositoryImpl()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Life RPG',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF81C784), // 힐링 라이트 초록색
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system, // 시스템 테마 자동 매칭 (다크/라이트모드)
      home: const HomeScreen(),
    );
  }
}
