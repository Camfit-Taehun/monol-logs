---
description: AI 요약 생성 (한글: 요약, 세션요약, 정리, 요약해줘)
use_when:
  - 사용자가 "요약", "summary", "정리" 등을 언급할 때
  - 세션 내용을 빠르게 파악하고 싶을 때
  - 작업 기록을 문서화하고 싶을 때
---

# /summary - AI 요약 생성

세션의 AI 요약을 생성합니다.

## 사용법

```
/summary                  # 최근 세션 AI 요약
/summary --show           # 최근 요약 보기
/summary --rule-based     # API 없이 규칙 기반 요약
/summary <session-file>   # 특정 세션 요약
```

## 인자: $ARGUMENTS

## 동작

### 1. 인자 파싱

- `--show` 또는 `-s`: 최근 요약 파일 표시
- `--rule-based` 또는 `-r`: AI API 없이 규칙 기반 요약
- `--help` 또는 `-h`: 도움말 표시
- `<session-file>`: 특정 세션 파일 경로

### 2. --show인 경우

`.claude/sessions/`에서 가장 최근 `.summary.md` 파일 내용 표시.

파일이 없으면:
```
No summary found. Generate with: /summary
```

### 3. AI 요약 생성 (기본)

#### 3.1 대상 세션 결정

- 인자 없음: `.claude/sessions/`에서 가장 최근 `.jsonl`
- `<session-file>`: 지정된 파일

#### 3.2 세션 내용 추출

JSONL 파일에서 대화 내용 추출:
- `"type":"human"` → 사용자 메시지
- `"type":"assistant"` → Claude 응답
- 최대 50개 메시지 (config.yaml의 summary_max_messages)

#### 3.3 AI 요약 요청

Claude API를 사용하여 요약 생성:

```
다음 Claude Code 세션을 요약해주세요:

[세션 내용]

다음 형식으로 작성:
1. 주요 작업 (무엇을 했는지)
2. 결정사항 (어떤 결정을 내렸는지)
3. 생성/수정된 파일
4. 다음 할 일 (남은 작업)
```

#### 3.4 요약 파일 생성

`{session}.summary.md`:

```markdown
# Session Summary

Session: {session-id}
Date: {date}
Generated: {timestamp}

## 주요 작업

- 작업 1 설명
- 작업 2 설명

## 결정사항

- 결정 1
- 결정 2

## 변경된 파일

- `path/to/file1.ts` - 설명
- `path/to/file2.ts` - 설명

## 다음 할 일

- [ ] TODO 1
- [ ] TODO 2
```

### 4. 규칙 기반 요약 (--rule-based)

AI API 없이 패턴 매칭으로 요약:

1. **파일 변경 추출**: `Edit`, `Write` 도구 사용 내역
2. **TODO 추출**: TODO 패턴 매칭
3. **첫/마지막 메시지**: 세션 시작/끝 요약
4. **키워드 추출**: 자주 등장하는 기술 용어

### 5. 결과 출력

```
Summary generated:
  Session: 2026-01-18_1430_f6702810.jsonl
  Method: AI (claude-sonnet-4-20250514)

  ## 주요 작업
  - 로그인 기능 구현
  - 테스트 코드 작성

  Saved: .claude/sessions/2026-01-18_1430_f6702810.summary.md
```

## 예시

```
/summary
→ 최근 세션 AI 요약 생성

/summary --show
→ 생성된 요약 보기

/summary --rule-based
→ API 없이 규칙 기반 요약
```

## 주의사항

- AI 요약에는 ANTHROPIC_API_KEY 환경변수 필요
- 대용량 세션은 요약에 시간이 걸릴 수 있음
- --rule-based는 AI보다 품질이 낮을 수 있음
