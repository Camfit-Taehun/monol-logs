# Session Console API 명세

## 개요

Session Console이 정상 작동하기 위해 필요한 API 목록.
현재는 목업 서버(`mock-server.js`)로 테스트 가능.

---

## API 엔드포인트

### 1. 세션 목록 조회

```
GET /api/sessions
```

**Query Parameters:**
| 파라미터 | 타입 | 설명 |
|---------|------|------|
| author | string | 작성자 필터 |
| dateFrom | string | 시작 날짜 (YYYY-MM-DD) |
| dateTo | string | 종료 날짜 (YYYY-MM-DD) |
| topic | string | 토픽 검색어 |
| sortBy | string | 정렬: newest, oldest, messages, name |
| bookmarked | boolean | 북마크된 것만 |

**Response:**
```json
{
  "sessions": [
    {
      "sessionId": "f6702810-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
      "topic": "login-feature",
      "savedBy": "alice",
      "createdAt": "2026-01-18T14:30:00Z",
      "savedAt": "2026-01-18T18:00:00Z",
      "messageCount": 42,
      "isBookmarked": false
    }
  ],
  "total": 1
}
```

---

### 2. 세션 상세 조회

```
GET /api/sessions/:id
```

**Response:**
```json
{
  "sessionId": "f6702810-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "topic": "login-feature",
  "savedBy": "alice",
  "createdAt": "2026-01-18T14:30:00Z",
  "savedAt": "2026-01-18T18:00:00Z",
  "messageCount": 42,
  "source": "~/.claude/projects/.../f6702810.jsonl",
  "isBookmarked": false
}
```

---

### 3. 세션 콘텐츠 조회

```
GET /api/sessions/:id/content?type=summary|conversation
```

**Query Parameters:**
| 파라미터 | 타입 | 설명 |
|---------|------|------|
| type | string | `summary` 또는 `conversation` |

**Response:**
```json
{
  "type": "summary",
  "content": "# Session Summary\n\n..."
}
```

---

### 4. 세션 삭제

```
DELETE /api/sessions/:id
```

**Response:**
```json
{
  "success": true,
  "deletedFiles": [
    "alice_2026-01-18_1430_login-feature_f6702810.meta.json",
    "alice_2026-01-18_1430_login-feature_f6702810.summary.md",
    "alice_2026-01-18_1430_login-feature_f6702810.conversation.md"
  ]
}
```

---

### 5. 세션 북마크 토글

```
POST /api/sessions/:id/bookmark
```

**Request Body:**
```json
{
  "bookmarked": true
}
```

**Response:**
```json
{
  "sessionId": "f6702810-xxxx",
  "isBookmarked": true
}
```

---

### 6. 통계 조회

```
GET /api/stats
```

**Response:**
```json
{
  "totalSessions": 42,
  "totalAuthors": 3,
  "totalMessages": 1250,
  "totalDuration": 86400000,
  "bookmarkedCount": 5,
  "hourlyActivity": [0, 0, 1, 2, 5, ...],
  "authorContribution": {
    "alice": 20,
    "bob": 15,
    "charlie": 7
  }
}
```

---

## 플러그인에서 필요한 기능

Console이 제대로 동작하려면 monol-logs 플러그인에서 다음 기능 구현 필요:

| 기능 | 현재 상태 | 구현 필요 |
|------|----------|----------|
| 세션 목록 조회 | ✅ index.md 파싱 | API 래핑 |
| 세션 메타 조회 | ✅ .meta.json 읽기 | API 래핑 |
| 세션 요약 조회 | ✅ .summary.md 읽기 | API 래핑 |
| 세션 대화 조회 | ✅ .conversation.md 읽기 | API 래핑 |
| 세션 삭제 | ❌ | 구현 필요 |
| 북마크 관리 | ❌ | 구현 필요 (메타에 저장 or 별도 파일) |
| 통계 집계 | ❌ | 구현 필요 |

---

## 서버 모드 vs 정적 모드

### 정적 모드 (현재)
- HTML에 세션 데이터 인라인 삽입
- 삭제/북마크는 localStorage만
- 오프라인 작동

### 서버 모드 (향후)
- API 호출로 실시간 데이터
- 실제 파일 삭제/수정
- 팀 동기화 가능

```
/visualize --serve       # 서버 모드로 실행 (포트 3847)
/visualize --html        # 정적 HTML 생성
```
