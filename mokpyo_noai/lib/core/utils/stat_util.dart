import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

// 5개 능력치(지식/커리어/체력/자산/소통)에 대응하는 이모지/라벨/색상 정보.
const List<String> allStatKeys = [
  'knowledge',
  'career',
  'health',
  'money',
  'communication',
];

class StatInfo {
  final String emoji;
  final String label;
  final Color color;

  const StatInfo({required this.emoji, required this.label, required this.color});
}

StatInfo statInfo(String stat) {
  switch (stat) {
    case 'knowledge':
      return const StatInfo(emoji: '📚', label: '지식', color: AppColors.statKnowledge);
    case 'career':
      return const StatInfo(emoji: '💼', label: '커리어', color: AppColors.statCareer);
    case 'health':
      return const StatInfo(emoji: '💪', label: '체력', color: AppColors.statHealth);
    case 'money':
      return const StatInfo(emoji: '💰', label: '자산', color: AppColors.statMoney);
    case 'communication':
      return const StatInfo(emoji: '💬', label: '소통', color: AppColors.statCommunication);
    default:
      return StatInfo(emoji: '🌱', label: stat, color: AppColors.textSecondary);
  }
}
