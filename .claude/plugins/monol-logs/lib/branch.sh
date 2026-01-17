#!/bin/bash
# Session Archive - Branch Utilities
# 세션 분기 관련 유틸리티 함수

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

# =====================
# 세션 관련 함수
# =====================

# 프로젝트 경로를 Claude Code 세션 디렉토리 이름으로 변환
get_project_hash() {
  local project_dir="${1:-$(pwd)}"
  # /Users/kent/Work/project → -Users-kent-Work-project
  # 앞의 -를 유지해야 함 (Claude Code 실제 동작)
  echo "$project_dir" | tr '/' '-'
}

# Claude Code 세션 디렉토리 경로
get_sessions_dir() {
  local project_dir="${1:-$(pwd)}"
  local project_hash=$(get_project_hash "$project_dir")
  echo "$HOME/.claude/projects/$project_hash"
}

# 현재(가장 최근) 세션 ID 찾기
get_current_session_id() {
  local project_dir="${1:-$(pwd)}"
  local sessions_dir=$(get_sessions_dir "$project_dir")

  if [ ! -d "$sessions_dir" ]; then
    echo ""
    return 1
  fi

  # 가장 최근에 수정된 jsonl 파일
  local latest=$(ls -t "$sessions_dir"/*.jsonl 2>/dev/null | head -1)

  if [ -z "$latest" ]; then
    echo ""
    return 1
  fi

  basename "$latest" .jsonl
}

# 세션 목록
list_sessions() {
  local project_dir="${1:-$(pwd)}"
  local sessions_dir=$(get_sessions_dir "$project_dir")

  if [ ! -d "$sessions_dir" ]; then
    echo "No sessions found"
    return 1
  fi

  echo "Sessions in: $sessions_dir"
  echo ""

  ls -lt "$sessions_dir"/*.jsonl 2>/dev/null | while read -r line; do
    local file=$(echo "$line" | awk '{print $NF}')
    local session_id=$(basename "$file" .jsonl)
    local size=$(echo "$line" | awk '{print $5}')
    local date=$(echo "$line" | awk '{print $6, $7, $8}')
    echo "  ${session_id:0:8}...  $date  $(numfmt --to=iec $size 2>/dev/null || echo "${size}B")"
  done
}

# =====================
# Git Worktree 함수
# =====================

# git worktree 생성
create_worktree() {
  local branch_name="$1"
  local base_branch="${2:-HEAD}"
  local worktree_base="${3:-..}"

  local project_name=$(basename "$(pwd)")
  local worktree_path="$worktree_base/${project_name}-${branch_name}"

  # 이미 존재하는지 확인
  if [ -d "$worktree_path" ]; then
    echo "Worktree already exists: $worktree_path" >&2
    return 1
  fi

  # 브랜치가 이미 존재하는지 확인
  if git show-ref --verify --quiet "refs/heads/$branch_name"; then
    # 기존 브랜치 사용
    git worktree add "$worktree_path" "$branch_name" >&2
  else
    # 새 브랜치 생성
    git worktree add -b "$branch_name" "$worktree_path" "$base_branch" >&2
  fi

  if [ $? -eq 0 ]; then
    # 절대 경로 반환 (stdout으로만)
    cd "$worktree_path" && pwd
  else
    return 1
  fi
}

# worktree 목록
list_worktrees() {
  git worktree list
}

# =====================
# 터미널 자동 열기 (macOS)
# =====================

# iTerm2에서 새 탭 열기
open_iterm_tab() {
  local dir="$1"
  local command="$2"

  osascript << EOF
tell application "iTerm"
  activate
  tell current window
    create tab with default profile
    tell current session
      write text "cd '$dir' && $command"
    end tell
  end tell
end tell
EOF
}

# iTerm2에서 새 창 열기
open_iterm_window() {
  local dir="$1"
  local command="$2"

  osascript << EOF
tell application "iTerm"
  activate
  set newWindow to (create window with default profile)
  tell current session of newWindow
    write text "cd '$dir' && $command"
  end tell
end tell
EOF
}

# Terminal.app에서 새 탭 열기
open_terminal_tab() {
  local dir="$1"
  local command="$2"

  osascript << EOF
tell application "Terminal"
  activate
  tell application "System Events" to keystroke "t" using command down
  delay 0.5
  do script "cd '$dir' && $command" in front window
end tell
EOF
}

# Terminal.app에서 새 창 열기
open_terminal_window() {
  local dir="$1"
  local command="$2"

  osascript << EOF
tell application "Terminal"
  activate
  do script "cd '$dir' && $command"
end tell
EOF
}

# Warp에서 새 탭 열기 (CLI 방식)
open_warp_tab() {
  local dir="$1"
  local command="$2"

  # 임시 스크립트 생성
  local tmp_script=$(mktemp /tmp/warp_cmd.XXXXXX.sh)
  cat > "$tmp_script" << SCRIPT
#!/bin/bash
cd '$dir'
$command
SCRIPT
  chmod +x "$tmp_script"

  # Warp에서 새 탭으로 스크립트 실행
  open -a Warp "$tmp_script"

  # 잠시 후 임시 파일 삭제 (백그라운드)
  (sleep 5 && rm -f "$tmp_script") &
}

# Warp에서 새 창 열기 (CLI 방식)
open_warp_window() {
  local dir="$1"
  local command="$2"

  # 임시 스크립트 생성
  local tmp_script=$(mktemp /tmp/warp_cmd.XXXXXX.sh)
  cat > "$tmp_script" << SCRIPT
#!/bin/bash
cd '$dir'
$command
SCRIPT
  chmod +x "$tmp_script"

  # Warp에서 새 창으로 스크립트 실행
  open -na Warp "$tmp_script"

  # 잠시 후 임시 파일 삭제 (백그라운드)
  (sleep 5 && rm -f "$tmp_script") &
}

# Kitty에서 새 탭 열기
open_kitty_tab() {
  local dir="$1"
  local command="$2"

  kitty @ launch --type=tab --cwd="$dir" --hold bash -c "$command"
}

# Kitty에서 새 창 열기
open_kitty_window() {
  local dir="$1"
  local command="$2"

  kitty @ launch --type=os-window --cwd="$dir" --hold bash -c "$command"
}

# config에서 터미널 앱 설정 읽기
get_terminal_app() {
  local config_file="$SCRIPT_DIR/../config.yaml"
  if [ -f "$config_file" ]; then
    local app=$(grep "^branch_terminal_app:" "$config_file" | sed 's/.*: *//' | tr -d '"' | tr -d "'")
    echo "${app:-auto}"
  else
    echo "auto"
  fi
}

# 터미널 앱 자동 감지
detect_terminal_app() {
  if [ -d "/Applications/Warp.app" ]; then
    echo "warp"
  elif [ -d "/Applications/iTerm.app" ]; then
    echo "iterm"
  elif command -v kitty &> /dev/null; then
    echo "kitty"
  else
    echo "terminal"
  fi
}

# 터미널 앱 설치 여부 확인
is_terminal_available() {
  local app="$1"
  case "$app" in
    warp) [ -d "/Applications/Warp.app" ] ;;
    iterm|iterm2) [ -d "/Applications/iTerm.app" ] ;;
    kitty) command -v kitty &> /dev/null ;;
    terminal) [ -d "/Applications/Utilities/Terminal.app" ] || [ -d "/System/Applications/Utilities/Terminal.app" ] ;;
    *) return 1 ;;
  esac
}

