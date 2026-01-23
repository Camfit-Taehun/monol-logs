---
description: 세션 로그에서 개인/팀/프로젝트 인사이트 도출
use_when:
  - 사용자가 "인사이트", "분석", "통계" 등을 언급할 때
  - 작업 패턴이나 생산성을 알고 싶을 때
  - 팀 기여도나 지식 맵을 확인하고 싶을 때
  - 미완료 TODO 현황을 파악하고 싶을 때
---

# /insights - 세션 인사이트

세션 로그를 분석하여 개인/팀/프로젝트 인사이트를 도출합니다.

## 사용법

```
/insights                    # 전체 인사이트
/insights --me               # 내 인사이트만
/insights --team             # 팀 인사이트
/insights --todos            # TODO 현황
/insights --author alice     # 특정 멤버 필터
/insights --knowledge-map    # 지식 맵만
/insights --report           # AI 분석 리포트 생성
/insights --report --weekly  # 주간 리포트
/insights --report --monthly # 월간 리포트
```

## 인자: $ARGUMENTS

## 동작

### 1. 인자 파싱

- (없음): 전체 인사이트 (개인 + 팀 + TODO)
- `--me` 또는 `-m`: 개인 인사이트만
- `--team` 또는 `-t`: 팀 인사이트만
- `--todos` 또는 `-d`: TODO 현황만
- `--author NAME`: 특정 작성자 필터
- `--knowledge-map` 또는 `-k`: 지식 맵만
- `--report` 또는 `-r`: AI 분석 리포트 생성
- `--weekly`: 주간 리포트 (기본값)
- `--monthly`: 월간 리포트
- `--export md`: 리포트를 마크다운 파일로 저장
- `--help` 또는 `-h`: 도움말

### 2. 세션 데이터 수집

`.claude/sessions/*.meta.json` 파일들에서 메타데이터 수집:
- sessionId, topic, savedBy, createdAt, savedAt, messageCount

### 3. 개인 인사이트 (--me)

세션 데이터를 분석하여 출력:

```
📊 My Work Patterns
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Peak Hours:    14:00 - 18:00
Most Active:   Tue, Thu
Avg Session:   2h 15m
Total:         24 sessions

🏷️ Topics I Work On
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
auth           ████████████ 35%
api            ████████     24%
bugfix         ██████       18%
docs           ████         12%
other          ███          11%
```

#### 계산 방법
- **Peak Hours**: createdAt의 시간대별 분포에서 최빈값
- **Most Active**: createdAt의 요일별 분포에서 최빈값
- **Avg Session**: (savedAt - createdAt) 평균
- **Topics**: topic 필드에서 기본 영역 추출 후 집계

### 4. 팀 인사이트 (--team)

```
👥 Team Contribution
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
alice        ████████████████ 24 sessions (45%)
bob          ██████████       15 sessions (28%)
charlie      █████████        14 sessions (26%)

🗺️ Knowledge Map
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
auth/*         → alice (●), bob
api/payments   → bob (●) ⚠️ sole owner
frontend/*     → charlie (●), alice
database       → alice (●), bob, charlie
infra          → (no sessions) ⚠️
```

#### 계산 방법
- **Contribution**: savedBy별 세션 수 집계
- **Knowledge Map**: topic에서 영역 추출, savedBy별 세션 수로 담당자 결정
- **sole owner 경고**: 해당 영역에 1명만 세션이 있는 경우

### 5. TODO 인사이트 (--todos)

```
📋 Open TODOs
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Total: 23 open, 15 completed
⚠️ Stale (>2 weeks): 8

[ ] Add unit tests for auth module
    login-feature · alice · 3d ago
[ ] Implement password reset
    login-feature · alice · 3d ago
[ ] Optimize database queries
    api-refactor · bob · 10d ago ⚠️
...
```

#### 계산 방법
- `.claude/sessions/*.roadmap.md` 파일들에서 TODO 수집
- 미완료: `- [ ]` 패턴
- 완료: `- [x]` 패턴
- Stale: 2주 이상 된 미완료 TODO

