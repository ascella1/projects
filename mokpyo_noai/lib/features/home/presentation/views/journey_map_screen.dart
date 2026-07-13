import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/level_config_service.dart';
import '../../../quest/domain/entities/quest_entity.dart';
import '../../../quest/presentation/providers/quest_provider.dart';
import '../../../quest/presentation/providers/user_provider.dart';

// ============================================================
// 🎨 지도 디자인 커스터마이징
// 여정 지도의 생김새를 바꾸고 싶다면 이 블록의 상수/리스트만 고치면 된다.
// 화면 로직(위젯 빌드, 탭 처리 등)은 건드릴 필요 없음.
// 자세한 안내는 프로젝트 루트의 MAP_DESIGN.md 참고.
// ============================================================

// 배경 그라데이션: 하늘(대목표 근처) → 산 → 숲 → 초원(오늘의 실천 근처).
const List<Color> mapBackgroundColors = [
  Color(0xFFBBDEFB),
  Color(0xFFD1C4E9),
  Color(0xFFC8E6C9),
  Color(0xFFE8F5E9),
];
const List<double> mapBackgroundStops = [0.0, 0.32, 0.62, 1.0];

// 배경에 흩뿌리는 장식 이모지. top/bottom 중 하나, left/right 중 하나씩 지정.
class MapDecoration {
  final String emoji;
  final double fontSize;
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;

  const MapDecoration({
    required this.emoji,
    required this.fontSize,
    this.top,
    this.bottom,
    this.left,
    this.right,
  });
}

const List<MapDecoration> mapDecorations = [
  MapDecoration(emoji: '☁️', fontSize: 26, top: 16, left: 28),
  MapDecoration(emoji: '☁️', fontSize: 20, top: 46, right: 36),
  MapDecoration(emoji: '⛰️', fontSize: 32, top: 130, left: 50),
  MapDecoration(emoji: '⛰️', fontSize: 28, top: 138, right: 60),
  MapDecoration(emoji: '🌲', fontSize: 24, top: 250, left: 18),
  MapDecoration(emoji: '🌲', fontSize: 22, top: 290, right: 20),
  MapDecoration(emoji: '🌼', fontSize: 20, bottom: 26, left: 34),
  MapDecoration(emoji: '🌿', fontSize: 22, bottom: 46, right: 44),
];

// 오솔길(트레일) 스타일: 굵은 밑색 위에 점선을 겹쳐 흙길처럼 보이게 한다.
const Color trailBaseColor = Color(0xFFD9C9A3);
const Color trailDashColor = Color(0xFF8D6E4B);
const double trailBaseWidth = 10;
const double trailDashWidth = 3;
const double trailDashLength = 10;
const double trailGapLength = 8;

// 핀(노드) 배치: 세로 간격, 위아래 여백, 좌우 지그재그 패턴(-1=완전 왼쪽 ~ 1=완전 오른쪽).
const double nodeSpacing = 150;
const double topPadding = 50;
const double bottomPadding = 70;
const List<double> zigzagPattern = [0.0, 0.55, 0.0, -0.55];

// 목표 단계(tier)별 이모지/이름/핀 크기. depth: 1=대목표, 2=중목표, 3=소목표, 4=일일퀘스트.
const Map<int, String> tierEmoji = {1: '🏆', 2: '🥈', 3: '🥉', 4: '🌱'};
const Map<int, String> tierLabel = {
  1: '대목표',
  2: '중목표',
  3: '소목표',
  4: '일일 퀘스트',
};
const Map<int, double> tierPinSize = {1: 60, 2: 52, 3: 46, 4: 40};

// ============================================================

