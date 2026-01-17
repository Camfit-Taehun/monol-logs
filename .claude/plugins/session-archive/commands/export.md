---
description: 세션 내보내기 - 프로젝트 내 .claude/sessions/로 백업
use_when:
  - 사용자가 "내보내기", "export", "백업", "저장" 등을 언급할 때
  - 세션을 프로젝트에 보관하고 싶을 때
  - 세션을 git에 포함시키고 싶을 때
---

# /export - 세션 내보내기

현재 또는 지정된 Claude Code 세션을 프로젝트 내 `.claude/sessions/`로 내보냅니다.

## 사용법

```
/export                      # 현재(최근) 세션 내보내기
/export <session-id>         # 특정 세션 내보내기
/export <session-id> <topic> # 토픽 지정하여 내보내기
/export --list               # 내보내기 가능한 세션 목록
/export --list-archived      # 이미 내보낸 세션 목록
```

## 인자: $ARGUMENTS

## 동작

### 1. 인자 파싱

- `--list` 또는 `-l`: 내보내기 가능한 세션 목록 표시
- `--list-archived`: 이미 아카이브된 세션 목록 표시
- `--help` 또는 `-h`: 도움말 표시
- `<session-id>`: 내보낼 세션 ID (생략 시 최근 세션)
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

### 3. --list-archived인 경우

`.claude/sessions/` 디렉토리의 아카이브된 세션 목록 표시:
- 파일명
- 크기
- 날짜

### 4. 세션 내보내기인 경우

#### 4.1 세션 파일 찾기

session-id가 주어지면:
- `~/.claude/projects/{project-hash}/` 에서 해당 ID로 시작하는 `.jsonl` 파일 찾기

session-id가 없으면:
- 가장 최근에 수정된 `.jsonl` 파일 사용

#### 4.2 출력 파일명 생성

형식: `{date}_{time}_{topic}_{session-id}.jsonl`
- date: YYYY-MM-DD
- time: HHMM
- topic: 사용자 지정 또는 첫 메시지에서 추출
- session-id: 앞 8자리

#### 4.3 파일 복사

```bash
mkdir -p .claude/sessions/
cp "{source}" ".claude/sessions/{filename}"
```

#### 4.4 결과 출력

```
Session exported:
  Source: ~/.claude/projects/.../f6702810-xxx.jsonl
  Target: .claude/sessions/2026-01-18_1430_topic_f6702810.jsonl
  Size: 125KB
  Messages: 42
```

### 5. 토픽 자동 추출 (토픽 미지정 시)

세션 파일의 첫 번째 사용자 메시지에서 토픽 추출:
1. 첫 번째 `"type":"human"` 메시지 찾기
2. 내용에서 첫 문장 또는 주요 키워드 추출
3. 파일명에 적합하게 변환 (공백→하이픈, 특수문자 제거)
4. 최대 30자로 제한

## 예시

```
/export
→ 최근 세션을 자동 토픽으로 내보내기

/export f6702810 "login-feature"
→ 특정 세션을 지정 토픽으로 내보내기

/export --list
→ 내보내기 가능한 세션 목록
```

## 주의사항

- 이미 내보낸 세션은 덮어쓰지 않음 (파일명 중복 시 경고)
- 대용량 세션은 내보내기에 시간이 걸릴 수 있음
