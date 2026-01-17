#!/bin/bash
# Session Archive - PreCompact Hook
# 컨텍스트 압축 전에 현재 세션 상태를 백업
# 압축 후에는 대화 내용이 요약되므로, 원본 보존을 위해 이 시점에 저장

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(dirname "$SCRIPT_DIR")"

# 공통 유틸 로드
source "$PLUGIN_DIR/lib/utils.sh"

# stdin에서 JSON 입력 받기
read -r input

# 필요한 정보 추출
SESSION_ID=$(echo "$input" | jq -r '.session_id // empty')
TRANSCRIPT_PATH=$(echo "$input" | jq -r '.transcript_path // empty')

# 검증
if [ -z "$SESSION_ID" ]; then
  log "ERROR" "session_id not found in input"
  exit 0  # 에러여도 컴팩트는 진행되어야 함
fi

if [ -z "$TRANSCRIPT_PATH" ] || [ ! -f "$TRANSCRIPT_PATH" ]; then
  log "ERROR" "transcript not found: $TRANSCRIPT_PATH"
  exit 0
fi

# 프로젝트 디렉토리 확인
if [ -z "$CLAUDE_PROJECT_DIR" ]; then
  log "ERROR" "CLAUDE_PROJECT_DIR not set"
  exit 0
fi

# 백업 디렉토리
BACKUP_DIR=$(get_backup_dir)
mkdir -p "$BACKUP_DIR"

# 파일명 생성 (pre-compact임을 표시)
TIMESTAMP=$(date +%Y-%m-%d_%H%M)
SHORT_ID="${SESSION_ID:0:8}"
FILENAME="${TIMESTAMP}_precompact_${SHORT_ID}.jsonl"

# 이미 같은 세션의 precompact 백업이 있는지 확인
EXISTING=$(find "$BACKUP_DIR" -name "*_precompact_${SHORT_ID}.jsonl" 2>/dev/null | head -1)
if [ -n "$EXISTING" ]; then
  # 기존 파일 덮어쓰기 (항상 최신 상태 유지)
  FILENAME=$(basename "$EXISTING")
fi

# 복사
if copy_session "$TRANSCRIPT_PATH" "$BACKUP_DIR/$FILENAME"; then
  log "INFO" "Pre-compact backup: $BACKUP_DIR/$FILENAME"
  print_session_stats "$BACKUP_DIR/$FILENAME" >&2
else
  log "ERROR" "Failed to backup session"
fi

exit 0
