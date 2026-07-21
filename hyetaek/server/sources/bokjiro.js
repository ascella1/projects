/**
 * 복지로(한국사회보장정보원) 중앙부처복지서비스 API.
 * data.go.kr/data/15090532 — 영유아~노년까지 생애주기(lifeArray)로 대상층을 필터링할 수 있는
 * 유일한 통합 스키마의 실시간 복지 혜택 API라 노인/중장년/청년/학생을 한 소스로 커버하기 위해 선택했다.
 * 정확한 응답 필드명은 공식 문서가 자동 조회로 확인되지 않아 표준으로 알려진 스키마 기준 방어적 구현.
 * 실제 키로 확인 후 /api/sources/bokjiro/raw로 검증 필요.
 */
export const bokjiroSource = {
  id: 'bokjiro',
  name: '복지로 중앙부처복지서비스',
  envKey: 'BOKJIRO_API_KEY',
  keyHint: /serv(Id|Nm)|life/i,
  baseUrl: 'http://apis.data.go.kr/B554287/NationalWelfareInformations/NationalWelfareInformationsV001/NationalWelfareListV001',

  buildUrl(query, apiKey) {
    const params = new URLSearchParams({
      serviceKey: apiKey,
      pageNo: query.pageNo ?? '1',
      numOfRows: query.numOfRows ?? '100',
      // 003 청소년/학생, 004 청년, 005 중장년, 006 노년 — 사용자가 요청한 전 연령대 커버
      lifeArray: query.lifeArray ?? '003,004,005,006',
      _type: 'json',
    });
    return `${this.baseUrl}?${params.toString()}`;
  },
};
