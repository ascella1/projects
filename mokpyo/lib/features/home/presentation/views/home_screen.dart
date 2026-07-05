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

class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
  int _currentTab = 0;

  // 온보딩 전용 상태
  int _onboardingStep = 0; // 0: 캐릭터선택, 1: 목표입력, 2: 추천스탯/퀘스트 결과
  String _selectedCharacter = 'fox'; // 'cat', 'dog', 'fox'
  final TextEditingController _goalController = TextEditingController();
  bool _isGenerating = false;
  List<String> _tempRecommendedStats = [];
  String _tempGoalId = '';

  // 상자 오픈 애니메이션용 상태
  bool _isOpeningBox = false;
  String? _boxOpenedItem;
  late AnimationController _boxAnimController;

  // 전체 악세사리 목록 정의
  final List<Map<String, String>> _accessories = [
    {'id': 'crown', 'name': '👑 전설의 왕관', 'desc': '모든 동물의 부러움을 삽니다.'},
    {'id': 'sunglasses', 'name': '🕶️ 멋쟁이 선글라스', 'desc': '햇살 가득한 정원 필수품.'},
    {'id': 'headset', 'name': '🎧 게이밍 헤드셋', 'desc': '비트를 느끼며 목표를 달성하세요.'},
    {'id': 'scarf', 'name': '🧣 루돌프 목도리', 'desc': '정원의 겨울을 따뜻하게.'},
    {'id': 'wizard_hat', 'name': '🎩 마술사 모자', 'desc': '신비한 기운이 솟아납니다.'},
    {'id': 'ribbon', 'name': '🎀 핑크 리본', 'desc': '너무 사랑스러운 리본.'},
    {'id': 'backpack', 'name': '🎒 모험가 가방', 'desc': '퀘스트 하러 갈 때 필수 가방.'},
    {'id': 'clover', 'name': '🍀 행운의 네잎클로버', 'desc': '지니고만 있어도 대박 납니다.'},
  ];

  @override
  void initState() {
    super.initState();
    _boxAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _goalController.dispose();
    _boxAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE8F5E9), // 연한 그린 (파스텔톤 정원 분위기)
              Color(0xFFFFF3E0), // 연한 살구색
            ],
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
              onTap: (index) {
                setState(() {
                  _currentTab = index;
                });
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.yard),
                  label: '나의 정원',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.card_giftcard),
                  label: '상자 오픈',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.backpack),
                  label: '인벤토리',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.emoji_events),
                  label: '업적 & 스탯',
                ),
              ],
            )
          : null,
    );
  }

  // ==================== 온보딩 UI ====================
  Widget _buildOnboarding() {
    if (_isGenerating) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF2E7D32)),
            SizedBox(height: 20),
            Text(
              'AI 정원사가 퀘스트를 설계하고 있습니다...',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF3E2723)),
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

  // 온보딩 0단계: 캐릭터 선택
  Widget _buildStepChooseCharacter() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '반가워요! 현실을 가꾸는 RPG 정원입니다.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            '함께 정원을 가꿀 동물을 골라주세요!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF3E2723)),
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _characterCard('cat', '🐱', '귀여운 고양이'),
              _characterCard('dog', '🐶', '듬직한 강아지'),
              _characterCard('fox', '🦊', '지혜로운 여우'),
            ],
          ),
          const SizedBox(height: 50),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _onboardingStep = 1;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            child: const Text('선택 완료', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _characterCard(String type, String emoji, String label) {
    final isSelected = _selectedCharacter == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCharacter = type;
        });
      },
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF2E7D32) : Colors.transparent,
            width: 3,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.green.withOpacity(0.2), blurRadius: 10, spreadRadius: 2)]
              : [],
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 10),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // 온보딩 1단계: 목표 입력
  Widget _buildStepEnterGoal() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '목표 수립',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            '이루고 싶은 핵심 목표는 무엇인가요?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF3E2723)),
          ),
          const SizedBox(height: 10),
          const Text(
            '예: 하루 30분 운동하기, 플러터 앱 마스터하기 등\n거대한 목표도 AI가 아주 작게 쪼개어 드립니다.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 30),
          TextField(
            controller: _goalController,
            decoration: InputDecoration(
              hintText: '목표를 입력해주세요...',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(18),
            ),
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _onboardingStep = 0;
                  });
                },
                child: const Text('이전으로', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_goalController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('목표를 입력해주세요!')),
                    );
                    return;
                  }
                  setState(() {
                    _isGenerating = true;
                  });

                  // 가짜 또는 AI 퀘스트 트리 생성 시작
                  // goalId로 사용될 고유 값 획득을 위해 임의 세팅
                  final resultStats = await ref.read(questListProvider('g_active').notifier).generateAndSaveQuests(
                        goal: _goalController.text.trim(),
                        characterType: _selectedCharacter,
                      );

                  setState(() {
                    _tempRecommendedStats = resultStats;
                    _isGenerating = false;
                    _onboardingStep = 2;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text('AI 목표 분석 시작', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 온보딩 2단계: AI 추천 및 스탯 결과 확인
  Widget _buildStepAiRecommendation() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '분석 완료',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'AI 정원사의 분석 결과가 나왔습니다!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF3E2723)),
          ),
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🎯 핵심 대목표:', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                Text(_goalController.text.trim(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF3E2723))),
                const Divider(height: 30),
                const Text('📊 획득하게 될 추천 스탯 장르:', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  children: _tempRecommendedStats.map((stat) {
                    String label = stat.toUpperCase();
                    String emoji = '🌱';
                    if (stat == 'knowledge') {
                      label = '지식 (Knowledge)';
                      emoji = '📚';
                    } else if (stat == 'career') {
                      label = '커리어 (Career)';
                      emoji = '💼';
                    } else if (stat == 'health') {
                      label = '체력 (Health)';
                      emoji = '💪';
                    } else if (stat == 'money') {
                      label = '자산 (Money)';
                      emoji = '💰';
                    } else if (stat == 'communication') {
                      label = '소통 (Comm)';
                      emoji = '💬';
                    }
                    return Chip(
                      avatar: Text(emoji),
                      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
                      backgroundColor: Colors.white,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                const Text(
                  '💡 AI 정원사가 대목표를 3단계 하위 계획과 일일 퀘스트로 정밀하게 쪼개어 두었습니다. 정원에서 차근차근 시작해보세요!',
                  style: TextStyle(fontSize: 12, color: Color(0xFF5D4037)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _onboardingStep = 1;
                  });
                },
                child: const Text('목표 수정', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () async {
                  // 온보딩 완료 처리
                  await ref.read(userProvider.notifier).completeOnboarding(
                        characterType: _selectedCharacter,
                        goal: _goalController.text.trim(),
                        recommendedStats: _tempRecommendedStats,
                      );
                  
                  // g_temp에 임시 저장된 퀘스트 리포지토리를 다시 올바르게 동기화하기 위해
                  // 앱 전체 퀘스트를 fetch할 수도 있지만, provider를 re-fetch 시켜주기 위해 탭 0으로 초기화
                  setState(() {
                    _currentTab = 0;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text('목표 수락 및 시작', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== 메인 앱 UI (탭 분기) ====================
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

  // -------------------- 탭 1: 정원 (My Garden / 일일 퀘스트) --------------------
  Widget _buildTabGarden(UserState userState) {
    // 퀘스트 프로바이더로부터 전체 리스트 획득
    final questsAsync = ref.watch(questListProvider('g_active')); // g_active 또는 유동적 goalId

    // 캐릭터 이모지
    String charEmoji = '🦊';
    if (userState.characterType == 'cat') charEmoji = '🐱';
    if (userState.characterType == 'dog') charEmoji = '🐶';

    // 장착된 액세서리 이모지 획득
    String? accessoryEmoji;
    if (userState.equippedAccessory != null) {
      final acc = _accessories.firstWhere((element) => element['id'] == userState.equippedAccessory, orElse: () => {});
      if (acc.isNotEmpty) {
        accessoryEmoji = acc['name']!.split(' ')[0]; // 첫 단어 이모지 추출
      }
    }

    return Column(
      children: [
        // 상단 스탯 영역
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            color: Colors.white.withOpacity(0.9),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: Color(0xFFC8E6C9),
                            child: Icon(Icons.person, color: Color(0xFF2E7D32)),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Lv.${userState.level} 정원사',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF3E2723)),
                              ),
                              Text(
                                '목표: ${userState.goal}',
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFECEB),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          '🎁 상자 ${userState.boxesCount}개',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFD84315)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // 경험치바
                  Row(
                    children: [
                      const Text('EXP', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: userState.exp / 100,
                            backgroundColor: Colors.grey.withOpacity(0.2),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF81C784)),
                            minHeight: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${userState.exp}/100', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // 캐릭터 배치 영역 (장착 악세사리 포함)
        Expanded(
          flex: 4,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 뒤편의 힐링 오라 이펙트
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.4),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.white.withOpacity(0.6), blurRadius: 40, spreadRadius: 10),
                  ],
                ),
              ),
              // 캐릭터 몸통 및 머리
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      // 캐릭터 이모지
                      Text(charEmoji, style: const TextStyle(fontSize: 96)),
                      // 장착된 액세서리 오버레이 데코레이션
                      if (accessoryEmoji != null)
                        Positioned(
                          top: -30, // 머리 위에 모자나 왕관 장착
                          child: Text(
                            accessoryEmoji,
                            style: const TextStyle(fontSize: 48),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      userState.characterType == 'cat'
                          ? '“야옹, 오늘도 한걸음 나아가볼까?”'
                          : userState.characterType == 'dog'
                              ? '“멍멍! 포기하지 말고 시작하자!”'
                              : '“천천히, 씨앗을 심듯 실천해봐.”',
                      style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Color(0xFF5D4037)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 하단 퀘스트 영역 (depth 4: 일일 퀘스트만 표시, 거대 대목표나 차순위 중목표는 표시하지 않음!)
        Expanded(
          flex: 5,
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 15, offset: Offset(0, -5)),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '🌱 오늘의 실천 목표 (다음 단계)',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF3E2723)),
                        ),
                        Tooltip(
                          message: '부담을 낮추기 위해, 당장 오늘 완료할 소목표만 제공됩니다.',
                          child: Icon(Icons.info_outline, size: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: questsAsync.when(
                      data: (quests) {
                        // depth == 4인 말단 일일 퀘스트만 필터링 
                        final dailyQuests = quests.where((q) => q.depth == 4).toList();
                        
                        if (dailyQuests.isEmpty) {
                          return const Center(
                            child: Text(
                              '오늘의 실천 목표를 전부 달성했습니다! 👏\n내일 새로운 정원이 찾아옵니다.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: dailyQuests.length,
                          itemBuilder: (context, index) {
                            final quest = dailyQuests[index];
                            final isDone = quest.status == QuestStatus.completed;

                            return Card(
                              elevation: 0,
                              color: isDone ? Colors.grey.withOpacity(0.05) : const Color(0xFFF9F9F9),
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              child: ListTile(
                                leading: Checkbox(
                                  value: isDone,
                                  activeColor: const Color(0xFF2E7D32),
                                  onChanged: isDone
                                      ? null
                                      : (val) {
                                          if (val == true) {
                                            ref.read(questListProvider('g_active').notifier).completeQuest(quest.id);
                                            // 성공 팝업
                                            _showSuccessRewardDialog(quest);
                                          }
                                        },
                                ),
                                title: Text(
                                  quest.title,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    decoration: isDone ? TextDecoration.lineThrough : null,
                                    color: isDone ? Colors.grey : const Color(0xFF3E2723),
                                  ),
                                ),
                                subtitle: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE8F5E9),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Text(
                                        'EXP +${quest.rewardExp}',
                                        style: const TextStyle(fontSize: 10, color: Color(0xFF2E7D32), fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text('🎁 랜덤 상자 1개 지급', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32))),
                      error: (err, stack) => Center(child: Text('목표 로드 오류: $err')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 퀘스트 완료 보상 팝업
  void _showSuccessRewardDialog(Quest quest) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('🎉 퀘스트 달성!', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '“오늘 하루도 멋지게 정원을 가꾸었군요!”',
                style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.grey),
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
                    Column(
                      children: [
                        const Text('⭐️', style: TextStyle(fontSize: 24)),
                        const SizedBox(height: 5),
                        Text('EXP +${quest.rewardExp}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                      ],
                    ),
                    const VerticalDivider(),
                    const Column(
                      children: [
                        Text('📦', style: TextStyle(fontSize: 24)),
                        const SizedBox(height: 5),
                        Text('랜덤 상자 1개', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE65100))),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text('수락하기', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        );
      },
    );
  }

  // -------------------- 탭 2: 상자 오픈 (Loot Box) --------------------
  Widget _buildTabLootBox(UserState userState) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '보물 보관소',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            '목표를 실천하고 획득한 상자를 열어보세요!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF3E2723)),
          ),
          const SizedBox(height: 40),

          // 보물 상자 시각화 영역
          AnimatedBuilder(
            animation: _boxAnimController,
            builder: (context, child) {
              final shake = sin(_boxAnimController.value * 2 * pi * 4) * 10 * (1.0 - _boxAnimController.value);
              return Transform.translate(
                offset: Offset(shake, 0),
                child: Transform.rotate(
                  angle: shake / 100,
                  child: const Text('📦', style: TextStyle(fontSize: 120)),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          Text(
            '보유한 랜덤 상자: ${userState.boxesCount}개',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
          ),
          const SizedBox(height: 40),

          // 상자 오픈 버튼
          ElevatedButton(
            onPressed: (userState.boxesCount <= 0 || _isOpeningBox)
                ? null
                : () async {
                    setState(() {
                      _isOpeningBox = true;
                    });
                    
                    // 상자 흔들기 애니메이션 플레이
                    await _boxAnimController.forward(from: 0.0);

                    // 랜덤 악세사리 결정
                    final random = Random();
                    final item = _accessories[random.nextInt(_accessories.length)];

                    // 상태 업데이트 반영
                    final success = await ref.read(userProvider.notifier).openBox(item['id']!);

                    setState(() {
                      _isOpeningBox = false;
                    });

                    if (success) {
                      _showItemAcquiredDialog(item);
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              elevation: 3,
            ),
            child: _isOpeningBox
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text(
                    '상자 열기',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
          ),
          const SizedBox(height: 12),
          if (userState.boxesCount <= 0)
            const Text(
              '오늘의 실천 목표(일일 퀘스트)를 달성해 상자를 모아보세요!',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
        ],
      ),
    );
  }

  void _showItemAcquiredDialog(Map<String, String> item) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('✨ 아이템 획득! ✨', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE65100))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item['name']!.split(' ')[0], // 이모지
                style: const TextStyle(fontSize: 72),
              ),
              const SizedBox(height: 10),
              Text(
                item['name']!.substring(2), // 텍스트명
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF3E2723)),
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
                  Navigator.of(context).pop();
                  setState(() {
                    _currentTab = 2; // 인벤토리 탭으로 이동
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text('인벤토리에서 확인', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        );
      },
    );
  }

  // -------------------- 탭 3: 인벤토리 (Inventory) --------------------
  Widget _buildTabInventory(UserState userState) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🎒 가방 (인벤토리)',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF3E2723)),
                ),
                SizedBox(height: 4),
                Text(
                  '상자에서 모은 액세서리를 동물에게 장착시켜 주세요.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
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
                            // 장착 해제
                            ref.read(userProvider.notifier).equipAccessory(null);
                          } else {
                            // 장착
                            ref.read(userProvider.notifier).equipAccessory(id);
                          }
                        },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isOwned ? Colors.white : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isEquipped ? const Color(0xFF2E7D32) : Colors.transparent,
                        width: 2.5,
                      ),
                      boxShadow: isOwned
                          ? [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5)]
                          : [],
                    ),
                    child: Stack(
                      children: [
                        // 중앙 정보
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                name.split(' ')[0], // 이모지
                                style: TextStyle(
                                  fontSize: 48,
                                  color: isOwned ? null : Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                name.substring(2),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isOwned ? const Color(0xFF3E2723) : Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: Text(
                                  item['desc']!,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  style: const TextStyle(fontSize: 9, color: Colors.grey),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // 우측 상단 잠금 아이콘
                        if (!isOwned)
                          const Positioned(
                            top: 10,
                            right: 10,
                            child: Icon(Icons.lock_outline, size: 16, color: Colors.grey),
                          ),
                        // 장착 뱃지
                        if (isEquipped)
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2E7D32),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                '장착됨',
                                style: TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
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
      ),
    );
  }

  // -------------------- 탭 4: 업적 & 스탯 (Achieved & Stats) --------------------
  Widget _buildTabAchievements(UserState userState) {
    final questsAsync = ref.watch(questListProvider('g_active'));

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '🏆 내 업적 및 성장 현황',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF3E2723)),
              ),
              IconButton(
                onPressed: () {
                  // 리셋 다이얼로그
                  _showResetConfirmDialog();
                },
                tooltip: '데이터 초기화',
                icon: const Icon(Icons.refresh, size: 20, color: Colors.redAccent),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 스탯 시각화 (추천 스탯 위주)
          Card(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('능력치 레벨', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF3E2723))),
                  const SizedBox(height: 10),
                  _buildStatRow('📚 지식 (Knowledge)', userState.recommendedStats.contains('knowledge') ? userState.level * 1.5 : 2.0, const Color(0xFF1E88E5)),
                  const SizedBox(height: 8),
                  _buildStatRow('💼 커리어 (Career)', userState.recommendedStats.contains('career') ? userState.level * 2.0 : 3.0, const Color(0xFF43A047)),
                  const SizedBox(height: 8),
                  _buildStatRow('💪 체력 (Health)', userState.recommendedStats.contains('health') ? userState.level * 2.0 : 1.0, const Color(0xFFE53935)),
                  const SizedBox(height: 8),
                  _buildStatRow('💰 자산 (Money)', userState.recommendedStats.contains('money') ? userState.level * 2.5 : 1.5, const Color(0xFFFFB300)),
                  const SizedBox(height: 8),
                  _buildStatRow('💬 소통 (Comm)', userState.recommendedStats.contains('communication') ? userState.level * 1.8 : 2.5, const Color(0xFF8E24AA)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 15),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              '달성 궤적 (완료된 모든 목표)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF3E2723)),
            ),
          ),
          const SizedBox(height: 8),

          // 전체 완료된 목표 히스토리 리스트 (Timeline 대용)
          Expanded(
            child: questsAsync.when(
              data: (quests) {
                // 완료된 퀘스트만 정렬 (최근 완료 순)
                final completedQuests = quests.where((q) => q.status == QuestStatus.completed).toList();

                if (completedQuests.isEmpty) {
                  return const Center(
                    child: Text(
                      '아직 완료한 퀘스트가 없습니다.\n정원에서 일일 퀘스트를 체크해보세요!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: completedQuests.length,
                  itemBuilder: (context, index) {
                    final quest = completedQuests[index];
                    String levelLabel = '일일 퀘스트';
                    Color levelColor = Colors.green;
                    if (quest.depth == 1) {
                      levelLabel = '대목표';
                      levelColor = Colors.deepPurple;
                    } else if (quest.depth == 2) {
                      levelLabel = '중목표';
                      levelColor = Colors.indigo;
                    } else if (quest.depth == 3) {
                      levelLabel = '소목표';
                      levelColor = Colors.teal;
                    }

                    return Card(
                      color: Colors.white,
                      elevation: 0,
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: levelColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            levelLabel,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: levelColor),
                          ),
                        ),
                        title: Text(
                          quest.title,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF3E2723)),
                        ),
                        trailing: const Icon(Icons.check_circle, color: Colors.green, size: 20),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('달성 내역 로드 오류: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String name, double val, Color color) {
    return Row(
      children: [
        SizedBox(width: 120, child: Text(name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: min(val / 10.0, 1.0),
              backgroundColor: Colors.grey.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text('Lv.${val.toStringAsFixed(1)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
      ],
    );
  }

  void _showResetConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('⚠️ 데이터 초기화'),
          content: const Text('캐릭터, 목표, 퀘스트, 획득한 아이템이 모두 사라집니다. 정말 초기화하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await ref.read(userProvider.notifier).resetAll();
                setState(() {
                  _onboardingStep = 0;
                  _goalController.clear();
                  _selectedCharacter = 'fox';
                  _currentTab = 0;
                });
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('초기화 실행'),
            ),
          ],
        );
      },
    );
  }
}

