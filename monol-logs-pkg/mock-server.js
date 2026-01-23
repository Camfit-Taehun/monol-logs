#!/usr/bin/env node
/**
 * Session Console Mock API Server
 *
 * Usage:
 *   node mock-server.js [port]
 *
 * Default port: 3847
 */

const http = require('http');
const fs = require('fs');
const path = require('path');
const url = require('url');

const PORT = process.argv[2] || 3847;

// Mock session data
const MOCK_SESSIONS = [
  {
    sessionId: 'f6702810-1234-5678-9abc-def012345678',
    topic: 'login-feature',
    savedBy: 'alice',
    createdAt: '2026-01-18T14:30:00Z',
    savedAt: '2026-01-18T18:00:00Z',
    messageCount: 42,
    isBookmarked: true
  },
  {
    sessionId: 'a1b2c3d4-5678-9abc-def0-123456789abc',
    topic: 'api-refactor',
    savedBy: 'bob',
    createdAt: '2026-01-17T09:30:00Z',
    savedAt: '2026-01-17T12:45:00Z',
    messageCount: 28,
    isBookmarked: false
  },
  {
    sessionId: 'deadbeef-cafe-babe-1234-567890abcdef',
    topic: 'dashboard-improvement',
    savedBy: 'alice',
    createdAt: '2026-01-19T10:00:00Z',
    savedAt: '2026-01-19T15:30:00Z',
    messageCount: 65,
    isBookmarked: false
  },
  {
    sessionId: '12345678-abcd-efgh-ijkl-mnopqrstuvwx',
    topic: 'bug-fix-auth',
    savedBy: 'charlie',
    createdAt: '2026-01-16T16:00:00Z',
    savedAt: '2026-01-16T17:30:00Z',
    messageCount: 15,
    isBookmarked: true
  },
  {
    sessionId: 'abcdef12-3456-7890-abcd-ef1234567890',
    topic: 'documentation-update',
    savedBy: 'bob',
    createdAt: '2026-01-15T11:00:00Z',
    savedAt: '2026-01-15T13:00:00Z',
    messageCount: 22,
    isBookmarked: false
  }
];

const MOCK_CONTENT = {
  summary: `# Session Summary

## 주요 작업
- 사용자 인증 기능 구현
- JWT 토큰 기반 로그인/로그아웃
- 세션 관리 미들웨어 추가

## 결정사항
- Access Token: 15분 만료
- Refresh Token: 7일 만료
- Redis에 세션 저장

## 변경된 파일
- src/auth/login.ts
- src/middleware/session.ts
- src/utils/jwt.ts

## 다음 할 일
- [ ] 소셜 로그인 추가 (Google, GitHub)
- [ ] 비밀번호 재설정 기능
- [ ] 2FA 구현`,

  conversation: `# Session: login-feature

Date: 2026-01-18
Author: alice

---

## 👤 User (14:30)
로그인 기능을 만들어줘. JWT 기반으로 하고 싶어.

## 🤖 Assistant (14:31)
JWT 기반 로그인 기능을 구현하겠습니다. 먼저 필요한 패키지를 설치하고 구조를 잡겠습니다.

\`\`\`bash
npm install jsonwebtoken bcrypt
\`\`\`

## 👤 User (14:35)
토큰 만료 시간은 어떻게 설정하면 좋을까?

## 🤖 Assistant (14:36)
보안과 사용자 경험 사이의 균형을 고려하면:

- **Access Token**: 15분 (짧게 유지)
- **Refresh Token**: 7일 (자동 갱신용)

이렇게 하면 Access Token이 탈취되어도 피해를 최소화할 수 있습니다.

---

*전체 대화는 실제 .conversation.md 파일에서 로드됩니다.*`
};

