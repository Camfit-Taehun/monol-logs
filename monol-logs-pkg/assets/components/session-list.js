/**
 * Logs Session List Component
 * 세션 목록 컴포넌트 (필터, 정렬, 검색)
 */

import { MonolComponent } from '/design-system/component-base.js';

export class LogsSessionList extends MonolComponent {
  constructor(container, options = {}) {
    super(container, options);
    this.state = {
      sessions: options.sessions || [],
      filteredSessions: [],
      filter: {
        author: '',
        topic: '',
        dateRange: 'all'
      },
      sort: 'newest',
      search: '',
      loading: true
    };
  }

  async init() {
    if (this.options.apiUrl) {
      await this.fetchSessions();
    } else {
      // Mock data
      this.state.sessions = this.getMockSessions();
    }
    this.state.filteredSessions = [...this.state.sessions];
    this.state.loading = false;
    this.render();
  }

  getMockSessions() {
    return [
      { id: 'f6702810', author: 'alice', topic: 'login-feature', date: '2026-01-19', time: '14:30', messageCount: 42, status: 'completed' },
      { id: 'a1b2c3d4', author: 'bob', topic: 'api-refactor', date: '2026-01-18', time: '09:15', messageCount: 28, status: 'completed' },
      { id: 'e5f6g7h8', author: 'alice', topic: 'bug-fix-auth', date: '2026-01-18', time: '16:45', messageCount: 15, status: 'completed' },
      { id: 'i9j0k1l2', author: 'charlie', topic: 'performance', date: '2026-01-17', time: '11:00', messageCount: 63, status: 'in-progress' },
      { id: 'm3n4o5p6', author: 'alice', topic: 'ui-redesign', date: '2026-01-17', time: '08:30', messageCount: 87, status: 'completed' },
      { id: 'q7r8s9t0', author: 'bob', topic: 'database-migration', date: '2026-01-16', time: '14:00', messageCount: 34, status: 'completed' }
    ];
  }

  async fetchSessions() {
    try {
      const response = await fetch(this.options.apiUrl);
      this.state.sessions = await response.json();
    } catch (error) {
      console.error('Failed to fetch sessions:', error);
      this.state.sessions = this.getMockSessions();
    }
  }

  applyFilters() {
    let result = [...this.state.sessions];
    const { filter, search, sort } = this.state;

    // Search
    if (search) {
      const q = search.toLowerCase();
      result = result.filter(s =>
        s.topic.toLowerCase().includes(q) ||
        s.author.toLowerCase().includes(q) ||
        s.id.toLowerCase().includes(q)
      );
    }

    // Filter by author
    if (filter.author) {
      result = result.filter(s => s.author === filter.author);
    }

    // Filter by date range
    if (filter.dateRange !== 'all') {
      const now = new Date();
      const days = filter.dateRange === '7d' ? 7 : filter.dateRange === '30d' ? 30 : 1;
      const cutoff = new Date(now.getTime() - days * 24 * 60 * 60 * 1000);
      result = result.filter(s => new Date(s.date) >= cutoff);
    }

    // Sort
    result.sort((a, b) => {
      if (sort === 'newest') return new Date(b.date) - new Date(a.date);
      if (sort === 'oldest') return new Date(a.date) - new Date(b.date);
      if (sort === 'messages') return b.messageCount - a.messageCount;
      if (sort === 'topic') return a.topic.localeCompare(b.topic);
      return 0;
    });

    this.state.filteredSessions = result;
  }

