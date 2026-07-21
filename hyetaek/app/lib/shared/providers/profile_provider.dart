import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../entities/user_profile.dart';

/// 앱 전체가 구독하는 현재 프로필 (docs/03 section 3 "전역으로 앱 전체가 구독하는 상태").
/// 프로필이 바뀌면 이를 watch하는 모든 파생 provider(랭킹, 자격판정)가 자동 재계산된다.
class ProfileNotifier extends Notifier<UserProfile> {
  @override
  UserProfile build() => const UserProfile();

  void update(UserProfile Function(UserProfile current) updater) {
    state = updater(state);
  }

  void reset() {
    state = const UserProfile();
  }
}

final profileProvider = NotifierProvider<ProfileNotifier, UserProfile>(ProfileNotifier.new);