// Mock TODO data
const MOCK_TODOS = [
  {
    id: 1,
    content: 'Add unit tests for auth module',
    session: 'login-feature',
    sessionId: 'f6702810-1234-5678-9abc-def012345678',
    author: 'alice',
    createdAt: '2026-01-18T14:30:00Z',
    completed: false,
    priority: 'high'
  },
  {
    id: 2,
    content: 'Implement password reset',
    session: 'login-feature',
    sessionId: 'f6702810-1234-5678-9abc-def012345678',
    author: 'alice',
    createdAt: '2026-01-18T14:30:00Z',
    completed: false,
    priority: 'high'
  },
  {
    id: 3,
    content: 'Optimize database queries',
    session: 'api-refactor',
    sessionId: 'a1b2c3d4-5678-9abc-def0-123456789abc',
    author: 'bob',
    createdAt: '2026-01-10T09:30:00Z',
    completed: false,
    priority: 'medium'
  },
  {
    id: 4,
    content: 'Add API rate limiting',
    session: 'api-refactor',
    sessionId: 'a1b2c3d4-5678-9abc-def0-123456789abc',
    author: 'bob',
    createdAt: '2026-01-17T09:30:00Z',
    completed: true,
    priority: 'high'
  },
  {
    id: 5,
    content: 'Fix memory leak in dashboard',
    session: 'dashboard-improvement',
    sessionId: 'deadbeef-cafe-babe-1234-567890abcdef',
    author: 'alice',
    createdAt: '2026-01-05T10:00:00Z',
    completed: false,
    priority: 'high'
  },
  {
    id: 6,
    content: 'Update documentation for new API',
    session: 'documentation-update',
    sessionId: 'abcdef12-3456-7890-abcd-ef1234567890',
    author: 'bob',
    createdAt: '2026-01-15T11:00:00Z',
    completed: false,
    priority: 'low'
  },
  {
    id: 7,
    content: 'Migrate to new auth system',
    session: 'bug-fix-auth',
    sessionId: '12345678-abcd-efgh-ijkl-mnopqrstuvwx',
    author: 'charlie',
    createdAt: '2025-12-20T16:00:00Z',
    completed: false,
    priority: 'high'
  }
];

// In-memory state
let deletedSessions = new Set();

// CORS headers
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type'
};

// Router
function handleRequest(req, res) {
  const parsedUrl = url.parse(req.url, true);
  const pathname = parsedUrl.pathname;
  const query = parsedUrl.query;

  // CORS preflight
  if (req.method === 'OPTIONS') {
    res.writeHead(204, corsHeaders);
    res.end();
    return;
  }

  // Set headers
  res.setHeader('Content-Type', 'application/json');
  Object.entries(corsHeaders).forEach(([k, v]) => res.setHeader(k, v));

  // Routes
  if (pathname === '/api/sessions' && req.method === 'GET') {
    return handleGetSessions(query, res);
  }

  if (pathname.match(/^\/api\/sessions\/[^/]+$/) && req.method === 'GET') {
    const id = pathname.split('/')[3];
    return handleGetSession(id, res);
  }

  if (pathname.match(/^\/api\/sessions\/[^/]+\/content$/) && req.method === 'GET') {
    const id = pathname.split('/')[3];
    return handleGetContent(id, query, res);
  }

  if (pathname.match(/^\/api\/sessions\/[^/]+$/) && req.method === 'DELETE') {
    const id = pathname.split('/')[3];
    return handleDeleteSession(id, res);
  }

  if (pathname.match(/^\/api\/sessions\/[^/]+\/bookmark$/) && req.method === 'POST') {
    const id = pathname.split('/')[3];
    return handleBookmark(id, req, res);
  }

  if (pathname === '/api/stats' && req.method === 'GET') {
    return handleGetStats(res);
  }

  if (pathname === '/api/insights' && req.method === 'GET') {
    return handleGetInsights(query, res);
  }

  if (pathname === '/api/insights/todos' && req.method === 'GET') {
    return handleGetTodos(query, res);
  }

  if (pathname.match(/^\/api\/insights\/todos\/\d+$/) && req.method === 'POST') {
    const id = parseInt(pathname.split('/')[4]);
    return handleUpdateTodo(id, req, res);
  }

  if (pathname === '/api/insights/report' && req.method === 'POST') {
    return handleGenerateReport(req, res);
  }

  // Serve static files (console.html)
  if (pathname === '/' || pathname === '/console.html') {
    return serveStaticFile(res);
  }

  // 404
  res.writeHead(404);
  res.end(JSON.stringify({ error: 'Not found' }));
}

