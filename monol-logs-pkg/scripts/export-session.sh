#!/bin/bash
# Session Archive - Manual Export Script
# 세션을 수동으로 내보내기
#
# 사용법:
#   export-session.sh                          # 가장 최근 세션 내보내기
#   export-session.sh <session-id>             # 특정 세션 내보내기
#   export-session.sh <session-id> "topic"     # 토픽명 지정하여 내보내기
#   export-session.sh --list                   # 사용 가능한 세션 목록
#   export-session.sh --list-archived          # 이미 저장된 세션 목록

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(dirname "$SCRIPT_DIR")"

# 공통 유틸 로드
source "$PLUGIN_DIR/lib/utils.sh"
source "$PLUGIN_DIR/lib/sync.sh"

# 사용법 출력
usage() {
  cat << EOF
Session Archive - Manual Export

Usage:
  $(basename "$0")                        Export most recent session
  $(basename "$0") <session-id>           Export specific session
  $(basename "$0") <session-id> "topic"   Export with topic name
  $(basename "$0") --list                 List available sessions
  $(basename "$0") --list-archived        List already archived sessions
  $(basename "$0") --help                 Show this help

Examples:
  $(basename "$0") f6702810               Export session starting with f6702810
  $(basename "$0") f6702810 "gap-analysis" Export with name gap-analysis
EOF
}

# 사용 가능한 세션 목록
list_sessions() {
  local claude_dir="$HOME/.claude/projects"

  echo "=== Available Sessions ==="
  echo ""

  # 현재 프로젝트의 세션들
  if [ -n "$CLAUDE_PROJECT_DIR" ]; then
    local project_sessions_dir=$(echo "$CLAUDE_PROJECT_DIR" | tr '/' '-' | sed 's/^-//')
    project_sessions_dir="$claude_dir/$project_sessions_dir"

    if [ -d "$project_sessions_dir" ]; then
      echo "Current project sessions:"
      ls -lt "$project_sessions_dir"/*.jsonl 2>/dev/null | head -10 | while read -r line; do
        local file=$(echo "$line" | awk '{print $NF}')
        local basename=$(basename "$file" .jsonl)
        local size=$(echo "$line" | awk '{print $5}')
        local date=$(echo "$line" | awk '{print $6, $7, $8}')
        echo "  $basename  ($size bytes, $date)"
      done
      echo ""
    fi
  fi

  # 모든 프로젝트의 최근 세션들
  echo "Recent sessions (all projects):"
  find "$claude_dir" -name "*.jsonl" -type f 2>/dev/null | while read -r file; do
    local basename=$(basename "$file" .jsonl)
    local size=$(ls -l "$file" | awk '{print $5}')
    local mtime=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$file" 2>/dev/null || stat -c "%y" "$file" 2>/dev/null | cut -d. -f1)
    echo "  ${basename:0:8}...  $mtime  $(numfmt --to=iec $size 2>/dev/null || echo "${size}B")"
  done | sort -k2 -r | head -15
}

# 이미 저장된 세션 목록
list_archived() {
  local backup_dir=$(get_backup_dir)

  echo "=== Archived Sessions ==="
  echo "Location: $backup_dir"
  echo ""

  if [ ! -d "$backup_dir" ]; then
    echo "No archived sessions yet."
    return
  fi

  ls -lt "$backup_dir"/*.jsonl 2>/dev/null | while read -r line; do
    local file=$(echo "$line" | awk '{print $NF}')
    local basename=$(basename "$file")
    local size=$(echo "$line" | awk '{print $5}')
    echo "  $basename  ($size bytes)"
    print_session_stats "$file" 2>/dev/null | sed 's/^/    /'
  done

  local count=$(ls -1 "$backup_dir"/*.jsonl 2>/dev/null | wc -l | tr -d ' ')
  echo ""
  echo "Total: $count archived sessions"
}

# 세션 내보내기
export_session() {
  local session_id="$1"
  local topic="$2"

  # 세션 파일 찾기
  local session_file=""

  if [ -z "$session_id" ]; then
    # 가장 최근 세션
    session_file=$(find "$HOME/.claude/projects" -name "*.jsonl" -type f 2>/dev/null | \
      xargs ls -t 2>/dev/null | head -1)

    if [ -z "$session_file" ]; then
      echo "No sessions found" >&2
      exit 1
    fi

    session_id=$(basename "$session_file" .jsonl)
    echo "Using most recent session: $session_id"
  else
    # 특정 세션 찾기 (부분 매칭 지원)
    session_file=$(find "$HOME/.claude/projects" -name "${session_id}*.jsonl" -type f 2>/dev/null | head -1)

    if [ -z "$session_file" ]; then
      echo "Session not found: $session_id" >&2
      echo "Use --list to see available sessions" >&2
      exit 1
    fi

    session_id=$(basename "$session_file" .jsonl)
  fi

  # 백업 디렉토리
  local backup_dir=$(get_backup_dir)
  mkdir -p "$backup_dir"

  # 파일명 생성
  local filename=$(generate_filename "$session_id" "$topic")

  # 복사
  echo "Exporting session..."
  echo "  From: $session_file"
  echo "  To:   $backup_dir/$filename"
  echo ""

  if copy_session "$session_file" "$backup_dir/$filename"; then
    echo ""
    echo "Stats:"
    local stats=$(print_session_stats "$backup_dir/$filename")
    echo "$stats"

    # 메타데이터 추출
    local message_count=$(echo "$stats" | grep -o '[0-9]* messages' | awk '{print $1}')
    local created_at=$(jq -r 'select(.type == "summary") | .createdAt' "$session_file" 2>/dev/null | head -1)
    local ended_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # duration 계산 (대략적)
    local duration_ms=0
    if [ -n "$created_at" ]; then
      local start_ts=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${created_at%Z}" "+%s" 2>/dev/null || echo "0")
      local end_ts=$(date "+%s")
      if [ "$start_ts" -gt 0 ]; then
        duration_ms=$(( (end_ts - start_ts) * 1000 ))
      fi
    fi

    echo ""

    # 서버 동기화
    if sync_session_saved "$session_id" "$topic" "$message_count" "$duration_ms" "$created_at" "$ended_at"; then
      color_echo cyan "Synced to server"
    fi

    color_echo green "Export complete!"
  else
    color_echo red "Export failed"
    exit 1
  fi
}

# 메인
main() {
  case "${1:-}" in
    --help|-h)
      usage
      ;;
    --list|-l)
      list_sessions
      ;;
    --list-archived|-a)
      list_archived
      ;;
    *)
      export_session "$1" "$2"
      ;;
  esac
}

main "$@"
