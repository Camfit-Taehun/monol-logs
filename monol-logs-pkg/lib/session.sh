#!/bin/bash
# Session Archive - Session View/Resume/Load Library
# 세션 보기, 이어하기, 로드 기능

# 현재 스크립트 디렉토리
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# utils.sh 로드
source "$SCRIPT_DIR/utils.sh"

# =====================
# 세션 찾기
# =====================

# 세션 ID로 메타 파일 찾기
find_session_meta() {
  local session_id="$1"
  local backup_dir=$(get_backup_dir)

  # 전체 ID 또는 앞 8자리로 검색
  local meta_file=$(ls "$backup_dir"/*"$session_id"*.meta.json 2>/dev/null | head -1)

  if [[ -n "$meta_file" && -f "$meta_file" ]]; then
    echo "$meta_file"
  else
    echo ""
  fi
}

# 메타 파일에서 세션 정보 추출
get_session_info() {
  local meta_file="$1"
  local field="$2"

  if [[ ! -f "$meta_file" ]]; then
    echo ""
    return 1
  fi

  jq -r ".$field // \"\"" "$meta_file"
}

# =====================
# 세션 보기 (view)
# =====================

view_session() {
  local session_id="$1"
  local show_all="${2:-false}"
  local tail_count="${3:-20}"

  local meta_file=$(find_session_meta "$session_id")

  if [[ -z "$meta_file" ]]; then
    echo "⚠️ 세션을 찾을 수 없습니다: $session_id"
    echo ""
    echo "💡 팁: /sessions 로 등록된 세션 목록을 확인하세요."
    return 1
  fi

  local topic=$(get_session_info "$meta_file" "topic")
  local created_at=$(get_session_info "$meta_file" "createdAt")
  local saved_by=$(get_session_info "$meta_file" "savedBy")
  local message_count=$(get_session_info "$meta_file" "messageCount")
  local source_path=$(get_session_info "$meta_file" "source")
  local full_session_id=$(get_session_info "$meta_file" "sessionId")

  # 1. conversation.md가 있으면 사용
  local base_name="${meta_file%.meta.json}"
  local conversation_file="${base_name}.conversation.md"

  if [[ -f "$conversation_file" ]]; then
    if [[ "$show_all" == "true" ]]; then
      cat "$conversation_file"
    else
      # 최근 N개 메시지만 (대략적으로)
      head -100 "$conversation_file"
      echo ""
      echo "... (전체 보기: /session view $session_id --all)"
    fi
    return 0
  fi

  # 2. 원본 jsonl이 있으면 파싱
  local expanded_source="${source_path/#\~/$HOME}"

  if [[ -f "$expanded_source" ]]; then
    format_jsonl_session "$expanded_source" "$topic" "$created_at" "$show_all" "$tail_count"
    return 0
  fi

  # 3. 둘 다 없으면 메타 정보만 표시
  echo "# Session: $topic"
  echo "ID: ${full_session_id:0:8}"
  echo "Date: ${created_at:0:10} ${created_at:11:5}"
  echo "Author: $saved_by"
  echo "Messages: $message_count"
  echo ""
  echo "⚠️ 세션 내용 파일을 찾을 수 없습니다."
  echo ""
  echo "💡 팁:"
  echo "  - 원본 jsonl이 삭제되었을 수 있습니다."
  echo "  - 요약이 있다면: /session load $session_id"
}

# jsonl 파일을 읽기 좋은 형식으로 변환
format_jsonl_session() {
  local jsonl_file="$1"
  local topic="${2:-untitled}"
  local created_at="${3:-}"
  local show_all="${4:-false}"
  local tail_count="${5:-20}"

  local date_str="${created_at:0:10} ${created_at:11:5}"

  echo "# Session: $topic"
  echo "Date: $date_str"
  echo ""
  echo "---"
  echo ""

  local count=0
  local messages=()

  while IFS= read -r line; do
    [[ -z "$line" ]] && continue

    local msg_type=$(echo "$line" | jq -r '.type // ""')
    local content=""
    local timestamp=""

    case "$msg_type" in
      human)
        content=$(echo "$line" | jq -r '.message.content // ""')
        timestamp=$(echo "$line" | jq -r '.timestamp // ""')
        local time_str="${timestamp:11:5}"
        messages+=("## 👤 User ($time_str)"$'\n'"$content"$'\n')
        ;;
      assistant)
        content=$(echo "$line" | jq -r '.message.content // ""')
        timestamp=$(echo "$line" | jq -r '.timestamp // ""')
        local time_str="${timestamp:11:5}"

        # tool_use 처리
        local tool_uses=$(echo "$line" | jq -r '.message.content[]? | select(.type == "tool_use") | "**Tool: \(.name)**"' 2>/dev/null | head -3)

        if [[ -n "$tool_uses" ]]; then
          messages+=("## 🤖 Assistant ($time_str)"$'\n'"$tool_uses"$'\n')
        else
          # 텍스트 content만 추출
          local text_content=$(echo "$line" | jq -r '.message.content | if type == "array" then map(select(.type == "text") | .text) | join("\n") else . end' 2>/dev/null)
          [[ -z "$text_content" || "$text_content" == "null" ]] && text_content="$content"
          messages+=("## 🤖 Assistant ($time_str)"$'\n'"${text_content:0:500}"$'\n')
        fi
        ;;
    esac

    count=$((count + 1))
  done < "$jsonl_file"

  # 출력
  local total=${#messages[@]}
  local start=0

  if [[ "$show_all" != "true" && $total -gt $tail_count ]]; then
    start=$((total - tail_count))
    echo "... (처음 $start개 메시지 생략, 전체 보기: --all)"
    echo ""
  fi

  for ((i=start; i<total; i++)); do
    echo "${messages[$i]}"
  done

  echo "---"
  echo "Total: $count messages"
}

# =====================
# 세션 이어하기 (resume)
# =====================

resume_session() {
  local session_id="$1"

  local meta_file=$(find_session_meta "$session_id")

  if [[ -z "$meta_file" ]]; then
    echo "⚠️ 세션을 찾을 수 없습니다: $session_id"
    echo ""
    echo "💡 팁: /sessions 로 등록된 세션 목록을 확인하세요."
    return 1
  fi

  local topic=$(get_session_info "$meta_file" "topic")
  local created_at=$(get_session_info "$meta_file" "createdAt")
  local message_count=$(get_session_info "$meta_file" "messageCount")
  local source_path=$(get_session_info "$meta_file" "source")
  local full_session_id=$(get_session_info "$meta_file" "sessionId")

  # 원본 파일 확인
  local expanded_source="${source_path/#\~/$HOME}"

  if [[ -f "$expanded_source" ]]; then
    echo "🔄 세션 이어하기"
    echo ""
    echo "Session: $topic (${full_session_id:0:8})"
    echo "Date: ${created_at:0:10} ${created_at:11:5}"
    echo "Messages: $message_count"
    echo ""
    echo "다음 명령어로 세션을 이어하세요:"
    echo ""
    echo "  claude --resume $full_session_id"
    echo ""
  else
    echo "⚠️ 원본 세션 파일이 없습니다."
    echo "   경로: $source_path"
    echo ""
    echo "   Claude가 세션을 정리했을 수 있습니다."
    echo "   요약이 있다면 /session load ${full_session_id:0:8} 로 컨텍스트를 로드하세요."
  fi
}

# =====================
# 세션 로드 (load)
# =====================

load_session() {
  local session_id="$1"

  local meta_file=$(find_session_meta "$session_id")

  if [[ -z "$meta_file" ]]; then
    echo "⚠️ 세션을 찾을 수 없습니다: $session_id"
    echo ""
    echo "💡 팁: /sessions 로 등록된 세션 목록을 확인하세요."
    return 1
  fi

  local topic=$(get_session_info "$meta_file" "topic")
  local created_at=$(get_session_info "$meta_file" "createdAt")
  local saved_by=$(get_session_info "$meta_file" "savedBy")
  local full_session_id=$(get_session_info "$meta_file" "sessionId")

  local base_name="${meta_file%.meta.json}"
  local summary_file="${base_name}.summary.md"
  local roadmap_file="${base_name}.roadmap.md"

  echo "📋 이전 세션 컨텍스트 로드"
  echo ""
  echo "**세션**: $topic (${created_at:0:10})"
  echo "**저장자**: $saved_by"
  echo ""
  echo "---"
  echo ""

  # 요약 파일 출력
  if [[ -f "$summary_file" ]]; then
    cat "$summary_file"
    echo ""
  else
    echo "⚠️ 요약 파일이 없습니다."
    echo ""
    echo "💡 /summary ${full_session_id:0:8} 로 요약을 생성하세요."
    echo ""
  fi

  echo "---"
  echo ""

  # TODO 목록 출력
  if [[ -f "$roadmap_file" ]]; then
    echo "**남은 TODO** (roadmap.md에서):"
    echo ""
    grep -E "^\s*-\s*\[\s*\]" "$roadmap_file" | head -10
    echo ""
  fi

  echo "---"
  echo "이어서 작업하려면 위 컨텍스트를 참고하세요."
}

# =====================
# 메인 함수
# =====================

session_main() {
  local command="${1:-}"
  shift || true

  local session_id=""
  local show_all="false"
  local tail_count="20"

  # 인자 파싱
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --all)
        show_all="true"
        shift
        ;;
      --tail)
        tail_count="$2"
        shift 2
        ;;
      -h|--help)
        echo "Usage: session <view|resume|load> <session-id> [--all] [--tail N]"
        return 0
        ;;
      *)
        if [[ -z "$session_id" ]]; then
          session_id="$1"
        fi
        shift
        ;;
    esac
  done

  if [[ -z "$command" ]]; then
    echo "Usage: session <view|resume|load> <session-id>"
    echo ""
    echo "Commands:"
    echo "  view    - 세션 내용 보기"
    echo "  resume  - 세션 이어하기 (claude --resume)"
    echo "  load    - 세션 요약을 현재 컨텍스트에 로드"
    return 1
  fi

  if [[ -z "$session_id" ]]; then
    echo "⚠️ 세션 ID를 입력하세요."
    echo ""
    echo "💡 팁: /sessions 로 등록된 세션 목록을 확인하세요."
    return 1
  fi

  case "$command" in
    view)
      view_session "$session_id" "$show_all" "$tail_count"
      ;;
    resume)
      resume_session "$session_id"
      ;;
    load)
      load_session "$session_id"
      ;;
    *)
      echo "⚠️ 알 수 없는 명령: $command"
      echo ""
      echo "사용 가능한 명령: view, resume, load"
      return 1
      ;;
  esac
}

# 직접 실행 시
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  session_main "$@"
fi
