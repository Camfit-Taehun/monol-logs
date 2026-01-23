#!/bin/bash
# Session Archive - Insights Utilities
# 세션 데이터에서 인사이트 추출

# SCRIPT_DIR 결정 (직접 실행 vs source)
if [ -n "${BASH_SOURCE[0]}" ] && [ "${BASH_SOURCE[0]}" != "$0" ]; then
  INSIGHTS_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
  INSIGHTS_SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
fi

# utils.sh가 같은 디렉토리에 있으면 source
if [ -f "$INSIGHTS_SCRIPT_DIR/utils.sh" ]; then
  source "$INSIGHTS_SCRIPT_DIR/utils.sh"
fi

# =====================
# Personal Insights
# =====================

# 작업 패턴 분석 (jq 기반으로 단순화)
analyze_work_patterns() {
  local backup_dir=$(get_backup_dir)
  local author="${1:-}"
  local tmpfile=$(mktemp)

  # 모든 meta.json에서 데이터 수집
  for meta_file in "$backup_dir"/*.meta.json; do
    [ -f "$meta_file" ] || continue

    # 작성자 필터링
    if [ -n "$author" ]; then
      local file_author=$(jq -r '.savedBy // ""' "$meta_file" 2>/dev/null)
      [ "$file_author" != "$author" ] && continue
    fi

    jq -r '[.createdAt, .savedAt] | @tsv' "$meta_file" 2>/dev/null >> "$tmpfile"
  done

  local session_count=$(wc -l < "$tmpfile" | tr -d ' ')

  if [ "$session_count" -eq 0 ]; then
    echo "peak_hour="
    echo "peak_day="
    echo "avg_duration=0"
    echo "total_sessions=0"
    rm -f "$tmpfile"
    return
  fi

  # 시간대별 분포 계산
  local peak_hour=$(cut -f1 "$tmpfile" | sed 's/T/ /' | cut -d' ' -f2 | cut -d':' -f1 | sort | uniq -c | sort -rn | head -1 | awk '{print $2}')

  # 요일별 분포 계산 (macOS date 사용)
  local peak_day=""
  if command -v gdate &>/dev/null; then
    peak_day=$(cut -f1 "$tmpfile" | while read d; do gdate -d "${d}" "+%a" 2>/dev/null; done | sort | uniq -c | sort -rn | head -1 | awk '{print $2}')
  else
    # macOS fallback - 파일 날짜에서 요일 추출 (간소화)
    peak_day="N/A"
  fi

  # 평균 세션 시간 (분)
  local total_duration=0
  while IFS=$'\t' read -r created saved; do
    if [ -n "$created" ] && [ -n "$saved" ]; then
      local start_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${created%%Z*}" "+%s" 2>/dev/null || echo "0")
      local end_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${saved%%Z*}" "+%s" 2>/dev/null || echo "0")
      if [ "$start_epoch" -gt 0 ] && [ "$end_epoch" -gt 0 ]; then
        total_duration=$((total_duration + end_epoch - start_epoch))
      fi
    fi
  done < "$tmpfile"

  local avg_duration=0
  if [ "$session_count" -gt 0 ] && [ "$total_duration" -gt 0 ]; then
    avg_duration=$((total_duration / session_count / 60))
  fi

  rm -f "$tmpfile"

  echo "peak_hour=$peak_hour"
  echo "peak_day=$peak_day"
  echo "avg_duration=$avg_duration"
  echo "total_sessions=$session_count"
}

# 토픽 분포 분석 (파이프 기반)
analyze_topic_distribution() {
  local backup_dir=$(get_backup_dir)
  local author="${1:-}"

  for meta_file in "$backup_dir"/*.meta.json; do
    [ -f "$meta_file" ] || continue

    if [ -n "$author" ]; then
      local file_author=$(jq -r '.savedBy // ""' "$meta_file" 2>/dev/null)
      [ "$file_author" != "$author" ] && continue
    fi

    # 토픽에서 기본 영역 추출
    jq -r '.topic // "other"' "$meta_file" 2>/dev/null | cut -d'-' -f1
  done | sort | uniq -c | sort -rn | awk '{print $1, $2}'
}

# =====================
# Team Insights
# =====================

# 팀 기여도 분석 (파이프 기반)
analyze_team_contribution() {
  local backup_dir=$(get_backup_dir)
  local tmpfile=$(mktemp)

  # author와 messageCount 수집
  for meta_file in "$backup_dir"/*.meta.json; do
    [ -f "$meta_file" ] || continue
    jq -r '[.savedBy // "unknown", .messageCount // 0] | @tsv' "$meta_file" 2>/dev/null >> "$tmpfile"
  done

  # author별 집계
  awk -F'\t' '{
    sessions[$1]++
    messages[$1]+=$2
  } END {
    for (a in sessions) {
      print sessions[a], a, messages[a]
    }
  }' "$tmpfile" | sort -rn

  rm -f "$tmpfile"
}

# 지식 맵 분석 (영역별 담당자) - awk 기반
analyze_knowledge_map() {
  local backup_dir=$(get_backup_dir)
  local tmpfile=$(mktemp)

  # topic과 author 수집
  for meta_file in "$backup_dir"/*.meta.json; do
    [ -f "$meta_file" ] || continue
    jq -r '[.topic // "", .savedBy // "unknown"] | @tsv' "$meta_file" 2>/dev/null >> "$tmpfile"
  done

  # 영역 추출 및 집계
  awk -F'\t' '
  {
    topic = $1
    author = $2

    # 영역 추출
    area = ""
    if (topic ~ /auth|login|session/) area = "auth"
    else if (topic ~ /api|endpoint/) area = "api"
    else if (topic ~ /ui|dashboard|frontend|component/) area = "frontend"
    else if (topic ~ /doc|readme/) area = "docs"
    else if (topic ~ /test|spec/) area = "test"
    else if (topic ~ /bug|fix|hotfix/) area = "bugfix"
    else if (topic ~ /infra|deploy|ci/) area = "infra"
    else {
      split(topic, parts, "-")
      area = parts[1]
    }

    if (area == "") area = "other"

    # author별 카운트
    key = area SUBSEP author
    counts[key]++
    areas[area] = 1
  }
  END {
    for (area in areas) {
      # 해당 영역의 모든 author 수집
      owners = ""
      for (key in counts) {
        split(key, parts, SUBSEP)
        if (parts[1] == area) {
          if (owners != "") owners = owners ","
          owners = owners parts[2] ":" counts[key]
        }
      }
      print area ":" owners
    }
  }' "$tmpfile"

  rm -f "$tmpfile"
}

# =====================
# TODO Insights
# =====================

# 모든 세션에서 TODO 수집
collect_all_todos() {
  local backup_dir=$(get_backup_dir)
  local author="${1:-}"

  for roadmap_file in "$backup_dir"/*.roadmap.md; do
    [ -f "$roadmap_file" ] || continue

    # 작성자 필터링
    if [ -n "$author" ]; then
      local meta_file="${roadmap_file%.roadmap.md}.meta.json"
      if [ -f "$meta_file" ]; then
        local file_author=$(jq -r '.savedBy // ""' "$meta_file" 2>/dev/null)
        [ "$file_author" != "$author" ] && continue
      fi
    fi

    # 세션 정보 추출
    local session_name=$(basename "$roadmap_file" .roadmap.md)
    local session_date=$(echo "$session_name" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' | head -1)

    # 미완료 TODO 추출
    grep -E '^\s*-\s*\[\s*\]' "$roadmap_file" 2>/dev/null | while read -r line; do
      local todo_text=$(echo "$line" | sed 's/^[[:space:]]*-[[:space:]]*\[[[:space:]]*\][[:space:]]*//')
      echo "$session_date|$session_name|$todo_text"
    done
  done
}

