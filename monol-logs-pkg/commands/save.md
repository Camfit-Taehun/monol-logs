---
description: 세션 등록 (한글: 저장, 내보내기, 세션저장, 등록)
use_when:
  - 사용자가 "내보내기", "export", "저장" 등을 언급할 때
  - 세션을 프로젝트에 등록하고 싶을 때
  - 세션을 git에 포함시키고 싶을 때
---

# /save - 세션 등록

현재 또는 지정된 Claude Code 세션을 프로젝트에 등록합니다.
**jsonl 파일을 복사하지 않고 참조만 저장**하여 저장 공간을 절약합니다.

## 사용법

```
/save                      # 현재(최근) 세션 등록
/save <session-id>         # 특정 세션 등록
/save <session-id> <topic> # 토픽 지정하여 등록
/save --list               # 등록 가능한 세션 목록
/save --list-saved         # 이미 등록된 세션 목록
```

## 인자: $ARGUMENTS

## 동작

### 1. 인자 파싱

- `--list` 또는 `-l`: 등록 가능한 세션 목록 표시
- `--list-saved`: 이미 등록된 세션 목록 표시
- `--help` 또는 `-h`: 도움말 표시
- `<session-id>`: 등록할 세션 ID (생략 시 최근 세션)
- `<topic>`: 파일명에 포함할 토픽 (선택)

### 2. --list인 경우

Claude Code 세션 디렉토리에서 세션 목록을 조회합니다.

프로젝트 경로 → Claude 세션 디렉토리 변환:
- 현재 디렉토리 절대 경로 가져오기
- `/`를 `-`로 변환 (예: `/Users/kent/Work/project` → `Users-kent-Work-project`)
- `~/.claude/projects/{변환된경로}/` 에서 `.jsonl` 파일 목록

각 세션에 대해 표시:
- 세션 ID (앞 8자리)
- 파일 크기
- 수정 날짜
- 메시지 수 (줄 수 / 2)
- 등록 여부 (✓/-)

### 3. --list-saved인 경우

`.claude/sessions/` 디렉토리의 등록된 세션 목록 표시:
- 토픽
- 날짜
- 세션 ID
- 요약 존재 여부

### 4. 세션 등록인 경우

#### 4.1 세션 파일 찾기

session-id가 주어지면:
- `~/.claude/projects/{project-hash}/` 에서 해당 ID로 시작하는 `.jsonl` 파일 찾기

session-id가 없으면:
- 가장 최근에 수정된 `.jsonl` 파일 사용

#### 4.2 메타데이터 파일 생성

**jsonl을 복사하지 않고 참조 저장:**

```bash
mkdir -p .claude/sessions/
```

`{date}_{time}_{topic}_{session-id}.meta.json` 파일 생성:

```json
{
  "sessionId": "f6702810-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "source": "~/.claude/projects/-Users-kent-Work-project/f6702810-xxxx.jsonl",
  "topic": "login-feature",
  "createdAt": "2026-01-18T14:30:00Z",
  "messageCount": 42,
  "size": 125000
}
```

#### 4.3 토픽 자동 추출 (토픽 미지정 시)

세션 파일의 첫 번째 사용자 메시지에서 토픽 추출:
1. 첫 번째 `"type":"human"` 메시지 찾기
2. 내용에서 첫 문장 또는 주요 키워드 추출
3. 파일명에 적합하게 변환 (공백→하이픈, 특수문자 제거)
4. 최대 30자로 제한

#### 4.4 결과 출력

```
Session saved:
  Session ID: f6702810
  Topic: login-feature
  Messages: 42

  Saved: .claude/sessions/2026-01-18_1430_login-feature_f6702810.meta.json

💡 팁:
  - /session view f6702810  → 읽기 좋은 형식으로 보기
  - /session resume f6702810 → 이 세션 이어하기
  - /summary f6702810       → AI 요약 생성
```

### 5. index.md 자동 업데이트

세션 등록 후 `.claude/sessions/index.md` 자동 갱신.

## 예시

```
/save
→ 최근 세션을 자동 토픽으로 등록

/save f6702810 "login-feature"
→ 특정 세션을 지정 토픽으로 등록

/save --list
→ 등록 가능한 세션 목록
```

## 파일 구조 (개선됨)

```
.claude/sessions/
├── index.md                                    # 세션 목록
├── roadmap.md                                  # TODO 통합
├── 2026-01-18_1430_login-feature_f6702810.meta.json    # 메타데이터 (참조)
├── 2026-01-18_1430_login-feature_f6702810.summary.md   # AI 요약
└── 2026-01-18_1430_login-feature_f6702810.roadmap.md   # 세션별 TODO
```

**jsonl 파일은 복사하지 않음** → 저장 공간 절약, 원본은 `~/.claude/projects/`에만 존재

## 주의사항

- 이미 등록된 세션은 덮어쓰지 않음 (중복 시 경고)
- 원본 세션 파일이 삭제되면 참조가 깨짐 (경고 표시)