  render() {
    const { filteredSessions, loading, filter, sort, search } = this.state;
    const authors = [...new Set(this.state.sessions.map(s => s.author))];

    if (loading) {
      this.container.innerHTML = this.html`
        <div class="logs-session-list loading">
          <div class="loading-spinner"></div>
        </div>
      `;
      return;
    }

    this.container.innerHTML = this.html`
      <div class="logs-session-list">
        <div class="list-header">
          <h3>Sessions</h3>
          <span class="session-count">${filteredSessions.length} sessions</span>
        </div>
        <div class="list-controls">
          <div class="search-box">
            <input type="text" placeholder="Search sessions..." value="${search}" class="search-input" />
          </div>
          <div class="filters">
            <select class="filter-author">
              <option value="">All Authors</option>
              ${authors.map(a => `<option value="${a}" ${filter.author === a ? 'selected' : ''}>${a}</option>`).join('')}
            </select>
            <select class="filter-date">
              <option value="all" ${filter.dateRange === 'all' ? 'selected' : ''}>All Time</option>
              <option value="1d" ${filter.dateRange === '1d' ? 'selected' : ''}>Today</option>
              <option value="7d" ${filter.dateRange === '7d' ? 'selected' : ''}>Last 7 days</option>
              <option value="30d" ${filter.dateRange === '30d' ? 'selected' : ''}>Last 30 days</option>
            </select>
            <select class="sort-select">
              <option value="newest" ${sort === 'newest' ? 'selected' : ''}>Newest First</option>
              <option value="oldest" ${sort === 'oldest' ? 'selected' : ''}>Oldest First</option>
              <option value="messages" ${sort === 'messages' ? 'selected' : ''}>Most Messages</option>
              <option value="topic" ${sort === 'topic' ? 'selected' : ''}>Topic A-Z</option>
            </select>
          </div>
        </div>
        <div class="session-items">
          ${filteredSessions.length === 0
            ? '<div class="empty-state">No sessions found</div>'
            : filteredSessions.map(s => this.renderSession(s)).join('')}
        </div>
      </div>
    `;

    this.bindEvents();
  }

  renderSession(session) {
    const statusClass = session.status === 'in-progress' ? 'status-active' : 'status-completed';
    return this.html`
      <div class="session-item" data-id="${session.id}">
        <div class="session-main">
          <div class="session-icon">&#x1F4DD;</div>
          <div class="session-info">
            <div class="session-topic">${session.topic}</div>
            <div class="session-meta">
              <span class="session-author">@${session.author}</span>
              <span class="session-date">${session.date} ${session.time}</span>
              <span class="session-messages">${session.messageCount} messages</span>
            </div>
          </div>
        </div>
        <div class="session-actions">
          <span class="session-status ${statusClass}">${session.status}</span>
          <button class="action-btn view-btn" title="View">&#x1F441;</button>
          <button class="action-btn resume-btn" title="Resume">&#x25B6;</button>
        </div>
      </div>
    `;
  }

  bindEvents() {
    // Search
    const searchInput = this.container.querySelector('.search-input');
    if (searchInput) {
      searchInput.addEventListener('input', (e) => {
        this.state.search = e.target.value;
        this.applyFilters();
        this.render();
      });
    }

    // Filters
    const authorFilter = this.container.querySelector('.filter-author');
    if (authorFilter) {
      authorFilter.addEventListener('change', (e) => {
        this.state.filter.author = e.target.value;
        this.applyFilters();
        this.render();
      });
    }

    const dateFilter = this.container.querySelector('.filter-date');
    if (dateFilter) {
      dateFilter.addEventListener('change', (e) => {
        this.state.filter.dateRange = e.target.value;
        this.applyFilters();
        this.render();
      });
    }

    // Sort
    const sortSelect = this.container.querySelector('.sort-select');
    if (sortSelect) {
      sortSelect.addEventListener('change', (e) => {
        this.state.sort = e.target.value;
        this.applyFilters();
        this.render();
      });
    }

    // Session actions
    this.container.querySelectorAll('.session-item').forEach(item => {
      const id = item.dataset.id;
      const session = this.state.sessions.find(s => s.id === id);

      item.querySelector('.view-btn')?.addEventListener('click', (e) => {
        e.stopPropagation();
        this.emit('session-view', session);
      });

      item.querySelector('.resume-btn')?.addEventListener('click', (e) => {
        e.stopPropagation();
        this.emit('session-resume', session);
      });

      item.addEventListener('click', () => {
        this.emit('session-select', session);
      });
    });
  }
}