# 터미널 열기 (설정 기반 + fallback)
open_terminal() {
  local dir="$1"
  local command="$2"
  local mode="${3:-tab}"  # tab 또는 window

  local app=$(get_terminal_app)

  # auto면 자동 감지
  if [ "$app" = "auto" ]; then
    app=$(detect_terminal_app)
  fi

  # 설정된 터미널이 없으면 fallback
  if ! is_terminal_available "$app"; then
    echo "Warning: $app not found, falling back..." >&2
    app=$(detect_terminal_app)
  fi

  case "$app" in
    warp)
      if [ "$mode" = "window" ]; then
        open_warp_window "$dir" "$command"
      else
        open_warp_tab "$dir" "$command"
      fi
      ;;
    iterm|iterm2)
      if [ "$mode" = "window" ]; then
        open_iterm_window "$dir" "$command"
      else
        open_iterm_tab "$dir" "$command"
      fi
      ;;
    kitty)
      if [ "$mode" = "window" ]; then
        open_kitty_window "$dir" "$command"
      else
        open_kitty_tab "$dir" "$command"
      fi
      ;;
    terminal|*)
      if [ "$mode" = "window" ]; then
        open_terminal_window "$dir" "$command"
      else
        open_terminal_tab "$dir" "$command"
      fi
      ;;
  esac
}

