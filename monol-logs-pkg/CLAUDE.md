# Session Archive Plugin v4.0

Claude Code 세션 관리 - 등록, 보기, 이어하기, 요약, 로드맵

## 핵심 기능

- **세션 등록**: jsonl 복사 없이 참조만 저장 (저장 공간 절약)
- **세션 보기**: 사람이 읽기 쉬운 형식으로 변환
- **세션 이어하기**: `claude --resume` 연동
- **AI 요약**: 세션 내용 자동 요약
- **TODO 추출**: 세션에서 할 일 추출

## 설치

```bash
npm install -g monol-logs
```

## 스킬 (Commands)

| 커맨드 | 한글 키워드 | 설명 |
|--------|-------------|------|
| `/sessions` | 세션, 세션목록 | 등록된 세션 목록 |
| `/save` | 저장, 내보내기 | 세션 등록 (참조 저장) |
| `/session` | 세션보기, 이어하기 | 세션 보기/이어하기 |
| `/roadmap` | 로드맵, 할일 | TODO 추출 |
| `/summary` | 요약, 정리 | AI 요약 생성 |
| `/branch` | 브랜치, 분기 | 세션 분기 |
| `/visualize` | 시각화, 대시보드 | 타임라인/대시보드 생성 |

**한글 자연어 입력 지원**: "세션 목록 보여줘", "이전 세션 이어해줘" 등

## 주요 워크플로우

### 1. 세션 등록

```
/save                      # 최근 세션 등록 + 요약/TODO 자동 생성
/save f6702810 login-feat  # 특정 세션 + 토픽으로 등록
/save --no-summary         # 요약 없이 빠르게 저장
/save --list               # 등록 가능한 세션 목록
```

**자동 생성되는 것:**
- `.meta.json` - 메타데이터 (원본 경로 참조)
- `.conversation.md` - 전체 대화 **(읽기 좋은 형태)**
- `.summary.md` - AI 요약 **(자동)**
- `.roadmap.md` - TODO 목록 **(자동)**

**저장 안 되는 것:**
- `.jsonl` 원본 (복사 안 함, 참조만)

**팀 공유:**
```bash
git add .claude/sessions/  # 요약/메타만 커밋 (jsonl 제외)
git commit -m "docs: feature-x 세션 기록"
```

### 2. 세션 보기

```
/session view f6702810     # 읽기 좋은 형식으로 보기
```

출력 예시:
```markdown
# Session: login-feature
Date: 2026-01-18 14:30

## 👤 User (14:30)
로그인 기능을 만들어줘.

## 🤖 Assistant (14:31)
로그인 기능을 구현하겠습니다...
```

### 3. 세션 이어하기

```
/session resume f6702810   # claude --resume 실행
```

또는

```
/session load f6702810     # 요약을 현재 세션에 로드
```

### 4. 세션 목록

```
/sessions                  # 등록된 세션
/sessions --available      # 등록 안 된 세션
/sessions --update         # index.md 갱신
```

## 파일 구조

```
.claude/sessions/
├── index.md                                                    # 세션 목록
├── roadmap.md                                                  # TODO 통합
├── alice_2026-01-18_1430_login-feature_f6702810.meta.json      # 메타데이터
├── alice_2026-01-18_1430_login-feature_f6702810.conversation.md # 전체 대화
├── alice_2026-01-18_1430_login-feature_f6702810.summary.md     # AI 요약
├── alice_2026-01-18_1430_login-feature_f6702810.roadmap.md     # 세션별 TODO
├── bob_2026-01-17_0930_api-refactor_a1b2c3d4.meta.json         # 다른 팀원
└── ...
```

**파일명 형식:** `{author}_{date}_{time}_{topic}_{session-id}.{ext}`

**meta.json 예시:**
```json
{
  "sessionId": "f6702810-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "source": "~/.claude/projects/-Users-kent-Work/f6702810-xxxx.jsonl",
  "topic": "login-feature",
  "createdAt": "2026-01-18T14:30:00Z",
  "savedAt": "2026-01-18T18:00:00Z",
  "savedBy": "alice",
  "messageCount": 42,
  "size": 125000
}
```

## 팀 협업

```bash
# 1. 각자 세션 저장 (작성자 자동 감지)
/save my-feature

# 2. git으로 공유
git add .claude/sessions/
git commit -m "docs: add session logs"
git push

# 3. 팀원 세션 확인
/sessions                    # 전체 세션 목록
/sessions --author alice     # alice 세션만
/session load <id>           # 요약 로드
```

## 시각화

```bash
# 터미널 ASCII 타임라인
/visualize

# 마크다운 보고서 생성
/visualize --md

# 인터랙티브 HTML 대시보드
/visualize --html --open

# 필터링
/visualize --author alice --date 7d
```

**출력 형식:**
- `--ascii` (기본): 터미널에 ASCII 타임라인 출력
- `--md`: `.claude/sessions/visualization.md` 생성
- `--html`: `.claude/sessions/dashboard.html` 생성 (브라우저에서 열기)

## vs `claude --resume`

| 기능 | `claude --resume` | monol-logs |
|------|-------------------|------------|
| 세션 이어하기 | ✓ | ✓ (연동) |
| 사람 읽기 쉬운 이름 | ❌ (UUID) | ✓ (토픽) |
| 세션 내용 보기 | ❌ | ✓ (markdown) |
| git 추적 | ❌ | ✓ (meta만) |
| TODO 추출 | ❌ | ✓ |
| AI 요약 | ❌ | ✓ |
| 저장 공간 | 1x | 1x (중복 없음) |

## 설정 (config.yaml)

```yaml
# 요약
summary_enabled: true
summary_use_ai: true

# 로드맵
roadmap_enabled: true
roadmap_per_session: true

# 인덱스
index_enabled: true
auto_update_index: true
```

## API 키 (AI 요약용)

```bash
export ANTHROPIC_API_KEY="sk-..."
```