// Handlers
function handleGetSessions(query, res) {
  let sessions = MOCK_SESSIONS.filter(s => !deletedSessions.has(s.sessionId));

  // Apply filters
  if (query.author) {
    sessions = sessions.filter(s => s.savedBy === query.author);
  }
  if (query.dateFrom) {
    sessions = sessions.filter(s => new Date(s.createdAt) >= new Date(query.dateFrom));
  }
  if (query.dateTo) {
    sessions = sessions.filter(s => new Date(s.createdAt) <= new Date(query.dateTo + 'T23:59:59'));
  }
  if (query.topic) {
    const term = query.topic.toLowerCase();
    sessions = sessions.filter(s => s.topic.toLowerCase().includes(term));
  }
  if (query.bookmarked === 'true') {
    sessions = sessions.filter(s => s.isBookmarked);
  }

  // Apply sorting
  switch (query.sortBy) {
    case 'oldest':
      sessions.sort((a, b) => new Date(a.createdAt) - new Date(b.createdAt));
      break;
    case 'messages':
      sessions.sort((a, b) => b.messageCount - a.messageCount);
      break;
    case 'name':
      sessions.sort((a, b) => a.topic.localeCompare(b.topic));
      break;
    default: // newest
      sessions.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
  }

  res.writeHead(200);
  res.end(JSON.stringify({ sessions, total: sessions.length }));
}

function handleGetSession(id, res) {
  const session = MOCK_SESSIONS.find(s => s.sessionId === id);
  if (!session || deletedSessions.has(id)) {
    res.writeHead(404);
    res.end(JSON.stringify({ error: 'Session not found' }));
    return;
  }
  res.writeHead(200);
  res.end(JSON.stringify(session));
}

function handleGetContent(id, query, res) {
  const session = MOCK_SESSIONS.find(s => s.sessionId === id);
  if (!session || deletedSessions.has(id)) {
    res.writeHead(404);
    res.end(JSON.stringify({ error: 'Session not found' }));
    return;
  }

  const type = query.type || 'summary';
  const content = MOCK_CONTENT[type] || MOCK_CONTENT.summary;

  res.writeHead(200);
  res.end(JSON.stringify({ type, content }));
}

function handleDeleteSession(id, res) {
  const session = MOCK_SESSIONS.find(s => s.sessionId === id);
  if (!session) {
    res.writeHead(404);
    res.end(JSON.stringify({ error: 'Session not found' }));
    return;
  }

  deletedSessions.add(id);

  res.writeHead(200);
  res.end(JSON.stringify({
    success: true,
    deletedFiles: [
      `${session.savedBy}_2026-01-18_1430_${session.topic}_${id.substring(0, 8)}.meta.json`,
      `${session.savedBy}_2026-01-18_1430_${session.topic}_${id.substring(0, 8)}.summary.md`,
      `${session.savedBy}_2026-01-18_1430_${session.topic}_${id.substring(0, 8)}.conversation.md`
    ]
  }));
}

function handleBookmark(id, req, res) {
  const session = MOCK_SESSIONS.find(s => s.sessionId === id);
  if (!session) {
    res.writeHead(404);
    res.end(JSON.stringify({ error: 'Session not found' }));
    return;
  }

  let body = '';
  req.on('data', chunk => body += chunk);
  req.on('end', () => {
    try {
      const data = JSON.parse(body || '{}');
      session.isBookmarked = data.bookmarked !== undefined ? data.bookmarked : !session.isBookmarked;

      res.writeHead(200);
      res.end(JSON.stringify({
        sessionId: id,
        isBookmarked: session.isBookmarked
      }));
    } catch (e) {
      res.writeHead(400);
      res.end(JSON.stringify({ error: 'Invalid JSON' }));
    }
  });
}

