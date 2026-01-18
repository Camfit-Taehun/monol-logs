#!/bin/bash
# Session Start Hook - 최신 세션 요약 및 로드맵 로드

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
SESSIONS_DIR="$PROJECT_DIR/.claude/sessions"

# 세션 디렉토리 없으면 종료
if [ ! -d "$SESSIONS_DIR" ]; then
  exit 0
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  monol-logs: 이전 세션 컨텍스트"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 최신 세션 요약 찾기
LATEST_SUMMARY=$(ls -t "$SESSIONS_DIR"/*.summary.md 2>/dev/null | head -1)

if [ -n "$LATEST_SUMMARY" ] && [ -f "$LATEST_SUMMARY" ]; then
  SUMMARY_NAME=$(basename "$LATEST_SUMMARY")
  echo "## 최근 세션 요약 ($SUMMARY_NAME)"
  echo ""
  cat "$LATEST_SUMMARY"
  echo ""
fi

# 로드맵 확인
ROADMAP="$SESSIONS_DIR/roadmap.md"

if [ -f "$ROADMAP" ]; then
  # 미완료 TODO만 추출
  PENDING=$(grep -E "^\s*-\s*\[\s*\]" "$ROADMAP" 2>/dev/null | head -10)

  if [ -n "$PENDING" ]; then
    echo "## 미완료 TODO (roadmap.md)"
    echo ""
    echo "$PENDING"
    echo ""
  fi
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
