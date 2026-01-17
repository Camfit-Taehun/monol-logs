# /roadmap - 로드맵/TODO 관리

세션에서 TODO/할 일을 추출하고 로드맵을 관리합니다.

## 사용법

```
/roadmap                # 최근 세션에서 TODO 추출
/roadmap --show         # 현재 roadmap.md 보기
/roadmap --all          # 모든 세션에서 TODO 추출
/roadmap <session-file> # 특정 세션에서 TODO 추출
```

## 인자: $ARGUMENTS

## 동작

### 1. 인자 파싱

- `--show` 또는 `-s`: roadmap.md 내용 표시
- `--all` 또는 `-a`: 모든 아카이브된 세션에서 TODO 추출
- `--help` 또는 `-h`: 도움말 표시
- `<session-file>`: 특정 세션 파일 경로

### 2. --show인 경우

`.claude/sessions/roadmap.md` 파일 내용을 읽어서 표시합니다.

파일이 없으면:
```
No roadmap found. Extract TODOs with: /roadmap
```

### 3. TODO 추출

#### 3.1 대상 세션 결정

- 인자 없음: `.claude/sessions/`에서 가장 최근 `.jsonl` 파일
- `--all`: `.claude/sessions/*.jsonl` 모든 파일
- `<session-file>`: 지정된 파일

#### 3.2 TODO 패턴 매칭

세션 파일에서 다음 패턴을 검색:
- `- [ ]` (체크박스)
- `TODO:`
- `FIXME:`
- `다음에`
- `나중에`
- `할 일`
- `해야 할`
- `구현 예정`

#### 3.3 세션별 로드맵 생성

`{session}.roadmap.md` 파일 생성:

```markdown
# Session Roadmap

Session: {session-id}
Date: {date}

## TODO Items

- [ ] 첫 번째 할 일
- [ ] 두 번째 할 일
...

## Context

추출된 TODO 항목들의 원본 컨텍스트
```

#### 3.4 통합 로드맵 업데이트

`roadmap.md` 파일에 병합:

```markdown
# Project Roadmap

Last updated: {timestamp}

## Active TODOs

### From session {date} ({session-id})
- [ ] 항목 1
- [ ] 항목 2

### From session {date} ({session-id})
- [ ] 항목 3
...

## Completed
- [x] 완료된 항목들...
```

### 4. 결과 출력

```
Roadmap extracted:
  Session: 2026-01-18_1430_f6702810.jsonl
  TODOs found: 5

  - [ ] 로그인 기능 구현
  - [ ] 테스트 코드 작성
  - [ ] API 문서 업데이트
  ...

Updated: .claude/sessions/roadmap.md
```

## 예시

```
/roadmap
→ 최근 세션에서 TODO 추출

/roadmap --show
→ 현재 로드맵 보기

/roadmap --all
→ 모든 세션에서 TODO 통합 추출
```

## 주의사항

- 중복 TODO는 자동으로 제거됨
- 완료된 항목 `[x]`는 Completed 섹션으로 이동
- 로드맵은 수동으로 편집 가능 (다음 추출 시 병합됨)
