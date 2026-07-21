/// 온통청년(청년정책 통합정보) Open API 응답 1건을 담는 방어적 DTO.
///
/// 공식 문서가 JS 렌더링이라 응답 필드명을 자동 조회로 100% 확정하지 못했다.
/// 아래 필드명은 이 API 계열에서 널리 알려진 표준 스키마를 기준으로 하되,
/// 실제 응답이 조금 다르더라도 앱이 죽지 않도록 전부 nullable로 방어적으로 파싱한다.
/// 실 키로 첫 호출 후 `server`의 `/api/youth-policies/raw`로 원본을 확인해 조정할 것.
class YouthPolicyDto {
  final Map<String, dynamic> raw;

  const YouthPolicyDto(this.raw);

  factory YouthPolicyDto.fromJson(Map<String, dynamic> json) => YouthPolicyDto(Map<String, dynamic>.from(json));

  Map<String, dynamic> toJson() => raw;

  String? get plcyNo => _str(raw['plcyNo']);
  String? get plcyNm => _str(raw['plcyNm']);
  String? get plcyExplnCn => _str(raw['plcyExplnCn']);
  String? get plcySprtCn => _str(raw['plcySprtCn']);
  String? get sprvsnInstCdNm => _str(raw['sprvsnInstCdNm']);
  String? get lclsfNm => _str(raw['lclsfNm']);
  String? get mclsfNm => _str(raw['mclsfNm']);
  String? get plcyKywdNm => _str(raw['plcyKywdNm']);
  int? get sprtTrgtMinAge => _int(raw['sprtTrgtMinAge']);
  int? get sprtTrgtMaxAge => _int(raw['sprtTrgtMaxAge']);
  String? get aplyYmd => _str(raw['aplyYmd']);
  String? get bizPrdEndYmd => _str(raw['bizPrdEndYmd']);
  String? get zipCd => _str(raw['zipCd']);
  String? get refUrlAddr1 => _str(raw['refUrlAddr1']);
  String? get rqutUrlAddr => _str(raw['rqutUrlAddr']);

  static String? _str(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  static int? _int(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString().trim());
  }
}
