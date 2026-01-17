# monol-logs

Claude Code 세션 아카이브 플러그인

> **"모든 AI 대화를 프로젝트 자산으로"**

## 왜 필요한가?

Claude Code는 세션을 `~/.claude/projects/` 아래에 저장하지만:
- **언제 삭제될지 모름** - Claude Code가 관리하는 영역
- **식별 불가** - `f6702810-b552-4a0c-9a93-053c8d44d240.jsonl` 같은 UUID
- **버전 관리 외부** - 프로젝트 git에 포함되지 않음

이 플러그인은 세션을 **프로젝트 내부에 자동 저장**합니다.

## 기능

- **SessionEnd 훅**: 세션 종료 시 자동 백업
- **PreCompact 훅**: 컨텍스트 압축 전 원본 보존
- **수동 내보내기**: 원하는 시점에 세션 저장
- **식별 가능한 파일명**: `2026-01-18_1430_f6702810.jsonl`

## 구조

```
.claude/plugins/session-archive/
├── CLAUDE.md              # 플러그인 설명
├── config.yaml            # 설정
├── hooks/
│   ├── on-session-end.sh  # SessionEnd 훅
│   └── on-pre-compact.sh  # PreCompact 훅
├── scripts/
│   ├── setup.sh           # 설치 스크립트
│   └── export-session.sh  # 수동 내보내기
└── lib/
    └── utils.sh           # 공통 유틸
```

## 설치

```bash
# 1. 레포 클론
git clone https://github.com/your/monol-logs.git ~/Work/kent-labs/monol-logs

# 2. 설치 스크립트 실행
~/Work/kent-labs/monol-logs/.claude/plugins/session-archive/scripts/setup.sh
```

설치 후 자동으로:
- `~/.claude/plugins/session-archive`에 심볼릭 링크 생성
- `~/.claude/settings.json`에 hooks 설정 추가

## 사용법

### 자동 저장 (설치 후 자동)

세션 종료 시 자동으로 저장됩니다:
```
$PROJECT/.claude/sessions/2026-01-18_1430_f6702810.jsonl
```

### 수동 내보내기

```bash
# 최근 세션 내보내기
export-session.sh

# 특정 세션 (세션 ID 앞부분)
export-session.sh f6702810

# 토픽 이름 지정
export-session.sh f6702810 "feature-auth"
# → 2026-01-18_1430_feature-auth_f6702810.jsonl

# 사용 가능한 세션 목록
export-session.sh --list

# 이미 저장된 세션 목록
export-session.sh --list-archived
```

## 설정

`config.yaml`에서 커스터마이즈:

```yaml
# 저장 위치 (프로젝트 기준 상대 경로)
output_dir: ".claude/sessions"

# 요약 생성 (TODO)
generate_summary: false

# 인덱스 자동 업데이트 (TODO)
update_index: false

# 최대 보관 기간 (일, 0=무제한) (TODO)
retention_days: 0
```

## 다른 컴퓨터에서 사용

```bash
# 1. 레포 클론
git clone https://github.com/your/monol-logs.git ~/Work/kent-labs/monol-logs

# 2. 설치
~/Work/kent-labs/monol-logs/.claude/plugins/session-archive/scripts/setup.sh

# 끝!
```

## 로드맵

- [x] SessionEnd 훅
- [x] PreCompact 훅
- [x] 수동 내보내기
- [ ] 세션 요약 자동 생성 (`.summary.md`)
- [ ] 세션 인덱스 자동 관리 (`index.md`)
- [ ] 토픽 자동 추출 (AI 기반)
- [ ] 보관 정책 (오래된 세션 정리)

## 라이선스

MIT
