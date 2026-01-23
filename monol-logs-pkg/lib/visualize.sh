#!/bin/bash
# Session Archive - Visualization Library
# 세션 시각화 기능 (ASCII 타임라인, 마크다운, HTML 대시보드)

# 현재 스크립트 디렉토리
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# utils.sh 로드
source "$SCRIPT_DIR/utils.sh"

# =====================
# 세션 데이터 수집
# =====================

# 모든 세션 메타데이터 수집
collect_sessions() {
  local backup_dir=$(get_backup_dir)
  local author_filter="${1:-}"
  local date_filter="${2:-}"
  local topic_filter="${3:-}"

  local sessions=()

  for meta_file in "$backup_dir"/*.meta.json; do
    [[ -f "$meta_file" ]] || continue

    local sessionId=$(jq -r '.sessionId // ""' "$meta_file")
    local topic=$(jq -r '.topic // "untitled"' "$meta_file")
    local createdAt=$(jq -r '.createdAt // ""' "$meta_file")
    local savedAt=$(jq -r '.savedAt // ""' "$meta_file")
    local savedBy=$(jq -r '.savedBy // "unknown"' "$meta_file")
    local messageCount=$(jq -r '.messageCount // 0' "$meta_file")

    # 필터 적용
    if [[ -n "$author_filter" && "$savedBy" != "$author_filter" ]]; then
      continue
    fi

    if [[ -n "$topic_filter" && ! "$topic" =~ $topic_filter ]]; then
      continue
    fi

    if [[ -n "$date_filter" ]]; then
      if ! check_date_filter "$createdAt" "$date_filter"; then
        continue
      fi
    fi

    echo "$sessionId|$topic|$createdAt|$savedAt|$savedBy|$messageCount|$meta_file"
  done
}

# 날짜 필터 체크
check_date_filter() {
  local created_at="$1"
  local filter="$2"

  local created_ts=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${created_at%.*}" "+%s" 2>/dev/null || echo "0")
  local now_ts=$(date "+%s")

  if [[ "$filter" =~ ^([0-9]+)d$ ]]; then
    local days="${BASH_REMATCH[1]}"
    local cutoff_ts=$((now_ts - days * 86400))
    [[ $created_ts -ge $cutoff_ts ]]
  elif [[ "$filter" =~ ^([0-9]{4}-[0-9]{2}-[0-9]{2}):([0-9]{4}-[0-9]{2}-[0-9]{2})$ ]]; then
    local start_ts=$(date -j -f "%Y-%m-%d" "${BASH_REMATCH[1]}" "+%s" 2>/dev/null || echo "0")
    local end_ts=$(date -j -f "%Y-%m-%d" "${BASH_REMATCH[2]}" "+%s" 2>/dev/null || echo "0")
    end_ts=$((end_ts + 86400))
    [[ $created_ts -ge $start_ts && $created_ts -lt $end_ts ]]
  else
    return 0
  fi
}

# =====================
# 작성자 스타일 관리
# =====================

AUTHOR_SYMBOLS=("@" "#" "*" "+" "=" "&" "%" "^")
AUTHOR_COLORS=("\033[34m" "\033[32m" "\033[35m" "\033[33m" "\033[36m" "\033[31m" "\033[37m" "\033[94m")

# 작성자 인덱스 (해시 기반)
get_author_index() {
  local author="$1"
  local hash=$(echo -n "$author" | md5 | cut -c1-8)
  echo $(( 16#${hash} % ${#AUTHOR_SYMBOLS[@]} ))
}

# 작성자 심볼
get_author_symbol() {
  local author="$1"
  local idx=$(get_author_index "$author")
  echo "${AUTHOR_SYMBOLS[$idx]}"
}

# 작성자 색상
get_author_color() {
  local author="$1"
  local idx=$(get_author_index "$author")
  echo "${AUTHOR_COLORS[$idx]}"
}

# =====================
# ASCII 타임라인
# =====================

print_ascii_timeline() {
  local author_filter="${1:-}"
  local date_filter="${2:-}"
  local topic_filter="${3:-}"

  local backup_dir=$(get_backup_dir)
  local width=60

  echo "Session Timeline"
  echo "Generated: $(date '+%Y-%m-%d %H:%M')"
  echo "════════════════════════════════════════════════════════════════"
  echo ""

  # 작성자 목록 수집
  local authors=()
  while IFS='|' read -r sessionId topic createdAt savedAt savedBy messageCount metaFile; do
    [[ -z "$sessionId" ]] && continue
    if [[ ! " ${authors[*]} " =~ " ${savedBy} " ]]; then
      authors+=("$savedBy")
    fi
  done < <(collect_sessions "$author_filter" "$date_filter" "$topic_filter")

  # Legend
  echo -n "Legend: "
  for author in "${authors[@]}"; do
    local symbol=$(get_author_symbol "$author")
    local color=$(get_author_color "$author")
    echo -en "${color}${symbol} ${author}\033[0m  "
  done
  echo ""
  echo ""

  # 날짜별 그룹핑
  local current_date=""
  local total_sessions=0
  local total_messages=0

  while IFS='|' read -r sessionId topic createdAt savedAt savedBy messageCount metaFile; do
    [[ -z "$sessionId" ]] && continue

    local date_part="${createdAt:0:10}"
    local time_part="${createdAt:11:5}"
    local end_time="${savedAt:11:5}"
    local short_id="${sessionId:0:8}"

    # 날짜 헤더
    if [[ "$date_part" != "$current_date" ]]; then
      [[ -n "$current_date" ]] && echo ""

      # 상대 날짜 계산
      local relative=""
      local today=$(date '+%Y-%m-%d')
      local yesterday=$(date -v-1d '+%Y-%m-%d' 2>/dev/null || date -d '1 day ago' '+%Y-%m-%d' 2>/dev/null)
      if [[ "$date_part" == "$today" ]]; then
        relative="Today"
      elif [[ "$date_part" == "$yesterday" ]]; then
        relative="Yesterday"
      else
        relative="$date_part"
      fi

      echo "$date_part ($relative)"
      current_date="$date_part"
    fi

    # 세션 라인
    local symbol=$(get_author_symbol "$savedBy")
    local color=$(get_author_color "$savedBy")
    local bar_length=$((messageCount / 3 + 5))
    [[ $bar_length -gt $width ]] && bar_length=$width
    local bar=$(printf '█%.0s' $(seq 1 $bar_length))

    echo "├─ $time_part ─────────────────────────────────── ${end_time:-$time_part}"
    echo -e "│  ${color}${symbol} ${bar}\033[0m $topic ($messageCount msgs, $short_id)"
    echo "│"

    total_sessions=$((total_sessions + 1))
    total_messages=$((total_messages + messageCount))
  done < <(collect_sessions "$author_filter" "$date_filter" "$topic_filter" | sort -t'|' -k3 -r)

  echo "════════════════════════════════════════════════════════════════"
  echo "Summary: $total_sessions sessions | ${#authors[@]} authors | $total_messages total messages"
}

# =====================
# 마크다운 생성
# =====================

generate_markdown() {
  local author_filter="${1:-}"
  local date_filter="${2:-}"
  local topic_filter="${3:-}"
  local output_path="${4:-$(get_backup_dir)/visualization.md}"

  local backup_dir=$(get_backup_dir)

  # 통계 수집
  local total_sessions=0
  local total_messages=0
  local authors=()
  local author_stats=""

  {
    echo "# Session Visualization"
    echo ""
    echo "Generated: $(date '+%Y-%m-%d %H:%M')"
    echo ""

    # 세션 테이블
    echo "## Timeline"
    echo ""
    echo "| Date | Time | Author | Topic | Duration | Msgs | Links |"
    echo "|------|------|--------|-------|----------|------|-------|"

    while IFS='|' read -r sessionId topic createdAt savedAt savedBy messageCount metaFile; do
      [[ -z "$sessionId" ]] && continue

      local date_part="${createdAt:0:10}"
      local time_part="${createdAt:11:5}"
      local short_id="${sessionId:0:8}"

      # Duration 계산
      local duration="N/A"
      if [[ -n "$savedAt" && -n "$createdAt" ]]; then
        local start_ts=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${createdAt%.*}" "+%s" 2>/dev/null || echo "0")
        local end_ts=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${savedAt%.*}" "+%s" 2>/dev/null || echo "0")
        local diff=$((end_ts - start_ts))
        if [[ $diff -gt 0 ]]; then
          local hours=$((diff / 3600))
          local mins=$(((diff % 3600) / 60))
          duration="${hours}h ${mins}m"
        fi
      fi

      # 링크
      local base_name="${metaFile%.meta.json}"
      local summary_link=""
      [[ -f "${base_name}.summary.md" ]] && summary_link="[summary](./$(basename "${base_name}.summary.md"))"

      echo "| $date_part | $time_part | $savedBy | $topic | $duration | $messageCount | $summary_link |"

      total_sessions=$((total_sessions + 1))
      total_messages=$((total_messages + messageCount))

      if [[ ! " ${authors[*]} " =~ " ${savedBy} " ]]; then
        authors+=("$savedBy")
      fi
    done < <(collect_sessions "$author_filter" "$date_filter" "$topic_filter" | sort -t'|' -k3 -r)

    echo ""
    echo "**Total**: $total_sessions sessions | ${#authors[@]} authors | $total_messages messages"
    echo ""

    # 작성자 통계
    echo "## Author Statistics"
    echo ""
    echo "| Author | Sessions | Messages |"
    echo "|--------|----------|----------|"

    for author in "${authors[@]}"; do
      local a_sessions=0
      local a_messages=0
      while IFS='|' read -r sessionId topic createdAt savedAt savedBy messageCount metaFile; do
        [[ "$savedBy" == "$author" ]] || continue
        a_sessions=$((a_sessions + 1))
        a_messages=$((a_messages + messageCount))
      done < <(collect_sessions "$author_filter" "$date_filter" "$topic_filter")
      echo "| $author | $a_sessions | $a_messages |"
    done

    echo ""
    echo "---"
    echo "*Generated by monol-logs /visualize*"

  } > "$output_path"

  echo "📄 Visualization saved:"
  echo "   $output_path"
}

# =====================
# HTML 대시보드 생성
# =====================

generate_html_dashboard() {
  local author_filter="${1:-}"
  local date_filter="${2:-}"
  local topic_filter="${3:-}"
  local output_path="${4:-$(get_backup_dir)/dashboard.html}"
  local open_browser="${5:-false}"

  local backup_dir=$(get_backup_dir)
  local template_path="$SCRIPT_DIR/../templates/dashboard.html"

  if [[ ! -f "$template_path" ]]; then
    echo "⚠️ 템플릿 파일을 찾을 수 없습니다: $template_path" >&2
    return 1
  fi

  # 세션 데이터를 JSON으로 변환 (한 줄로)
  local sessions_json="["
  local first=true

  while IFS='|' read -r sessionId topic createdAt savedAt savedBy messageCount metaFile; do
    [[ -z "$sessionId" ]] && continue

    [[ "$first" == "true" ]] && first=false || sessions_json+=","

    local base_name="${metaFile%.meta.json}"
    local has_summary=$([[ -f "${base_name}.summary.md" ]] && echo "true" || echo "false")
    local has_roadmap=$([[ -f "${base_name}.roadmap.md" ]] && echo "true" || echo "false")

    # 한 줄 JSON 생성
    sessions_json+="{\"sessionId\":\"$sessionId\",\"topic\":\"$topic\",\"createdAt\":\"$createdAt\",\"savedAt\":\"$savedAt\",\"savedBy\":\"$savedBy\",\"messageCount\":$messageCount,\"hasSummary\":$has_summary,\"hasRoadmap\":$has_roadmap}"
  done < <(collect_sessions "$author_filter" "$date_filter" "$topic_filter")

  sessions_json+="]"

  # 템플릿에 데이터 주입
  mkdir -p "$(dirname "$output_path")"

  # awk를 사용하여 안전하게 치환 (sed의 줄바꿈 문제 회피)
  awk -v json="$sessions_json" '{gsub(/\/\* SESSION_DATA_PLACEHOLDER \*\/\[\]/, json); print}' "$template_path" > "$output_path"

  echo "🌐 Dashboard generated:"
  echo "   $output_path"
  echo ""
  echo "💡 팁:"
  echo "  - 브라우저에서 열어 인터랙티브 대시보드 확인"
  echo "  - /visualize --html --open 으로 자동 열기"

  # 브라우저에서 열기
  if [[ "$open_browser" == "true" ]]; then
    echo ""
    echo "🌐 브라우저에서 열기..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
      open "$output_path"
    elif command -v xdg-open &>/dev/null; then
      xdg-open "$output_path"
    else
      echo "브라우저에서 열어주세요: $output_path"
    fi
  fi
}

# =====================
# 메인 함수
# =====================

visualize_main() {
  local mode="ascii"
  local author_filter=""
  local date_filter=""
  local topic_filter=""
  local output_path=""
  local open_browser="false"

  # 인자 파싱
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --ascii)
        mode="ascii"
        shift
        ;;
      --md)
        mode="md"
        shift
        ;;
      --html)
        mode="html"
        shift
        ;;
      --author)
        author_filter="$2"
        shift 2
        ;;
      --date)
        date_filter="$2"
        shift 2
        ;;
      --topic)
        topic_filter="$2"
        shift 2
        ;;
      --output)
        output_path="$2"
        shift 2
        ;;
      --open)
        open_browser="true"
        shift
        ;;
      -h|--help)
        echo "Usage: visualize [--ascii|--md|--html] [--author <name>] [--date <range>] [--topic <search>] [--output <path>] [--open]"
        return 0
        ;;
      *)
        shift
        ;;
    esac
  done

  case "$mode" in
    ascii)
      print_ascii_timeline "$author_filter" "$date_filter" "$topic_filter"
      ;;
    md)
      generate_markdown "$author_filter" "$date_filter" "$topic_filter" "$output_path"
      ;;
    html)
      generate_html_dashboard "$author_filter" "$date_filter" "$topic_filter" "$output_path" "$open_browser"
      ;;
  esac
}

# 직접 실행 시
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  visualize_main "$@"
fi
