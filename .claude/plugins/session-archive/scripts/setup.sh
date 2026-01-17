#!/bin/bash
# Session Archive - Setup Script
# Claude Code settings.json에 hooks 설정 추가

set -e

SETTINGS_FILE="$HOME/.claude/settings.json"
PLUGIN_DIR="$HOME/.claude/plugins/session-archive"

echo "=== Session Archive Plugin Setup ==="

# 1. settings.json 존재 확인
if [ ! -f "$SETTINGS_FILE" ]; then
  echo "Creating $SETTINGS_FILE..."
  echo '{}' > "$SETTINGS_FILE"
fi

# 2. jq 설치 확인
if ! command -v jq &> /dev/null; then
  echo "Error: jq is required. Install with: brew install jq"
  exit 1
fi

# 3. 현재 설정 백업
cp "$SETTINGS_FILE" "$SETTINGS_FILE.backup.$(date +%Y%m%d_%H%M%S)"

# 4. hooks 설정 추가
HOOK_CONFIG=$(cat <<EOF
{
  "hooks": {
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

# 5. 기존 설정과 병합
jq -s '.[0] * .[1]' "$SETTINGS_FILE" <(echo "$HOOK_CONFIG") > "$SETTINGS_FILE.tmp"
mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"

# 6. hook 스크립트 실행 권한
chmod +x "$PLUGIN_DIR/hooks/"*.sh

echo ""
echo "Setup complete!"
echo "  - Settings: $SETTINGS_FILE"
echo "  - Plugin: $PLUGIN_DIR"
echo ""
echo "Sessions will be saved to: \$PROJECT/.claude/sessions/"