# TODO 통계
get_todo_stats() {
  local backup_dir=$(get_backup_dir)

  local total_open=0
  local total_completed=0
  local stale_count=0
  local two_weeks_ago=$(date -v-14d +%Y-%m-%d 2>/dev/null || date -d "14 days ago" +%Y-%m-%d 2>/dev/null || echo "2000-01-01")

  for roadmap_file in "$backup_dir"/*.roadmap.md; do
    [ -f "$roadmap_file" ] || continue

    # 미완료
    local open=$(grep -cE '^\s*-\s*\[\s*\]' "$roadmap_file" 2>/dev/null | tr -d ' \n' || echo "0")
    open=$((open + 0))
    total_open=$((total_open + open))

    # 완료
    local completed=$(grep -cE '^\s*-\s*\[x\]' "$roadmap_file" 2>/dev/null | tr -d ' \n' || echo "0")
    completed=$((completed + 0))
    total_completed=$((total_completed + completed))

    # Stale 체크 (2주 이상 된 파일의 미완료 TODO)
    local file_date=$(basename "$roadmap_file" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' | head -1)
    if [ -n "$file_date" ] && [[ "$file_date" < "$two_weeks_ago" ]]; then
      stale_count=$((stale_count + open))
    fi
  done

  echo "open=$total_open"
  echo "completed=$total_completed"
  echo "stale=$stale_count"
}

# =====================
# Output Formatting
# =====================

# ASCII 바 차트 생성
make_bar() {
  local value=$1
  local max=$2
  local width=${3:-20}

  if [ "$max" -eq 0 ]; then
    printf '%*s' "$width" | tr ' ' '░'
    return
  fi

  local filled=$((value * width / max))
  local empty=$((width - filled))

  printf '%*s' "$filled" | tr ' ' '█'
  printf '%*s' "$empty" | tr ' ' '░'
}

# 퍼센트 계산
calc_percent() {
  local value=$1
  local total=$2

  if [ "$total" -eq 0 ]; then
    echo "0"
  else
    echo "$((value * 100 / total))"
  fi
}

# 시간 포맷팅 (분 -> Xh Xm)
format_duration() {
  local minutes=$1

  if [ "$minutes" -lt 60 ]; then
    echo "${minutes}m"
  else
    local hours=$((minutes / 60))
    local mins=$((minutes % 60))
    echo "${hours}h ${mins}m"
  fi
}

# =====================
# Main Display Functions
# =====================

# 개인 인사이트 출력
print_personal_insights() {
  local author="${1:-}"

  echo ""
  color_echo blue "📊 My Work Patterns"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  # 작업 패턴 분석
  eval "$(analyze_work_patterns "$author")"

  if [ -n "$peak_hour" ]; then
    local peak_end=$(( (10#$peak_hour + 4) % 24 ))
    printf "Peak Hours:    %02d:00 - %02d:00\n" "$peak_hour" "$peak_end"
  else
    echo "Peak Hours:    (not enough data)"
  fi

  echo "Most Active:   ${peak_day:-N/A}"
  echo "Avg Session:   $(format_duration ${avg_duration:-0})"
  echo "Total:         ${total_sessions:-0} sessions"

  echo ""
  color_echo blue "🏷️  Topics I Work On"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  local topics=$(analyze_topic_distribution "$author")
  local total=$(echo "$topics" | awk '{sum+=$1} END {print sum}')

  echo "$topics" | head -5 | while read -r count topic; do
    local pct=$(calc_percent $count $total)
    printf "%-14s %s %d%%\n" "$topic" "$(make_bar $count $total 12)" "$pct"
  done
}

# 팀 인사이트 출력
print_team_insights() {
  echo ""
  color_echo green "👥 Team Contribution"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  local contribution=$(analyze_team_contribution)
  local total=$(echo "$contribution" | awk '{sum+=$1} END {print sum}')

  echo "$contribution" | while read -r sessions author messages; do
    local pct=$(calc_percent $sessions $total)
    printf "%-12s %s %d sessions (%d%%)\n" "$author" "$(make_bar $sessions $total 16)" "$sessions" "$pct"
  done

  echo ""
  color_echo green "🗺️  Knowledge Map"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  analyze_knowledge_map | while IFS=':' read -r area owners; do
    # 소유자 파싱
    local owner_list=""
    local owner_count=0
    IFS=',' read -ra pairs <<< "$owners"
    for pair in "${pairs[@]}"; do
      local a="${pair%%:*}"
      local c="${pair##*:}"
      if [ -z "$owner_list" ]; then
        owner_list="$a (●)"
      else
        owner_list="$owner_list, $a"
      fi
      owner_count=$((owner_count + 1))
    done

    local warning=""
    if [ "$owner_count" -eq 1 ]; then
      warning=" ⚠️ sole owner"
    fi

    printf "%-14s → %s%s\n" "$area/*" "$owner_list" "$warning"
  done
}

# TODO 인사이트 출력
print_todo_insights() {
  local author="${1:-}"

  echo ""
  color_echo yellow "📋 Open TODOs"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  eval "$(get_todo_stats)"
  open=${open:-0}
  completed=${completed:-0}
  stale=${stale:-0}

  echo "Total: $open open, $completed completed"
  if [ "$stale" -gt 0 ] 2>/dev/null; then
    color_echo red "⚠️  Stale (>2 weeks): $stale"
  fi
  echo ""

  # 최근 TODO 목록
  collect_all_todos "$author" | head -10 | while IFS='|' read -r date session todo; do
    local days_ago=""
    if [ -n "$date" ]; then
      local today=$(date +%Y-%m-%d)
      # 간단한 일수 계산 (정확하지 않을 수 있음)
      days_ago="$(echo "$date" | cut -d'-' -f3)d ago"
    fi
    printf "[ ] %s\n    %s · %s\n" "$todo" "$session" "$days_ago"
  done
}

# 전체 인사이트 출력
print_all_insights() {
  local author="${1:-}"
  local scope="${2:-all}"  # all | me | team | todos

  echo ""
  echo "╭─────────────────────────────────────────╮"
  echo "│         Session Insights                │"
  echo "╰─────────────────────────────────────────╯"

  case "$scope" in
    me|personal)
      print_personal_insights "$author"
      ;;
    team)
      print_team_insights
      ;;
    todos)
      print_todo_insights "$author"
      ;;
    *)
      print_personal_insights "$author"
      print_team_insights
      print_todo_insights "$author"
      ;;
  esac

  echo ""
}

# =====================
# AI Report Generation
# =====================

# summary.sh에서 API 함수 가져오기
source_summary_lib() {
  local summary_lib="$INSIGHTS_SCRIPT_DIR/summary.sh"
  if [ -f "$summary_lib" ]; then
    source "$summary_lib"
    return 0
  fi
  return 1
}

# 인사이트 데이터를 JSON으로 수집
collect_insights_json() {
  local backup_dir=$(get_backup_dir)
  local author="${1:-}"

  # 세션 데이터 수집
  local sessions_json="["
  local first=true
  for meta_file in "$backup_dir"/*.meta.json; do
    [ -f "$meta_file" ] || continue

    if [ -n "$author" ]; then
      local file_author=$(jq -r '.savedBy // ""' "$meta_file" 2>/dev/null)
      [ "$file_author" != "$author" ] && continue
    fi

    if [ "$first" = true ]; then
      first=false
    else
      sessions_json+=","
    fi
    sessions_json+=$(cat "$meta_file")
  done
  sessions_json+="]"

  # TODO 데이터 수집
  local todos_json="["
  first=true
  for roadmap_file in "$backup_dir"/*.roadmap.md; do
    [ -f "$roadmap_file" ] || continue

    local session_name=$(basename "$roadmap_file" .roadmap.md)

    grep -E '^\s*-\s*\[\s*\]' "$roadmap_file" 2>/dev/null | while read -r line; do
      local todo_text=$(echo "$line" | sed 's/^[[:space:]]*-[[:space:]]*\[[[:space:]]*\][[:space:]]*//')
      if [ "$first" = true ]; then
        first=false
      else
        echo ","
      fi
      jq -n --arg text "$todo_text" --arg session "$session_name" \
        '{"text": $text, "session": $session, "completed": false}'
    done
  done
  todos_json+=$(grep -h -E '^\s*-\s*\[\s*\]' "$backup_dir"/*.roadmap.md 2>/dev/null | \
    head -20 | \
    while read -r line; do
      echo "$line" | sed 's/^[[:space:]]*-[[:space:]]*\[[[:space:]]*\][[:space:]]*//'
    done | jq -R -s 'split("\n") | map(select(. != "")) | map({"text": ., "completed": false})')
  todos_json=${todos_json:-"[]"}

  # 결과 조합
  jq -n \
    --argjson sessions "$sessions_json" \
    --argjson todos "$todos_json" \
    '{
      sessions: $sessions,
      todos: $todos,
      generated_at: now | strftime("%Y-%m-%dT%H:%M:%SZ")
    }'
}

