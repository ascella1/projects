// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'character_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(characterRepository)
final characterRepositoryProvider = CharacterRepositoryProvider._();

final class CharacterRepositoryProvider
    extends
        $FunctionalProvider<
          CharacterRepository,
          CharacterRepository,
          CharacterRepository
        >
    with $Provider<CharacterRepository> {
  CharacterRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'characterRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$characterRepositoryHash();

  @$internal
  @override
  $ProviderElement<CharacterRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CharacterRepository create(Ref ref) {
    return characterRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CharacterRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CharacterRepository>(value),
    );
  }
}

String _$characterRepositoryHash() =>
    r'8e7721c825eb4222983601797297ac849351be20';

/// 집/카페 화면이 공통으로 구독하는 캐릭터 상태 notifier.
/// 케어 액션, 상점 구매, 정산 반영이 전부 이 notifier를 통해 이루어진다.
/// keepAlive: 화면 전환 중에도 캐릭터 상태(코인 등)가 유실되지 않아야 한다.

@ProviderFor(CharacterNotifier)
final characterProvider = CharacterNotifierProvider._();

/// 집/카페 화면이 공통으로 구독하는 캐릭터 상태 notifier.
/// 케어 액션, 상점 구매, 정산 반영이 전부 이 notifier를 통해 이루어진다.
/// keepAlive: 화면 전환 중에도 캐릭터 상태(코인 등)가 유실되지 않아야 한다.
final class CharacterNotifierProvider
    extends $AsyncNotifierProvider<CharacterNotifier, Character> {
  /// 집/카페 화면이 공통으로 구독하는 캐릭터 상태 notifier.
  /// 케어 액션, 상점 구매, 정산 반영이 전부 이 notifier를 통해 이루어진다.
  /// keepAlive: 화면 전환 중에도 캐릭터 상태(코인 등)가 유실되지 않아야 한다.
  CharacterNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'characterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$characterNotifierHash();

  @$internal
  @override
  CharacterNotifier create() => CharacterNotifier();
}

String _$characterNotifierHash() => r'cfb9616db92f7b5f84a36193bf9ff2c06caa84e1';

/// 집/카페 화면이 공통으로 구독하는 캐릭터 상태 notifier.
/// 케어 액션, 상점 구매, 정산 반영이 전부 이 notifier를 통해 이루어진다.
/// keepAlive: 화면 전환 중에도 캐릭터 상태(코인 등)가 유실되지 않아야 한다.

abstract class _$CharacterNotifier extends $AsyncNotifier<Character> {
  FutureOr<Character> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Character>, Character>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Character>, Character>,
              AsyncValue<Character>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