function handleGetStats(res) {
  const sessions = MOCK_SESSIONS.filter(s => !deletedSessions.has(s.sessionId));
  const authors = new Set(sessions.map(s => s.savedBy));
  const totalMessages = sessions.reduce((sum, s) => sum + s.messageCount, 0);
  const totalDuration = sessions.reduce((sum, s) => {
    return sum + (new Date(s.savedAt) - new Date(s.createdAt));
  }, 0);
  const bookmarkedCount = sessions.filter(s => s.isBookmarked).length;

  // Hourly activity (mock)
  const hourlyActivity = new Array(24).fill(0);
  sessions.forEach(s => {
    const hour = new Date(s.createdAt).getHours();
    hourlyActivity[hour]++;
  });

  // Author contribution
  const authorContribution = {};
  sessions.forEach(s => {
    authorContribution[s.savedBy] = (authorContribution[s.savedBy] || 0) + 1;
  });

  res.writeHead(200);
  res.end(JSON.stringify({
    totalSessions: sessions.length,
    totalAuthors: authors.size,
    totalMessages,
    totalDuration,
    bookmarkedCount,
    hourlyActivity,
    authorContribution
  }));
}

function handleGetInsights(query, res) {
  const sessions = MOCK_SESSIONS.filter(s => !deletedSessions.has(s.sessionId));
  const todos = MOCK_TODOS.filter(t => !t.completed);
  const now = new Date();

  // Personal patterns
  const hourCounts = new Array(24).fill(0);
  const dayCounts = new Array(7).fill(0);
  sessions.forEach(s => {
    const d = new Date(s.createdAt);
    hourCounts[d.getHours()]++;
    dayCounts[d.getDay()]++;
  });

  const peakHour = hourCounts.indexOf(Math.max(...hourCounts));
  const peakDay = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][dayCounts.indexOf(Math.max(...dayCounts))];

  const avgDuration = sessions.reduce((sum, s) => {
    return sum + (new Date(s.savedAt) - new Date(s.createdAt));
  }, 0) / (sessions.length || 1);

  // Topic distribution
  const topicCounts = {};
  sessions.forEach(s => {
    const base = s.topic.split('-')[0];
    topicCounts[base] = (topicCounts[base] || 0) + 1;
  });

  // Team contribution
  const authorSessions = {};
  const authorMessages = {};
  sessions.forEach(s => {
    authorSessions[s.savedBy] = (authorSessions[s.savedBy] || 0) + 1;
    authorMessages[s.savedBy] = (authorMessages[s.savedBy] || 0) + s.messageCount;
  });

  // Knowledge map (author -> areas)
  const knowledgeMap = {};
  sessions.forEach(s => {
    const area = s.topic.split('-')[0];
    if (!knowledgeMap[area]) {
      knowledgeMap[area] = { primary: null, contributors: [], sessionCount: 0 };
    }
    knowledgeMap[area].sessionCount++;
    if (!knowledgeMap[area].contributors.includes(s.savedBy)) {
      knowledgeMap[area].contributors.push(s.savedBy);
    }
  });

  // Determine primary owner for each area
  Object.keys(knowledgeMap).forEach(area => {
    const areaSessions = sessions.filter(s => s.topic.startsWith(area));
    const countByAuthor = {};
    areaSessions.forEach(s => {
      countByAuthor[s.savedBy] = (countByAuthor[s.savedBy] || 0) + 1;
    });
    const sorted = Object.entries(countByAuthor).sort((a, b) => b[1] - a[1]);
    if (sorted.length > 0) {
      knowledgeMap[area].primary = sorted[0][0];
    }
  });

  // Knowledge silos (areas with only one contributor)
  const silos = Object.entries(knowledgeMap)
    .filter(([_, data]) => data.contributors.length === 1)
    .map(([area, data]) => ({ area, owner: data.primary }));

  // Hot topics (areas with multiple contributors)
  const hotTopics = Object.entries(knowledgeMap)
    .filter(([_, data]) => data.contributors.length > 1)
    .map(([area, data]) => ({
      area,
      contributors: data.contributors,
      sessionCount: data.sessionCount
    }))
    .sort((a, b) => b.sessionCount - a.sessionCount);

  // Weekly activity
  const weeklyActivity = [];
  for (let i = 6; i >= 0; i--) {
    const date = new Date(now);
    date.setDate(date.getDate() - i);
    const dateStr = date.toISOString().split('T')[0];
    const dayName = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][date.getDay()];

    const daySessions = sessions.filter(s => s.createdAt.startsWith(dateStr));
    const byAuthor = {};
    daySessions.forEach(s => {
      byAuthor[s.savedBy] = (byAuthor[s.savedBy] || 0) + 1;
    });

    weeklyActivity.push({ date: dateStr, day: dayName, byAuthor, total: daySessions.length });
  }

  // Stale TODOs (>2 weeks old)
  const twoWeeksAgo = new Date(now);
  twoWeeksAgo.setDate(twoWeeksAgo.getDate() - 14);
  const staleTodos = todos.filter(t => new Date(t.createdAt) < twoWeeksAgo);

  res.writeHead(200);
  res.end(JSON.stringify({
    personal: {
      peakHour: `${peakHour}:00-${peakHour + 1}:00`,
      peakDay,
      avgSessionDuration: Math.round(avgDuration / 60000),
      totalSessions: sessions.length,
      topicDistribution: topicCounts
    },
    team: {
      authorSessions,
      authorMessages,
      knowledgeMap,
      silos,
      hotTopics,
      weeklyActivity
    },
    todos: {
      total: MOCK_TODOS.length,
      open: todos.length,
      completed: MOCK_TODOS.filter(t => t.completed).length,
      stale: staleTodos.length,
      highPriority: todos.filter(t => t.priority === 'high').length,
      items: todos.slice(0, 10)
    }
  }));
}

