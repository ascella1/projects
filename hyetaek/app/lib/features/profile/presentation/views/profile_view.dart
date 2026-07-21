import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/entities/user_profile.dart';
import '../../../../shared/providers/profile_provider.dart';

/// docs/01 section 4.6 "프로필" — 변경 시 즉시 전체 재계산.
/// profileProvider.update()를 호출하는 즉시 홈 대시보드의 rankedBenefitsProvider가 재평가된다.
class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final notifier = ref.read(profileProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('프로필')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text('프로필을 바꾸면 혜택 목록이 실시간으로 다시 계산돼요.', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 20),

          _FieldGroup(
            title: '태어난 해',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _recentYears().map((y) {
                return ChoiceChip(
                  label: Text('$y'),
                  selected: profile.birthYear == y,
                  onSelected: (_) => notifier.update((c) => c.copyWith(birthYear: y)),
                );
              }).toList(),
            ),
          ),

          _FieldGroup(
            title: '성별',
            child: Wrap(
              spacing: 8,
              children: Gender.values.map((g) {
                return ChoiceChip(
                  label: Text(g.label),
                  selected: profile.gender == g,
                  onSelected: (_) => notifier.update((c) => c.copyWith(gender: g)),
                );
              }).toList(),
            ),
          ),

          _FieldGroup(
            title: '거주지',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: regionOptions.entries.map((e) {
                return ChoiceChip(
                  label: Text(e.value),
                  selected: profile.regionCode == e.key,
                  onSelected: (_) => notifier.update((c) => c.copyWith(regionCode: e.key)),
                );
              }).toList(),
            ),
          ),

          _FieldGroup(
            title: '고용상태',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: EmploymentStatus.values.map((s) {
                return ChoiceChip(
                  label: Text(s.label),
                  selected: profile.employmentStatus == s,
                  onSelected: (_) => notifier.update((c) => c.copyWith(employmentStatus: s)),
                );
              }).toList(),
            ),
          ),

          _FieldGroup(
            title: '연소득',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [0, 20000000, 40000000, 60000000, 75000000, 100000000].map((v) {
                return ChoiceChip(
                  label: Text(v == 0 ? '없음' : '${v ~/ 10000}만원 이하'),
                  selected: profile.incomeAnnual == v,
                  onSelected: (_) => notifier.update((c) => c.copyWith(incomeAnnual: v)),
                );
              }).toList(),
            ),
          ),

          _FieldGroup(
            title: '결혼 여부',
            child: Wrap(spacing: 8, children: [
              ChoiceChip(label: const Text('기혼'), selected: profile.isMarried == true, onSelected: (_) => notifier.update((c) => c.copyWith(isMarried: true))),
              ChoiceChip(label: const Text('미혼'), selected: profile.isMarried == false, onSelected: (_) => notifier.update((c) => c.copyWith(isMarried: false))),
            ]),
          ),

          _FieldGroup(
            title: '자녀 수',
            child: Wrap(
              spacing: 8,
              children: [0, 1, 2, 3].map((n) {
                return ChoiceChip(
                  label: Text(n == 3 ? '3명 이상' : '$n명'),
                  selected: profile.childrenCount == n,
                  onSelected: (_) => notifier.update((c) => c.copyWith(childrenCount: n)),
                );
              }).toList(),
            ),
          ),

          _FieldGroup(
            title: '주택 보유',
            child: Wrap(
              spacing: 8,
              children: HousingStatus.values.map((h) {
                return ChoiceChip(
                  label: Text(h.label),
                  selected: profile.housingStatus == h,
                  onSelected: (_) => notifier.update((c) => c.copyWith(housingStatus: h)),
                );
              }).toList(),
            ),
          ),

          _FieldGroup(
            title: '프리랜서 여부',
            child: Wrap(spacing: 8, children: [
              ChoiceChip(label: const Text('예'), selected: profile.isFreelancer == true, onSelected: (_) => notifier.update((c) => c.copyWith(isFreelancer: true))),
              ChoiceChip(label: const Text('아니오'), selected: profile.isFreelancer == false, onSelected: (_) => notifier.update((c) => c.copyWith(isFreelancer: false))),
            ]),
          ),

          _FieldGroup(
            title: '장애 여부',
            child: Wrap(spacing: 8, children: [
              ChoiceChip(label: const Text('해당'), selected: profile.hasDisability == true, onSelected: (_) => notifier.update((c) => c.copyWith(hasDisability: true))),
              ChoiceChip(label: const Text('비해당'), selected: profile.hasDisability == false, onSelected: (_) => notifier.update((c) => c.copyWith(hasDisability: false))),
            ]),
          ),

          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => notifier.reset(),
            child: const Text('프로필 초기화'),
          ),
        ],
      ),
    );
  }

  static List<int> _recentYears() {
    final currentYear = DateTime.now().year;
    return List.generate(60, (i) => currentYear - 15 - i);
  }
}

class _FieldGroup extends StatelessWidget {
  final String title;
  final Widget child;
  const _FieldGroup({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
