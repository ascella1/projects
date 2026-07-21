import 'package:flutter/material.dart';

import '../../features/eligibility_engine/rule_models.dart';

/// docs/01 "상태색(초록=Eligible, 노랑=Possibly, 회색=Not Eligible)" + docs/05 section 4.
class StatusColors {
  StatusColors._();

  static Color background(EligibilityStatus status, bool isDark) => switch (status) {
        EligibilityStatus.eligible => isDark ? const Color(0xFF14321F) : const Color(0xFFE7F8ED),
        EligibilityStatus.possiblyEligible => isDark ? const Color(0xFF3A2E10) : const Color(0xFFFEF6E0),
        EligibilityStatus.notEligible => isDark ? const Color(0xFF23262D) : const Color(0xFFF0F1F3),
      };

  static Color foreground(EligibilityStatus status, bool isDark) => switch (status) {
        EligibilityStatus.eligible => isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A),
        EligibilityStatus.possiblyEligible => isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309),
        EligibilityStatus.notEligible => isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
      };

  static String label(EligibilityStatus status) => switch (status) {
        EligibilityStatus.eligible => '받을 수 있어요',
        EligibilityStatus.possiblyEligible => '확인이 필요해요',
        EligibilityStatus.notEligible => '대상이 아니에요',
      };

  static IconData icon(EligibilityStatus status) => switch (status) {
        EligibilityStatus.eligible => Icons.check_circle_rounded,
        EligibilityStatus.possiblyEligible => Icons.help_rounded,
        EligibilityStatus.notEligible => Icons.remove_circle_outline_rounded,
      };
}
