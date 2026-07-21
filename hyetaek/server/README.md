# hyetaek proxy server

Flutter 앱이 정부 오픈API 키를 직접 들고 있지 않도록 하는 경량 프록시. 특히 web 빌드는 JS 번들에 키가 그대로 노출되므로 반드시 서버를 경유한다. 소스는 `server/sources/`에 레지스트리로 등록되어 있고, 새 소스를 추가해도 라우트는 그대로다.

## 실행

```bash
npm install
cp .env.example .env   # 아래 소스별 키 채우기 (하나만 채워도 그 소스만 동작, 나머지는 503)
npm start               # http://localhost:8787
```

## 등록된 소스

| id | 대상 | 키 | 발급처 |
|---|---|---|---|
| `youth-policies` | 청년 | `YOUTH_API_KEY` | youthcenter.go.kr 마이페이지 (승인제) |
| `bokjiro` | 노인/중장년/청년/학생 등 전 생애주기 | `BOKJIRO_API_KEY` | data.go.kr 활용신청 |

키가 없어도 서버는 정상 기동하고, 해당 소스만 503을 반환한다 (다른 소스/seed 데이터에는 영향 없음).

## 엔드포인트

- `GET /health` — 헬스체크
- `GET /api/sources` — 등록된 소스 목록 + 키 설정 여부(`configured`)
- `GET /api/sources/:id?...` — 정규화된 목록 (`{ items, fetchedAt, source }`), 10분 캐시
- `GET /api/sources/:id/raw` — 업스트림 원본 응답 그대로 반환 (필드 매핑 확인/디버그용)
