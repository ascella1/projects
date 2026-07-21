export const youthCenterSource = {
  id: 'youth-policies',
  name: '온통청년 청년정책',
  envKey: 'YOUTH_API_KEY',
  keyHint: /plcy/i,
  baseUrl: 'https://www.youthcenter.go.kr/opi/youthPlcyList.do',

  buildUrl(query, apiKey) {
    const params = new URLSearchParams({
      openApiVlak: apiKey,
      display: query.display ?? '100',
      pageIndex: query.pageIndex ?? '1',
      rtnType: query.rtnType ?? 'json',
    });
    if (query.keyword) params.set('keyword', String(query.keyword));
    if (query.srchPolyBizSecd) params.set('srchPolyBizSecd', String(query.srchPolyBizSecd));
    return `${this.baseUrl}?${params.toString()}`;
  },
};
