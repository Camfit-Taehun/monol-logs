#!/bin/bash
# Session Archive - Setup Script
# Claude Code settings.json에 hooks 설정 추가

set -e

SETTINGS_FILE="$HOME/.claude/settings.json"
PLUGIN_DIR="$HOME/.claude/plugins/session-archive"

echo "=== Session Archive Plugin Setup ==="
echo ""

# 프로젝트 디렉토리 감지 (git root 또는 현재 디렉토리)
if git rev-parse --show-toplevel &>/dev/null; then
  PROJECT_DIR="$(git rev-parse --show-toplevel)"
else
  PROJECT_DIR="$(pwd)"
fi

# 1. 플러그인 디렉토리 확인
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_PLUGIN_DIR="$(dirname "$SCRIPT_DIR")"

echo "[1/7] Checking plugin source..."
if [ ! -d "$SOURCE_PLUGIN_DIR/hooks" ]; then
  echo "Error: Plugin hooks directory not found at $SOURCE_PLUGIN_DIR/hooks"
  exit 1
fi
echo "  Source: $SOURCE_PLUGIN_DIR"

# 2. 플러그인 설치 (심볼릭 링크)
echo "[2/7] Installing plugin..."
mkdir -p "$HOME/.claude/plugins"

if [ -L "$PLUGIN_DIR" ]; then
  echo "  Plugin symlink already exists"
elif [ -d "$PLUGIN_DIR" ]; then
  echo "  Plugin directory exists (not a symlink)"
  read -p "  Replace with symlink? [y/N] " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -rf "$PLUGIN_DIR"
    ln -s "$SOURCE_PLUGIN_DIR" "$PLUGIN_DIR"
    echo "  Replaced with symlink"
  fi
else
  ln -s "$SOURCE_PLUGIN_DIR" "$PLUGIN_DIR"
  echo "  Created symlink: $PLUGIN_DIR -> $SOURCE_PLUGIN_DIR"
fi

# 3. 프로젝트에 commands 설치
echo "[3/7] Installing commands to project..."
mkdir -p "$PROJECT_DIR/.claude/commands"

# commands 디렉토리의 각 .md 파일을 심볼릭 링크
if [ -d "$SOURCE_PLUGIN_DIR/commands" ]; then
  for cmd_file in "$SOURCE_PLUGIN_DIR/commands"/*.md; do
    if [ -f "$cmd_file" ]; then
      cmd_name=$(basename "$cmd_file")
      target="$PROJECT_DIR/.claude/commands/$cmd_name"
      if [ -L "$target" ]; then
        echo "  Command /$cmd_name already linked"
      elif [ -f "$target" ]; then
        echo "  Command /$cmd_name exists (not a symlink), skipping"
      else
        ln -s "$cmd_file" "$target"
        echo "  Linked: /$cmd_name"
      fi
    fi
  done
else
  echo "  No commands to install"
fi

# 4. settings.json 존재 확인
echo "[4/7] Checking settings file..."
if [ ! -f "$SETTINGS_FILE" ]; then
  echo "  Creating $SETTINGS_FILE..."
  mkdir -p "$(dirname "$SETTINGS_FILE")"
  echo '{}' > "$SETTINGS_FILE"
else
  echo "  Found: $SETTINGS_FILE"
fi

# 5. jq 설치 확인
echo "[5/7] Checking dependencies..."
if ! command -v jq &> /dev/null; then
  echo "Error: jq is required. Install with: brew install jq"
  exit 1
fi
echo "  jq: OK"

# 6. 현재 설정 백업
echo "[6/7] Backing up current settings..."
BACKUP_FILE="$SETTINGS_FILE.backup.$(date +%Y%m%d_%H%M%S)"
cp "$SETTINGS_FILE" "$BACKUP_FILE"
echo "  Backup: $BACKUP_FILE"

# 7. hooks 설정 추가
echo "[7/7] Configuring hooks..."
HOOK_CONFIG=$(cat <<EOF
{
  "hooks": {
    "PreCompact": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash $PLUGIN_DIR/hooks/on-pre-compact.sh"
          }
        ]
      }
    ],
    "SessionEnd": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash $PLUGIN_DIR/hooks/on-session-end.sh"
          }
        ]
      }
    ]
  }
}
EOF
)

# 기존 설정과 병합 (deep merge)
jq -s '
  def deep_merge:
    if type == "object" then
      reduce (.[0] | keys_unsorted)[] as $key (
        .[1];
        if .[0][$key] | type == "object" and .[$key] | type == "object"
        then .[$key] = ([.[0][$key], .[$key]] | deep_merge)
        else .[$key] = .[0][$key]
        end
      )
    else .[0]
    end;
  [.[1], .[0]] | deep_merge
' "$SETTINGS_FILE" <(echo "$HOOK_CONFIG") > "$SETTINGS_FILE.tmp"
mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"

# 8. hook 스크립트 실행 권한
chmod +x "$PLUGIN_DIR/hooks/"*.sh 2>/dev/null || true
chmod +x "$PLUGIN_DIR/scripts/"*.sh 2>/dev/null || true

echo ""
echo "=== Setup Complete! ==="
echo ""
echo "Configured hooks:"
echo "  - PreCompact: Saves session before context compaction"
echo "  - SessionEnd: Saves session when closing"
echo ""
echo "Installed commands:"
echo "  /branch <name>  - Fork session to new branch/worktree"
echo ""
echo "Sessions will be saved to: \$PROJECT/.claude/sessions/"
echo ""
echo "Useful scripts:"
echo "  $PLUGIN_DIR/scripts/export-session.sh --list"
echo "  $PLUGIN_DIR/scripts/session-branch.sh --help"
echo ""
