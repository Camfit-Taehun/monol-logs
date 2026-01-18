---
description: 세션 분기 - git worktree + 새 터미널에서 분기된 세션 시작
use_when:
  - 사용자가 "브랜치", "분기", "fork" 등을 언급할 때
  - 새 기능 작업을 위해 세션을 나누고 싶을 때
  - 실험적인 작업을 별도로 진행하고 싶을 때
---

# /branch - 세션 분기

현재 Claude Code 세션을 분기하여 새 터미널에서 시작합니다.

## 사용법

```
/branch <branch-name> [options]
/branch --list
/branch --branches
/branch --worktrees          # 워크트리 목록 + 상태
/branch --prune              # stale 워크트리 정리
/branch --delete <name>      # 워크트리 삭제
```

## 인자: $ARGUMENTS

## 동작

### 1. 인자 파싱

사용자가 입력한 `$ARGUMENTS`를 파싱합니다:

- `--list` 또는 `-l`: 현재 세션 목록 표시
- `--branches` 또는 `-b`: 분기 기록 표시
- `--worktrees` 또는 `--wt`: 워크트리 목록 및 상태 표시
- `--prune`: stale(삭제된) 워크트리 기록 정리
- `--delete <name>` 또는 `-d <name>`: 워크트리 삭제 (브랜치명 또는 경로)
- `--force`: `--delete`와 함께 사용, 강제 삭제
- `--help` 또는 `-h`: 도움말 표시
- `<branch-name>`: 분기할 브랜치 이름
- `--same-dir`: git worktree 없이 같은 디렉토리에서 세션만 분기
- `--no-auto`: 터미널 자동 열기 안 함

### 2. --list인 경우

`~/.claude/projects/` 에서 현재 프로젝트의 세션 목록을 조회합니다.

프로젝트 경로를 Claude 세션 디렉토리로 변환:
- 현재 디렉토리의 절대 경로를 가져옴
- `/`를 `-`로 변환 (예: `/Users/kent/Work/project` → `Users-kent-Work-project`)
- `~/.claude/projects/{변환된경로}/` 에서 `.jsonl` 파일 목록 표시

### 3. --branches인 경우

`.claude/sessions/branches.md` 파일 내용을 표시합니다.

### 4. --worktrees인 경우

현재 레포의 모든 git worktree 목록과 상태를 표시합니다.

```bash
# lib/branch.sh의 list_worktrees 함수 호출
list_worktrees true  # verbose 모드
```

출력 예시:
```
=== Git Worktrees ===

✓ main
  경로: /Users/kent/Work/monol/monol-logs

✓ feature-auth
  경로: /Users/kent/Work/monol/monol-logs-feature-auth

⚠ old-experiment
  경로: /Users/kent/Work/monol/monol-logs-old-experiment (prunable - 삭제됨)
```

상태 표시:
- ✓: 정상
- ⚠: prunable (디렉토리 삭제됨, git 기록만 남음)
- ✗: missing (경로 접근 불가)

### 5. --prune인 경우

삭제된 워크트리의 git 기록을 정리합니다.

```bash
# lib/branch.sh의 prune_worktrees 함수 호출
prune_worktrees
```

출력:
```
=== Prunable Worktrees ===
  - /Users/kent/Work/monol/monol-logs-old-experiment

✓ 워크트리 정리 완료
```

### 6. --delete인 경우

특정 워크트리를 삭제합니다. 브랜치명 또는 경로로 지정 가능.

```bash
# lib/branch.sh의 remove_worktree 함수 호출
remove_worktree "feature-auth"        # 브랜치명
remove_worktree "../monol-logs-feature-auth"  # 경로

# --force와 함께 사용
remove_worktree "feature-auth" true   # 강제 삭제
```

### 7. 브랜치 생성인 경우

#### 4.1 현재 세션 ID 확인

**중요**: Claude Code 내부에서 실행 중이므로 현재 세션 ID를 직접 알 수 있습니다.
환경변수나 내부 상태에서 세션 ID를 확인하거나, 가장 최근 수정된 세션 파일을 사용합니다.

#### 4.2 Git Worktree 생성 (기본 모드)

`--same-dir`가 없으면:

```bash
git worktree add -b <branch-name> ../<project-name>-<branch-name>
```

이미 브랜치가 존재하면:
```bash
git worktree add ../<project-name>-<branch-name> <branch-name>
```

#### 4.3 분기 기록 저장

`.claude/sessions/branches.md`에 기록 추가:

```markdown
| <branch-name> | <session-id 앞 8자리> | <날짜 시간> | <worktree 경로> | <부모 브랜치> |
```

#### 4.4 새 터미널 열기 (`--no-auto`가 없으면)

macOS에서 osascript를 사용하여 새 터미널 탭을 엽니다:

**iTerm2가 설치된 경우:**
```bash
osascript -e '
tell application "iTerm"
  activate
  tell current window
    create tab with default profile
    tell current session
      write text "cd '\''<worktree-path>'\'' && claude --resume <session-id> --fork-session"
    end tell
  end tell
end tell
'
```

**Terminal.app (fallback):**
```bash
osascript -e '
tell application "Terminal"
  activate
  tell application "System Events" to keystroke "t" using command down
  delay 0.5
  do script "cd '\''<worktree-path>'\'' && claude --resume <session-id> --fork-session" in front window
end tell
'
```

#### 4.5 결과 출력

```
=== Branch created ===
Branch: <branch-name>
Directory: <worktree-path>
Session: <session-id 앞 8자리>...

분기된 세션이 새 터미널 탭에서 시작됩니다.
```

`--no-auto`인 경우:
```
=== Branch created ===
Directory: <worktree-path>

분기된 세션을 시작하려면:
  cd <worktree-path>
  claude --resume <session-id> --fork-session
```

## 예시

```
/branch feature-login
→ git worktree 생성 + 새 터미널에서 분기된 세션 시작

/branch experiment --same-dir
→ 같은 디렉토리에서 세션만 분기

/branch hotfix --no-auto
→ worktree 생성, 터미널은 수동으로 열기

/branch --list
→ 현재 프로젝트의 세션 목록

/branch --branches
→ 분기 기록 보기

/branch --worktrees
→ 모든 워크트리 목록 + 상태 (prunable 등)

/branch --prune
→ 삭제된 워크트리 기록 정리

/branch --delete feature-old
→ feature-old 브랜치의 워크트리 삭제

/branch --delete feature-old --force
→ 변경사항이 있어도 강제 삭제
```

## 주의사항

- git 저장소에서만 worktree 모드 사용 가능
- `--same-dir` 옵션은 git 저장소가 아니어도 사용 가능
- 세션 분기는 `claude --resume <id> --fork-session` 옵션 사용
