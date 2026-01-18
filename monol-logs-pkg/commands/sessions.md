---
description: 세션 목록 조회 및 인덱스 관리 (한글: 세션, 세션목록, 세션보기)
use_when:
  - 사용자가 "세션", "목록", "아카이브" 등을 언급할 때
  - 이전 세션을 찾고 싶을 때
  - 세션 인덱스를 갱신하고 싶을 때
---

# /sessions - 세션 목록 및 인덱스

아카이브된 세션 목록을 조회하고 인덱스를 관리합니다.

## 사용법

```
/sessions                # 아카이브된 세션 목록
/sessions --index        # index.md 보기
/sessions --update       # index.md 갱신
/sessions --available    # 내보내기 가능한 세션 (아직 아카이브 안 된)
```

## 인자: $ARGUMENTS

## 동작

### 1. 인자 파싱

- (없음): 아카이브된 세션 목록 표시
- `--index` 또는 `-i`: index.md 내용 표시
- `--update` 또는 `-u`: index.md 갱신
- `--available` 또는 `-a`: 아카이브 가능한 세션 목록
- `--help` 또는 `-h`: 도움말 표시

### 2. 세션 목록 (기본)

`.claude/sessions/*.jsonl` 파일들을 조회하여 표시:

```
Archived Sessions (5)

| Date       | Topic         | Messages | Size  | Summary |
|------------|---------------|----------|-------|---------|
| 2026-01-18 | login-feature | 42       | 125KB | ✓       |
| 2026-01-17 | api-refactor  | 78       | 230KB | ✓       |
| 2026-01-16 | bug-fix       | 15       | 45KB  | -       |
...
```

각 세션에 대해:
- 날짜: 파일명에서 추출
- 토픽: 파일명에서 추출
- 메시지 수: 줄 수 / 2
- 크기: 파일 크기
- Summary: `.summary.md` 존재 여부

### 3. --index인 경우

`.claude/sessions/index.md` 파일 내용 표시.

파일이 없으면:
```
No index found. Generate with: /sessions --update
```

### 4. --update인 경우

index.md 파일을 갱신합니다.

#### 4.1 세션 정보 수집

각 `.jsonl` 파일에서:
- 파일명 파싱 (날짜, 시간, 토픽, 세션ID)
- 파일 크기
- 메시지 수
- 관련 파일 존재 여부 (`.summary.md`, `.roadmap.md`)

#### 4.2 index.md 생성

```markdown
# Session Index

Last updated: {timestamp}
Total sessions: {count}

## Sessions

| Date | Time | Topic | ID | Messages | Size | Summary | Roadmap |
|------|------|-------|-----|----------|------|---------|---------|
| 2026-01-18 | 14:30 | login-feature | f6702810 | 42 | 125KB | [View](./xxx.summary.md) | [View](./xxx.roadmap.md) |
...

## Statistics

- Total sessions: 15
- Total messages: 520
- Total size: 2.3MB
- With summaries: 12
- With roadmaps: 10
```

### 5. --available인 경우

아직 아카이브되지 않은 세션 목록:

```
Available Sessions (not archived)

| Session ID | Last Modified | Size   |
|------------|---------------|--------|
| f6702810   | 2 hours ago   | 125KB  |
| a1b2c3d4   | 1 day ago     | 230KB  |
...

Export with: /export <session-id>
```

Claude 세션 디렉토리 (`~/.claude/projects/{project-hash}/`)와 아카이브 디렉토리 (`.claude/sessions/`)를 비교하여 아직 내보내지 않은 세션 표시.

### 6. 결과 출력

목록 표시 후:
```
Tip: Use /export to archive sessions, /summary to generate summaries
```

## 예시

```
/sessions
→ 아카이브된 세션 목록

/sessions --index
→ index.md 보기

/sessions --update
→ index.md 갱신

/sessions --available
→ 아카이브 가능한 세션 보기
```

## 주의사항

- index.md는 세션 내보내기 시 자동 업데이트됨 (훅 설정 시)
- 수동으로 index.md를 편집해도 --update 시 덮어씀