function handleGetTodos(query, res) {
  let todos = [...MOCK_TODOS];

  // Apply filters
  if (query.author) {
    todos = todos.filter(t => t.author === query.author);
  }
  if (query.completed === 'true') {
    todos = todos.filter(t => t.completed);
  } else if (query.completed === 'false') {
    todos = todos.filter(t => !t.completed);
  }
  if (query.priority) {
    todos = todos.filter(t => t.priority === query.priority);
  }
  if (query.session) {
    todos = todos.filter(t => t.session.includes(query.session));
  }

  // Sort by date (newest first) then by priority
  const priorityOrder = { high: 0, medium: 1, low: 2 };
  todos.sort((a, b) => {
    if (a.completed !== b.completed) return a.completed ? 1 : -1;
    if (priorityOrder[a.priority] !== priorityOrder[b.priority]) {
      return priorityOrder[a.priority] - priorityOrder[b.priority];
    }
    return new Date(b.createdAt) - new Date(a.createdAt);
  });

  res.writeHead(200);
  res.end(JSON.stringify({
    todos,
    total: todos.length,
    open: todos.filter(t => !t.completed).length,
    completed: todos.filter(t => t.completed).length
  }));
}

function handleUpdateTodo(id, req, res) {
  const todo = MOCK_TODOS.find(t => t.id === id);
  if (!todo) {
    res.writeHead(404);
    res.end(JSON.stringify({ error: 'TODO not found' }));
    return;
  }

  let body = '';
  req.on('data', chunk => body += chunk);
  req.on('end', () => {
    try {
      const data = JSON.parse(body || '{}');
      if (data.completed !== undefined) {
        todo.completed = data.completed;
      }
      if (data.priority) {
        todo.priority = data.priority;
      }

      res.writeHead(200);
      res.end(JSON.stringify(todo));
    } catch (e) {
      res.writeHead(400);
      res.end(JSON.stringify({ error: 'Invalid JSON' }));
    }
  });
}

