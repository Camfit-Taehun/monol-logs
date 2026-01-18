#!/bin/bash
# Session Archive - Common Utilities
# 공통 유틸리티 함수

# 설정 파일 경로 찾기
find_config() {
  local plugin_dir="${1:-$(dirname "$(dirname "${BASH_SOURCE[0]}")")}"
  local config_file="$plugin_dir/config.yaml"

  if [ -f "$config_file" ]; then
    echo "$config_file"
  else
    echo ""
  fi
}

# YAML에서 값 읽기 (간단한 파서, yq 없이 동작)
get_config_value() {
  local key="$1"
  local default="$2"
  local config_file="${3:-$(find_config)}"

  if [ -z "$config_file" ] || [ ! -f "$config_file" ]; then
    echo "$default"
    return
  fi

  # 간단한 YAML 파싱 (key: value 형태만 지원)
  local value=$(grep "^${key}:" "$config_file" | sed 's/^[^:]*:[[:space:]]*//' | tr -d '"' | tr -d "'")

  if [ -z "$value" ]; then
    echo "$default"
  else
    echo "$value"
  fi
}

# 백업 디렉토리 경로 생성
get_backup_dir() {
  local project_dir="${CLAUDE_PROJECT_DIR:-$(pwd)}"
  local output_dir=$(get_config_value "output_dir" ".claude/sessions")

  echo "$project_dir/$output_dir"
}

# 세션 파일명 생성
generate_filename() {
  local session_id="$1"
  local topic="${2:-}"

  local timestamp=$(date +%Y-%m-%d_%H%M)
  local short_id="${session_id:0:8}"

  if [ -n "$topic" ]; then
    # topic이 있으면 포함
    echo "${timestamp}_${topic}_${short_id}.jsonl"
  else
    echo "${timestamp}_${short_id}.jsonl"
  fi
}

# 세션 파일 복사
copy_session() {
  local src="$1"
  local dest="$2"

  if [ ! -f "$src" ]; then
    echo "Source file not found: $src" >&2
    return 1
  fi

  local dest_dir=$(dirname "$dest")
  mkdir -p "$dest_dir"

  cp "$src" "$dest"
  echo "Archived: $dest" >&2
  return 0
}

# 세션 통계 출력
print_session_stats() {
  local session_file="$1"

  if [ ! -f "$session_file" ]; then
    echo "File not found" >&2
    return 1
  fi

  local total_lines=$(wc -l < "$session_file" | tr -d ' ')
  local user_msgs=$(grep -c '"type":"user"' "$session_file" 2>/dev/null || echo "0")
  local assistant_msgs=$(grep -c '"type":"assistant"' "$session_file" 2>/dev/null || echo "0")
  local file_size=$(ls -lh "$session_file" | awk '{print $5}')

  echo "Lines: $total_lines | User: $user_msgs | Assistant: $assistant_msgs | Size: $file_size"
}

# 현재 세션 ID 추출 (Claude Code 내부에서 실행 시)
get_current_session_id() {
  # stdin에서 JSON 입력이 있으면 거기서 추출
  if [ -p /dev/stdin ]; then
    read -r input
    echo "$input" | jq -r '.session_id // empty'
  else
    echo ""
  fi
}

# 세션 파일 경로 찾기 (session_id로)
find_session_file() {
  local session_id="$1"
  local claude_dir="$HOME/.claude/projects"

  # 모든 프로젝트에서 해당 세션 찾기
  find "$claude_dir" -name "${session_id}.jsonl" 2>/dev/null | head -1
}

# 로그 출력 (verbose 모드용)
log() {
  local level="$1"
  shift
  local message="$*"

  local verbose=$(get_config_value "verbose" "false")

  if [ "$verbose" = "true" ] || [ "$level" = "ERROR" ]; then
    echo "[$level] $message" >&2
  fi
}

# 색상 출력 (터미널 지원 시)
color_echo() {
  local color="$1"
  shift
  local message="$*"

  case "$color" in
    green)  echo -e "\033[32m$message\033[0m" ;;
    yellow) echo -e "\033[33m$message\033[0m" ;;
    red)    echo -e "\033[31m$message\033[0m" ;;
    blue)   echo -e "\033[34m$message\033[0m" ;;
    *)      echo "$message" ;;
  esac
}
