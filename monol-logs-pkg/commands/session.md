---
description: 세션 보기/이어하기 (한글: 세션보기, 세션열기, 이어하기)
argument-hint: "<view|resume|load> <session-id>"
allowed-tools: [Read, Bash, Glob, Grep]
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

두 번째 인자가 session-id (앞 8자리도 가능)

### 2. 세션 찾기

session-id로 세션 찾기:

1. `.claude/sessions/`에서 `*_{session-id}.meta.json` 파일 찾기
2. meta.json에서 `source` 경로 읽기
3. 원본 jsonl 파일 존재 확인

원본이 없으면:
```
⚠️ 원본 세션 파일이 없습니다.
   경로: ~/.claude/projects/.../xxx.jsonl

   Claude가 세션을 정리했을 수 있습니다.
   요약이 있다면 /session load <id>로 요약을 로드하세요.
```

### 3. view - 세션 내용 보기

jsonl 파일을 파싱하여 읽기 좋은 형식으로 출력:

```markdown
# Session: login-feature
Date: 2026-01-18 14:30
Messages: 42

---

## 👤 User (14:30)
로그인 기능을 만들어줘.

## 🤖 Assistant (14:31)
로그인 기능을 구현하겠습니다.

먼저 필요한 파일들을 확인하겠습니다.

**Tool: Read** `src/auth/login.ts`

...

## 👤 User (14:35)
테스트도 추가해줘

## 🤖 Assistant (14:36)
테스트 코드를 추가하겠습니다.

...
```

#### 3.1 jsonl 파싱 규칙

각 줄의 JSON에서:
- `"type": "human"` → User 메시지
- `"type": "assistant"` → Assistant 메시지
- `"type": "tool_use"` → Tool 사용 (간략히 표시)
- `"type": "tool_result"` → Tool 결과 (생략 또는 축약)

시간은 `timestamp` 필드에서 추출.

#### 3.2 출력 옵션

긴 세션은 페이지네이션:
- 기본: 최근 20개 메시지
- `--all`: 전체 보기
- `--from <n>`: n번째 메시지부터

### 4. resume - 세션 이어하기

**새 터미널에서 `claude --resume` 실행:**

```bash
# macOS
osascript -e 'tell app "Terminal" to do script "cd {project-path} && claude --resume {session-id}"'

# 또는 현재 터미널 안내
echo "다음 명령어로 세션을 이어하세요:"
echo "claude --resume {session-id}"
```

#### 4.1 resume 출력

```
🔄 세션 이어하기

Session: login-feature (f6702810)
Date: 2026-01-18 14:30
Messages: 42

새 터미널에서 세션을 시작합니다...

또는 직접 실행:
  claude --resume f6702810-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

### 5. load - 세션 요약 로드

세션 요약을 읽어서 현재 세션의 컨텍스트로 제공:

#### 5.1 요약 파일 확인

1. `{session}.summary.md` 파일이 있으면 읽기
2. 없으면 jsonl에서 간략 요약 생성

#### 5.2 컨텍스트 출력

```markdown
📋 이전 세션 컨텍스트 로드

**세션**: login-feature (2026-01-18)
**주요 작업**:
- 로그인 API 구현 완료
- JWT 토큰 발급 로직 추가
- 테스트 코드 작성 중

**마지막 작업**:
src/auth/login.test.ts 파일에서 테스트 케이스 추가 중이었음

**남은 TODO**:
- [ ] 에러 케이스 테스트 추가
- [ ] 로그아웃 기능 구현

---
이어서 작업하려면 위 컨텍스트를 참고하세요.
```

## 예시

```
/session view f6702810
→ 세션 내용을 읽기 좋게 표시

/session resume f6702810
→ 해당 세션 이어하기 (claude --resume)

/session load f6702810
→ 세션 요약을 현재 컨텍스트에 로드
```

## 관련 커맨드

- `/save` - 세션 등록
- `/sessions` - 등록된 세션 목록
- `/summary` - 세션 요약 생성
