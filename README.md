# monol-logs

Claude Code 세션 아카이브 플러그인 v3.2

> **"모든 AI 대화를 프로젝트 자산으로"**

## 왜 필요한가?

Claude Code는 세션을 `~/.claude/projects/` 아래에 저장하지만:
- **언제 삭제될지 모름** - Claude Code가 관리하는 영역
- **식별 불가** - `f6702810-b552-4a0c-9a93-053c8d44d240.jsonl` 같은 UUID
- **버전 관리 외부** - 프로젝트 git에 포함되지 않음

이 플러그인은 세션을 **프로젝트 내부에 자동 저장**하고, **로드맵/요약/인덱스**를 자동 생성합니다.

## 핵심 기능

### 1. 세션 자동 저장
- **SessionEnd 훅**: 세션 종료 시 자동 백업
- **PreCompact 훅**: 컨텍스트 압축 전 원본 보존
- **식별 가능한 파일명**: `2026-01-18_1430_f6702810.jsonl`

### 2. 로드맵 관리 (v2.0)
- 세션에서 TODO/할 일 자동 추출
- 통합 `roadmap.md` 관리
- 세션별 `.roadmap.md` 생성

### 3. AI 요약 (v2.0)
- Claude API로 세션 요약 자동 생성
- 주요 작업, 결정사항, 다음 할 일 추출
- 세션별 `.summary.md` 생성

### 4. 세션 인덱스 (v2.0)
- 전체 세션 목록 `index.md` 자동 생성
- 날짜, 토픽, 메시지 수, 크기 등 메타데이터

### 5. 세션 브랜치 (v3.0)
- **Git 브랜치처럼** 현재 세션을 분기
- git worktree 자동 생성 + 새 터미널 열기
- 대화 컨텍스트 유지하며 새 작업 시작

### 6. Claude Code 스킬 (v3.2)
- `/sessions` - 세션 목록 및 인덱스 관리
- `/export` - 세션 내보내기
- `/roadmap` - TODO/로드맵 추출
- `/summary` - AI 요약 생성
- `/branch` - 세션 분기

## 구조

```
.claude/plugins/session-archive/
├── CLAUDE.md
├── config.yaml
├── commands/
│   ├── sessions.md           # /sessions 스킬
│   ├── export.md             # /export 스킬
│   ├── roadmap.md            # /roadmap 스킬
│   ├── summary.md            # /summary 스킬
│   └── branch.md             # /branch 스킬
├── hooks/
│   ├── on-session-end.sh     # SessionEnd 훅
│   └── on-pre-compact.sh     # PreCompact 훅
├── scripts/
│   ├── setup.sh              # 설치
│   ├── export-session.sh     # 수동 내보내기
│   ├── extract-roadmap.sh    # 로드맵 추출
│   ├── generate-summary.sh   # 요약 생성
│   ├── update-index.sh       # 인덱스 업데이트
│   └── session-branch.sh     # 세션 브랜치 스크립트
└── lib/
    ├── utils.sh              # 공통 유틸
    ├── roadmap.sh            # 로드맵 유틸
    ├── summary.sh            # 요약 유틸
    └── branch.sh             # 브랜치 유틸
```

## 설치

```bash
# 1. 레포 클론
git clone https://github.com/your/monol-logs.git ~/Work/kent-labs/monol-logs

# 2. 설치 스크립트 실행
~/Work/kent-labs/monol-logs/.claude/plugins/session-archive/scripts/setup.sh
```

## 사용법

### 스킬 (Claude Code 안에서)

```
# 세션 목록
/sessions                    # 아카이브된 세션 목록
/sessions --available        # 내보내기 가능한 세션
/sessions --update           # index.md 갱신

# 세션 내보내기
/export                      # 최근 세션 내보내기
/export <id> <topic>         # 특정 세션 + 토픽 지정

# 로드맵/TODO
/roadmap                     # 최근 세션 TODO 추출
/roadmap --show              # roadmap.md 보기

# AI 요약
/summary                     # 최근 세션 AI 요약
/summary --rule-based        # API 없이 규칙 기반

# 세션 분기
/branch feature-b            # git worktree + 새 터미널
/branch exp --same-dir       # 같은 폴더에서 세션만 분기
```

### 자동 저장 (설치 후 자동)

세션 종료 시 자동으로:
1. 세션 파일 저장
2. TODO/로드맵 추출
3. AI 요약 생성 (백그라운드)
4. 인덱스 업데이트

```
$PROJECT/.claude/sessions/
├── index.md                          # 세션 목록
├── roadmap.md                        # 통합 TODO
├── 2026-01-18_1430_f6702810.jsonl    # 세션 원본
├── 2026-01-18_1430_f6702810.summary.md   # AI 요약
└── 2026-01-18_1430_f6702810.roadmap.md   # 세션별 TODO
```

### 수동 명령어

```bash
# 세션 내보내기
export-session.sh                     # 최근 세션
export-session.sh f6702810 "topic"    # 토픽 지정

# 로드맵 관리
extract-roadmap.sh                    # 최근 세션 TODO 추출
extract-roadmap.sh --all              # 모든 세션 TODO 추출
extract-roadmap.sh --show             # roadmap.md 보기

# 요약 생성
generate-summary.sh                   # 최근 세션 AI 요약
generate-summary.sh --rule-based      # API 없이 규칙 기반

# 인덱스 업데이트
update-index.sh                       # index.md 갱신
update-index.sh --show                # index.md 보기

# 세션 브랜치 (v3.0)
session-branch.sh feature-b           # git worktree + 새 터미널
session-branch.sh exp --same-dir      # 같은 폴더에서 세션만 분기
session-branch.sh fix --no-auto       # 터미널 자동 열기 안 함
session-branch.sh --list              # 현재 세션 목록
session-branch.sh --branches          # 분기 기록 보기
```

## 설정

`config.yaml`:

```yaml
# 기본
output_dir: ".claude/sessions"
verbose: false

# 로드맵
roadmap_enabled: true
roadmap_per_session: true

# 요약 (AI)
summary_enabled: true
summary_use_ai: true
# API 키: 환경변수 ANTHROPIC_API_KEY 또는 여기에 설정

# 인덱스
index_enabled: true
```

## API 키 설정

AI 요약 기능을 사용하려면:

```bash
# 방법 1: 환경변수
export ANTHROPIC_API_KEY="sk-..."

# 방법 2: config.yaml
anthropic_api_key: "sk-..."

# 방법 3: macOS 키체인
security add-generic-password -s "anthropic-api-key" -a "$USER" -w "sk-..."
```

## 라이선스

MIT
