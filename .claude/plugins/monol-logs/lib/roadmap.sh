#!/bin/bash
# Session Archive - Roadmap Utilities
# 세션에서 TODO/로드맵 항목 추출 및 관리

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

# 기본 TODO 패턴들
DEFAULT_PATTERNS=(
  '- \[ \]'           # 마크다운 체크박스
  'TODO:'             # TODO 주석
  'FIXME:'            # FIXME 주석
  '다음에'            # 한국어 패턴
  '나중에'
  '할 일'
  '해야 할'
  '구현 예정'
  '추가 예정'
)

# 세션 JSONL에서 어시스턴트 메시지 추출
extract_assistant_messages() {
  local session_file="$1"

  if [ ! -f "$session_file" ]; then
    echo "File not found: $session_file" >&2
    return 1
  fi

  # assistant 타입 메시지의 content 추출
  grep '"type":"assistant"' "$session_file" | \
    jq -r '.message.content // empty' 2>/dev/null | \
    grep -v '^$'
}

# 텍스트에서 TODO 항목 추출
extract_todos_from_text() {
  local text="$1"
  local patterns=("${@:2}")

  # 패턴이 없으면 기본 패턴 사용
  if [ ${#patterns[@]} -eq 0 ]; then
    patterns=("${DEFAULT_PATTERNS[@]}")
  fi

  # 각 패턴에 대해 검색
  for pattern in "${patterns[@]}"; do
    echo "$text" | grep -E "$pattern" 2>/dev/null || true
  done | sort -u
}

# 세션 파일에서 TODO 추출
extract_todos_from_session() {
  local session_file="$1"

  # 어시스턴트 메시지 추출
  local messages=$(extract_assistant_messages "$session_file")

  if [ -z "$messages" ]; then
    return 0
  fi

  # TODO 패턴 추출
  extract_todos_from_text "$messages"
}

# roadmap.md 파일 경로 반환
get_roadmap_file() {
  local backup_dir=$(get_backup_dir)
  local roadmap_file=$(get_config_value "roadmap_file" "roadmap.md")

  echo "$backup_dir/$roadmap_file"
}

# 세션별 roadmap 파일 경로 반환
get_session_roadmap_file() {
  local session_file="$1"
  local basename=$(basename "$session_file" .jsonl)

  echo "$(dirname "$session_file")/${basename}.roadmap.md"
}

# roadmap.md 초기화 (없으면 생성)
init_roadmap_file() {
  local roadmap_file=$(get_roadmap_file)

  if [ ! -f "$roadmap_file" ]; then
    mkdir -p "$(dirname "$roadmap_file")"
    cat > "$roadmap_file" << 'EOF'
# Session Roadmap

세션에서 추출된 할 일 목록

## Active (진행 중)

<!-- 진행 중인 항목들 -->

## Backlog (나중에)

<!-- 나중에 할 항목들 -->

## Completed (완료)

<!-- 완료된 항목들 -->
EOF
    log "INFO" "Created roadmap file: $roadmap_file"
  fi

  echo "$roadmap_file"
}

# roadmap.md에 TODO 추가
add_todos_to_roadmap() {
  local roadmap_file="$1"
  local session_date="$2"
  local session_id="$3"
  shift 3
  local todos=("$@")

  if [ ${#todos[@]} -eq 0 ]; then
    log "INFO" "No TODOs to add"
    return 0
  fi

  # 임시 파일에 새 항목 추가
  local temp_file=$(mktemp)

  # Active 섹션 찾아서 그 아래에 추가
  local in_active=false
  local added=false

  while IFS= read -r line; do
    echo "$line" >> "$temp_file"

    if [[ "$line" == "## Active"* ]]; then
      in_active=true
    elif [[ "$line" == "## "* ]] && [ "$in_active" = true ]; then
      in_active=false
    fi

    # Active 섹션의 첫 번째 빈 줄 또는 주석 뒤에 추가
    if [ "$in_active" = true ] && [ "$added" = false ]; then
      if [[ "$line" == "" ]] || [[ "$line" == "<!--"* ]]; then
        echo "" >> "$temp_file"
        echo "### From: $session_date (${session_id:0:8})" >> "$temp_file"
        for todo in "${todos[@]}"; do
          # 이미 체크박스가 있으면 그대로, 없으면 추가
          if [[ "$todo" == "- ["* ]]; then
            echo "$todo" >> "$temp_file"
          else
            echo "- [ ] $todo" >> "$temp_file"
          fi
        done
        added=true
      fi
    fi
  done < "$roadmap_file"

  mv "$temp_file" "$roadmap_file"
  log "INFO" "Added ${#todos[@]} TODOs to roadmap"
}

# 세션별 roadmap 파일 생성
create_session_roadmap() {
  local session_file="$1"
  local session_date="$2"
  local todos=("${@:3}")

  local roadmap_file=$(get_session_roadmap_file "$session_file")

  cat > "$roadmap_file" << EOF
# Session Roadmap
Date: $session_date
Session: $(basename "$session_file" .jsonl)

## TODO Items

EOF

  for todo in "${todos[@]}"; do
    if [[ "$todo" == "- ["* ]]; then
      echo "$todo" >> "$roadmap_file"
    else
      echo "- [ ] $todo" >> "$roadmap_file"
    fi
  done

  echo "$roadmap_file"
}

# TODO 항목 정리 (중복 제거, 포맷팅)
clean_todos() {
  local todos=("$@")
  local cleaned=()

  for todo in "${todos[@]}"; do
    # 빈 줄 제거
    [ -z "$todo" ] && continue

    # 앞뒤 공백 제거
    todo=$(echo "$todo" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    # 중복 체크
    local is_dup=false
    for existing in "${cleaned[@]}"; do
      if [ "$todo" = "$existing" ]; then
        is_dup=true
        break
      fi
    done

    [ "$is_dup" = false ] && cleaned+=("$todo")
  done

  printf '%s\n' "${cleaned[@]}"
}