### 6. 지식 맵 (--knowledge-map)

영역별 담당자를 시각화:

```
🗺️ Knowledge Map
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
auth/*         → alice (●), bob
api/*          → bob (●), charlie
frontend/*     → charlie (●), alice ⚠️
docs/*         → bob (●)
test/*         → (no sessions) ⚠️
```

#### 영역 추출 규칙
- `auth`, `login` 포함 → `auth`
- `api` 포함 → `api`
- `ui`, `dashboard`, `frontend` 포함 → `frontend`
- `doc` 포함 → `docs`
- `test` 포함 → `test`
- `bug`, `fix` 포함 → `bugfix`
- 그 외 → topic의 첫 번째 단어 (하이픈 기준)

### 7. 결과 출력

분석 완료 후:
```
Tip: Use /visualize --html for interactive dashboard
```

## 예시

```
/insights
→ 전체 인사이트 (개인 + 팀 + TODO)

/insights --me
→ 내 작업 패턴과 토픽 분포

/insights --team
→ 팀 기여도와 지식 맵

/insights --todos
→ 미완료 TODO 목록

/insights --author bob --todos
→ bob의 TODO만

/insights --knowledge-map
→ 영역별 담당자 맵
```

## 데이터 소스

### meta.json 예시
```json
{
  "sessionId": "f6702810-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "topic": "login-feature",
  "savedBy": "alice",
  "createdAt": "2026-01-18T14:30:00Z",
  "savedAt": "2026-01-18T18:00:00Z",
  "messageCount": 42
}
```

### roadmap.md 예시
```markdown
# Session Roadmap

## TODO Items

- [ ] Add unit tests for auth module
- [ ] Implement password reset
- [x] Setup JWT middleware (completed)
```

### 8. AI 리포트 (--report)

AI를 활용하여 세션 데이터를 분석하고 인사이트 리포트를 생성합니다.

```
/insights --report
→ 주간 AI 분석 리포트 생성

/insights --report --monthly
→ 월간 AI 분석 리포트 생성

/insights --report --export md
→ .claude/sessions/report_2026-01-19.md 로 저장
```

#### 리포트 구조

```markdown
# Weekly Insights Report
Generated: 2026-01-19

## Executive Summary
이번 주 팀은 총 12개의 세션을 진행했으며...

## Highlights
- ✅ login-feature 완료 (alice 주도)
- 🔄 api-refactor 진행 중 (bob, charlie 협업)
- ⚠️ payments 모듈 지식 집중 (bob만 담당)

## Team Analysis

### 기여도 분석
alice가 가장 활발하게 활동했으며...

### 지식 맵 분석
auth/* 영역은 alice가 primary owner...

### 협업 기회
api-refactor에 alice 참여 권장...

## Technical Debt
2주 이상 된 미완료 TODO 8개...

## Recommendations
1. payments 모듈 지식 공유 세션 권장
2. 오래된 TODO 정리 필요
3. ...

## Next Steps
- [ ] 지식 공유 세션 스케줄링
- [ ] TODO 정리 회의
```

#### 요구사항
- `ANTHROPIC_API_KEY` 환경변수 설정 필요
- 또는 `config.yaml`에 `anthropic_api_key` 설정

## 예시

```
/insights
→ 전체 인사이트 (개인 + 팀 + TODO)

/insights --me
→ 내 작업 패턴과 토픽 분포

/insights --team
→ 팀 기여도와 지식 맵

/insights --todos
→ 미완료 TODO 목록

/insights --author bob --todos
→ bob의 TODO만

/insights --knowledge-map
→ 영역별 담당자 맵

/insights --report
→ AI 분석 리포트 생성

/insights --report --export md
→ 리포트를 파일로 저장
```

## 주의사항

- 인사이트는 아카이브된 세션만 분석합니다
- 정확한 분석을 위해 세션 저장 시 topic과 savedBy가 필요합니다
- AI 리포트는 ANTHROPIC_API_KEY가 필요합니다
- 대시보드에서 더 상세한 시각화: `/visualize --html`
