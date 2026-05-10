import 'package:flutter/material.dart';
import 'recipe_page.dart';
import 'board_page.dart';
import 'ranking_page.dart';
import 'settings_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      // 탭 개수
      length: 4,

      child: Scaffold(
        appBar: AppBar(
          title: const Text('AI 요리 레시피'),

          bottom: const TabBar(
            isScrollable: true,

            tabs: [
              Tab(text: '레시피 검색'),
              Tab(text: '요리 레시피 게시글'),
              Tab(text: '랭킹'),
              Tab(text: '설정'),
            ],
          ),
        ),

        body: const TabBarView(
          children: [
            RecipePage(),
            BoardPage(),
            RankingPage(),
            SettingsPage(),
          ],
        ),
      ),
    );
  }
}