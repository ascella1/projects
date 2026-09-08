# VentureOS

AI 에이전트들이 실제 회사 조직처럼 데이터로 연결되어 움직이는 1인 벤처 스튜디오 시스템.

## 조직도 / 데이터 흐름

```
Research Agent  ──▶ ventureos/research/<YYYY-MM-DD>-<N>.md
                          │
                          ▼
Market Agent    ──▶ ventureos/market/<YYYY-MM-DD>-<N>.md
                          │
                          ▼
Validation Agent ─▶ ventureos/validation/<YYYY-MM-DD>-<N>.md   (미구현)
                          │
                          ▼
Experiment Agent ─▶ ventureos/experiment/<YYYY-MM-DD>-<N>.md   (미구현)
                          │
                          ▼
Portfolio Agent  ─▶ ventureos/portfolio/<YYYY-MM-DD>-<N>.md    (미구현)
                          │
                          ▼
CEO Agent        ──▶ ventureos/decisions/<YYYY-MM-DD>-<N>.md
```

`N`은 같은 날짜 안에서의 실행 회차(1, 2, 3...)다. 하루에 여러 번 실행할 수 있으므로 날짜만으로는 파일이 겹칠 수 있어 인덱스를 붙인다. 파일 하나 안에는 그 실행에서 다룬 여러 `problem_id`(예: `P001`, `P002`)가 `## P001.` 같은 섹션으로 들어있고, 모든 단계는 이 `problem_id`를 공통 키로 사용해서 서로의 산출물을 찾는다.

## 폴더

- `research/` — Research Agent가 발굴한 문제 (근거 기반, 실행 1회당 1파일에 여러 문제 포함)
- `market/` — Market Agent의 시장성 점수/추천 (실행 1회당 1파일에 여러 문제 포함)
- `validation/` — (향후) 고객 인터뷰·설문 등 검증 결과
- `experiment/` — (향후) 랜딩페이지·광고 등 실험 결과
- `portfolio/` — (향후) 프로젝트별 누적 현황
- `decisions/` — CEO Agent의 자본 배분·의사결정 로그 (실행 회차별 1파일)
- `rejected.md` — founder가 명시적으로 거절한 `problem_id` 목록 (아래 "거절 워크플로우" 참고)

## 파이프라인 실행 순서

1. `research-agent`로 문제 발굴 → `ventureos/research/`에 저장 (매 회차 최소 10개, 오늘 기준 신선한 데이터 우선)
2. `market-agent`로 시장성 분석 → `ventureos/market/`에 저장
3. `ceo-agent`로 포트폴리오 검토 및 자본 배분 결정 → `ventureos/decisions/`에 저장

각 에이전트는 실행 전에 관련 폴더를 먼저 읽어 중복 작업을 피하고, 이전 산출물을 이어받아 작업한다. Validation/Experiment/Portfolio Agent는 아직 없으므로, CEO Agent는 해당 데이터가 없을 때 이를 리스크로 명시한다.

## 거절 워크플로우

Founder가 `decisions/`의 결과를 검토하다가 특정 `problem_id`가 마음에 들지 않으면, 채팅으로 알려준다 ("P002, P004는 별로다" 등). 그러면 그 `problem_id`가 `ventureos/rejected.md`에 기록되고, 이후 모든 회차에서 CEO Agent는 그 문제를 다시 랭킹/결정에 올리지 않는다 (Research Agent도 동일한 아이디어를 재조사하지 않으려 시도한다). `rejected.md`는 founder 또는 그 지시를 받은 세션만 수정하며, 에이전트가 스스로 쓰지 않는다.
