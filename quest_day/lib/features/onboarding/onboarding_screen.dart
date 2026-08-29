import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/user_profile.dart';
import '../../core/models/quest.dart';
import '../../core/theme/app_theme.dart';
import '../../state/app_state.dart';

class _Question {
  final String text;
  final String statementSuffix;
  final String trait;

  const _Question({
    required this.text,
    required this.statementSuffix,
    required this.trait,
  });
}

const _questions = [
  _Question(
    text: '주말에 나는 주로',
    statementSuffix: '사람들과 어울리는 편이다.',
    trait: 'social',
  ),
  _Question(
    text: '새로운 장소에 혼자 가는 것이',
    statementSuffix: '설레고 좋다.',
    trait: 'exploration',
  ),
  _Question(
    text: '계획 없이 즉흥적으로 행동하는 것이',
    statementSuffix: '재미있고 자연스럽다.',
    trait: 'spontaneity',
  ),
  _Question(
    text: '운동이나 신체 활동을',
    statementSuffix: '즐기는 편이다.',
    trait: 'activity',
  ),
  _Question(
    text: '혼자만의 조용한 시간이',
    statementSuffix: '별로 필요하지 않다.',
    trait: 'solitude',
  ),
  _Question(
    text: '새로운 도전이나 위험을',
    statementSuffix: '즐기고 싶다.',
    trait: 'courage',
  ),
  _Question(
    text: '무언가를 직접 만들거나 창작하는 것을',
    statementSuffix: '매우 좋아한다.',
    trait: 'creativity',
  ),
  _Question(
    text: '낯선 음식이나 문화를 경험하는 것이',
    statementSuffix: '기대되고 흥미롭다.',
    trait: 'adaptability',
  ),
  _Question(
    text: '예상치 못한 상황에서',
    statementSuffix: '당황하지 않고 잘 적응하는 편이다.',
    trait: 'adaptability',
  ),
  _Question(
    text: '먼저 친구에게 연락하거나 만남을 제안하는 것이',
    statementSuffix: '자연스럽고 편하다.',
    trait: 'social',
  ),
];

