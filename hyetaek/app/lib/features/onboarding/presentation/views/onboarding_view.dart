import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/entities/user_profile.dart';
import '../../../../shared/providers/profile_provider.dart';
import '../../../home_dashboard/presentation/views/home_view.dart';

/// docs/01 section 3 핵심 플로우 — 온보딩(3~4단계, 스킵 가능) → 홈 대시보드.
class OnboardingView extends ConsumerStatefulWidget {
  const OnboardingView({super.key});

  @override
  ConsumerState<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends ConsumerState<OnboardingView> {
  final _controller = PageController();
  int _step = 0;
  static const _totalSteps = 4;

  int? _birthYear;
  Gender? _gender;
  String? _regionCode;
  EmploymentStatus? _employmentStatus;

  int? _incomeAnnual;
  bool? _isMarried;
  int? _childrenCount;
  HousingStatus? _housingStatus;
  bool? _hasDisability;

  bool get _canProceedStep0 => _birthYear != null && _gender != null;
  bool get _canProceedStep1 => _regionCode != null;
  bool get _canProceedStep2 => _employmentStatus != null;

  void _next() {
    if (_step < _totalSteps - 1) {
      setState(() => _step++);
      _controller.nextPage(duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic);
    } else {
      _finish();
    }
  }

  void _finish() {
    ref.read(profileProvider.notifier).update((current) => current.copyWith(
          birthYear: _birthYear,
          gender: _gender,
          regionCode: _regionCode,
          employmentStatus: _employmentStatus,
          incomeAnnual: _incomeAnnual,
          isMarried: _isMarried,
          childrenCount: _childrenCount,
          housingStatus: _housingStatus,
          hasDisability: _hasDisability,
        ));
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canProceed = switch (_step) {
      0 => _canProceedStep0,
      1 => _canProceedStep1,
      2 => _canProceedStep2,
      _ => true,
    };

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: List.generate(_totalSteps, (i) {
                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.only(right: i == _totalSteps - 1 ? 0 : 6),
                      height: 4,
                      decoration: BoxDecoration(
                        color: i <= _step
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _AgeGenderStep(
                    birthYear: _birthYear,
                    gender: _gender,
                    onBirthYearChanged: (v) => setState(() => _birthYear = v),
                    onGenderChanged: (v) => setState(() => _gender = v),
                  ),
                  _RegionStep(
                    regionCode: _regionCode,
                    onChanged: (v) => setState(() => _regionCode = v),
                  ),
                  _EmploymentStep(
                    status: _employmentStatus,
                    onChanged: (v) => setState(() => _employmentStatus = v),
                  ),
                  _OptionalStep(
                    incomeAnnual: _incomeAnnual,
                    isMarried: _isMarried,
                    childrenCount: _childrenCount,
                    housingStatus: _housingStatus,
                    hasDisability: _hasDisability,
                    onIncomeChanged: (v) => setState(() => _incomeAnnual = v),
                    onMarriedChanged: (v) => setState(() => _isMarried = v),
                    onChildrenChanged: (v) => setState(() => _childrenCount = v),
                    onHousingChanged: (v) => setState(() => _housingStatus = v),
                    onDisabilityChanged: (v) => setState(() => _hasDisability = v),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  if (_step == _totalSteps - 1)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _finish,
                        child: const Text('건너뛰기'),
                      ),
                    ),
                  if (_step == _totalSteps - 1) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: canProceed ? _next : null,
                      child: Text(_step == _totalSteps - 1 ? '완료' : '다음'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _StepScaffold({required this.title, required this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(subtitle, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 28),
          Expanded(child: SingleChildScrollView(child: child)),
        ],
      ),
    );
  }
}

class _AgeGenderStep extends StatelessWidget {
  final int? birthYear;
  final Gender? gender;
  final ValueChanged<int> onBirthYearChanged;
  final ValueChanged<Gender> onGenderChanged;

  const _AgeGenderStep({
    required this.birthYear,
    required this.gender,
    required this.onBirthYearChanged,
    required this.onGenderChanged,
  });

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    final years = List.generate(80, (i) => currentYear - i);

    return _StepScaffold(
      title: '언제 태어나셨나요?',
      subtitle: '나이 조건에 맞는 혜택을 찾기 위해 필요해요.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 160,
            child: ListView.builder(
              itemCount: years.length,
              itemBuilder: (context, i) {
                final y = years[i];
                final selected = y == birthYear;
                return ListTile(
                  title: Text('$y년생', style: TextStyle(fontWeight: selected ? FontWeight.w800 : FontWeight.w400)),
                  trailing: selected ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary) : null,
                  onTap: () => onBirthYearChanged(y),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          Text('성별', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: Gender.values.map((g) {
              return ChoiceChip(
                label: Text(g.label),
                selected: gender == g,
                onSelected: (_) => onGenderChanged(g),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _RegionStep extends StatelessWidget {
  final String? regionCode;
  final ValueChanged<String> onChanged;

  const _RegionStep({required this.regionCode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      title: '어디에 거주하시나요?',
      subtitle: '지역별로 다른 지자체 혜택을 매칭해드려요.',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: regionOptions.entries.map((e) {
          return ChoiceChip(
            label: Text(e.value),
            selected: regionCode == e.key,
            onSelected: (_) => onChanged(e.key),
          );
        }).toList(),
      ),
    );
  }
}

class _EmploymentStep extends StatelessWidget {
  final EmploymentStatus? status;
  final ValueChanged<EmploymentStatus> onChanged;

  const _EmploymentStep({required this.status, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      title: '현재 어떤 일을 하고 계신가요?',
      subtitle: '고용형태에 따라 받을 수 있는 혜택이 달라져요.',
      child: Column(
        children: EmploymentStatus.values.map((s) {
          final selected = status == s;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _SelectableTile(label: s.label, selected: selected, onTap: () => onChanged(s)),
          );
        }).toList(),
      ),
    );
  }
}

class _OptionalStep extends StatelessWidget {
  final int? incomeAnnual;
  final bool? isMarried;
  final int? childrenCount;
  final HousingStatus? housingStatus;
  final bool? hasDisability;
  final ValueChanged<int> onIncomeChanged;
  final ValueChanged<bool> onMarriedChanged;
  final ValueChanged<int> onChildrenChanged;
  final ValueChanged<HousingStatus> onHousingChanged;
  final ValueChanged<bool> onDisabilityChanged;

  const _OptionalStep({
    required this.incomeAnnual,
    required this.isMarried,
    required this.childrenCount,
    required this.housingStatus,
    required this.hasDisability,
    required this.onIncomeChanged,
    required this.onMarriedChanged,
    required this.onChildrenChanged,
    required this.onHousingChanged,
    required this.onDisabilityChanged,
  });

  static const _incomeSteps = [0, 20000000, 40000000, 60000000, 75000000, 100000000];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _StepScaffold(
      title: '조금 더 정확하게 알려주실래요?',
      subtitle: '입력하지 않아도 괜찮아요 — 나중에 프로필에서 추가할 수 있어요.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('연소득', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _incomeSteps.map((v) {
              return ChoiceChip(
                label: Text(v == 0 ? '없음' : '${v ~/ 10000}만원 이하'),
                selected: incomeAnnual == v,
                onSelected: (_) => onIncomeChanged(v),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Text('결혼 여부', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(spacing: 8, children: [
            ChoiceChip(label: const Text('기혼'), selected: isMarried == true, onSelected: (_) => onMarriedChanged(true)),
            ChoiceChip(label: const Text('미혼'), selected: isMarried == false, onSelected: (_) => onMarriedChanged(false)),
          ]),
          const SizedBox(height: 24),
          Text('자녀 수', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [0, 1, 2, 3].map((n) {
              return ChoiceChip(
                label: Text(n == 3 ? '3명 이상' : '$n명'),
                selected: childrenCount == n,
                onSelected: (_) => onChildrenChanged(n),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Text('주택 보유', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: HousingStatus.values.map((h) {
              return ChoiceChip(
                label: Text(h.label),
                selected: housingStatus == h,
                onSelected: (_) => onHousingChanged(h),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Text('장애 여부', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(spacing: 8, children: [
            ChoiceChip(label: const Text('해당'), selected: hasDisability == true, onSelected: (_) => onDisabilityChanged(true)),
            ChoiceChip(label: const Text('비해당'), selected: hasDisability == false, onSelected: (_) => onDisabilityChanged(false)),
          ]),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SelectableTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SelectableTile({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: selected ? theme.colorScheme.primary.withValues(alpha: 0.1) : theme.cardColor,
          border: Border.all(
            color: selected ? theme.colorScheme.primary : theme.dividerColor,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(label, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
            ),
            if (selected) Icon(Icons.check_circle, color: theme.colorScheme.primary, size: 20),
          ],
        ),
      ),
    );
  }
}
