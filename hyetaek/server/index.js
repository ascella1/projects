import 'dotenv/config';
import express from 'express';
import cors from 'cors';

import { sources, findSource } from './sources/index.js';
import { normalizeUpstreamResponse } from './sources/normalize.js';

const app = express();
const PORT = process.env.PORT || 8787;

const CACHE_TTL_MS = 10 * 60 * 1000; // 정부 API 일일 호출 제한 대응 (docs/04 6번)
const cache = new Map(); // `${sourceId}?${queryString}` -> { body, expiresAt }

app.use(cors());

app.get('/health', (_req, res) => res.json({ ok: true }));

/** 등록된 소스 목록 + 키 설정 여부만 반환 (키 값 자체는 절대 노출하지 않음). */
app.get('/api/sources', (_req, res) => {
  res.json({
    sources: sources.map((s) => ({ id: s.id, name: s.name, configured: Boolean(process.env[s.envKey]) })),
  });
});

app.get('/api/sources/:id', async (req, res) => {
  const source = findSource(req.params.id);
  if (!source) return res.status(404).json({ error: 'unknown_source' });

  const apiKey = process.env[source.envKey];
  if (!apiKey) {
    return res.status(503).json({ error: `${source.envKey} not configured` });
  }

  const cacheKey = `${source.id}?${new URLSearchParams(req.query).toString()}`;
  const cached = cache.get(cacheKey);
  if (cached && cached.expiresAt > Date.now()) {
    return res.json(cached.body);
  }

  try {
    const upstream = await fetch(source.buildUrl(req.query, apiKey), { signal: AbortSignal.timeout(8000) });
    const text = await upstream.text();
    const items = normalizeUpstreamResponse(text, source.keyHint);
    const body = { items, fetchedAt: new Date().toISOString(), source: source.id };
    cache.set(cacheKey, { body, expiresAt: Date.now() + CACHE_TTL_MS });
    res.json(body);
  } catch (err) {
    res.status(502).json({ error: 'upstream_fetch_failed', message: String(err?.message ?? err) });
  }
});

/**
 * 실제 키로 첫 호출을 해보기 전엔 응답 스키마(JSON/XML, 래핑 구조)를 100% 확정할 수 없어서
 * 원본 그대로 확인할 수 있는 디버그용 엔드포인트를 소스 공통으로 남겨둔다.
 */
app.get('/api/sources/:id/raw', async (req, res) => {
  const source = findSource(req.params.id);
  if (!source) return res.status(404).json({ error: 'unknown_source' });

  const apiKey = process.env[source.envKey];
  if (!apiKey) {
    return res.status(503).json({ error: `${source.envKey} not configured` });
  }

  try {
    const upstream = await fetch(source.buildUrl(req.query, apiKey), { signal: AbortSignal.timeout(8000) });
    const text = await upstream.text();
    res.type(upstream.headers.get('content-type') ?? 'text/plain').send(text);
  } catch (err) {
    res.status(502).json({ error: 'upstream_fetch_failed', message: String(err?.message ?? err) });
  }
});

app.listen(PORT, () => {
  console.log(`hyetaek proxy server listening on http://localhost:${PORT}`);
  for (const s of sources) {
    if (!process.env[s.envKey]) {
      console.warn(`${s.envKey}가 설정되지 않았습니다. /api/sources/${s.id}는 503을 반환합니다. .env.example 참고.`);
    }
  }
});
