#!/bin/bash
# monol-server 동기화 모듈
# 세션 이벤트를 서버로 전송

# 설정 로드
load_sync_config() {
  local config_file="$PLUGIN_DIR/config.yaml"

  if [ -f "$config_file" ]; then
    SYNC_ENABLED=$(grep "^sync_enabled:" "$config_file" | awk '{print $2}' | tr -d '"')
    SYNC_SERVER_URL=$(grep "^sync_server_url:" "$config_file" | awk '{print $2}' | tr -d '"')
    SYNC_TEAM=$(grep "^sync_team:" "$config_file" | awk '{print $2}' | tr -d '"')
    SYNC_TIMEOUT=$(grep "^sync_timeout:" "$config_file" | awk '{print $2}' | tr -d '"')
  fi

  # 환경변수 우선
  SYNC_ENABLED="${MONOL_SYNC_ENABLED:-${SYNC_ENABLED:-true}}"
  SYNC_SERVER_URL="${MONOL_SERVER_URL:-${SYNC_SERVER_URL:-http://localhost:3030}}"
  SYNC_TEAM="${MONOL_TEAM:-${SYNC_TEAM:-}}"
  SYNC_TIMEOUT="${SYNC_TIMEOUT:-5}"

  # 사용자 감지
  SYNC_USER="${MONOL_USER:-$(git config user.name 2>/dev/null || echo "$USER")}"
}

# 서버 연결 확인
check_server() {
  local health_url="${SYNC_SERVER_URL}/api/health"

  if curl -s --max-time 2 "$health_url" > /dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}

# 이벤트 전송
send_event() {
  local event_type="$1"
  local event_data="$2"

  # 동기화 비활성화 확인
  if [ "$SYNC_ENABLED" != "true" ]; then
    [ "$VERBOSE" = "true" ] && echo "[sync] Sync disabled, skipping"
    return 0
  fi

  # 서버 URL 확인
  if [ -z "$SYNC_SERVER_URL" ]; then
    [ "$VERBOSE" = "true" ] && echo "[sync] No server URL configured"
    return 0
  fi

  # JSON 페이로드 생성
  local payload=$(cat <<EOF
{
  "user": "$SYNC_USER",
  "team": "$SYNC_TEAM",
  "plugin": "monol-logs",
  "type": "$event_type",
  "data": $event_data
}
EOF
)

  # 전송 (백그라운드, 실패해도 무시)
  if [ "$VERBOSE" = "true" ]; then
    echo "[sync] Sending $event_type to $SYNC_SERVER_URL"
  fi

  local response
  response=$(curl -s --max-time "$SYNC_TIMEOUT" \
    -X POST \
    -H "Content-Type: application/json" \
    -d "$payload" \
    "${SYNC_SERVER_URL}/api/events" 2>/dev/null)

  local exit_code=$?

  if [ $exit_code -eq 0 ]; then
    if echo "$response" | grep -q '"success":true'; then
      [ "$VERBOSE" = "true" ] && echo "[sync] Event sent successfully"
      return 0
    else
      [ "$VERBOSE" = "true" ] && echo "[sync] Server returned error: $response"
      return 1
    fi
  else
    [ "$VERBOSE" = "true" ] && echo "[sync] Failed to connect to server (timeout or error)"
    return 1
  fi
}

# 세션 저장 이벤트 전송
sync_session_saved() {
  local session_id="$1"
  local topic="$2"
  local message_count="$3"
  local duration_ms="$4"
  local started_at="$5"
  local ended_at="$6"

  load_sync_config

  local event_data=$(cat <<EOF
{
  "sessionId": "$session_id",
  "topic": "$topic",
  "messageCount": ${message_count:-0},
  "durationMs": ${duration_ms:-0},
  "startedAt": "$started_at",
  "endedAt": "$ended_at"
}
EOF
)

  send_event "session_saved" "$event_data"
}

# 세션 재개 이벤트 전송
sync_session_resumed() {
  local session_id="$1"

  load_sync_config

  local event_data=$(cat <<EOF
{
  "sessionId": "$session_id"
}
EOF
)

  send_event "session_resumed" "$event_data"
}
