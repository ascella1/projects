// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'work_session_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 출근-퇴근 연결 로직의 핵심 상태. 집 케어 상태 스냅샷(컨디션 점수)과
/// 카페 세션 동안 쌓인 코인/주문 수를 들고 있다가 퇴근 시 캐릭터에 정산한다.
/// keepAlive: clockIn()은 아직 아무도 watch하지 않는 홈 화면에서 호출되므로,
/// autoDispose였다면 비동기 대기 중 provider가 폐기되어 상태 반영이 유실된다.

@ProviderFor(WorkSessionNotifier)
final workSessionProvider = WorkSessionNotifierProvider._();

/// 출근-퇴근 연결 로직의 핵심 상태. 집 케어 상태 스냅샷(컨디션 점수)과
/// 카페 세션 동안 쌓인 코인/주문 수를 들고 있다가 퇴근 시 캐릭터에 정산한다.
/// keepAlive: clockIn()은 아직 아무도 watch하지 않는 홈 화면에서 호출되므로,
/// autoDispose였다면 비동기 대기 중 provider가 폐기되어 상태 반영이 유실된다.
final class WorkSessionNotifierProvider
    extends $NotifierProvider<WorkSessionNotifier, WorkSession> {
  /// 출근-퇴근 연결 로직의 핵심 상태. 집 케어 상태 스냅샷(컨디션 점수)과
  /// 카페 세션 동안 쌓인 코인/주문 수를 들고 있다가 퇴근 시 캐릭터에 정산한다.
  /// keepAlive: clockIn()은 아직 아무도 watch하지 않는 홈 화면에서 호출되므로,
  /// autoDispose였다면 비동기 대기 중 provider가 폐기되어 상태 반영이 유실된다.
  WorkSessionNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'workSessionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$workSessionNotifierHash();

  @$internal
  @override
  WorkSessionNotifier create() => WorkSessionNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WorkSession value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WorkSession>(value),
    );
  }
}

String _$workSessionNotifierHash() =>
    r'4685c585b950a002db147b1cdf55fc783662ec58';

/// 출근-퇴근 연결 로직의 핵심 상태. 집 케어 상태 스냅샷(컨디션 점수)과
/// 카페 세션 동안 쌓인 코인/주문 수를 들고 있다가 퇴근 시 캐릭터에 정산한다.
/// keepAlive: clockIn()은 아직 아무도 watch하지 않는 홈 화면에서 호출되므로,
/// autoDispose였다면 비동기 대기 중 provider가 폐기되어 상태 반영이 유실된다.

abstract class _$WorkSessionNotifier extends $Notifier<WorkSession> {
  WorkSession build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<WorkSession, WorkSession>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<WorkSession, WorkSession>,
              WorkSession,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