// CSS
const style = document.createElement('style');
style.textContent = `
  .logs-session-list {
    background: var(--bg-secondary);
    border: 1px solid var(--border-color);
    border-radius: var(--radius-md, 8px);
    padding: 16px;
  }
  .logs-session-list.loading {
    display: flex;
    justify-content: center;
    align-items: center;
    min-height: 200px;
  }
  .logs-session-list .loading-spinner {
    width: 24px;
    height: 24px;
    border: 2px solid var(--border-color);
    border-top-color: var(--accent-cyan);
    border-radius: 50%;
    animation: spin 1s linear infinite;
  }
  .logs-session-list .list-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 12px;
  }
  .logs-session-list .list-header h3 {
    font-size: 14px;
    font-weight: 600;
    margin: 0;
  }
  .logs-session-list .session-count {
    font-size: 12px;
    color: var(--text-secondary);
  }
  .logs-session-list .list-controls {
    display: flex;
    flex-direction: column;
    gap: 8px;
    margin-bottom: 12px;
  }
  .logs-session-list .search-box {
    width: 100%;
  }
  .logs-session-list .search-input {
    width: 100%;
    padding: 8px 12px;
    border: 1px solid var(--border-color);
    border-radius: 6px;
    background: var(--bg-tertiary);
    color: var(--text-primary);
    font-size: 13px;
  }
  .logs-session-list .search-input:focus {
    outline: none;
    border-color: var(--accent-cyan);
  }
  .logs-session-list .filters {
    display: flex;
    gap: 8px;
    flex-wrap: wrap;
  }
  .logs-session-list .filters select {
    padding: 6px 10px;
    border: 1px solid var(--border-color);
    border-radius: 6px;
    background: var(--bg-tertiary);
    color: var(--text-primary);
    font-size: 12px;
    cursor: pointer;
  }
  .logs-session-list .session-items {
    display: flex;
    flex-direction: column;
    gap: 8px;
    max-height: 400px;
    overflow-y: auto;
  }
  .logs-session-list .empty-state {
    text-align: center;
    padding: 32px;
    color: var(--text-secondary);
    font-size: 13px;
  }
  .logs-session-list .session-item {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 12px;
    background: var(--bg-tertiary);
    border: 1px solid var(--border-color);
    border-radius: 8px;
    cursor: pointer;
    transition: all 0.2s;
  }
  .logs-session-list .session-item:hover {
    border-color: var(--accent-cyan);
    background: rgba(57, 197, 207, 0.05);
  }
  .logs-session-list .session-main {
    display: flex;
    align-items: center;
    gap: 12px;
  }
  .logs-session-list .session-icon {
    font-size: 20px;
  }
  .logs-session-list .session-topic {
    font-size: 13px;
    font-weight: 500;
    color: var(--text-primary);
  }
  .logs-session-list .session-meta {
    display: flex;
    gap: 12px;
    font-size: 11px;
    color: var(--text-secondary);
    margin-top: 2px;
  }
  .logs-session-list .session-author {
    color: var(--accent-cyan);
  }
  .logs-session-list .session-actions {
    display: flex;
    align-items: center;
    gap: 8px;
  }
  .logs-session-list .session-status {
    font-size: 10px;
    padding: 2px 8px;
    border-radius: 4px;
    background: var(--bg-primary);
  }
  .logs-session-list .status-active {
    color: var(--accent-green);
    background: rgba(50, 205, 50, 0.1);
  }
  .logs-session-list .status-completed {
    color: var(--text-secondary);
  }
  .logs-session-list .action-btn {
    background: none;
    border: none;
    cursor: pointer;
    font-size: 14px;
    padding: 4px 8px;
    border-radius: 4px;
    opacity: 0.6;
    transition: all 0.2s;
  }
  .logs-session-list .action-btn:hover {
    opacity: 1;
    background: var(--bg-primary);
  }
`;
document.head.appendChild(style);

export default LogsSessionList;