# =====================
# 브랜치 레지스트리 관리
# =====================

# branches.md 파일 경로
get_branches_file() {
  local backup_dir=$(get_backup_dir)
  echo "$backup_dir/branches.md"
}

# branches.md 초기화
init_branches_file() {
  local branches_file=$(get_branches_file)

  if [ ! -f "$branches_file" ]; then
    mkdir -p "$(dirname "$branches_file")"
    cat > "$branches_file" << 'EOF'
# Session Branches

세션 분기 기록

| Branch | Session ID | Date | Path | Parent |
|--------|------------|------|------|--------|
EOF
    log "INFO" "Created branches file: $branches_file"
  fi

  echo "$branches_file"
}

# branches.md에 기록 추가
add_branch_record() {
  local branch_name="$1"
  local session_id="$2"
  local path="$3"
  local parent_branch="${4:-main}"

  local branches_file=$(init_branches_file)
  local date=$(date +%Y-%m-%d\ %H:%M)
  local short_id="${session_id:0:8}"

  echo "| $branch_name | $short_id | $date | $path | $parent_branch |" >> "$branches_file"

  log "INFO" "Recorded branch: $branch_name -> $short_id"
}

# 브랜치 기록 조회
get_branch_info() {
  local branch_name="$1"
  local branches_file=$(get_branches_file)

  if [ ! -f "$branches_file" ]; then
    return 1
  fi

  grep "| $branch_name |" "$branches_file"
}

# =====================
# 메인 분기 함수
# =====================

# 세션 분기 실행
branch_session() {
  local branch_name="$1"
  local options="${@:2}"

  # 옵션 파싱
  local same_dir=false
  local no_auto=false
  local no_worktree=false

  for opt in $options; do
    case "$opt" in
      --same-dir) same_dir=true ;;
      --no-auto) no_auto=true ;;
      --no-worktree) no_worktree=true ;;
    esac
  done

  # 현재 세션 ID
  local current_session=$(get_current_session_id)
  if [ -z "$current_session" ]; then
    echo "No current session found" >&2
    return 1
  fi

  echo "Current session: ${current_session:0:8}..."

  local target_dir=$(pwd)
  local parent_branch="main"

  # 원본 프로젝트 경로 저장
  local source_dir=$(pwd)

  # 1. git worktree 생성 (옵션에 따라)
  if [ "$same_dir" = false ] && [ "$no_worktree" = false ]; then
    echo "Creating git worktree..."
    target_dir=$(create_worktree "$branch_name")

    if [ $? -ne 0 ]; then
      echo "Failed to create worktree" >&2
      return 1
    fi

    parent_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")
    echo "Worktree created: $target_dir"

    # 1.5 .claude/sessions 폴더 복사
    if [ -d "$source_dir/.claude/sessions" ]; then
      echo "Copying session history..."
      mkdir -p "$target_dir/.claude"
      cp -r "$source_dir/.claude/sessions" "$target_dir/.claude/sessions"
      echo "Session history copied"
    fi
  fi

  # 2. 브랜치 레지스트리에 기록
  add_branch_record "$branch_name" "$current_session" "$target_dir" "$parent_branch"

  # 3. Claude Code 시작 명령어
  local claude_cmd="claude --resume $current_session --fork-session"

  if [ "$no_auto" = true ]; then
    # 수동 모드: 명령어만 출력
    echo ""
    echo "=== Branch created ==="
    echo "Directory: $target_dir"
    echo ""
    echo "To start the branched session, run:"
    echo "  cd $target_dir"
    echo "  $claude_cmd"
  else
    # 자동 모드: 새 터미널 열기
    echo ""
    echo "Opening new terminal..."
    open_terminal "$target_dir" "$claude_cmd" "tab"
    echo ""
    echo "=== Branch created ==="
    echo "Directory: $target_dir"
    echo "Session forked in new terminal tab"
  fi

  return 0
}
