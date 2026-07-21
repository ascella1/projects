import { youthCenterSource } from './youthCenter.js';
import { bokjiroSource } from './bokjiro.js';

/**
 * 정부 오픈API 소스 레지스트리. 새 소스를 추가하려면 이 배열에 등록만 하면 되고
 * server/index.js의 라우트는 전혀 손댈 필요 없다 (docs/04 "새 데이터 소스 추가 = 새 어댑터" 원칙).
 */
export const sources = [youthCenterSource, bokjiroSource];

export function findSource(id) {
  return sources.find((s) => s.id === id);
}
