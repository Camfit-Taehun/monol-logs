#!/bin/bash
# Session Archive - Extract Roadmap Script
# 세션에서 TODO/로드맵 항목을 추출하여 roadmap.md에 추가
#
# 사용법:
#   extract-roadmap.sh                     # 최근 세션에서 추출
#   extract-roadmap.sh <session-file>      # 특정 세션에서 추출
#   extract-roadmap.sh --all               # 모든 세션에서 추출
#   extract-roadmap.sh --show              # roadmap.md 내용 보기
#   extract-roadmap.sh --init              # roadmap.md 초기화

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(dirname "$SCRIPT_DIR")"

# 라이브러리 로드
source "$PLUGIN_DIR/lib/utils.sh"
source "$PLUGIN_DIR/lib/roadmap.sh"

# 사용법 출력
usage() {
  cat << EOF
Session Archive - Extract Roadmap

Usage:
  $(basename "$0")                     Extract from most recent session
  $(basename "$0") <session-file>      Extract from specific session
  $(basename "$0") --all               Extract from all sessions
  $(basename "$0") --show              Show roadmap.md content
  $(basename "$0") --init              Initialize roadmap.md
  $(basename "$0") --help              Show this help

Examples:
  $(basename "$0")                                    # 최근 세션
  $(basename "$0") .claude/sessions/2026-01-18_*.jsonl  # 특정 세션
  $(basename "$0") --show                             # 로드맵 보기
EOF
}

# roadmap.md 내용 보기
show_roadmap() {
  local roadmap_file=$(get_roadmap_file)

  if [ -f "$roadmap_file" ]; then
    cat "$roadmap_file"
  else
    echo "Roadmap file not found: $roadmap_file"
    echo "Run '$(basename "$0") --init' to create it"
    exit 1
  fi
}

# 세션에서 TODO 추출 및 추가
process_session() {
  local session_file="$1"

  if [ ! -f "$session_file" ]; then
    echo "Session file not found: $session_file" >&2
    return 1
  fi

  echo "Processing: $(basename "$session_file")"

  # 세션 날짜 추출 (파일명에서)
  local basename=$(basename "$session_file" .jsonl)
  local session_date=$(echo "$basename" | cut -d'_' -f1,2 | tr '_' ' ')
  local session_id=$(echo "$basename" | rev | cut -d'_' -f1 | rev)

  # TODO 추출
  local todos_raw=$(extract_todos_from_session "$session_file")

  if [ -z "$todos_raw" ]; then
    echo "  No TODOs found"
    return 0
  fi

  # TODO 정리
  local todos=()
  while IFS= read -r line; do
    [ -n "$line" ] && todos+=("$line")
  done <<< "$(clean_todos $todos_raw)"

  if [ ${#todos[@]} -eq 0 ]; then
    echo "  No TODOs found after cleaning"
    return 0
  fi

  echo "  Found ${#todos[@]} TODO(s)"

  # roadmap.md 초기화 및 추가
  local roadmap_file=$(init_roadmap_file)
  add_todos_to_roadmap "$roadmap_file" "$session_date" "$session_id" "${todos[@]}"

  # 세션별 roadmap 생성 (설정에 따라)
  local per_session=$(get_config_value "roadmap_per_session" "true")
  if [ "$per_session" = "true" ]; then
    local session_roadmap=$(create_session_roadmap "$session_file" "$session_date" "${todos[@]}")
    echo "  Created: $(basename "$session_roadmap")"
  fi

  echo "  Updated: $roadmap_file"
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
  for session_file in "$backup_dir"/*.jsonl; do
    # precompact 파일 제외
    [[ "$session_file" == *"_precompact_"* ]] && continue
    [ -f "$session_file" ] || continue

    process_session "$session_file"
    ((count++)) || true
  done

  echo ""
  echo "Processed $count session(s)"
}

# 메인
main() {
  case "${1:-}" in
    --help|-h)
      usage
      ;;
    --show|-s)
      show_roadmap
      ;;
    --init|-i)
      local roadmap_file=$(init_roadmap_file)
      echo "Initialized: $roadmap_file"
      ;;
    --all|-a)
      process_all_sessions
      ;;
    "")
      # 최근 세션
      local recent=$(find_recent_session)
      if [ -z "$recent" ]; then
        echo "No sessions found"
        exit 1
      fi
      process_session "$recent"
      ;;
    *)
      # 특정 파일
      process_session "$1"
      ;;
  esac
}

main "$@"
