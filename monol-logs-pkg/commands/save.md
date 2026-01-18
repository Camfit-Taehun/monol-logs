---
description: 세션 등록 (한글: 저장, 내보내기, 세션저장, 등록)
argument-hint: "[session-id] [topic]"
allowed-tools: [Read, Write, Bash, Glob, Grep]
use_when:
  - 사용자가 "내보내기", "export", "저장" 등을 언급할 때
  - 세션을 프로젝트에 등록하고 싶을 때
  - 세션을 git에 포함시키고 싶을 때
---

# /save - 세션 등록

현재 또는 지정된 Claude Code 세션을 프로젝트에 등록합니다.

**저장되는 것:**
- `meta.json` - 메타데이터 (원본 경로 참조)
- `summary.md` - AI 요약 **(자동 생성)**
- `roadmap.md` - TODO 추출 **(자동 생성)**

**저장 안 되는 것:**
- `.jsonl` 원본 (복사 안 함, 참조만)

## 사용법

```
/save                      # 현재(최근) 세션 등록
/save <session-id>         # 특정 세션 등록
/save <session-id> <topic> # 토픽 지정하여 등록
/save --list               # 등록 가능한 세션 목록
/save --list-saved         # 이미 등록된 세션 목록
/save --no-summary         # 요약 생성 건너뛰기
```

## 인자: $ARGUMENTS

## 동작

### 1. 인자 파싱

- `--list` 또는 `-l`: 등록 가능한 세션 목록 표시
- `--list-saved`: 이미 등록된 세션 목록 표시
- `--no-summary`: 요약/로드맵 자동 생성 건너뛰기
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

#### 4.2 토픽 자동 추출 (토픽 미지정 시)

세션 파일의 첫 번째 사용자 메시지에서 토픽 추출:
1. 첫 번째 `"type":"human"` 메시지 찾기
2. 내용에서 첫 문장 또는 주요 키워드 추출
3. 파일명에 적합하게 변환 (공백→하이픈, 특수문자 제거)
4. 최대 30자로 제한

#### 4.3 파일 생성 (3개)

```bash
mkdir -p .claude/sessions/
```

**파일 1: `{base}.meta.json`** - 메타데이터

```json
{
  "sessionId": "f6702810-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "source": "~/.claude/projects/-Users-kent-Work-project/f6702810-xxxx.jsonl",
  "topic": "login-feature",
  "createdAt": "2026-01-18T14:30:00Z",
  "savedAt": "2026-01-18T18:00:00Z",
  "savedBy": "kent",
  "messageCount": 42,
  "size": 125000
}
```

**파일 2: `{base}.summary.md`** - AI 요약 (자동 생성)

세션 내용을 분석하여 요약 생성:

```markdown
# Session Summary

Session: login-feature (f6702810)
Date: 2026-01-18
Author: kent

## 주요 작업

- 로그인 API 엔드포인트 구현
- JWT 토큰 발급 로직 추가
- 테스트 코드 작성 (성공 케이스)

## 결정사항

- bcrypt 대신 argon2 사용하기로 결정
- 토큰 만료 시간 24시간으로 설정

## 변경된 파일

- `src/auth/login.ts` - 로그인 컨트롤러
- `src/auth/jwt.ts` - JWT 유틸리티
- `src/auth/login.test.ts` - 테스트 코드

## 다음 할 일

- [ ] 실패 케이스 테스트 추가
- [ ] 비밀번호 3회 실패 잠금 구현
- [ ] 로그아웃 기능 추가
```

**파일 3: `{base}.roadmap.md`** - TODO 추출 (자동 생성)

세션에서 TODO 패턴 추출:

```markdown
# Session Roadmap

Session: login-feature (f6702810)
Date: 2026-01-18

## TODO Items

- [ ] 실패 케이스 테스트 추가
- [ ] 비밀번호 3회 실패 잠금 구현
- [ ] 로그아웃 기능 추가
- [ ] refresh token 구현

## Context

마지막 작업: 로그인 성공 테스트까지 완료
다음 예정: 실패 케이스 테스트
```

#### 4.4 index.md 업데이트

`.claude/sessions/index.md` 자동 갱신.

#### 4.5 roadmap.md 통합

전체 `roadmap.md`에 새 TODO 병합.

### 5. 결과 출력

```
Session saved:
  Session ID: f6702810
  Topic: login-feature
  Messages: 42
  Author: kent

📁 Generated files:
  ✓ .claude/sessions/2026-01-18_1430_login-feature_f6702810.meta.json
  ✓ .claude/sessions/2026-01-18_1430_login-feature_f6702810.summary.md
  ✓ .claude/sessions/2026-01-18_1430_login-feature_f6702810.roadmap.md

📋 Summary:
  - 로그인 API 구현
  - JWT 토큰 발급
  - 테스트 코드 작성 (일부)

📝 TODOs extracted: 4

💡 팁:
  - /session view f6702810  → 전체 내용 보기
  - /session resume f6702810 → 이어하기
  - git add .claude/sessions/ → 팀과 공유
```

## 팀 공유 워크플로우

```bash
# 1. 세션 저장
/save my-feature

# 2. git에 커밋 (요약/메타만, jsonl 제외)
git add .claude/sessions/
git commit -m "docs: my-feature 작업 세션 기록"
git push

# 3. 팀원이 pull 후 확인
/sessions                    # 목록 보기
/session load <id>           # 요약 로드 (jsonl 없어도 가능)
```

## 예시

```
/save
→ 최근 세션을 자동 토픽으로 등록 + 요약/TODO 자동 생성

/save f6702810 "login-feature"
→ 특정 세션을 지정 토픽으로 등록

/save --no-summary
→ 요약 없이 메타데이터만 저장 (빠름)

/save --list
→ 등록 가능한 세션 목록
```

## 주의사항

- 이미 등록된 세션은 덮어쓰지 않음 (중복 시 경고)
- 원본 세션 파일이 삭제되면 view/resume 불가 (summary/roadmap은 유지)
- AI 요약에는 시간이 걸릴 수 있음 (--no-summary로 건너뛰기 가능)
