# Session Archive Plugin

Claude Code 세션을 프로젝트 내에 자동 저장하는 플러그인

## 설치 필요

이 플러그인을 사용하려면 `~/.claude/settings.json`에 hooks 설정이 필요합니다.

```bash
# 자동 설정
./scripts/setup.sh

# 또는 수동으로 ~/.claude/settings.json에 추가:
{
  "hooks": {
    "SessionEnd": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.claude/plugins/session-archive/hooks/on-session-end.sh"
          }
        ]
      }
    ]
  }
}
```

## 동작

- **SessionEnd**: 세션 종료 시 `$CLAUDE_PROJECT_DIR/.claude/sessions/`에 자동 저장
- **파일명**: `YYYY-MM-DD_HHMM_{session-id-short}.jsonl`

## 설정

`config.yaml`에서 커스터마이즈 가능:

```yaml
output_dir: ".claude/sessions"
filename_format: "{date}_{time}_{session_id}"
generate_summary: true
```
