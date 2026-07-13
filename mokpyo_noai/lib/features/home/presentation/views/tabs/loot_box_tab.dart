import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/services/item_service.dart';
import '../../../../../core/utils/item_util.dart';
import '../../../../quest/presentation/providers/user_provider.dart';

// 탭 1: 상자 오픈 — 보유한 상자를 열어 랜덤 악세사리를 획득한다.
class LootBoxTab extends ConsumerStatefulWidget {
  const LootBoxTab({super.key, required this.onGoToInventory});

  // 아이템 획득 다이얼로그에서 "인벤토리에서 장착하기"를 눌렀을 때 호출된다.
  final VoidCallback onGoToInventory;

  @override
  ConsumerState<LootBoxTab> createState() => _LootBoxTabState();
}

class _LootBoxTabState extends ConsumerState<LootBoxTab>
    with SingleTickerProviderStateMixin {
  bool _isOpeningBox = false;
  late AnimationController _boxAnimController;

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
    _boxAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);
    final accessories = ref.watch(itemListProvider).value ?? [];

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
                color: AppColors.textPrimary),
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
                  child: const Text('📦', style: TextStyle(fontSize: 120)),
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
                color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          Text(
            '인벤토리: ${userState.inventory.length}/${accessories.length} 수집',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 36),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (userState.boxesCount <= 0 ||
                      _isOpeningBox ||
                      accessories.isEmpty)
                  ? null
                  : () async {
                      setState(() => _isOpeningBox = true);
                      await _boxAnimController.forward(from: 0.0);

                      final random = Random();
                      final item =
                          accessories[random.nextInt(accessories.length)];
                      final success = await ref
                          .read(userProvider.notifier)
                          .openBox(item['id']!);

                      setState(() => _isOpeningBox = false);
                      if (success && mounted) {
                        _showItemAcquiredDialog(item);
                      }
                    },
              style: ElevatedButton.styleFrom(
                disabledBackgroundColor: Colors.grey.withValues(alpha: 0.3),
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
                          fontSize: 16, fontWeight: FontWeight.bold)),
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

  void _showItemAcquiredDialog(Map<String, String> item) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('✨ 아이템 획득! ✨',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.streakBadgeFg)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            itemVisual(item, size: 72),
            const SizedBox(height: 10),
            Text(
              itemLabel(item),
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary),
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
                widget.onGoToInventory();
              },
              child: const Text('인벤토리에서 장착하기'),
            ),
          ),
        ],
      ),
    );
  }
}
