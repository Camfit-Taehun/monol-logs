#!/bin/bash
# Session Archive - Update Index Script
# 세션 인덱스(index.md) 생성 및 업데이트
#
# 사용법:
#   update-index.sh           # 인덱스 업데이트
#   update-index.sh --show    # 인덱스 내용 보기

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(dirname "$SCRIPT_DIR")"

# 라이브러리 로드
source "$PLUGIN_DIR/lib/utils.sh"

# 사용법 출력
usage() {
  cat << EOF
Session Archive - Update Index

Usage:
  $(basename "$0")           Update session index
  $(basename "$0") --show    Show index content
  $(basename "$0") --help    Show this help

The index file (index.md) contains a table of all archived sessions
with metadata like date, topic, size, and links to summaries.
EOF
}

# 인덱스 파일 경로
get_index_file() {
  local backup_dir=$(get_backup_dir)
  local index_file=$(get_config_value "index_file" "index.md")

  echo "$backup_dir/$index_file"
}

# 세션 토픽 추출 (파일명 또는 요약에서)
extract_topic() {
  local session_file="$1"
  local basename=$(basename "$session_file" .jsonl)

  # 파일명에서 토픽 추출 (날짜_시간_토픽_세션ID 형식)
  local parts=$(echo "$basename" | tr '_' '\n' | wc -l)

  if [ "$parts" -gt 3 ]; then
    # 중간 부분이 토픽
    echo "$basename" | cut -d'_' -f3- | rev | cut -d'_' -f2- | rev
  else
    # 요약 파일에서 키워드 추출 시도
    local summary_file="${session_file%.jsonl}.summary.md"
    if [ -f "$summary_file" ]; then
      grep -A1 "## 키워드" "$summary_file" 2>/dev/null | tail -1 | cut -d',' -f1 | tr -d ' ' || echo "-"
    else
      echo "-"
    fi
  fi
}

# 세션 메타데이터 추출
get_session_info() {
  local session_file="$1"
  local basename=$(basename "$session_file" .jsonl)

  # 날짜, 시간
  local date=$(echo "$basename" | cut -d'_' -f1)
  local time=$(echo "$basename" | cut -d'_' -f2)

  # 세션 ID
  local session_id=$(echo "$basename" | rev | cut -d'_' -f1 | rev)

  # 토픽
  local topic=$(extract_topic "$session_file")

  # 파일 크기
  local size=$(ls -lh "$session_file" | awk '{print $5}')

  # 메시지 수
  local user_msgs=$(grep -c '"type":"user"' "$session_file" 2>/dev/null || echo "0")
  local assistant_msgs=$(grep -c '"type":"assistant"' "$session_file" 2>/dev/null || echo "0")
  local total_msgs=$((user_msgs + assistant_msgs))

  # 요약 파일 존재 여부
  local summary_file="${session_file%.jsonl}.summary.md"
  local summary_link="-"
  if [ -f "$summary_file" ]; then
    summary_link="[summary](./$(basename "$summary_file"))"
  fi

  # 로드맵 파일 존재 여부
  local roadmap_file="${session_file%.jsonl}.roadmap.md"
  local roadmap_link=""
  if [ -f "$roadmap_file" ]; then
    roadmap_link=" [roadmap](./$(basename "$roadmap_file"))"
  fi

  echo "$date|$time|$topic|$total_msgs|$size|${session_id:0:8}|$summary_link$roadmap_link"
}

# 인덱스 생성
generate_index() {
  local backup_dir=$(get_backup_dir)
  local index_file=$(get_index_file)

  if [ ! -d "$backup_dir" ]; then
    echo "No sessions directory: $backup_dir"
    exit 1
  fi

  echo "Generating index: $index_file"

  # 헤더 작성
  cat > "$index_file" << 'EOF'
# Session Index

세션 아카이브 목록

| Date | Time | Topic | Messages | Size | Session | Links |
|------|------|-------|----------|------|---------|-------|
EOF

  # 세션 목록 (최신순)
  local count=0
  for session_file in $(ls -t "$backup_dir"/*.jsonl 2>/dev/null); do
    # precompact 파일 제외
    [[ "$session_file" == *"_precompact_"* ]] && continue
    [ -f "$session_file" ] || continue

    local info=$(get_session_info "$session_file")
    echo "| $(echo "$info" | tr '|' ' | ') |" >> "$index_file"
    ((count++)) || true
  done

  # 푸터
  cat >> "$index_file" << EOF

---

Total: $count sessions
Last updated: $(date +%Y-%m-%d\ %H:%M:%S)

## Quick Links

- [Roadmap](./roadmap.md) - 전체 TODO 목록
EOF

  echo "Indexed $count sessions"
}

# 인덱스 보기
show_index() {
  local index_file=$(get_index_file)

  if [ -f "$index_file" ]; then
    cat "$index_file"
  else
    echo "Index file not found: $index_file"
    echo "Run '$(basename "$0")' to generate it"
    exit 1
  fi
}

# 메인
main() {
  case "${1:-}" in
    --help|-h)
      usage
      ;;
    --show|-s)
      show_index
      ;;
    *)
      generate_index
      ;;
  esac
}

main "$@"
