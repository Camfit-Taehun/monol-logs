---
description: 세션 목록 조회 및 인덱스 관리 (한글: 세션, 세션목록, 세션보기)
use_when:
  - 사용자가 "세션", "목록", "아카이브" 등을 언급할 때
  - 이전 세션을 찾고 싶을 때
  - 세션 인덱스를 갱신하고 싶을 때
---

# /sessions - 세션 목록 및 인덱스

등록된 세션 목록을 조회하고 인덱스를 관리합니다.

## 사용법

```
/sessions                # 등록된 세션 목록
/sessions --available    # 등록 가능한 세션 (아직 등록 안 된)
/sessions --index        # index.md 보기
/sessions --update       # index.md 갱신
```

## 인자: $ARGUMENTS

## 동작

### 1. 인자 파싱

- (없음): 등록된 세션 목록 표시
- `--available` 또는 `-a`: 등록 가능한 세션 목록
- `--index` 또는 `-i`: index.md 내용 표시
- `--update` 또는 `-u`: index.md 갱신
- `--help` 또는 `-h`: 도움말 표시

### 2. 세션 목록 (기본)

`.claude/sessions/*.meta.json` 파일들을 조회하여 표시:

```
📚 등록된 세션 (5)

| # | Date       | Topic           | ID       | Msgs | Summary | Source |
|---|------------|-----------------|----------|------|---------|--------|
| 1 | 2026-01-18 | login-feature   | f6702810 | 42   | ✓       | ✓      |
| 2 | 2026-01-17 | api-refactor    | a1b2c3d4 | 78   | ✓       | ✓      |
| 3 | 2026-01-16 | bug-fix         | e5f6g7h8 | 15   | -       | ⚠️      |
...

💡 팁:
  /session view <id>   → 세션 내용 보기
  /session resume <id> → 세션 이어하기
  /session load <id>   → 요약 로드
```

각 세션에 대해:
- 날짜: meta.json의 `createdAt`에서 추출
- 토픽: meta.json의 `topic`
- ID: 세션 ID 앞 8자리
- Msgs: 메시지 수
- Summary: `.summary.md` 존재 여부
- Source: 원본 jsonl 존재 여부 (⚠️ = 원본 없음)

### 3. --available인 경우

등록되지 않은 세션 목록:

```
📋 등록 가능한 세션 (3)

| # | Session ID | Last Modified    | Size   | Msgs |
|---|------------|------------------|--------|------|
| 1 | f6702810   | 2 hours ago      | 125KB  | 42   |
| 2 | a1b2c3d4   | 1 day ago        | 230KB  | 78   |
| 3 | e5f6g7h8   | 3 days ago       | 45KB   | 15   |

💡 등록하려면: /save <session-id> [topic]
```

Claude 세션 디렉토리 (`~/.claude/projects/{project-hash}/`)와 등록된 세션 (`.claude/sessions/*.meta.json`)을 비교하여 아직 등록 안 된 세션 표시.

### 4. --index인 경우

`.claude/sessions/index.md` 파일 내용 표시.

파일이 없으면:
```
No index found. Generate with: /sessions --update
```

### 5. --update인 경우

index.md 파일을 갱신합니다.

#### 5.1 세션 정보 수집

각 `.meta.json` 파일에서:
- 세션 ID, 토픽, 날짜
- 메시지 수, 파일 크기
- 관련 파일 존재 여부 (`.summary.md`, `.roadmap.md`)
- 원본 존재 여부

#### 5.2 index.md 생성

```markdown
# Session Index

Last updated: 2026-01-18T15:00:00Z
Total sessions: 5

## Sessions

| Date | Topic | ID | Messages | Summary | Roadmap | Source |
|------|-------|-----|----------|---------|---------|--------|
| 2026-01-18 | login-feature | f6702810 | 42 | [View](./xxx.summary.md) | [View](./xxx.roadmap.md) | ✓ |
| 2026-01-17 | api-refactor | a1b2c3d4 | 78 | [View](./xxx.summary.md) | - | ✓ |
...

## Quick Commands

- View session: `/session view <id>`
- Resume session: `/session resume <id>`
- Load context: `/session load <id>`

## Statistics

- Total sessions: 5
- Total messages: 195
- With summaries: 4
- With roadmaps: 3
- Missing source: 1
```

### 6. 결과 출력

목록 표시 후:
```
💡 팁: /session view <id>로 세션 내용을 보거나, /session resume <id>로 이어하기
```

## 예시

```
/sessions
→ 등록된 세션 목록

/sessions --available
→ 등록 가능한 세션 보기

/sessions --index
→ index.md 보기

/sessions --update
→ index.md 갱신
```

## 관련 커맨드

- `/save` - 세션 등록
- `/session view` - 세션 내용 보기
- `/session resume` - 세션 이어하기
- `/summary` - 세션 요약 생성
