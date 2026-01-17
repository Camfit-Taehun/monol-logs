#!/bin/bash
# Session Archive - Session Branch Script
# 현재 세션을 복제하여 새 브랜치/폴더에서 분기
#
# 사용법:
#   session-branch.sh <branch-name>           # git worktree + 새 터미널
#   session-branch.sh <branch-name> --same-dir    # 같은 폴더에서 세션만 분기
#   session-branch.sh <branch-name> --no-auto     # 터미널 자동 열기 안 함
#   session-branch.sh --list                  # 현재 세션 목록
#   session-branch.sh --branches              # 분기 기록 보기

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(dirname "$SCRIPT_DIR")"

# 라이브러리 로드
source "$PLUGIN_DIR/lib/utils.sh"
source "$PLUGIN_DIR/lib/branch.sh"

# 사용법 출력
usage() {
  cat << 'EOF'
Session Archive - Session Branch

Fork the current Claude Code session into a new branch/directory.

Usage:
  session-branch.sh <branch-name>              Default: git worktree + new terminal
  session-branch.sh <branch-name> --same-dir   Fork session only (same directory)
  session-branch.sh <branch-name> --no-auto    Don't auto-open terminal
  session-branch.sh <branch-name> --no-worktree  No worktree, session only
  session-branch.sh --list                     List current sessions
  session-branch.sh --branches                 Show branch history
  session-branch.sh --help                     Show this help

Options:
  --same-dir       Fork session in the same directory (no worktree)
  --no-auto        Don't automatically open new terminal
  --no-worktree    Don't create git worktree (just fork session)

Examples:
  # Fork to work on feature-b
  session-branch.sh feature-b
  # → Creates ../project-feature-b worktree
  # → Opens new terminal with forked session

  # Experimental branch in same directory
  session-branch.sh experiment --same-dir
  # → Forks session, prints command to run

  # Manual mode
  session-branch.sh hotfix --no-auto
  # → Creates worktree, prints command (doesn't open terminal)

How it works:
  1. Finds your current Claude Code session
  2. Creates git worktree (if not --same-dir)
  3. Opens new terminal with: claude --resume <session> --fork-session
  4. Records branch in .claude/sessions/branches.md

Note: Requires git repository for worktree mode.
EOF
}

# 브랜치 기록 보기
show_branches() {
  local branches_file=$(get_branches_file)

  if [ -f "$branches_file" ]; then
    cat "$branches_file"
  else
    echo "No branches recorded yet."
    echo "Create a branch with: $(basename "$0") <branch-name>"
  fi
}

# 메인
main() {
  case "${1:-}" in
    --help|-h)
      usage
      exit 0
      ;;
    --list|-l)
      list_sessions
      exit 0
      ;;
    --branches|-b)
      show_branches
      exit 0
      ;;
    "")
      echo "Error: Branch name required"
      echo ""
      usage
      exit 1
      ;;
    --*)
      echo "Error: Unknown option: $1"
      echo ""
      usage
      exit 1
      ;;
    *)
      # 브랜치 이름이 주어짐
      local branch_name="$1"
      shift

      # git 저장소 확인 (worktree 모드일 때)
      local same_dir=false
      local no_worktree=false
      for arg in "$@"; do
        case "$arg" in
          --same-dir) same_dir=true ;;
          --no-worktree) no_worktree=true ;;
        esac
      done

      if [ "$same_dir" = false ] && [ "$no_worktree" = false ]; then
        if ! git rev-parse --git-dir > /dev/null 2>&1; then
          echo "Error: Not a git repository."
          echo "Use --same-dir or --no-worktree for non-git directories."
          exit 1
        fi
      fi

      # 분기 실행
      branch_session "$branch_name" "$@"
      ;;
  esac
}

main "$@"
