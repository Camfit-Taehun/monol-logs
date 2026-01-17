#!/bin/bash
# Session Archive - Generate Summary Script
# AI를 사용하여 세션 요약 생성
#
# 사용법:
#   generate-summary.sh                     # 최근 세션 요약
#   generate-summary.sh <session-file>      # 특정 세션 요약
#   generate-summary.sh --all               # 모든 세션 요약 (요약 없는 것만)
#   generate-summary.sh --rule-based        # 규칙 기반 요약 (API 없이)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(dirname "$SCRIPT_DIR")"

# 라이브러리 로드
source "$PLUGIN_DIR/lib/utils.sh"
source "$PLUGIN_DIR/lib/summary.sh"

# 사용법 출력
usage() {
  cat << EOF
Session Archive - Generate Summary

Usage:
  $(basename "$0")                     Generate summary for most recent session
  $(basename "$0") <session-file>      Generate summary for specific session
  $(basename "$0") --all               Generate summaries for all sessions (skip existing)
  $(basename "$0") --rule-based        Use rule-based summary (no API)
  $(basename "$0") --help              Show this help

Options:
  --rule-based    Use pattern matching instead of AI (no API key needed)
  --force         Regenerate even if summary exists

Environment:
  ANTHROPIC_API_KEY    API key for Claude (or set in config.yaml)

Examples:
  $(basename "$0")                                    # 최근 세션 AI 요약
  $(basename "$0") --rule-based                       # API 없이 규칙 기반 요약
  $(basename "$0") .claude/sessions/2026-01-18_*.jsonl  # 특정 세션
EOF
}

# 옵션 파싱
RULE_BASED=false
FORCE=false
ALL=false
SESSION_FILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h)
      usage
      exit 0
      ;;
    --rule-based|-r)
      RULE_BASED=true
      shift
      ;;
    --force|-f)
      FORCE=true
      shift
      ;;
    --all|-a)
      ALL=true
      shift
      ;;
    *)
      SESSION_FILE="$1"
      shift
      ;;
  esac
done

# 세션 요약 생성
process_session() {
  local session_file="$1"

  if [ ! -f "$session_file" ]; then
    echo "Session file not found: $session_file" >&2
    return 1
  fi

  # precompact 파일 제외
  if [[ "$session_file" == *"_precompact_"* ]]; then
    echo "Skipping precompact file: $(basename "$session_file")"
    return 0
  fi

  local summary_file=$(get_summary_file "$session_file")

  # 이미 존재하면 스킵 (--force가 아니면)
  if [ -f "$summary_file" ] && [ "$FORCE" = false ]; then
    echo "Summary already exists: $(basename "$summary_file")"
    return 0
  fi

  echo "Processing: $(basename "$session_file")"

  local summary=""

  if [ "$RULE_BASED" = true ]; then
    # 규칙 기반 요약
    echo "  Using rule-based summary..."
    summary=$(generate_rule_based_summary "$session_file")
  else
    # AI 기반 요약
    echo "  Calling Claude API..."
    summary=$(generate_ai_summary "$session_file")

    if [ $? -ne 0 ] || [ -z "$summary" ]; then
      echo "  AI summary failed, falling back to rule-based..."
      summary=$(generate_rule_based_summary "$session_file")
    fi
  fi

  if [ -z "$summary" ]; then
    echo "  Failed to generate summary" >&2
    return 1
  fi

  # 저장
  local saved_file=$(save_summary "$session_file" "$summary")
  echo "  Created: $(basename "$saved_file")"

  return 0
}

# 최근 세션 찾기
find_recent_session() {
  local backup_dir=$(get_backup_dir)

  if [ ! -d "$backup_dir" ]; then
    echo "No sessions directory: $backup_dir" >&2
    return 1
  fi

  # 가장 최근 jsonl 파일 (precompact 제외)
  find "$backup_dir" -name "*.jsonl" -not -name "*_precompact_*" -type f 2>/dev/null | \
    xargs ls -t 2>/dev/null | head -1
}

# 모든 세션 처리
process_all_sessions() {
  local backup_dir=$(get_backup_dir)

  if [ ! -d "$backup_dir" ]; then
    echo "No sessions directory: $backup_dir"
    exit 1
  fi

  local count=0
  local skipped=0
  local failed=0

  for session_file in "$backup_dir"/*.jsonl; do
    # precompact 파일 제외
    [[ "$session_file" == *"_precompact_"* ]] && continue
    [ -f "$session_file" ] || continue

    if process_session "$session_file"; then
      ((count++)) || true
    else
      ((failed++)) || true
    fi
  done

  echo ""
  echo "Processed: $count, Failed: $failed"
}

# 메인
main() {
  if [ "$ALL" = true ]; then
    process_all_sessions
  elif [ -n "$SESSION_FILE" ]; then
    process_session "$SESSION_FILE"
  else
    # 최근 세션
    local recent=$(find_recent_session)
    if [ -z "$recent" ]; then
      echo "No sessions found"
      exit 1
    fi
    process_session "$recent"
  fi
}

main
