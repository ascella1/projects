import '../../domain/entities/character.dart';

/// 로컬/원격 구현을 교체할 수 있도록 인터페이스로 분리한다.
/// 지금은 Hive 기반 구현체만 존재하지만, 나중에 서버 동기화가 필요해지면
/// 이 인터페이스를 만족하는 remote 구현체를 추가해서 교체할 수 있다.
abstract class CharacterRepository {
  Future<Character> load();
  Future<void> save(Character character);
}