const _answerOptions = [
  (label: '매우\n그렇다', value: 1.0),
  (label: '그렇다', value: 0.75),
  (label: '보통', value: 0.5),
  (label: '아니다', value: 0.25),
  (label: '매우\n아니다', value: 0.0),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  int _step = 0;
  final List<double?> _answers = List.filled(_questions.length, null);
  ComfortLevel _comfortZone = ComfortLevel.normal;
  final _nicknameController = TextEditingController();
  late AnimationController _anim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  void _next() {
    _anim.reverse().then((_) {
      setState(() => _step++);
      _anim.forward();
    });
  }

  void _prev() {
    if (_step == 0) return;
    _anim.reverse().then((_) {
      setState(() => _step--);
      _anim.forward();
    });
  }

  Map<String, double> _buildPersonality() {
    final traitSums = <String, double>{};
    final traitCounts = <String, int>{};
    for (int i = 0; i < _questions.length; i++) {
      final trait = _questions[i].trait;
      final answer = _answers[i] ?? 0.5;
      traitSums[trait] = (traitSums[trait] ?? 0) + answer;
      traitCounts[trait] = (traitCounts[trait] ?? 0) + 1;
    }
    return traitSums.map((k, v) => MapEntry(k, v / traitCounts[k]!));
  }

  Future<void> _finish() async {
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) return;
    final profile = UserProfile(
      nickname: nickname,
      personality: _buildPersonality(),
      comfortZone: _comfortZone,
    );
    await context.read<AppState>().completeOnboarding(profile);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnim,
        child: _buildStep(),
      ),
    );
  }

  Widget _buildStep() {
    if (_step == 0) return _buildWelcome();
    final qi = _step - 1;
    if (qi < _questions.length) return _buildQuestion(qi);
    if (_step == _questions.length + 1) return _buildComfortZone();
    return _buildNickname();
  }

  Widget _buildWelcome() {
    final qc = context.qc;
    return _PageShell(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('✦', style: TextStyle(fontSize: 60, color: AppColors.primary)),
          const SizedBox(height: 24),
          Text(
            'QUEST DAY',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: qc.textPrimary,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '평범한 하루를\n조금 다르게 만드는 방법',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              color: qc.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 60),
          _PrimaryButton(label: '시작하기', onTap: _next),
        ],
      ),
    );
  }

  Widget _buildQuestion(int index) {
    final q = _questions[index];
    final selected = _answers[index];
    final canNext = selected != null;
    final qc = context.qc;

    return _PageShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 56),
          _ProgressBar(current: index + 1, total: _questions.length),
          const SizedBox(height: 40),
          const Text(
            'Q',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 10),
          RichText(
            text: TextSpan(
              style: TextStyle(
                color: qc.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                height: 1.5,
              ),
              children: [
                TextSpan(text: '${q.text}\n'),
                const TextSpan(
                  text: '',
                ),
              ],
            ),
          ),
          Text(
            q.statementSuffix,
            style: const TextStyle(
              color: AppColors.primaryLight,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 36),
          _FiveScaleQuestion(
            selected: selected,
            onSelect: (v) => setState(() => _answers[index] = v),
          ),
          const Spacer(),
          Row(
            children: [
              if (index > 0) _GhostButton(label: '이전', onTap: _prev),
              if (index > 0) const SizedBox(width: 12),
              Expanded(
                child: _PrimaryButton(
                  label: index < _questions.length - 1 ? '다음' : '완료',
                  onTap: canNext ? _next : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildComfortZone() {
    final qc = context.qc;
    return _PageShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 60),
          Text(
            '오늘 당신의 일상을\n얼마나 흔들어볼까요?',
            style: TextStyle(
              color: qc.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '나중에 설정에서 언제든 바꿀 수 있어요.',
            style: TextStyle(color: qc.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 32),
          ..._comfortOptions.map((opt) => _ComfortOption(
                label: opt.label,
                description: opt.description,
                color: opt.color,
                selected: _comfortZone == opt.zone,
                onTap: () => setState(() => _comfortZone = opt.zone),
              )),
          const Spacer(),
          _PrimaryButton(label: '다음', onTap: _next),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildNickname() {
    final qc = context.qc;
    return _PageShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 100),
          Text(
            '마지막으로,\n이름을 알려주세요.',
            style: TextStyle(
              color: qc.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '닉네임이나 실명 무엇이든 괜찮아요.',
            style: TextStyle(color: qc.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 36),
          TextField(
            controller: _nicknameController,
            autofocus: true,
            style: TextStyle(
              color: qc.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: '닉네임 입력',
              hintStyle: TextStyle(color: qc.textMuted),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: qc.divider, width: 2),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
            onSubmitted: (_) => _finish(),
          ),
          const Spacer(),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _nicknameController,
            builder: (ctx, val, _) => _PrimaryButton(
              label: '퀘스트 시작하기',
              onTap: val.text.trim().isNotEmpty ? _finish : null,
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── 5단계 척도 버튼 ───────────────────────────────────────────────────────────

class _FiveScaleQuestion extends StatelessWidget {
  final double? selected;
  final ValueChanged<double> onSelect;

  const _FiveScaleQuestion({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final qc = context.qc;
    return Row(
      children: _answerOptions.map((opt) {
        final isSelected = selected == opt.value;
        return Expanded(
          child: GestureDetector(
            onTap: () => onSelect(opt.value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.2)
                    : qc.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.primary : qc.divider,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Text(
                opt.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? AppColors.primary : qc.textSecondary,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  height: 1.3,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Comfort Zone ─────────────────────────────────────────────────────────────

class _ComfortOpt {
  final ComfortLevel zone;
  final String label;
  final String description;
  final Color color;
  const _ComfortOpt(this.zone, this.label, this.description, this.color);
}

const _comfortOptions = [
  _ComfortOpt(ComfortLevel.safe, 'SAFE', '평소와 거의 비슷하지만 조금 다른 행동', AppColors.safe),
  _ComfortOpt(ComfortLevel.normal, 'NORMAL', '확실히 새로운 경험 (기본 권장)', AppColors.normal),
  _ComfortOpt(ComfortLevel.challenge, 'CHALLENGE', '약간 불편하지만 해볼 만한 행동', AppColors.challenge),
  _ComfortOpt(ComfortLevel.crazy, 'CRAZY', '평소라면 절대 하지 않을 행동', AppColors.crazy),
];

// ── Shared Widgets ───────────────────────────────────────────────────────────

class _PageShell extends StatelessWidget {
  final Widget child;
  const _PageShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: child,
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final int current;
  final int total;
  const _ProgressBar({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    final qc = context.qc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$current / $total',
          style: TextStyle(color: qc.textMuted, fontSize: 11, letterSpacing: 1),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: current / total,
            backgroundColor: qc.divider,
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            minHeight: 4,
          ),
        ),
      ],
    );
  }
}

class _ComfortOption extends StatelessWidget {
  final String label;
  final String description;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _ComfortOption({
    required this.label,
    required this.description,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final qc = context.qc;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : qc.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: selected ? color : qc.textMuted,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: selected ? color : qc.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(color: qc.textSecondary, fontSize: 12),
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

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _PrimaryButton({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final qc = context.qc;
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: onTap != null ? AppColors.primary : qc.divider,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 1),
        ),
        child: Text(label),
      ),
    );
  }
}

class _GhostButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _GhostButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final qc = context.qc;
    return SizedBox(
      height: 54,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: qc.textSecondary,
          side: BorderSide(color: qc.divider),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(label),
      ),
    );
  }
}
