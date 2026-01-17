# Session Archive Plugin v4.0

Claude Code 세션을 프로젝트 내에 자동 저장 + 로드맵/요약/인덱스/브랜치

## 설치 (Claude Code 플러그인)

```bash
# 1. 레포 클론
git clone https://github.com/your/monol-logs.git ~/monol-logs

# 2. ~/.claude/settings.json에 마켓플레이스 등록
```

`~/.claude/settings.json`:
```json
{
  "extraKnownMarketplaces": {
    "monol-logs": {
      "source": {
        "source": "directory",
        "path": "~/monol-logs/.claude/plugins"
      }
    }
  },
  "enabledPlugins": {
    "session-archive@monol-logs": true
  }
}
```

플러그인 활성화 후 자동으로:
- `/sessions`, `/export`, `/roadmap`, `/summary`, `/branch` 스킬 사용 가능
- SessionEnd, PreCompact 훅 자동 등록

## 스킬 (Commands)

```
/sessions                # 아카이브된 세션 목록
/sessions --available    # 내보내기 가능한 세션
/sessions --update       # index.md 갱신

/export                  # 최근 세션 내보내기
/export <id> <topic>     # 특정 세션 내보내기
/export --list           # 내보내기 가능한 세션

/roadmap                 # 최근 세션 TODO 추출
/roadmap --show          # roadmap.md 보기
/roadmap --all           # 모든 세션 TODO 추출

/summary                 # 최근 세션 AI 요약
/summary --show          # 요약 보기
/summary --rule-based    # API 없이 규칙 기반

/branch <name>           # 세션 분기 → git worktree + 새 터미널
/branch <name> --same-dir # 같은 폴더에서 세션만 분기
/branch --branches       # 분기 기록
```

## 자동 동작 (SessionEnd 훅)

세션 종료 시:
1. **세션 저장** → `.claude/sessions/{date}_{time}_{id}.jsonl`
2. **로드맵 추출** → `roadmap.md` + `{session}.roadmap.md`
3. **AI 요약 생성** → `{session}.summary.md` (백그라운드)
4. **인덱스 업데이트** → `index.md`

## 수동 스크립트

```bash
# 세션 내보내기
./scripts/export-session.sh [session-id] [topic]
./scripts/export-session.sh --list

# 로드맵 추출
./scripts/extract-roadmap.sh [session-file]
./scripts/extract-roadmap.sh --show
./scripts/extract-roadmap.sh --all

# AI 요약 생성
./scripts/generate-summary.sh [session-file]
./scripts/generate-summary.sh --rule-based   # API 없이

# 인덱스 업데이트
./scripts/update-index.sh
./scripts/update-index.sh --show

# 세션 브랜치 (v3.0)
./scripts/session-branch.sh feature-b     # worktree + 새 터미널
./scripts/session-branch.sh exp --same-dir # 같은 폴더
./scripts/session-branch.sh --list        # 세션 목록
./scripts/session-branch.sh --branches    # 분기 기록
```

## 설정 (config.yaml)

```yaml
# 로드맵
roadmap_enabled: true
roadmap_per_session: true

# AI 요약
summary_enabled: true
summary_use_ai: true

# 인덱스
index_enabled: true
```

## 생성되는 파일들

```
.claude/sessions/
├── index.md                      # 세션 목록 (자동 업데이트)
├── roadmap.md                    # 통합 TODO 목록
├── 2026-01-18_1430_f6702810.jsonl       # 세션 원본
├── 2026-01-18_1430_f6702810.summary.md  # AI 요약
└── 2026-01-18_1430_f6702810.roadmap.md  # 세션별 TODO
```

## API 키

AI 요약에 필요:
```bash
export ANTHROPIC_API_KEY="sk-..."
# 또는 config.yaml의 anthropic_api_key
```

## 파일 구조

```
.claude/plugins/
├── marketplace.json           # 마켓플레이스 정의
└── session-archive/
    ├── plugin.json            # 플러그인 매니페스트
    ├── commands/
    │   ├── sessions.md        # /sessions 스킬
    │   ├── export.md          # /export 스킬
    │   ├── roadmap.md         # /roadmap 스킬
    │   ├── summary.md         # /summary 스킬
    │   └── branch.md          # /branch 스킬
    ├── hooks/
    │   ├── hooks.json         # 훅 정의
    │   ├── on-session-end.sh  # 세션 종료 훅
    │   └── on-pre-compact.sh  # 압축 전 훅
    ├── scripts/               # 수동 스크립트 (선택)
    ├── lib/                   # 공통 유틸
    ├── config.yaml            # 설정
    └── CLAUDE.md              # 이 파일
```
