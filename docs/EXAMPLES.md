# Session Archive Examples

모든 스킬 사용 예제

## /sessions - 세션 목록

```bash
# 아카이브된 세션 목록
/sessions

# index.md 보기
/sessions --index
/sessions -i

# index.md 갱신
/sessions --update
/sessions -u

# 아카이브 가능한 세션 보기 (아직 내보내지 않은)
/sessions --available
/sessions -a
```

**출력 예시:**
```
Archived Sessions (5)

| Date       | Topic         | Messages | Size  | Summary |
|------------|---------------|----------|-------|---------|
| 2026-01-18 | login-feature | 42       | 125KB | ✓       |
| 2026-01-17 | api-refactor  | 78       | 230KB | ✓       |
| 2026-01-16 | bug-fix       | 15       | 45KB  | -       |
```

---

## /export - 세션 내보내기

```bash
# 최근 세션 내보내기 (토픽 자동 추출)
/export

# 특정 세션 내보내기
/export f6702810

# 토픽 지정하여 내보내기
/export f6702810 "login-feature"

# 내보내기 가능한 세션 목록
/export --list
/export -l

# 이미 내보낸 세션 목록
/export --list-archived
```

**출력 예시:**
```
Session exported:
  Source: ~/.claude/projects/.../f6702810-xxx.jsonl
  Target: .claude/sessions/2026-01-18_1430_login-feature_f6702810.jsonl
  Size: 125KB
  Messages: 42
```

---

## /roadmap - TODO/로드맵 추출

```bash
# 최근 세션에서 TODO 추출
/roadmap

# 현재 로드맵 보기
/roadmap --show
/roadmap -s

# 모든 세션에서 TODO 통합 추출
/roadmap --all
/roadmap -a

# 특정 세션에서 TODO 추출
/roadmap .claude/sessions/2026-01-18_1430_f6702810.jsonl
```

**출력 예시:**
```
Roadmap extracted:
  Session: 2026-01-18_1430_f6702810.jsonl
  TODOs found: 5

  - [ ] 로그인 기능 구현
  - [ ] 테스트 코드 작성
  - [ ] API 문서 업데이트

Updated: .claude/sessions/roadmap.md
```

**생성되는 roadmap.md:**
```markdown
# Project Roadmap

Last updated: 2026-01-18 15:00

## Active TODOs

### From session 2026-01-18 (f6702810)
- [ ] 로그인 기능 구현
- [ ] 테스트 코드 작성

## Completed
- [x] 환경 설정 완료
```

---

## /summary - AI 요약 생성

```bash
# 최근 세션 AI 요약 생성
/summary

# 생성된 요약 보기
/summary --show
/summary -s

# API 없이 규칙 기반 요약
/summary --rule-based
/summary -r

# 특정 세션 요약
/summary .claude/sessions/2026-01-18_1430_f6702810.jsonl
```

**출력 예시:**
```
Summary generated:
  Session: 2026-01-18_1430_f6702810.jsonl
  Method: AI (claude-sonnet-4-20250514)

  ## 주요 작업
  - 로그인 기능 구현
  - 테스트 코드 작성

  Saved: .claude/sessions/2026-01-18_1430_f6702810.summary.md
```

**생성되는 summary.md:**
```markdown
# Session Summary

Session: f6702810
Date: 2026-01-18
Generated: 2026-01-18 15:30

## 주요 작업
- 사용자 인증 시스템 구현
- JWT 토큰 기반 로그인 기능 추가

## 결정사항
- 세션 만료 시간 24시간으로 설정
- 리프레시 토큰 사용하지 않기로 결정

## 변경된 파일
- `src/auth/login.ts` - 로그인 핸들러 추가
- `src/middleware/auth.ts` - 인증 미들웨어 구현

## 다음 할 일
- [ ] 회원가입 기능 구현
- [ ] 비밀번호 재설정 기능
```

---

## /branch - 세션 분기

```bash
# git worktree + 새 터미널에서 분기된 세션 시작
/branch feature-login

# 같은 디렉토리에서 세션만 분기
/branch experiment --same-dir

# worktree 생성, 터미널은 수동으로 열기
/branch hotfix --no-auto

# 현재 프로젝트의 세션 목록
/branch --list
/branch -l

# 분기 기록 보기
/branch --branches
/branch -b
```

**출력 예시 (기본):**
```
Current session: d0e2a576...
Creating git worktree...
Worktree created: /Users/kent/Work/project-feature-login

=== Branch created ===
Directory: /Users/kent/Work/project-feature-login
Session forked in new terminal tab
```

**출력 예시 (--no-auto):**
```
=== Branch created ===
Directory: /Users/kent/Work/project-feature-login

To start the branched session, run:
  cd /Users/kent/Work/project-feature-login
  claude --resume d0e2a576-xxxx --fork-session
```

**분기 기록 (branches.md):**
```markdown
# Session Branches

| Branch        | Session ID | Date             | Path                    | Parent |
|---------------|------------|------------------|-------------------------|--------|
| feature-login | d0e2a576   | 2026-01-18 14:30 | ../project-feature-login| main   |
| hotfix        | a1b2c3d4   | 2026-01-18 16:00 | ../project-hotfix       | main   |
```

---

## 스크립트 직접 실행

스킬 대신 스크립트 직접 실행도 가능:

```bash
# 세션 내보내기
./scripts/export-session.sh
./scripts/export-session.sh f6702810 "topic"
./scripts/export-session.sh --list

# 로드맵 추출
./scripts/extract-roadmap.sh
./scripts/extract-roadmap.sh --all
./scripts/extract-roadmap.sh --show

# AI 요약 생성
./scripts/generate-summary.sh
./scripts/generate-summary.sh --rule-based

# 인덱스 업데이트
./scripts/update-index.sh
./scripts/update-index.sh --show

# 세션 브랜치
./scripts/session-branch.sh feature-b
./scripts/session-branch.sh exp --same-dir
./scripts/session-branch.sh --list
./scripts/session-branch.sh --branches
```

---

## 자동 동작 (훅)

SessionEnd 훅이 설정되어 있으면 세션 종료 시 자동으로:

1. 세션 파일 저장 → `.claude/sessions/{date}_{time}_{id}.jsonl`
2. TODO/로드맵 추출 → `roadmap.md`
3. AI 요약 생성 → `{session}.summary.md` (백그라운드)
4. 인덱스 업데이트 → `index.md`

---

## 생성되는 파일 구조

```
.claude/sessions/
├── index.md                              # 세션 목록 (자동 업데이트)
├── roadmap.md                            # 통합 TODO 목록
├── branches.md                           # 분기 기록
├── 2026-01-18_1430_login_f6702810.jsonl  # 세션 원본
├── 2026-01-18_1430_login_f6702810.summary.md   # AI 요약
└── 2026-01-18_1430_login_f6702810.roadmap.md   # 세션별 TODO
```