// 목표 트리를 리스트가 아니라 진짜 지도를 탐험하는 느낌으로 보여준다.
// 맨 위가 최종 목적지(🏆 대목표, 산 정상), 맨 아래가 오늘 당장 실천할
// 일일 퀘스트(🌱, 출발지)로, 좌우로 구불구불한 오솔길을 따라 올라간다.
// 잠금 해제된 퀘스트는 탭해서 바로 완료할 수도 있다.
class JourneyMapScreen extends ConsumerWidget {
  const JourneyMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questsAsync = ref.watch(questListProvider('g_active'));
    final userState = ref.watch(userProvider);
    final cfg = LevelConfigService.current;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('🗺️ 여정 지도',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
              SizedBox(height: 4),
              Text('맨 위 대목표를 향해 오솔길을 따라 한 걸음씩 나아가보세요.',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
        Expanded(
          child: questsAsync.when(
            data: (quests) {
              final ordered = [
                ...quests.where((q) => q.depth == 1),
                ...quests.where((q) => q.depth == 2),
                ...quests.where((q) => q.depth == 3),
                ...quests.where((q) => q.depth == 4),
              ];

              if (ordered.isEmpty) {
                return const Center(
                  child: Text('아직 등록된 목표가 없어요.',
                      style: TextStyle(color: AppColors.textSecondary)),
                );
              }

              final meta = ordered.map((q) {
                final requiredLevel =
                    q.depth == 4 ? 1 : (cfg.tierUnlockLevelByDepth[q.depth] ?? 1);
                final unlocked =
                    q.depth == 4 || userState.level >= requiredLevel;
                return (quest: q, unlocked: unlocked, requiredLevel: requiredLevel);
              }).toList();

              // "여기부터 시작" 표시: 오늘의 실천 목표(맨 아래) 쪽부터 훑어
              // 처음 만나는 미완료 항목을 다음 걸음으로 안내한다.
              final reversedIdx = meta.reversed.toList().indexWhere(
                  (m) => m.unlocked && m.quest.status != QuestStatus.completed);
              final currentIndex =
                  reversedIdx == -1 ? -1 : meta.length - 1 - reversedIdx;

              final totalHeight =
                  meta.length * nodeSpacing + topPadding + bottomPadding;

              return SingleChildScrollView(
                child: SizedBox(
                  height: totalHeight,
                  child: Stack(
                    children: [
                      const Positioned.fill(child: _MapBackground()),
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _TrailPainter(count: meta.length),
                        ),
                      ),
                      for (var i = 0; i < meta.length; i++)
                        Positioned(
                          top: topPadding + i * nodeSpacing,
                          left: 0,
                          right: 0,
                          child: Align(
                            alignment:
                                Alignment(zigzagPattern[i % zigzagPattern.length], 0),
                            child: _mapNode(
                              context,
                              ref,
                              meta[i].quest,
                              unlocked: meta[i].unlocked,
                              requiredLevel: meta[i].requiredLevel,
                              isCurrent: i == currentIndex,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
            loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary)),
            error: (err, _) => Center(child: Text('오류: $err')),
          ),
        ),
      ],
    );
  }

  Widget _mapNode(
    BuildContext context,
    WidgetRef ref,
    Quest quest, {
    required bool unlocked,
    required int requiredLevel,
    required bool isCurrent,
  }) {
    final color = AppColors.depthColors[quest.depth];
    final completed = quest.status == QuestStatus.completed;
    final emoji = tierEmoji[quest.depth]!;
    final label = tierLabel[quest.depth]!;
    final pinSize = tierPinSize[quest.depth]!;

    return GestureDetector(
      onTap: () =>
          _onNodeTap(context, ref, quest, unlocked, completed, requiredLevel),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isCurrent)
            Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.streakBadgeFg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('📍 여기부터!',
                  style: TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold)),
            ),
          Container(
            width: pinSize,
            height: pinSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: !unlocked
                  ? Colors.grey.withValues(alpha: 0.3)
                  : (completed ? color : Colors.white),
              border: Border.all(
                color: !unlocked ? Colors.grey.withValues(alpha: 0.5) : color,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 2)),
              ],
            ),
            child: !unlocked
                ? Icon(Icons.lock, size: pinSize * 0.4, color: Colors.grey)
                : completed
                    ? Icon(Icons.check, size: pinSize * 0.45, color: Colors.white)
                    : Text(emoji, style: TextStyle(fontSize: pinSize * 0.42)),
          ),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 122),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: unlocked ? 0.95 : 0.6),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    quest.title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: !unlocked ? Colors.grey : AppColors.textPrimary,
                      decoration: completed ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (!unlocked)
                    Text('Lv.$requiredLevel 해금',
                        style: const TextStyle(fontSize: 9, color: Colors.grey))
                  else if (!completed)
                    Text('$label · EXP +${quest.rewardExp}',
                        style: TextStyle(
                            fontSize: 9,
                            color: color,
                            fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onNodeTap(
    BuildContext context,
    WidgetRef ref,
    Quest quest,
    bool unlocked,
    bool completed,
    int requiredLevel,
  ) async {
    if (!unlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lv.$requiredLevel에 해금돼요! 조금만 더 성장해봐요.')),
      );
      return;
    }
    if (completed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이미 완료한 퀘스트예요!')),
      );
      return;
    }

    final levelBefore = ref.read(userProvider).level;
    final levelsGained = await ref
        .read(questListProvider('g_active').notifier)
        .completeQuest(quest.id);
    if (!context.mounted) return;

    if (levelsGained > 0) {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.levelUpBg,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🌟', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 8),
              Text('LEVEL UP! Lv.${levelBefore + levelsGained}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.levelUpBg),
                child: const Text('계속하기'),
              ),
            ],
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ "${quest.title}" 완료! EXP +${quest.rewardExp}')),
      );
    }
  }
}

