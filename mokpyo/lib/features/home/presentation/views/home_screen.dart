import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../quest/domain/entities/quest_entity.dart';
import '../../../quest/presentation/providers/quest_provider.dart';
import '../../../quest/presentation/providers/user_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _currentTab = 0;

  // 온보딩 상태
  int _onboardingStep = 0;
  String _selectedCharacter = 'fox';
  final TextEditingController _goalController = TextEditingController();
  bool _isGenerating = false;
  List<String> _tempRecommendedStats = [];
  // AI가 생성한 일일 목표 미리보기(편집 가능) + 나머지(중/소/대목표, 편집 불가)
  final List<Quest> _previewDailyQuests = [];
  final List<TextEditingController> _dailyControllers = [];
  List<Quest> _nonDailyQuests = [];
  int _dailyQuestSeq = 0;

  // 상자 오픈 애니메이션
  bool _isOpeningBox = false;
  late AnimationController _boxAnimController;

  // 전체 악세사리 목록 (18개)
  final List<Map<String, String>> _accessories = [
    {'id': 'crown', 'name': '👑 전설의 왕관', 'desc': '모든 동물의 부러움을 삽니다.'},
    {'id': 'sunglasses', 'name': '🕶️ 멋쟁이 선글라스', 'desc': '햇살 가득한 정원 필수품.'},
    {'id': 'headset', 'name': '🎧 게이밍 헤드셋', 'desc': '비트를 느끼며 목표를 달성하세요.'},
    {'id': 'scarf', 'name': '🧣 루돌프 목도리', 'desc': '정원의 겨울을 따뜻하게.'},
    {'id': 'wizard_hat', 'name': '🎩 마술사 모자', 'desc': '신비한 기운이 솟아납니다.'},
    {'id': 'ribbon', 'name': '🎀 핑크 리본', 'desc': '너무 사랑스러운 리본.'},
    {'id': 'backpack', 'name': '🎒 모험가 가방', 'desc': '퀘스트 하러 갈 때 필수 가방.'},
    {'id': 'clover', 'name': '🍀 행운의 네잎클로버', 'desc': '지니고만 있어도 대박 납니다.'},
    {'id': 'graduation_cap', 'name': '🎓 졸업 모자', 'desc': '지식의 정점에 오른 증거.'},
    {'id': 'sakura_crown', 'name': '🌸 벚꽃 화관', 'desc': '봄바람처럼 사랑받는 아이.'},
    {'id': 'straw_hat', 'name': '👒 여름 밀짚모자', 'desc': '따사로운 햇살이 함께합니다.'},
    {'id': 'cape', 'name': '🦸 슈퍼히어로 망토', 'desc': '오늘의 히어로는 바로 당신!'},
    {'id': 'diamond', 'name': '💎 다이아 목걸이', 'desc': '빛나는 성과를 기념하세요.'},
    {'id': 'mushroom', 'name': '🍄 버섯 모자', 'desc': '숲 속 정원의 요정 같아요.'},
    {'id': 'star_wand', 'name': '⭐ 별빛 지팡이', 'desc': '소원을 이루어주는 마법봉.'},
    {'id': 'beret', 'name': '🎨 아티스트 베레', 'desc': '삶을 예술로 만드는 당신.'},
    {'id': 'monocle', 'name': '🧐 탐정 돋보기', 'desc': '목표를 날카롭게 분석합니다.'},
    {'id': 'rocket', 'name': '🚀 우주 헬멧', 'desc': '별을 향해 쏘아 올려라!'},
  ];

  @override
  void initState() {
    super.initState();
    _boxAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
  }

  @override
  void dispose() {
    _goalController.dispose();
    _boxAnimController.dispose();
    for (final c in _dailyControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _clearDailyPreview() {
    for (final c in _dailyControllers) {
      c.dispose();
    }
    _dailyControllers.clear();
    _previewDailyQuests.clear();
  }

  void _addDailyPreviewQuest(Quest quest) {
    _previewDailyQuests.add(quest);
    _dailyControllers.add(TextEditingController(text: quest.title));
  }

  void _removeDailyPreviewAt(int index) {
    _dailyControllers[index].dispose();
    _dailyControllers.removeAt(index);
    _previewDailyQuests.removeAt(index);
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);

    // 7일 연속 접속 보상 & 레벨업은 각 이벤트에서 직접 처리
    ref.listen<UserState>(userProvider, (prev, next) {
      if (next.pendingStreakReward &&
          !(prev?.pendingStreakReward ?? false)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _showStreakRewardDialog();
          ref.read(userProvider.notifier).clearPendingStreakReward();
        });
      }

      // 레벨 10/20 도달 시 중목표/대목표 해금 알림 (소목표는 Lv.5)
      final prevLevel = prev?.level ?? 1;
      final unlocked = <String>[];
      if (prevLevel < 5 && next.level >= 5) unlocked.add('🥉 소목표');
      if (prevLevel < 10 && next.level >= 10) unlocked.add('🥈 중목표');
      if (prevLevel < 20 && next.level >= 20) unlocked.add('🏆 대목표');
      if (unlocked.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _showTierUnlockDialog(unlocked);
        });
      }
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE8F5E9), Color(0xFFFFF3E0)],
          ),
        ),
        child: SafeArea(
          child: userState.hasCompletedOnboarding
              ? _buildMainApp(userState)
              : _buildOnboarding(),
        ),
      ),
      bottomNavigationBar: userState.hasCompletedOnboarding
          ? BottomNavigationBar(
              currentIndex: _currentTab,
              selectedItemColor: const Color(0xFF2E7D32),
              unselectedItemColor: Colors.grey,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              elevation: 8,
              onTap: (i) => setState(() => _currentTab = i),
              items: const [
                BottomNavigationBarItem(
                    icon: Icon(Icons.yard), label: '나의 정원'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.card_giftcard), label: '상자 오픈'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.backpack), label: '인벤토리'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.emoji_events), label: '업적 & 스탯'),
              ],
            )
          : null,
    );
  }

  // ===================== 온보딩 =====================

  Widget _buildOnboarding() {
    if (_isGenerating) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🌱', style: TextStyle(fontSize: 64)),
            SizedBox(height: 24),
            CircularProgressIndicator(color: Color(0xFF2E7D32)),
            SizedBox(height: 20),
            Text(
              'AI 정원사가 퀘스트를 설계하고 있습니다...',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3E2723)),
            ),
            SizedBox(height: 8),
            Text(
              '목표를 수십 개의 퀘스트로 분해 중이에요.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }
    switch (_onboardingStep) {
      case 0:
        return _buildStepChooseCharacter();
      case 1:
        return _buildStepEnterGoal();
      case 2:
        return _buildStepAiRecommendation();
      default:
        return const SizedBox();
    }
  }

  Widget _buildStepChooseCharacter() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Text(
            '반가워요! 현실을 가꾸는 RPG 정원입니다.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            '함께 정원을 가꿀\n동물 친구를 골라주세요!',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3E2723)),
          ),
          const SizedBox(height: 36),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.1,
            children: [
              _characterCard('cat', '🐱', '귀여운 고양이'),
              _characterCard('dog', '🐶', '듬직한 강아지'),
              _characterCard('rabbit', '🐰', '사랑스런 토끼'),
              _characterCard('fox', '🦊', '지혜로운 여우'),
            ],
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => setState(() => _onboardingStep = 1),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text('선택 완료',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _characterCard(String type, String emoji, String label) {
    final isSelected = _selectedCharacter == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedCharacter = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.45),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2E7D32)
                : Colors.transparent,
            width: 3,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: Colors.green.withOpacity(0.25),
                      blurRadius: 12,
                      spreadRadius: 2)
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 52)),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.bold)),
            if (isSelected) ...[
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('선택됨',
                    style: TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStepEnterGoal() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _characterEmoji(_selectedCharacter),
              style: const TextStyle(fontSize: 40),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '이루고 싶은 핵심 목표는\n무엇인가요?',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3E2723)),
          ),
          const SizedBox(height: 10),
          const Text(
            '예: 10억 모으기, 10kg 다이어트,\n플러터 앱 출시하기, 영어 회화 마스터\n\nAI가 목표를 수십 개의 단계로 분해합니다.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.6),
          ),
          const SizedBox(height: 30),
          TextField(
            controller: _goalController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: '목표를 자유롭게 입력해주세요...',
              hintStyle:
                  TextStyle(color: Colors.grey.withOpacity(0.7)),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(18),
            ),
          ),
          const SizedBox(height: 36),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _onboardingStep = 0),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text('이전으로'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_goalController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('목표를 입력해주세요!')),
                      );
                      return;
                    }
                    setState(() => _isGenerating = true);

                    final result = await ref
                        .read(questListProvider('g_active').notifier)
                        .generateAndSaveQuests(
                          goal: _goalController.text.trim(),
                          characterType: _selectedCharacter,
                        );

                    _clearDailyPreview();
                    for (final q in result.quests.where((q) => q.depth == 4)) {
                      _addDailyPreviewQuest(q);
                    }
                    _nonDailyQuests =
                        result.quests.where((q) => q.depth != 4).toList();

                    if (!mounted) return;
                    setState(() {
                      _tempRecommendedStats = result.stats;
                      _isGenerating = false;
                      _onboardingStep = 2;
                    });

                    if (result.aiError != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          duration: const Duration(seconds: 6),
                          content: Text(
                              'AI 생성 실패로 기본 퀘스트를 사용했어요.\n${result.aiError}'),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text('AI 목표 분석 시작',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepAiRecommendation() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Text('✨ 분석 완료 ✨',
              style: TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 8),
          const Text(
            'AI 정원사의 분석 결과!',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3E2723)),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10)
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🎯 핵심 목표',
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(
                  _goalController.text.trim(),
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3E2723)),
                ),
                const Divider(height: 28),
                const Text('📊 성장할 능력치',
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _tempRecommendedStats.map((stat) {
                    final info = _statInfo(stat);
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: info['color'] as Color,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${info['emoji']} ${info['label']}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.white),
                      ),
                    );
                  }).toList(),
                ),
                const Divider(height: 28),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '💡 AI 정원사가 목표를 대목표 → 중목표 → 소목표 → 일일 퀘스트 4단계로 분해했습니다. 정원에서 하루하루 실천해 보세요!',
                    style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF2E7D32),
                        height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildDailyQuestPreview(),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _onboardingStep = 1),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text('목표 수정'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () async {
                    final finalDaily = <Quest>[];
                    for (var i = 0; i < _previewDailyQuests.length; i++) {
                      final title = _dailyControllers[i].text.trim();
                      if (title.isEmpty) continue;
                      finalDaily.add(
                          _previewDailyQuests[i].copyWith(title: title));
                    }
                    if (finalDaily.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('일일 목표를 최소 1개 이상 남겨주세요!')),
                      );
                      return;
                    }

                    await ref
                        .read(questListProvider('g_active').notifier)
                        .replaceQuests([...finalDaily, ..._nonDailyQuests]);

                    await ref.read(userProvider.notifier).completeOnboarding(
                          characterType: _selectedCharacter,
                          goal: _goalController.text.trim(),
                          recommendedStats: _tempRecommendedStats,
                        );
                    if (!mounted) return;
                    setState(() => _currentTab = 0);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text('목표 수락 및 시작!',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDailyQuestPreview() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('🌱 일일 목표 미리보기 (${_previewDailyQuests.length}개)',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3E2723))),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _addDailyPreviewQuest(Quest(
                      id: 'q_custom_${_dailyQuestSeq++}',
                      goalId: 'g_active',
                      title: '',
                      depth: 4,
                      status: QuestStatus.todo,
                      difficulty: QuestDifficulty.easy,
                      rewardExp: 10,
                      rewardStats: _tempRecommendedStats.isEmpty
                          ? ['career']
                          : _tempRecommendedStats,
                      dueDate: DateTime.now().add(const Duration(days: 1)),
                    ));
                  });
                },
                icon: const Icon(Icons.add, size: 16),
                label: const Text('직접 추가'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            '마음에 들지 않는 항목은 직접 수정하거나 삭제하고, 새 목표를 추가할 수 있어요.',
            style: TextStyle(fontSize: 11, color: Colors.grey, height: 1.4),
          ),
          const SizedBox(height: 10),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _previewDailyQuests.length,
            itemBuilder: (ctx, i) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _dailyControllers[i],
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          isDense: true,
                          filled: true,
                          fillColor: const Color(0xFFF9F9F9),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          hintText: '일일 목표를 입력하세요',
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () =>
                          setState(() => _removeDailyPreviewAt(i)),
                      icon: const Icon(Icons.close, size: 18),
                      color: Colors.grey,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ===================== 메인 앱 =====================

  Widget _buildMainApp(UserState userState) {
    switch (_currentTab) {
      case 0:
        return _buildTabGarden(userState);
      case 1:
        return _buildTabLootBox(userState);
      case 2:
        return _buildTabInventory(userState);
      case 3:
        return _buildTabAchievements(userState);
      default:
        return const SizedBox();
    }
  }

  // -------------------- 탭 0: 나의 정원 --------------------

  Widget _buildTabGarden(UserState userState) {
    final questsAsync = ref.watch(questListProvider('g_active'));

    final charEmoji = _characterEmoji(userState.characterType);
    final speechBubble = _characterSpeech(userState.characterType);

    String? accessoryEmoji;
    if (userState.equippedAccessory != null) {
      final acc = _accessories.firstWhere(
          (e) => e['id'] == userState.equippedAccessory,
          orElse: () => {});
      if (acc.isNotEmpty) accessoryEmoji = acc['name']!.split(' ')[0];
    }

    return Column(
      children: [
        // 상단 유저 정보 카드
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
          child: Card(
            color: Colors.white.withOpacity(0.92),
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 유저 정보
                      Expanded(
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: const Color(0xFFC8E6C9),
                              child: Text(charEmoji,
                                  style: const TextStyle(fontSize: 22)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Lv.${userState.level} 정원사',
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF3E2723)),
                                  ),
                                  Text(
                                    userState.goal,
                                    style: const TextStyle(
                                        fontSize: 11, color: Colors.grey),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 상자 수 + 스트릭
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _badge('🎁 상자 ${userState.boxesCount}개',
                              const Color(0xFFFFECEB),
                              const Color(0xFFD84315)),
                          const SizedBox(height: 4),
                          _badge(
                              '🔥 ${userState.currentStreak}일 연속',
                              const Color(0xFFFFF8E1),
                              const Color(0xFFE65100)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // EXP 바
                  Row(
                    children: [
                      const Text('EXP',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: userState.exp / 100.0,
                            backgroundColor:
                                Colors.grey.withOpacity(0.15),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF81C784)),
                            minHeight: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${userState.exp}/100',
                          style: const TextStyle(
                              fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                  // 7일 연속 접속 진행 바
                  const SizedBox(height: 10),
                  Row(
                    children: List.generate(7, (i) {
                      final filled = i < userState.currentStreak;
                      return Expanded(
                        child: Container(
                          height: 5,
                          margin: const EdgeInsets.symmetric(horizontal: 1.5),
                          decoration: BoxDecoration(
                            color: filled
                                ? const Color(0xFFE65100)
                                : Colors.grey.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '7일 연속 접속 달성 시 상자 3개 보상!',
                    style: TextStyle(fontSize: 9, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),

        // 캐릭터 뷰
        Expanded(
          flex: 4,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.35),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.white.withOpacity(0.55),
                        blurRadius: 45,
                        spreadRadius: 12)
                  ],
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Text(charEmoji,
                          style: const TextStyle(fontSize: 96)),
                      if (accessoryEmoji != null)
                        Positioned(
                          top: -34,
                          child: Text(accessoryEmoji,
                              style: const TextStyle(fontSize: 50)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.82),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 6)
                      ],
                    ),
                    child: Text(
                      speechBubble,
                      style: const TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFF5D4037)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 퀘스트 패널
        Expanded(
          flex: 5,
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
              boxShadow: [
                BoxShadow(
                    color: Colors.black12,
                    blurRadius: 16,
                    offset: Offset(0, -5))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: questsAsync.when(
                    data: (quests) {
                      final tiers = [
                        (
                          depth: 4,
                          title: '🌱 오늘의 실천 목표',
                          unlocked: true,
                        ),
                        (
                          depth: 3,
                          title: '🥉 소목표 (Lv.5 해금)',
                          unlocked: userState.level >= 5,
                        ),
                        (
                          depth: 2,
                          title: '🥈 중목표 (Lv.10 해금)',
                          unlocked: userState.level >= 10,
                        ),
                        (
                          depth: 1,
                          title: '🏆 대목표 (Lv.20 해금)',
                          unlocked: userState.level >= 20,
                        ),
                      ];

                      final sections = <Widget>[];
                      for (final tier in tiers) {
                        if (!tier.unlocked) continue;
                        final items = quests
                            .where((q) => q.depth == tier.depth)
                            .toList();
                        if (items.isEmpty) continue;
                        sections.add(_questSectionHeader(tier.title));
                        sections.addAll(items.map(_questTile));
                      }

                      if (sections.isEmpty) {
                        return const Center(
                          child: Text(
                            '🎉 오늘의 퀘스트를 전부 달성했습니다!\n내일 새로운 목표가 찾아옵니다.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.grey, height: 1.5),
                          ),
                        );
                      }
                      return ListView(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
                        children: sections,
                      );
                    },
                    loading: () => const Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFF2E7D32))),
                    error: (err, _) =>
                        Center(child: Text('오류: $err')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // -------------------- 탭 1: 상자 오픈 --------------------

  Widget _buildTabLootBox(UserState userState) {
    return Padding(
      padding: const EdgeInsets.all(28.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('보물 보관소',
              style: TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 8),
          const Text(
            '퀘스트를 완료하고\n획득한 상자를 열어보세요!',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3E2723)),
          ),
          const SizedBox(height: 40),
          AnimatedBuilder(
            animation: _boxAnimController,
            builder: (context, child) {
              final shake = sin(_boxAnimController.value * 2 * pi * 5) *
                  12 *
                  (1.0 - _boxAnimController.value);
              final scale = 1.0 +
                  sin(_boxAnimController.value * pi) *
                      0.15 *
                      (1.0 - _boxAnimController.value);
              return Transform.translate(
                offset: Offset(shake, 0),
                child: Transform.scale(
                  scale: scale,
                  child: const Text('📦',
                      style: TextStyle(fontSize: 120)),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          Text(
            '보유 상자: ${userState.boxesCount}개',
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32)),
          ),
          const SizedBox(height: 8),
          Text(
            '인벤토리: ${userState.inventory.length}/${_accessories.length} 수집',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 36),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (userState.boxesCount <= 0 || _isOpeningBox)
                  ? null
                  : () async {
                      setState(() => _isOpeningBox = true);
                      await _boxAnimController.forward(from: 0.0);

                      final random = Random();
                      final item =
                          _accessories[random.nextInt(_accessories.length)];
                      final success = await ref
                          .read(userProvider.notifier)
                          .openBox(item['id']!);

                      setState(() => _isOpeningBox = false);
                      if (success && mounted) {
                        _showItemAcquiredDialog(item);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
                elevation: 4,
              ),
              child: _isOpeningBox
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('✨ 상자 열기',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
            ),
          ),
          const SizedBox(height: 14),
          if (userState.boxesCount <= 0)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                '🌱 일일 퀘스트를 완료하면 상자를 얻을 수 있어요!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }

  // -------------------- 탭 2: 인벤토리 --------------------

  Widget _buildTabInventory(UserState userState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('🎒 가방 (인벤토리)',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3E2723))),
              SizedBox(height: 4),
              Text('악세사리를 탭해서 캐릭터에게 장착시켜 주세요.',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.82,
            ),
            itemCount: _accessories.length,
            itemBuilder: (context, index) {
              final item = _accessories[index];
              final id = item['id']!;
              final name = item['name']!;
              final isOwned = userState.inventory.contains(id);
              final isEquipped = userState.equippedAccessory == id;

              return GestureDetector(
                onTap: !isOwned
                    ? null
                    : () {
                        if (isEquipped) {
                          ref
                              .read(userProvider.notifier)
                              .equipAccessory(null);
                        } else {
                          ref
                              .read(userProvider.notifier)
                              .equipAccessory(id);
                        }
                      },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isOwned
                        ? Colors.white
                        : Colors.grey.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isEquipped
                          ? const Color(0xFF2E7D32)
                          : Colors.transparent,
                      width: 2.5,
                    ),
                    boxShadow: isOwned
                        ? [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 6)
                          ]
                        : [],
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              name.split(' ')[0],
                              style: TextStyle(
                                fontSize: 36,
                                color: isOwned ? null : Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              name.substring(name.indexOf(' ') + 1),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isOwned
                                    ? const Color(0xFF3E2723)
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isOwned)
                        const Positioned(
                          top: 8,
                          right: 8,
                          child: Icon(Icons.lock_outline,
                              size: 14, color: Colors.grey),
                        ),
                      if (isEquipped)
                        Positioned(
                          top: 6,
                          left: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2E7D32),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('장착',
                                style: TextStyle(
                                    fontSize: 8,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // -------------------- 탭 3: 업적 & 스탯 --------------------

  Widget _buildTabAchievements(UserState userState) {
    final questsAsync = ref.watch(questListProvider('g_active'));

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('🏆 성장 현황',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3E2723))),
              IconButton(
                onPressed: _showResetConfirmDialog,
                tooltip: '데이터 초기화',
                icon: const Icon(Icons.refresh,
                    size: 20, color: Colors.redAccent),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 전체 레벨 & 수집 현황
          Row(
            children: [
              Expanded(
                child: _summaryCard(
                    '⭐ 전체 레벨', 'Lv.${userState.level}',
                    const Color(0xFFE8F5E9)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _summaryCard(
                    '🔥 연속 접속',
                    '${userState.currentStreak}일',
                    const Color(0xFFFFF8E1)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _summaryCard(
                    '🎒 수집 아이템',
                    '${userState.inventory.length}/${_accessories.length}',
                    const Color(0xFFE8EAF6)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 능력치 카드
          Card(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('능력치 레벨',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3E2723))),
                  const SizedBox(height: 14),
                  _statRow('📚 지식',
                      userState.statLevels['knowledge'] ?? 0,
                      const Color(0xFF1E88E5)),
                  const SizedBox(height: 10),
                  _statRow('💼 커리어',
                      userState.statLevels['career'] ?? 0,
                      const Color(0xFF43A047)),
                  const SizedBox(height: 10),
                  _statRow('💪 체력',
                      userState.statLevels['health'] ?? 0,
                      const Color(0xFFE53935)),
                  const SizedBox(height: 10),
                  _statRow('💰 자산',
                      userState.statLevels['money'] ?? 0,
                      const Color(0xFFFFB300)),
                  const SizedBox(height: 10),
                  _statRow('💬 소통',
                      userState.statLevels['communication'] ?? 0,
                      const Color(0xFF8E24AA)),
                  const SizedBox(height: 8),
                  const Text(
                    '퀘스트 완료 시 해당 능력치 레벨이 1씩 오릅니다.',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 완료 퀘스트 히스토리
          const Text('달성 기록',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3E2723))),
          const SizedBox(height: 8),
          questsAsync.when(
            data: (quests) {
              final completed = quests
                  .where((q) => q.status == QuestStatus.completed)
                  .toList();
              if (completed.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      '아직 완료한 퀘스트가 없습니다.\n정원에서 일일 퀘스트를 체크해보세요!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                );
              }
              return Column(
                children: completed.map((quest) {
                  final depthLabel =
                      ['', '대목표', '중목표', '소목표', '일일 퀘스트'][quest.depth];
                  final depthColor = [
                    Colors.grey,
                    Colors.deepPurple,
                    Colors.indigo,
                    Colors.teal,
                    Colors.green
                  ][quest.depth];
                  return Card(
                    color: Colors.white,
                    elevation: 0,
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      dense: true,
                      leading: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: depthColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(depthLabel,
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: depthColor)),
                      ),
                      title: Text(quest.title,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3E2723))),
                      trailing: const Icon(Icons.check_circle,
                          color: Colors.green, size: 18),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (err, _) =>
                Center(child: Text('달성 내역 오류: $err')),
          ),
        ],
      ),
    );
  }

  // ===================== 다이얼로그 =====================

  void _showSuccessRewardDialog(
    Quest quest, {
    required int levelBefore,
    required int levelsGained,
  }) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('🎉 퀘스트 달성!',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '"오늘 하루도 멋지게 정원을 가꾸었군요!"',
              style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _rewardItem('⭐', 'EXP +${quest.rewardExp}',
                      const Color(0xFF2E7D32)),
                  Container(
                      width: 1, height: 36, color: Colors.grey.withOpacity(0.3)),
                  _rewardItem('📦', '랜덤 상자 1개',
                      const Color(0xFFE65100)),
                ],
              ),
            ),
            if (levelsGained > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🌟', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text(
                      'LEVEL UP! Lv.${levelBefore + levelsGained}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE65100),
                          fontSize: 15),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                if (levelsGained > 0 && mounted) {
                  _showLevelUpDialog(
                      levelBefore + levelsGained, levelsGained);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 12),
              ),
              child: const Text('수락하기',
                  style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  void _showLevelUpDialog(int newLevel, int levelsGained) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1B5E20),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🌟', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 12),
            const Text(
              'LEVEL UP!',
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2),
            ),
            const SizedBox(height: 8),
            Text(
              'Lv.$newLevel 달성!',
              style: const TextStyle(
                  fontSize: 18, color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                '"한 걸음씩 나아가는 당신,\n이미 충분히 멋집니다."',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white70,
                    fontStyle: FontStyle.italic,
                    height: 1.5),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1B5E20),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 36, vertical: 12),
              ),
              child: const Text('계속하기',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showStreakRewardDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('🔥 7일 연속 접속!',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Color(0xFFE65100))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎊', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 12),
            const Text(
              '7일 동안 꾸준히 정원을 가꿔줬군요!\n특별 상자 3개를 드립니다.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, height: 1.5),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text('📦', style: TextStyle(fontSize: 28)),
                  Text('📦', style: TextStyle(fontSize: 28)),
                  Text('📦', style: TextStyle(fontSize: 28)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE65100),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 12),
              ),
              child: const Text('감사합니다!',
                  style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  void _showTierUnlockDialog(List<String> unlockedTiers) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('🔓 새로운 목표 해금!',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🌟', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 12),
            Text(
              '${unlockedTiers.join(', ')}가(이) 정원에 나타났어요!\n오늘의 실천 목표 아래에서 확인해보세요.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, height: 1.5),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 12),
              ),
              child: const Text('확인했어요!',
                  style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  void _showItemAcquiredDialog(Map<String, String> item) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('✨ 아이템 획득! ✨',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Color(0xFFE65100))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(item['name']!.split(' ')[0],
                style: const TextStyle(fontSize: 72)),
            const SizedBox(height: 10),
            Text(
              item['name']!.substring(item['name']!.indexOf(' ') + 1),
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3E2723)),
            ),
            const SizedBox(height: 8),
            Text(
              item['desc']!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                setState(() => _currentTab = 2);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
              ),
              child: const Text('인벤토리에서 장착하기',
                  style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  void _showResetConfirmDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('⚠️ 데이터 초기화'),
        content: const Text(
            '캐릭터, 목표, 퀘스트, 획득 아이템이 모두 삭제됩니다.\n정말 초기화하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(userProvider.notifier).resetAll();
              setState(() {
                _onboardingStep = 0;
                _goalController.clear();
                _selectedCharacter = 'fox';
                _currentTab = 0;
              });
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('초기화'),
          ),
        ],
      ),
    );
  }

  // ===================== 헬퍼 위젯 =====================

  Widget _questSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 14, 4, 6),
      child: Text(
        title,
        style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF3E2723)),
      ),
    );
  }

  Widget _questTile(Quest quest) {
    final isDone = quest.status == QuestStatus.completed;
    return Card(
      elevation: 0,
      color: isDone ? Colors.grey.withOpacity(0.05) : const Color(0xFFF9F9F9),
      margin: const EdgeInsets.symmetric(vertical: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Checkbox(
          value: isDone,
          activeColor: const Color(0xFF2E7D32),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          onChanged: isDone
              ? null
              : (val) async {
                  if (val != true || !mounted) return;
                  final levelBefore = ref.read(userProvider).level;
                  final levelsGained = await ref
                      .read(questListProvider('g_active').notifier)
                      .completeQuest(quest.id);
                  if (!mounted) return;
                  _showSuccessRewardDialog(
                    quest,
                    levelBefore: levelBefore,
                    levelsGained: levelsGained,
                  );
                },
        ),
        title: Text(
          quest.title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            decoration: isDone ? TextDecoration.lineThrough : null,
            color: isDone ? Colors.grey : const Color(0xFF3E2723),
          ),
        ),
        subtitle: Row(
          children: [
            _expChip('EXP +${quest.rewardExp}'),
            const SizedBox(width: 8),
            const Text('🎁 상자 1개',
                style: TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
      child: Text(text,
          style:
              TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg)),
    );
  }

  Widget _expChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(text,
          style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF2E7D32),
              fontWeight: FontWeight.bold)),
    );
  }

  Widget _summaryCard(String label, String value, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3E2723))),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _statRow(String name, int level, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(name,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: min(level / 20.0, 1.0),
              backgroundColor: Colors.grey.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 10,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 44,
          child: Text('Lv.$level',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color)),
        ),
      ],
    );
  }

  Widget _rewardItem(String emoji, String label, Color color) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 12)),
      ],
    );
  }

  // ===================== 유틸 =====================

  String _characterEmoji(String type) {
    switch (type) {
      case 'cat':
        return '🐱';
      case 'dog':
        return '🐶';
      case 'rabbit':
        return '🐰';
      default:
        return '🦊';
    }
  }

  String _characterSpeech(String type) {
    switch (type) {
      case 'cat':
        return '"야옹, 오늘도 한걸음 나아가볼까?"';
      case 'dog':
        return '"멍멍! 포기하지 말고 시작하자!"';
      case 'rabbit':
        return '"깡충깡충! 작은 발걸음이 큰 변화를 만들어요!"';
      default:
        return '"천천히, 씨앗을 심듯 실천해봐."';
    }
  }

  Map<String, dynamic> _statInfo(String stat) {
    switch (stat) {
      case 'knowledge':
        return {'emoji': '📚', 'label': '지식', 'color': const Color(0xFF1E88E5)};
      case 'career':
        return {'emoji': '💼', 'label': '커리어', 'color': const Color(0xFF43A047)};
      case 'health':
        return {'emoji': '💪', 'label': '체력', 'color': const Color(0xFFE53935)};
      case 'money':
        return {'emoji': '💰', 'label': '자산', 'color': const Color(0xFFFFB300)};
      case 'communication':
        return {'emoji': '💬', 'label': '소통', 'color': const Color(0xFF8E24AA)};
      default:
        return {'emoji': '🌱', 'label': stat, 'color': Colors.grey};
    }
  }
}
