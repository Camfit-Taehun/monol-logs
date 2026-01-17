# monol-logs

Claude Code 세션 아카이브 플러그인

> **"모든 AI 대화를 프로젝트 자산으로"**

## 목적

- Claude Code 세션을 자동으로 프로젝트 내에 저장
- 세션 식별 가능한 이름으로 관리
- 이식성 있는 플러그인 형태로 배포

## 구조

```
.claude/plugins/session-archive/
├── CLAUDE.md              # 플러그인 설명
├── hooks/
│   ├── on-session-end.sh  # SessionEnd 훅
│   └── on-pre-compact.sh  # PreCompact 훅
├── scripts/
│   ├── setup.sh           # 설치 스크립트
│   └── export-session.sh  # 수동 내보내기
├── lib/
│   └── utils.sh           # 공통 유틸
└── config.yaml            # 설정
```

## 설치

```bash
# 1. 플러그인 복사 또는 링크
cp -r ~/Work/kent-labs/monol-logs/.claude/plugins/session-archive ~/.claude/plugins/

# 2. 또는 글로벌 심볼릭 링크
ln -s ~/Work/kent-labs/monol-logs/.claude/plugins/session-archive ~/.claude/plugins/

# 3. hooks 설정 추가 (setup.sh 실행)
~/.claude/plugins/session-archive/scripts/setup.sh
```

## 기능 (계획)

- [ ] SessionEnd 시 자동 백업
- [ ] PreCompact 시 자동 백업
- [ ] 사람이 읽기 쉬운 파일명 (`2026-01-18_gap-analysis.jsonl`)
- [ ] 세션 요약 자동 생성 (`.summary.md`)
- [ ] 세션 인덱스 관리 (`index.md`)
- [ ] 수동 내보내기 명령어 (`/session export`)

## 라이선스

MIT
