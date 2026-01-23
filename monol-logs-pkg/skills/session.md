---
description: 세션 보기/이어하기/로드
use_when:
  - 사용자가 "세션 보기", "세션 열기", "이어하기" 등을 언급할 때
  - 이전 세션 내용을 확인하고 싶을 때
  - 세션을 이어서 작업하고 싶을 때
  - 세션 컨텍스트를 현재 세션에 로드하고 싶을 때
---

# /session - 세션 보기 및 이어하기

등록된 세션을 사람이 읽기 쉬운 형식으로 보거나, 이어서 작업합니다.

## 사용법

```
/session view <id>      # 세션 내용을 읽기 좋게 보기
/session resume <id>    # 세션 이어하기 (claude --resume 실행)
/session load <id>      # 세션 요약을 현재 컨텍스트에 로드
```

## 인자: $ARGUMENTS

## 동작

### 1. 인자 파싱

첫 번째 인자가 서브커맨드:
- `view`: 세션 내용 보기
- `resume`: 세션 이어하기
- `load`: 세션 요약을 현재 세션에 로드
- `--help` 또는 `-h`: 도움말 표시

두 번째 인자가 session-id (앞 8자리도 가능)

### 2. 세션 찾기

session-id로 세션 찾기:

```bash
backup_dir=".claude/sessions"
meta_file=$(ls "$backup_dir"/*_"$session_id"*.meta.json 2>/dev/null | head -1)
```

1. `.claude/sessions/`에서 `*_{session-id}*.meta.json` 파일 찾기
2. meta.json에서 정보 추출:
   - `sessionId`: 전체 세션 ID
   - `source`: 원본 jsonl 경로
   - `topic`: 토픽명
   - `savedBy`: 저장자
   - `createdAt`, `savedAt`: 날짜

### 3. view - 세션 내용 보기

#### 3.1 conversation.md가 있으면

`.conversation.md` 파일을 직접 출력:

```bash
conversation_file="${meta_file%.meta.json}.conversation.md"
if [[ -f "$conversation_file" ]]; then
  cat "$conversation_file"
fi
```

#### 3.2 conversation.md가 없고 원본 jsonl이 있으면

jsonl 파일을 파싱하여 읽기 좋은 형식으로 변환:

```markdown
# Session: {topic}
Date: {date}
Messages: {count}

---

## 👤 User ({time})
{user_message}

## 🤖 Assistant ({time})
{assistant_message}

**Tool: {tool_name}** `{tool_input_summary}`

...
```

#### 3.3 jsonl 파싱 규칙

각 줄의 JSON에서:
- `"type": "human"` → User 메시지
- `"type": "assistant"` → Assistant 메시지
- `"type": "tool_use"` → Tool 사용 (간략히 표시)
- `"type": "tool_result"` → Tool 결과 (생략)

#### 3.4 출력 옵션

긴 세션은 페이지네이션:
- 기본: 최근 20개 메시지
- `--all`: 전체 보기
- `--tail <n>`: 마지막 n개 메시지

### 4. resume - 세션 이어하기

원본 세션 파일이 있는지 확인 후 안내:

```bash
source_path=$(jq -r '.source' "$meta_file")
full_session_id=$(jq -r '.sessionId' "$meta_file")

# source 경로 확장 (~ 처리)
expanded_source="${source_path/#\~/$HOME}"

if [[ -f "$expanded_source" ]]; then
  echo "🔄 세션 이어하기"
  echo ""
  echo "Session: $topic ($session_id)"
  echo "Date: $created_date"
  echo ""
  echo "다음 명령어로 세션을 이어하세요:"
  echo "  claude --resume $full_session_id"
else
  echo "⚠️ 원본 세션 파일이 없습니다."
  echo "   경로: $source_path"
  echo ""
  echo "   Claude가 세션을 정리했을 수 있습니다."
  echo "   요약이 있다면 /session load $session_id 로 컨텍스트를 로드하세요."
fi
```

### 5. load - 세션 요약 로드

세션 요약을 읽어서 현재 세션의 컨텍스트로 제공:

#### 5.1 요약 파일 확인

```bash
summary_file="${meta_file%.meta.json}.summary.md"
roadmap_file="${meta_file%.meta.json}.roadmap.md"
```

#### 5.2 컨텍스트 출력

요약 파일이 있으면:

```markdown
📋 이전 세션 컨텍스트 로드

**세션**: {topic} ({date})
**저장자**: {savedBy}

---

{summary.md 내용}

---

**남은 TODO** (roadmap.md에서):
- [ ] {todo1}
- [ ] {todo2}

---
이어서 작업하려면 위 컨텍스트를 참고하세요.
```

요약 파일이 없으면:

```
⚠️ 요약 파일이 없습니다.

/summary {session_id} 로 요약을 생성하거나,
/session view {session_id} 로 전체 내용을 확인하세요.
```

### 6. 결과 출력

각 서브커맨드 완료 후 관련 팁 표시:

```
💡 팁:
  - /session view <id> - 세션 내용 보기
  - /session resume <id> - 세션 이어하기
  - /session load <id> - 요약 로드
```

## 예시

```
/session view f6702810
→ 세션 내용을 읽기 좋게 표시

/session view f6702810 --all
→ 전체 대화 내용 표시

/session resume f6702810
→ 해당 세션 이어하기 안내

/session load f6702810
→ 세션 요약을 현재 컨텍스트에 로드
```

## 관련 커맨드

- `/save` - 세션 등록
- `/sessions` - 등록된 세션 목록
- `/summary` - 세션 요약 생성
