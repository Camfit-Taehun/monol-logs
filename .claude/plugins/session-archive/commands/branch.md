# /branch - 세션 분기

현재 Claude Code 세션을 분기하여 새 터미널에서 시작합니다.

## 사용법

```
/branch <branch-name> [options]
/branch --list
/branch --branches
```

## 인자: $ARGUMENTS

## 동작

### 1. 인자 파싱

사용자가 입력한 `$ARGUMENTS`를 파싱합니다:

- `--list` 또는 `-l`: 현재 세션 목록 표시
- `--branches` 또는 `-b`: 분기 기록 표시
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

### 4. 브랜치 생성인 경우

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
```

## 주의사항

- git 저장소에서만 worktree 모드 사용 가능
- `--same-dir` 옵션은 git 저장소가 아니어도 사용 가능
- 세션 분기는 `claude --resume <id> --fork-session` 옵션 사용
