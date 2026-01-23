# monol-logs 개발 로드맵

> 최종 업데이트: 2026-01-22
> 버전: 4.7.0

## 현재 상태 요약

### 디렉토리 구조

```
commands/  8개 ✅
skills/    8개 ✅
lib/       8개 ✅
```

### 파일별 상태

| 기능 | commands/ | skills/ | lib/ | 상태 |
|------|-----------|---------|------|------|
| save | ✅ | ✅ | - | ✅ 완료 |
| sessions | ✅ | ✅ | - | ✅ 완료 |
| session | ✅ | ✅ | ✅ | ✅ 완료 |
| summary | ✅ | ✅ | ✅ | ✅ 완료 |
| roadmap | ✅ | ✅ | ✅ | ✅ 완료 |
| branch | ✅ | ✅ | ✅ | ✅ 완료 |
| visualize | ✅ | ✅ | ✅ | ✅ 완료 |
| insights | ✅ | ✅ | ✅ | ✅ 완료 |
| sync | ❌ | ❌ | 🔶 | 🟡 초안 |

### 배포 현황

| 항목 | 상태 |
|------|------|
| `package.json` | ✅ v4.7.0 |
| `plugin.json` | ✅ v4.7.0 |
| `bin/monol-logs` | ✅ CLI 래퍼 |
| `templates/dashboard.html` | ✅ 목업 완료 |
| `mock-server.js` | ✅ 개발용 서버 |
| npm publish | ❌ 미완료 |

---

## ✅ Phase 1: Core 스킬 (완료)

### 1.1 /session 스킬 ✅
- `skills/session.md` - view/resume/load 스킬 정의
- `lib/session.sh` - jsonl 파싱, 세션 조회

### 1.2 /visualize 스킬 ✅
- `skills/visualize.md` - 시각화 스킬 정의
- `lib/visualize.sh` - ASCII/MD/HTML 생성

### 1.3 디렉토리 동기화 ✅
- `commands/insights.md` 추가 완료

---

## 🔄 Phase 2: 배포 준비 (진행 중)

### 2.1 npm 패키지 ✅
- `package.json` - 완료
- `bin/monol-logs` - 완료

### 2.2 문서
- [x] README.md 작성 ✅
- [ ] 설치 가이드 (README에 포함)
- [ ] CHANGELOG.md

### 2.3 배포 (대기)
- [ ] npm publish
- [ ] GitHub release

---

## 🟢 Phase 3: 고급 기능 (Future)

### 3.1 sync 기능
- [ ] `lib/sync.sh` 완성
- [ ] 원격 세션 공유
- [ ] `skills/sync.md` 생성

### 3.2 Console 실제 연동
- [ ] mock → real API 변환
- [ ] Express/Fastify 서버

### 3.3 AI 기능 강화
- [ ] 자동 카테고리 분류
- [ ] 세션 간 연관성 분석
- [ ] 코드 변경 요약

---

## 파일 구조 (현재)

```
monol-logs-pkg/
├── package.json           ✅ v4.7.0
├── plugin.json            ✅ v4.7.0
├── bin/
│   └── monol-logs         ✅ CLI
├── lib/
│   ├── utils.sh           ✅
│   ├── summary.sh         ✅
│   ├── roadmap.sh         ✅
│   ├── branch.sh          ✅
│   ├── insights.sh        ✅
│   ├── session.sh         ✅
│   ├── visualize.sh       ✅
│   └── sync.sh            🔶 초안
├── skills/
│   ├── save.md            ✅
│   ├── sessions.md        ✅
│   ├── session.md         ✅
│   ├── summary.md         ✅
│   ├── roadmap.md         ✅
│   ├── branch.md          ✅
│   ├── insights.md        ✅
│   └── visualize.md       ✅
├── commands/
│   ├── save.md            ✅
│   ├── sessions.md        ✅
│   ├── session.md         ✅
│   ├── summary.md         ✅
│   ├── roadmap.md         ✅
│   ├── branch.md          ✅
│   ├── insights.md        ✅
│   └── visualize.md       ✅
├── hooks/                 ✅
├── templates/
│   └── dashboard.html     ✅
├── scripts/               ✅
├── config.yaml            ✅
├── CLAUDE.md              ✅
└── docs/
    ├── ROADMAP.md         ✅
    ├── console-api.md     ✅
    └── insights-design.md ✅
```

---

## 다음 작업

### 즉시
1. ~~**README.md** 작성~~ ✅
2. **npm publish** 준비
3. **CHANGELOG.md** 작성

### 선택적
4. `lib/sync.sh` 완성
5. Console 실제 API 연동

---

## CLI 사용법

```bash
# 버전 확인
monol-logs --version

# 세션 관리
monol-logs session view <id>
monol-logs session load <id>
monol-logs session resume <id>

# 시각화
monol-logs visualize --ascii
monol-logs visualize --md
monol-logs visualize --html --open

# 인사이트
monol-logs insights --me
monol-logs insights --team
monol-logs insights --todos
```

## Claude Code 스킬

```
/save                  # 세션 저장
/sessions              # 세션 목록
/session view <id>     # 세션 보기
/session load <id>     # 세션 로드
/summary               # AI 요약
/roadmap               # TODO 추출
/visualize --html      # 대시보드 생성
/insights              # 인사이트 분석
/branch                # 세션 분기
```
