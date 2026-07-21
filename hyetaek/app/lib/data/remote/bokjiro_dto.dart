/// 복지로(한국사회보장정보원) 중앙부처복지서비스 API 응답 1건을 담는 방어적 DTO.
///
/// `youth_policy_dto.dart`와 같은 이유로 nullable/방어적 파싱: 공식 문서가 자동 조회로
/// 확인되지 않아 표준으로 알려진 필드명을 기준으로 하되, 실제 응답이 다르더라도 앱이 죽지 않게 한다.
/// 실 키로 첫 호출 후 `server`의 `/api/sources/bokjiro/raw`로 원본을 확인해 조정할 것.
class BokjiroDto {
  final Map<String, dynamic> raw;

  const BokjiroDto(this.raw);

  factory BokjiroDto.fromJson(Map<String, dynamic> json) => BokjiroDto(Map<String, dynamic>.from(json));

  Map<String, dynamic> toJson() => raw;

  String? get servId => _str(raw['servId']);
  String? get servNm => _str(raw['servNm']);
  String? get servDgst => _str(raw['servDgst']);
  String? get jurMnofNm => _str(raw['jurMnofNm']);
  String? get aplyMtdNm => _str(raw['aplyMtdNm']);
  String? get lifeNmArray => _str(raw['lifeNmArray']);
  String? get trgterIndvdlNmArray => _str(raw['trgterIndvdlNmArray']);
  String? get servDtlLink => _str(raw['servDtlLink']);

  static String? _str(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }
}