function handleGenerateReport(req, res) {
  let body = '';
  req.on('data', chunk => body += chunk);
  req.on('end', () => {
    try {
      const data = JSON.parse(body || '{}');
      const reportType = data.type || 'weekly';
      const sessions = MOCK_SESSIONS.filter(s => !deletedSessions.has(s.sessionId));

      // Generate mock AI report
      const report = generateMockReport(reportType, sessions);

      // Simulate AI processing delay
      setTimeout(() => {
        res.writeHead(200);
        res.end(JSON.stringify({
          success: true,
          type: reportType,
          generatedAt: new Date().toISOString(),
          content: report
        }));
      }, 1500); // 1.5 second delay to simulate AI processing
    } catch (e) {
      res.writeHead(400);
      res.end(JSON.stringify({ error: 'Invalid JSON' }));
    }
  });
}

function generateMockReport(type, sessions) {
  const totalSessions = sessions.length;
  const authors = [...new Set(sessions.map(s => s.savedBy))];
  const totalMessages = sessions.reduce((sum, s) => sum + s.messageCount, 0);

  // Topic distribution
  const topicCounts = {};
  sessions.forEach(s => {
    const base = s.topic.split('-')[0];
    topicCounts[base] = (topicCounts[base] || 0) + 1;
  });
  const topTopics = Object.entries(topicCounts)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 3)
    .map(([topic]) => topic);

  // Author contributions
  const authorSessions = {};
  sessions.forEach(s => {
    authorSessions[s.savedBy] = (authorSessions[s.savedBy] || 0) + 1;
  });
  const topContributor = Object.entries(authorSessions)
    .sort((a, b) => b[1] - a[1])[0];

  // Open TODOs
  const openTodos = MOCK_TODOS.filter(t => !t.completed);
  const staleTodos = openTodos.filter(t => {
    const created = new Date(t.createdAt);
    const now = new Date();
    return (now - created) > 14 * 24 * 60 * 60 * 1000;
  });

  const typeTitle = type.charAt(0).toUpperCase() + type.slice(1);

  return `# ${typeTitle} Insights Report
Generated: ${new Date().toISOString().split('T')[0]}

## Executive Summary

이번 ${type === 'weekly' ? '주' : '달'}에 팀은 총 **${totalSessions}개의 세션**을 진행했으며, **${totalMessages}개의 메시지**를 교환했습니다. 주요 작업 영역은 ${topTopics.join(', ')}이며, ${topContributor ? topContributor[0] + '이(가) ' + topContributor[1] + '개의 세션으로 가장 활발하게 활동했습니다' : '활동 데이터가 부족합니다'}.

## Highlights

- ✅ **${topTopics[0] || 'N/A'}** 영역에서 활발한 작업 진행
- 🔄 총 ${totalSessions}개 세션 완료, ${openTodos.length}개 TODO 진행 중
- ⚠️ ${staleTodos.length > 0 ? `${staleTodos.length}개의 TODO가 2주 이상 미완료 상태` : '모든 TODO가 적절히 관리되고 있음'}

## Team Analysis

### 기여도 분석

${authors.map(author => {
  const count = authorSessions[author];
  const pct = Math.round((count / totalSessions) * 100);
  return `- **${author}**: ${count}개 세션 (${pct}%)`;
}).join('\n')}

### 지식 맵 분석

${Object.entries(topicCounts).map(([topic, count]) => {
  const topicSessions = sessions.filter(s => s.topic.startsWith(topic));
  const topicAuthors = [...new Set(topicSessions.map(s => s.savedBy))];
  const isSilo = topicAuthors.length === 1;
  return `- **${topic}/***: ${topicAuthors.join(', ')} ${isSilo ? '⚠️ (sole owner)' : ''}`;
}).join('\n')}

### 협업 기회

${authors.length > 1 ? `- ${authors[0]}와 ${authors[1]}이(가) 공통 영역에서 협업하면 좋겠습니다.
- 지식 사일로 방지를 위해 코드 리뷰나 페어 프로그래밍을 권장합니다.` : '- 팀원이 추가되면 협업 분석이 가능합니다.'}

## Technical Debt

현재 **${openTodos.length}개의 미완료 TODO**가 있습니다.

${openTodos.slice(0, 5).map(todo => `- [ ] ${todo.content} (${todo.session}, ${todo.author})`).join('\n')}
${openTodos.length > 5 ? `\n... 외 ${openTodos.length - 5}개` : ''}

${staleTodos.length > 0 ? `\n### ⚠️ Stale TODOs (2주 이상)\n\n${staleTodos.map(t => `- ${t.content}`).join('\n')}` : ''}

## Recommendations

1. ${staleTodos.length > 0 ? '오래된 TODO 항목들을 검토하고 정리하세요.' : 'TODO 관리가 잘 되고 있습니다. 계속 유지하세요.'}
2. ${Object.values(topicCounts).some(c => c === 1) ? '단일 담당자 영역에 대한 지식 공유 세션을 계획하세요.' : '지식 분산이 잘 되어 있습니다.'}
3. 정기적인 팀 싱크 미팅으로 진행 상황을 공유하세요.

## Next Steps

- [ ] ${staleTodos.length > 0 ? 'Stale TODO 정리 회의 진행' : '신규 기능 개발 계획 수립'}
- [ ] 다음 ${type === 'weekly' ? '주' : '달'} 목표 설정
- [ ] 코드 리뷰 및 지식 공유 세션 스케줄링`;
}

function serveStaticFile(res) {
  const filePath = path.join(__dirname, 'templates', 'dashboard.html');

  fs.readFile(filePath, 'utf8', (err, content) => {
    if (err) {
      res.writeHead(404);
      res.end('Console HTML not found');
      return;
    }

    // Inject mock data and API base URL
    const sessions = MOCK_SESSIONS.filter(s => !deletedSessions.has(s.sessionId));
    const apiBaseScript = `<script>window.CONSOLE_API_BASE = 'http://localhost:${PORT}';</script>`;
    const injectedContent = content
      .replace(
        '<head>',
        `<head>\n${apiBaseScript}`
      )
      .replace(
        '/* SESSION_DATA_PLACEHOLDER */[]',
        JSON.stringify(sessions)
      )
      .replace(
        '/* FILE_CONTENTS_PLACEHOLDER */{}',
        JSON.stringify({
          [sessions[0]?.sessionId]: {
            summary: MOCK_CONTENT.summary,
            conversation: MOCK_CONTENT.conversation
          }
        })
      );

    res.setHeader('Content-Type', 'text/html');
    res.writeHead(200);
    res.end(injectedContent);
  });
}

// Start server
const server = http.createServer(handleRequest);

server.listen(PORT, () => {
  console.log(`
╭─────────────────────────────────────────╮
│  Session Console Mock Server            │
├─────────────────────────────────────────┤
│  URL: http://localhost:${PORT}             │
│                                         │
│  Endpoints:                             │
│    GET  /api/sessions                   │
│    GET  /api/sessions/:id               │
│    GET  /api/sessions/:id/content       │
│    DELETE /api/sessions/:id             │
│    POST /api/sessions/:id/bookmark      │
│    GET  /api/stats                      │
│    GET  /api/insights                   │
│    GET  /api/insights/todos             │
│    POST /api/insights/todos/:id         │
│    POST /api/insights/report            │
│                                         │
│  Press Ctrl+C to stop                   │
╰─────────────────────────────────────────╯
`);
});
