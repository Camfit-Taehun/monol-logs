# monol-logs

Claude Code 세션 관리 플러그인 - 등록, 보기, 이어하기, 요약, 시각화, 인사이트

[![npm version](https://img.shields.io/npm/v/monol-logs.svg)](https://www.npmjs.com/package/monol-logs)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## 주요 기능

- **세션 저장** - jsonl 복사 없이 참조만 저장 (저장 공간 절약)
- **세션 보기** - 사람이 읽기 쉬운 마크다운 형식으로 변환
- **세션 이어하기** - `claude --resume` 연동
- **AI 요약** - Claude API로 세션 내용 자동 요약
- **TODO 추출** - 세션에서 할 일 목록 추출
- **시각화** - ASCII 타임라인, 마크다운, HTML 대시보드
- **인사이트** - 개인/팀 작업 패턴, 지식 맵, TODO 현황 분석
- **세션 분기** - git worktree로 세션 브랜치 관리

## 설치

```bash
npm install -g monol-logs
```

## Claude Code 스킬

Claude Code 내에서 슬래시 명령어로 사용:

| 명령어 | 설명 |
|--------|------|
| `/save` | 세션 저장 |
| `/sessions` | 세션 목록 |
| `/session view <id>` | 세션 내용 보기 |
| `/session load <id>` | 세션 컨텍스트 로드 |
| `/session resume <id>` | 세션 이어하기 |
| `/summary` | AI 요약 생성 |
| `/roadmap` | TODO 추출 |
| `/visualize` | 시각화 |
| `/insights` | 인사이트 분석 |
| `/branch` | 세션 분기 |

### 예시

```bash
# 세션 저장
/save                      # 최근 세션 저장
/save f6702810 login-feat  # 특정 세션 + 토픽으로 저장

# 세션 보기
/session view f6702810     # 세션 내용 보기
/session load f6702810     # 요약을 현재 컨텍스트에 로드

# 시각화
/visualize                 # ASCII 타임라인
/visualize --html --open   # HTML 대시보드 생성 후 열기

# 인사이트
/insights                  # 전체 인사이트
/insights --me             # 내 작업 패턴
/insights --team           # 팀 기여도
/insights --todos          # TODO 현황
```

## CLI 사용법

터미널에서 직접 실행:

```bash
# 버전 확인
monol-logs --version

# 세션 관리
monol-logs session view <id>
monol-logs session load <id>
monol-logs session resume <id>

# 시각화
monol-logs visualize --ascii
monol-logs visualize --md
monol-logs visualize --html --open

# 인사이트
monol-logs insights --me
monol-logs insights --team
monol-logs insights --todos
monol-logs insights --report
```

## 파일 구조

세션은 프로젝트 내 `.claude/sessions/`에 저장됩니다:

```
.claude/sessions/
├── index.md                                    # 세션 목록
├── roadmap.md                                  # TODO 통합
├── alice_2026-01-18_1430_login-feature_f6702810.meta.json
├── alice_2026-01-18_1430_login-feature_f6702810.conversation.md
├── alice_2026-01-18_1430_login-feature_f6702810.summary.md
├── alice_2026-01-18_1430_login-feature_f6702810.roadmap.md
└── ...
```

**파일 형식:**
- `.meta.json` - 메타데이터 (원본 경로 참조)
- `.conversation.md` - 전체 대화 (읽기 좋은 형태)
- `.summary.md` - AI 요약
- `.roadmap.md` - 세션별 TODO

## 설정

`config.yaml`에서 설정 변경:

```yaml
# 출력 디렉토리
output_dir: .claude/sessions

# 요약
summary_enabled: true
summary_use_ai: true

# 로드맵
roadmap_enabled: true
roadmap_per_session: true

# 인덱스
index_enabled: true
auto_update_index: true

# 인사이트
insights_enabled: true
insights_stale_days: 14
```

## AI 요약 설정

AI 요약 기능을 사용하려면 API 키 설정이 필요합니다:

```bash
export ANTHROPIC_API_KEY="sk-..."
```

## 팀 협업

세션을 git으로 공유할 수 있습니다:

```bash
# 세션 저장 (작성자 자동 감지)
/save my-feature

# git으로 공유
git add .claude/sessions/
git commit -m "docs: add session logs"
git push

# 팀원 세션 확인
/sessions                    # 전체 목록
/sessions --author alice     # alice 세션만
/session load <id>           # 요약 로드
```

## 시각화 옵션

### ASCII 타임라인

```
/visualize --ascii
```

```
Session Timeline
════════════════════════════════════════════════════════════════

Legend: @ alice  # bob  * charlie

2026-01-22 (Today)
├─ 14:30 ─────────────────────────────────── 16:45
│  @ ████████████ login-feature (42 msgs, f6702810)
│
└─ 09:15 ─────────────────────────────────── 11:30
   # ██████████ api-refactor (28 msgs, a1b2c3d4)

════════════════════════════════════════════════════════════════
Summary: 2 sessions | 2 authors | 70 total messages
```

### 마크다운

```
/visualize --md
```

`.claude/sessions/visualization.md` 생성

### HTML 대시보드

```
/visualize --html --open
```

`.claude/sessions/dashboard.html` 생성 후 브라우저에서 열기

## 인사이트

### 개인 패턴

```
/insights --me
```

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
```

### 팀 기여도

```
/insights --team
```

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
```

### AI 리포트

```
/insights --report
```

AI가 세션 데이터를 분석하여 주간/월간 인사이트 리포트 생성

## vs `claude --resume`

| 기능 | `claude --resume` | monol-logs |
|------|-------------------|------------|
| 세션 이어하기 | ✓ | ✓ (연동) |
| 사람 읽기 쉬운 이름 | ❌ (UUID) | ✓ (토픽) |
| 세션 내용 보기 | ❌ | ✓ (markdown) |
| git 추적 | ❌ | ✓ (meta만) |
| TODO 추출 | ❌ | ✓ |
| AI 요약 | ❌ | ✓ |
| 시각화 | ❌ | ✓ |
| 인사이트 | ❌ | ✓ |
| 저장 공간 | 1x | 1x (중복 없음) |

## 요구사항

- macOS 또는 Linux
- Bash 4.0+
- jq (JSON 파싱)
- Node.js 16+ (선택, mock 서버용)

## 라이센스

MIT

## 기여

이슈와 PR을 환영합니다.

- GitHub: https://github.com/monol/monol-logs
- Issues: https://github.com/monol/monol-logs/issues
