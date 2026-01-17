#!/bin/bash
# Session Archive - SessionEnd Hook
# 세션 종료 시 자동으로 세션 파일을 프로젝트 내에 백업

set -e

# stdin에서 JSON 입력 받기
read -r input

# 필요한 정보 추출
SESSION_ID=$(echo "$input" | jq -r '.session_id')
TRANSCRIPT_PATH=$(echo "$input" | jq -r '.transcript_path')

# 프로젝트 디렉토리 확인
if [ -z "$CLAUDE_PROJECT_DIR" ]; then
  echo "CLAUDE_PROJECT_DIR not set" >&2
  exit 1
fi

# 백업 디렉토리
BACKUP_DIR="$CLAUDE_PROJECT_DIR/.claude/sessions"
mkdir -p "$BACKUP_DIR"

# 파일명 생성: YYYY-MM-DD_HHMM_세션ID앞8자리
TIMESTAMP=$(date +%Y-%m-%d_%H%M)
SHORT_ID="${SESSION_ID:0:8}"
FILENAME="${TIMESTAMP}_${SHORT_ID}.jsonl"

# 복사
if [ -f "$TRANSCRIPT_PATH" ]; then
  cp "$TRANSCRIPT_PATH" "$BACKUP_DIR/$FILENAME"
  echo "Session archived: $BACKUP_DIR/$FILENAME" >&2
else
  echo "Transcript not found: $TRANSCRIPT_PATH" >&2
  exit 1
fi

exit 0
