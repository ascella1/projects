// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cafe_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(recipeRepository)
final recipeRepositoryProvider = RecipeRepositoryProvider._();

final class RecipeRepositoryProvider
    extends
        $FunctionalProvider<
          RecipeRepository,
          RecipeRepository,
          RecipeRepository
        >
    with $Provider<RecipeRepository> {
  RecipeRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recipeRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recipeRepositoryHash();

  @$internal
  @override
  $ProviderElement<RecipeRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RecipeRepository create(Ref ref) {
    return recipeRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RecipeRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RecipeRepository>(value),
    );
  }
}

String _$recipeRepositoryHash() => r'7a16da596176ff163c7c2b9acd612bc41621988b';

/// 카페 화면의 주문/레시피 숙련도 상태. 코인은 여기서 캐릭터에 바로 반영하지 않고
/// work_session_provider에 누적시켰다가 퇴근 시 한 번에 정산한다 (실시간 노출 X).
/// keepAlive: 상점 화면을 오가는 동안에도 현재 주문/숙련도 상태가 유지되어야 한다.

@ProviderFor(CafeNotifier)
final cafeProvider = CafeNotifierProvider._();

/// 카페 화면의 주문/레시피 숙련도 상태. 코인은 여기서 캐릭터에 바로 반영하지 않고
/// work_session_provider에 누적시켰다가 퇴근 시 한 번에 정산한다 (실시간 노출 X).
/// keepAlive: 상점 화면을 오가는 동안에도 현재 주문/숙련도 상태가 유지되어야 한다.
final class CafeNotifierProvider
    extends $AsyncNotifierProvider<CafeNotifier, CafeState> {
  /// 카페 화면의 주문/레시피 숙련도 상태. 코인은 여기서 캐릭터에 바로 반영하지 않고
  /// work_session_provider에 누적시켰다가 퇴근 시 한 번에 정산한다 (실시간 노출 X).
  /// keepAlive: 상점 화면을 오가는 동안에도 현재 주문/숙련도 상태가 유지되어야 한다.
  CafeNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cafeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cafeNotifierHash();

  @$internal
  @override
  CafeNotifier create() => CafeNotifier();
}

String _$cafeNotifierHash() => r'd57f750b4c71ab57f155f675e35357aff80970c8';

/// 카페 화면의 주문/레시피 숙련도 상태. 코인은 여기서 캐릭터에 바로 반영하지 않고
/// work_session_provider에 누적시켰다가 퇴근 시 한 번에 정산한다 (실시간 노출 X).
/// keepAlive: 상점 화면을 오가는 동안에도 현재 주문/숙련도 상태가 유지되어야 한다.

abstract class _$CafeNotifier extends $AsyncNotifier<CafeState> {
  FutureOr<CafeState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<CafeState>, CafeState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<CafeState>, CafeState>,
              AsyncValue<CafeState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
