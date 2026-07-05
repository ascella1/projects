import 'package:equatable/equatable.dart';

enum QuestStatus { todo, completed, failed }
enum QuestDifficulty { easy, medium, hard }

class Quest extends Equatable {
  final String id;
  final String goalId;
  final String title;
  final int depth; // 1: 대목표, 2: 중목표, 3: 소목표, 4: 일일 퀘스트
  final QuestStatus status;
  final QuestDifficulty difficulty;
  final int rewardExp;
  final List<String> rewardStats; // ['money', 'knowledge', 'health' 등]
  final DateTime dueDate;
  final DateTime? completedAt;

  const Quest({
    required this.id,
    required this.goalId,
    required this.title,
    required this.depth,
    required this.status,
    required this.difficulty,
    required this.rewardExp,
    required this.rewardStats,
    required this.dueDate,
    this.completedAt,
  });

  Quest copyWith({
    String? id,
    String? goalId,
    String? title,
    int? depth,
    QuestStatus? status,
    QuestDifficulty? difficulty,
    int? rewardExp,
    List<String>? rewardStats,
    DateTime? dueDate,
    DateTime? completedAt,
  }) {
    return Quest(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      title: title ?? this.title,
      depth: depth ?? this.depth,
      status: status ?? this.status,
      difficulty: difficulty ?? this.difficulty,
      rewardExp: rewardExp ?? this.rewardExp,
      rewardStats: rewardStats ?? this.rewardStats,
      dueDate: dueDate ?? this.dueDate,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        goalId,
        title,
        depth,
        status,
        difficulty,
        rewardExp,
        rewardStats,
        dueDate,
        completedAt,
      ];
}
