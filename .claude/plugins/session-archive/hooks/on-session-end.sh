#!/bin/bash
# Session Archive - SessionEnd Hook
# 세션 종료 시 자동으로 세션 파일을 프로젝트 내에 백업
# + 로드맵 추출, 요약 생성, 인덱스 업데이트

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
  exit 1
fi

if [ -z "$TRANSCRIPT_PATH" ] || [ ! -f "$TRANSCRIPT_PATH" ]; then
  log "ERROR" "transcript not found: $TRANSCRIPT_PATH"
  exit 1
fi

# 프로젝트 디렉토리 확인
if [ -z "$CLAUDE_PROJECT_DIR" ]; then
  log "ERROR" "CLAUDE_PROJECT_DIR not set"
  exit 1
fi

# 백업 디렉토리
BACKUP_DIR=$(get_backup_dir)
mkdir -p "$BACKUP_DIR"

# 파일명 생성
FILENAME=$(generate_filename "$SESSION_ID")

# 기존 precompact 파일 확인 (있으면 최종본으로 대체)
SHORT_ID="${SESSION_ID:0:8}"
PRECOMPACT_FILE=$(find "$BACKUP_DIR" -name "*_precompact_${SHORT_ID}.jsonl" 2>/dev/null | head -1)
if [ -n "$PRECOMPACT_FILE" ]; then
  # precompact 파일 삭제 (최종본으로 대체될 것이므로)
  rm -f "$PRECOMPACT_FILE"
  log "INFO" "Removed precompact backup: $PRECOMPACT_FILE"
fi

# 1. 세션 파일 복사
ARCHIVED_FILE="$BACKUP_DIR/$FILENAME"
if copy_session "$TRANSCRIPT_PATH" "$ARCHIVED_FILE"; then
  log "INFO" "Session archived: $ARCHIVED_FILE"
  print_session_stats "$ARCHIVED_FILE" >&2
else
  log "ERROR" "Failed to archive session"
  exit 1
fi

# 2. 로드맵 추출 (설정에 따라)
ROADMAP_ENABLED=$(get_config_value "roadmap_enabled" "true")
if [ "$ROADMAP_ENABLED" = "true" ]; then
  log "INFO" "Extracting roadmap..."
  if "$PLUGIN_DIR/scripts/extract-roadmap.sh" "$ARCHIVED_FILE" 2>&1; then
    log "INFO" "Roadmap extracted"
  else
    log "WARN" "Roadmap extraction failed (non-fatal)"
  fi
fi

# 3. 요약 생성 (설정에 따라, 백그라운드)
SUMMARY_ENABLED=$(get_config_value "summary_enabled" "true")
if [ "$SUMMARY_ENABLED" = "true" ]; then
  log "INFO" "Generating summary (background)..."
  # 백그라운드로 실행 (세션 종료 지연 방지)
  nohup "$PLUGIN_DIR/scripts/generate-summary.sh" "$ARCHIVED_FILE" > /dev/null 2>&1 &
fi

# 4. 인덱스 업데이트 (설정에 따라)
INDEX_ENABLED=$(get_config_value "index_enabled" "true")
if [ "$INDEX_ENABLED" = "true" ]; then
  log "INFO" "Updating index..."
  if "$PLUGIN_DIR/scripts/update-index.sh" 2>&1; then
    log "INFO" "Index updated"
  else
    log "WARN" "Index update failed (non-fatal)"
  fi
fi

exit 0
