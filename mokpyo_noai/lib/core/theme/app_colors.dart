import 'package:flutter/material.dart';

// mokpyo(원본)의 초록 정원 라이트 테마를 그대로 재현한 팔레트.
// 디자인을 바꾸고 싶다면 이 파일의 값만 수정하면 앱 전체에 반영된다.
// 자세한 안내는 프로젝트 루트의 APP_DESIGN.md 참고.
class AppColors {
  AppColors._();

  // 배경 그라데이션 (상단→하단)
  static const backgroundStart = Color(0xFFE8F5E9);
  static const backgroundEnd = Color(0xFFFFF3E0);

  // 브랜드 포인트 컬러
  static const primary = Color(0xFF2E7D32); // 진한 초록: 버튼/강조 텍스트
  static const primaryLight = Color(0xFF81C784); // 연한 초록: 진행바 채움
  static const primarySoft = Color(0xFFE8F5E9); // 아주 연한 초록: 칩/배지 배경
  static const avatarBg = Color(0xFFC8E6C9); // 캐릭터 아바타 원형 배경

  // 카드/서페이스
  static const surface = Colors.white;
  static const surfaceMuted = Color(0xFFF9F9F9); // 완료 전 퀘스트 타일 배경
  static const surfaceDone = Color(0x0D000000); // 완료된 퀘스트 타일 배경(검정 5%)

  // 텍스트
  static const textPrimary = Color(0xFF3E2723); // 짙은 브라운
  static const textSecondary = Colors.grey;

  // 뱃지
  static const boxBadgeBg = Color(0xFFFFECEB);
  static const boxBadgeFg = Color(0xFFD84315);
  static const streakBadgeBg = Color(0xFFFFF8E1);
  static const streakBadgeFg = Color(0xFFE65100);

  // 레벨업 다이얼로그
  static const levelUpBg = Color(0xFF1B5E20);
  static const gold = Color(0xFFE65100); // 레벨업/강조 문구

  // 상태
  static const danger = Colors.redAccent;
  static const success = Colors.green;

  // 능력치별 색상
  static const statKnowledge = Color(0xFF1E88E5);
  static const statCareer = Color(0xFF43A047);
  static const statHealth = Color(0xFFE53935);
  static const statMoney = Color(0xFFFFB300);
  static const statCommunication = Color(0xFF8E24AA);

  // 업적 탭 depth별 색상 (대/중/소/일일)
  static const depthColors = [
    Colors.grey,
    Colors.deepPurple,
    Colors.indigo,
    Colors.teal,
    Colors.green,
  ];
}
