import { XMLParser } from 'fast-xml-parser';

const xmlParser = new XMLParser({ ignoreAttributes: false, trimValues: true });

/**
 * 응답이 JSON이면 그대로 파싱, 아니면 XML로 간주해 변환한 뒤
 * `keyHint`(소스별로 다른 정규식, 예 /plcy/i)에 매칭되는 키를 가진 객체 배열을 재귀 탐색해 뽑아낸다.
 * 실제 필드명이 문서와 다르더라도 서버가 죽지 않고 빈 배열을 반환하도록 방어적으로 작성.
 */
export function normalizeUpstreamResponse(text, keyHint) {
  let parsed;
  try {
    parsed = JSON.parse(text);
  } catch {
    try {
      parsed = xmlParser.parse(text);
    } catch {
      return [];
    }
  }

  if (Array.isArray(parsed)) return parsed;

  const found = findArrayByKeyHint(parsed, keyHint);
  return found ?? [];
}

function findArrayByKeyHint(node, keyHint, depth = 0) {
  if (depth > 6 || node == null || typeof node !== 'object') return null;

  if (Array.isArray(node)) {
    if (node.length > 0 && typeof node[0] === 'object' && looksLikeMatch(node[0], keyHint)) {
      return node;
    }
    return null;
  }

  for (const value of Object.values(node)) {
    if (Array.isArray(value) && value.length > 0 && typeof value[0] === 'object' && looksLikeMatch(value[0], keyHint)) {
      return value;
    }
  }
  for (const value of Object.values(node)) {
    if (typeof value === 'object') {
      const nested = findArrayByKeyHint(value, keyHint, depth + 1);
      if (nested) return nested;
    }
  }
  return null;
}

function looksLikeMatch(obj, keyHint) {
  if (!obj || typeof obj !== 'object') return false;
  return Object.keys(obj).some((k) => keyHint.test(k));
}