// 하늘 → 산 → 숲 → 초원으로 이어지는 배경과, mapDecorations 리스트에 정의된
// 장식용 지형 이모지로 실제 지도 같은 분위기를 낸다. 배경을 이미지로 바꾸고
// 싶다면 이 위젯의 Container만 Image.asset으로 교체하면 된다 (MAP_DESIGN.md 참고).
class _MapBackground extends StatelessWidget {
  const _MapBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: mapBackgroundColors,
              stops: mapBackgroundStops,
            ),
          ),
        ),
        for (final d in mapDecorations)
          Positioned(
            top: d.top,
            bottom: d.bottom,
            left: d.left,
            right: d.right,
            child: Text(d.emoji, style: TextStyle(fontSize: d.fontSize)),
          ),
      ],
    );
  }
}

// 지그재그로 놓인 핀들을 잇는, 흙길처럼 보이는 점선 오솔길을 그린다.
class _TrailPainter extends CustomPainter {
  final int count;
  const _TrailPainter({required this.count});

  @override
  void paint(Canvas canvas, Size size) {
    if (count < 2) return;
    const margin = 54.0;
    final points = List.generate(count, (i) {
      final x = size.width / 2 +
          zigzagPattern[i % zigzagPattern.length] * (size.width / 2 - margin);
      final y = topPadding + i * nodeSpacing + 27;
      return Offset(x, y);
    });

    final basePaint = Paint()
      ..color = trailBaseColor
      ..strokeWidth = trailBaseWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final dashPaint = Paint()
      ..color = trailDashColor
      ..strokeWidth = trailDashWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], basePaint);
    }
    for (var i = 0; i < points.length - 1; i++) {
      _drawDashed(canvas, points[i], points[i + 1], dashPaint);
    }
  }

  void _drawDashed(Canvas canvas, Offset a, Offset b, Paint paint) {
    final total = (b - a).distance;
    if (total == 0) return;
    final dir = (b - a) / total;
    var covered = 0.0;
    while (covered < total) {
      final start = a + dir * covered;
      final end = a + dir * math.min(covered + trailDashLength, total);
      canvas.drawLine(start, end, paint);
      covered += trailDashLength + trailGapLength;
    }
  }

  @override
  bool shouldRepaint(covariant _TrailPainter oldDelegate) =>
      oldDelegate.count != count;
}