# 인사이트 요약 텍스트 생성
generate_insights_summary_text() {
  local backup_dir=$(get_backup_dir)

  # 기본 통계
  local total_sessions=$(ls -1 "$backup_dir"/*.meta.json 2>/dev/null | wc -l | tr -d ' ')
  local total_messages=0
  local authors=""

  for meta_file in "$backup_dir"/*.meta.json; do
    [ -f "$meta_file" ] || continue
    local msgs=$(jq -r '.messageCount // 0' "$meta_file" 2>/dev/null)
    total_messages=$((total_messages + msgs))
    local author=$(jq -r '.savedBy // ""' "$meta_file" 2>/dev/null)
    if [[ ! "$authors" =~ "$author" ]]; then
      authors="$authors $author"
    fi
  done

  # 팀 기여도
  local contribution=$(analyze_team_contribution)

  # 토픽 분포
  local topics=$(analyze_topic_distribution)

  # 지식 맵
  local knowledge=$(analyze_knowledge_map)

  # TODO 통계
  eval "$(get_todo_stats)"

  cat << EOF
## 기본 통계
- 총 세션 수: $total_sessions
- 총 메시지 수: $total_messages
- 참여자:$authors

## 팀 기여도
$contribution

## 토픽 분포 (세션 수 기준)
$topics

## 지식 맵 (영역별 담당자)
$knowledge

## TODO 현황
- 미완료: ${open:-0}
- 완료: ${completed:-0}
- Stale (2주 이상): ${stale:-0}

## 미완료 TODO 목록
$(collect_all_todos | head -15)
EOF
}

# AI 리포트 프롬프트 생성
generate_report_prompt() {
  local insights_text="$1"
  local report_type="${2:-weekly}"  # weekly | monthly | custom

  cat << EOF
다음 Claude Code 세션 인사이트 데이터를 분석하여 팀/프로젝트 리포트를 작성해주세요.

## 인사이트 데이터
$insights_text

---

다음 형식으로 리포트를 작성해주세요 (한국어로):

# ${report_type^} Insights Report
Generated: $(date +%Y-%m-%d)

## Executive Summary
(2-3문장으로 핵심 요약)

## Highlights
- ✅ (긍정적인 성과 2-3개)
- 🔄 (진행 중인 주요 작업)
- ⚠️ (주의가 필요한 사항)

## Team Analysis

### 기여도 분석
(팀원별 기여도 분석, 누가 어떤 영역에서 활발한지)

### 지식 맵 분석
(영역별 담당자 현황, 지식 사일로 위험 분석)

### 협업 기회
(함께 작업하면 좋을 팀원/영역 제안)

## Technical Debt
(미완료 TODO 분석, 오래된 항목 정리 필요성)

## Recommendations
1. (구체적인 액션 아이템)
2. (구체적인 액션 아이템)
3. (구체적인 액션 아이템)

## Next Steps
- [ ] (다음 주기에 집중해야 할 것들)
EOF
}

# AI 리포트 생성
generate_ai_report() {
  local report_type="${1:-weekly}"
  local output_file="${2:-}"

  # summary.sh에서 API 함수 로드
  if ! source_summary_lib; then
    echo "Error: summary.sh not found. Cannot generate AI report." >&2
    return 1
  fi

  # API 키 확인
  local api_key=$(get_api_key)
  if [ -z "$api_key" ]; then
    echo "Error: ANTHROPIC_API_KEY not set. Cannot generate AI report." >&2
    echo "Set with: export ANTHROPIC_API_KEY='sk-...'" >&2
    return 1
  fi

  echo "Collecting insights data..." >&2

  # 인사이트 데이터 수집
  local insights_text=$(generate_insights_summary_text)

  if [ -z "$insights_text" ]; then
    echo "Error: No session data found." >&2
    return 1
  fi

  echo "Generating AI report (this may take a moment)..." >&2

  # 프롬프트 생성
  local prompt=$(generate_report_prompt "$insights_text" "$report_type")

  # API 호출 (summary.sh의 call_claude_api 사용)
  local report=$(call_claude_api "$prompt")

  if [ -z "$report" ]; then
    echo "Error: Failed to generate report." >&2
    return 1
  fi

  # 출력 파일 결정
  if [ -z "$output_file" ]; then
    local backup_dir=$(get_backup_dir)
    output_file="$backup_dir/report_$(date +%Y-%m-%d).md"
  fi

  # 헤더 추가해서 저장
  cat > "$output_file" << EOF
<!-- Auto-generated Insights Report -->
<!-- Type: $report_type -->
<!-- Generated: $(date +%Y-%m-%d\ %H:%M:%S) -->

$report
EOF

  echo "Report saved to: $output_file" >&2
  echo "$output_file"
}

# 리포트 출력 (파일 저장 없이)
print_ai_report() {
  local report_type="${1:-weekly}"

  # summary.sh에서 API 함수 로드
  if ! source_summary_lib; then
    echo "Error: summary.sh not found. Cannot generate AI report." >&2
    return 1
  fi

  # API 키 확인
  local api_key=$(get_api_key)
  if [ -z "$api_key" ]; then
    echo "Error: ANTHROPIC_API_KEY not set." >&2
    return 1
  fi

  color_echo blue "Collecting insights data..." >&2

  local insights_text=$(generate_insights_summary_text)

  if [ -z "$insights_text" ]; then
    echo "No session data found." >&2
    return 1
  fi

  color_echo blue "Generating AI report..." >&2

  local prompt=$(generate_report_prompt "$insights_text" "$report_type")
  local report=$(call_claude_api "$prompt")

  if [ -z "$report" ]; then
    echo "Failed to generate report." >&2
    return 1
  fi

  echo ""
  echo "$report"
}

# =====================
# 메인 함수
# =====================

insights_main() {
  local mode="all"
  local author_filter=""
  local report_type="weekly"
  local export_format=""

  # 인자 파싱
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --me|-m)
        mode="me"
        shift
        ;;
      --team|-t)
        mode="team"
        shift
        ;;
      --todos|-d)
        mode="todos"
        shift
        ;;
      --knowledge-map|-k)
        mode="knowledge"
        shift
        ;;
      --report|-r)
        mode="report"
        shift
        ;;
      --author)
        author_filter="$2"
        shift 2
        ;;
      --weekly)
        report_type="weekly"
        shift
        ;;
      --monthly)
        report_type="monthly"
        shift
        ;;
      --export)
        export_format="$2"
        shift 2
        ;;
      -h|--help)
        echo "Usage: insights [--me|--team|--todos|--knowledge-map|--report] [--author <name>] [--weekly|--monthly]"
        return 0
        ;;
      *)
        shift
        ;;
    esac
  done

  case "$mode" in
    me)
      print_personal_insights "$author_filter"
      ;;
    team)
      print_team_insights "$author_filter"
      ;;
    todos)
      print_todo_insights "$author_filter"
      ;;
    knowledge)
      analyze_knowledge_map "$author_filter"
      ;;
    report)
      if [[ -n "$export_format" ]]; then
        local backup_dir=$(get_backup_dir)
        local output_file="$backup_dir/report_$(date +%Y-%m-%d).md"
        generate_ai_report "$report_type" "$output_file"
      else
        print_ai_report "$report_type"
      fi
      ;;
    all|*)
      print_all_insights "$author_filter"
      ;;
  esac
}

# 직접 실행 시
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  insights_main "$@"
fi
