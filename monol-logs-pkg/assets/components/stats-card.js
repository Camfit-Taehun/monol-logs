/**
 * Logs Stats Card Component
 * 세션 통계 카드 컴포넌트
 */

import { MonolComponent } from '/design-system/component-base.js';

export class LogsStatsCard extends MonolComponent {
  constructor(container, options = {}) {
    super(container, options);
    this.state = {
      stats: options.stats || {
        total: 0,
        today: 0,
        bookmarked: 0,
        recentActivity: 'N/A'
      },
      loading: true
    };
  }

  async init() {
    if (this.options.apiUrl) {
      await this.fetchStats();
    }
    this.state.loading = false;
    this.render();
  }

  async fetchStats() {
    try {
      const response = await fetch(this.options.apiUrl);
      this.state.stats = await response.json();
    } catch (error) {
      console.error('Failed to fetch logs stats:', error);
      // Use mock data on error
      this.state.stats = {
        total: 24,
        today: 3,
        bookmarked: 5,
        recentActivity: '2h ago'
      };
    }
  }

  render() {
    const { stats, loading } = this.state;

    if (loading) {
      this.container.innerHTML = this.html`
        <div class="logs-stats-card loading">
          <div class="loading-spinner"></div>
        </div>
      `;
      return;
    }

    this.container.innerHTML = this.html`
      <div class="logs-stats-card">
        <div class="stats-header">
          <h3>Session Statistics</h3>
          <button class="refresh-btn" title="Refresh">
            <span class="refresh-icon">&#x21bb;</span>
          </button>
        </div>
        <div class="stats-grid">
          <div class="stat-item">
            <div class="stat-icon">&#x1F4DA;</div>
            <div class="stat-value">${stats.total}</div>
            <div class="stat-label">Total Sessions</div>
          </div>
          <div class="stat-item highlight">
            <div class="stat-icon">&#x1F4C5;</div>
            <div class="stat-value">${stats.today}</div>
            <div class="stat-label">Today</div>
          </div>
          <div class="stat-item">
            <div class="stat-icon">&#x2B50;</div>
            <div class="stat-value">${stats.bookmarked}</div>
            <div class="stat-label">Bookmarked</div>
          </div>
          <div class="stat-item">
            <div class="stat-icon">&#x23F1;</div>
            <div class="stat-value">${stats.recentActivity}</div>
            <div class="stat-label">Last Activity</div>
          </div>
        </div>
      </div>
    `;

    this.bindEvents();
  }

  bindEvents() {
    const refreshBtn = this.container.querySelector('.refresh-btn');
    if (refreshBtn) {
      refreshBtn.addEventListener('click', async () => {
        this.state.loading = true;
        this.render();
        await this.fetchStats();
        this.state.loading = false;
        this.render();
        this.emit('stats-refreshed', this.state.stats);
      });
    }
  }

  update(stats) {
    this.state.stats = { ...this.state.stats, ...stats };
    this.render();
  }
}

// CSS
const style = document.createElement('style');
style.textContent = `
  .logs-stats-card {
    background: var(--bg-secondary);
    border: 1px solid var(--border-color);
    border-radius: var(--radius-md, 8px);
    padding: 16px;
  }
  .logs-stats-card.loading {
    display: flex;
    justify-content: center;
    align-items: center;
    min-height: 150px;
  }
  .logs-stats-card .loading-spinner {
    width: 24px;
    height: 24px;
    border: 2px solid var(--border-color);
    border-top-color: var(--accent-cyan);
    border-radius: 50%;
    animation: spin 1s linear infinite;
  }
  @keyframes spin {
    to { transform: rotate(360deg); }
  }
  .logs-stats-card .stats-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 16px;
  }
  .logs-stats-card .stats-header h3 {
    font-size: 14px;
    font-weight: 600;
    margin: 0;
    color: var(--text-primary);
  }
  .logs-stats-card .refresh-btn {
    background: none;
    border: none;
    cursor: pointer;
    font-size: 16px;
    color: var(--text-secondary);
    padding: 4px;
    border-radius: 4px;
    transition: all 0.2s;
  }
  .logs-stats-card .refresh-btn:hover {
    color: var(--accent-cyan);
    background: var(--bg-tertiary);
  }
  .logs-stats-card .stats-grid {
    display: grid;
    grid-template-columns: repeat(4, 1fr);
    gap: 12px;
  }
  .logs-stats-card .stat-item {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 4px;
    padding: 12px 8px;
    background: var(--bg-tertiary);
    border-radius: 8px;
    transition: transform 0.2s;
  }
  .logs-stats-card .stat-item:hover {
    transform: translateY(-2px);
  }
  .logs-stats-card .stat-item.highlight {
    background: rgba(57, 197, 207, 0.1);
    border: 1px solid var(--accent-cyan);
  }
  .logs-stats-card .stat-icon {
    font-size: 20px;
  }
  .logs-stats-card .stat-value {
    font-size: 20px;
    font-weight: 700;
    color: var(--text-primary);
  }
  .logs-stats-card .stat-label {
    font-size: 11px;
    color: var(--text-secondary);
    text-align: center;
  }
  @media (max-width: 600px) {
    .logs-stats-card .stats-grid {
      grid-template-columns: repeat(2, 1fr);
    }
  }
`;
document.head.appendChild(style);

export default LogsStatsCard;
