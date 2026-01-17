# Session Archive Plugin

Claude Code 세션을 프로젝트 내에 자동 저장하는 플러그인

## 설치

```bash
# setup.sh 실행 (심볼릭 링크 + hooks 설정)
./scripts/setup.sh
```

## 동작

### 자동 훅

| 훅 | 시점 | 파일명 |
|---|---|---|
| PreCompact | 컨텍스트 압축 전 | `*_precompact_*.jsonl` |
| SessionEnd | 세션 종료 시 | `YYYY-MM-DD_HHMM_{session-id}.jsonl` |

- PreCompact: 압축 전 원본 보존 (세션 종료 시 삭제됨)
- SessionEnd: 최종 세션 파일 저장

### 수동 내보내기

```bash
# 최근 세션
./scripts/export-session.sh

# 특정 세션 + 토픽명
./scripts/export-session.sh f6702810 "my-topic"

# 목록 보기
./scripts/export-session.sh --list
./scripts/export-session.sh --list-archived
```

## 설정

`config.yaml`:

```yaml
output_dir: ".claude/sessions"    # 저장 위치
generate_summary: false           # 요약 생성 (TODO)
update_index: false               # 인덱스 업데이트 (TODO)
retention_days: 0                 # 보관 기간 (0=무제한)
verbose: false                    # 상세 로그
```

## 파일 구조

```
.claude/plugins/session-archive/
├── hooks/
│   ├── on-session-end.sh    # SessionEnd 훅
│   └── on-pre-compact.sh    # PreCompact 훅
├── scripts/
│   ├── setup.sh             # 설치
│   └── export-session.sh    # 수동 내보내기
├── lib/
│   └── utils.sh             # 공통 유틸
├── config.yaml              # 설정
└── CLAUDE.md                # 이 파일
```

## 훅 입력 형식

Claude Code가 훅에 전달하는 JSON:

```json
{
  "session_id": "f6702810-b552-4a0c-9a93-053c8d44d240",
  "transcript_path": "/Users/kent/.claude/projects/.../f6702810-....jsonl"
}
```

환경 변수:
- `CLAUDE_PROJECT_DIR`: 현재 프로젝트 디렉토리

## 문제 해결

### 세션이 저장되지 않음

1. hooks 설정 확인:
```bash
cat ~/.claude/settings.json | jq '.hooks'
```

2. 플러그인 심볼릭 링크 확인:
```bash
ls -la ~/.claude/plugins/session-archive
```

3. 실행 권한 확인:
```bash
ls -la ~/.claude/plugins/session-archive/hooks/
```

### 로그 보기

`config.yaml`에서 `verbose: true` 설정 후 세션 종료
