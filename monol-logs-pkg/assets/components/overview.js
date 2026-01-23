/**
 * Logs Overview Component
 * 통합 Overview 컴포넌트 (StatsCard + SessionList + Timeline)
 */

import { MonolComponent } from '/design-system/component-base.js';
import { LogsStatsCard } from './stats-card.js';
import { LogsSessionList } from './session-list.js';
import { LogsTimeline } from './timeline.js';

export class LogsOverview extends MonolComponent {
  constructor(container, options = {}) {
    super(container, options);
    this.childComponents = {};
    this.state = {
      loading: true
    };
  }

  async init() {
    this.render();
    await this.initChildComponents();
    this.state.loading = false;
  }

  render() {
    this.container.innerHTML = this.html`
      <div class="logs-overview">
        <div class="overview-header">
          <h2>Session Logs</h2>
          <p class="overview-desc">Track and manage your Claude Code sessions</p>
        </div>
        <div class="overview-grid">
          <div class="overview-section stats-section">
            <div id="logs-stats-container"></div>
          </div>
          <div class="overview-section timeline-section">
            <div id="logs-timeline-container"></div>
          </div>
          <div class="overview-section sessions-section">
            <div id="logs-sessions-container"></div>
          </div>
        </div>
      </div>
    `;
  }

  async initChildComponents() {
    // Initialize Stats Card
    const statsContainer = this.container.querySelector('#logs-stats-container');
    if (statsContainer) {
      this.childComponents.stats = new LogsStatsCard(statsContainer, {
        apiUrl: this.options.statsApiUrl || '/api/logs/stats'
      });
      await this.childComponents.stats.init();
    }

    // Initialize Timeline
    const timelineContainer = this.container.querySelector('#logs-timeline-container');
    if (timelineContainer) {
      this.childComponents.timeline = new LogsTimeline(timelineContainer, {
        apiUrl: this.options.timelineApiUrl || '/api/logs/timeline'
      });
      this.childComponents.timeline.on('event-select', (event) => {
        this.emit('event-select', event);
      });
      await this.childComponents.timeline.init();
    }

    // Initialize Session List
    const sessionsContainer = this.container.querySelector('#logs-sessions-container');
    if (sessionsContainer) {
      this.childComponents.sessions = new LogsSessionList(sessionsContainer, {
        apiUrl: this.options.sessionsApiUrl || '/api/logs/sessions'
      });
      this.childComponents.sessions.on('session-select', (session) => {
        this.emit('session-select', session);
      });
      this.childComponents.sessions.on('session-view', (session) => {
        this.emit('session-view', session);
      });
      this.childComponents.sessions.on('session-resume', (session) => {
        this.emit('session-resume', session);
      });
      await this.childComponents.sessions.init();
    }
  }

  destroy() {
    Object.values(this.childComponents).forEach(comp => {
      if (comp.destroy) comp.destroy();
    });
    this.childComponents = {};
  }
}

// CSS
const style = document.createElement('style');
style.textContent = `
  .logs-overview {
    padding: 0;
  }
  .logs-overview .overview-header {
    margin-bottom: 20px;
  }
  .logs-overview .overview-header h2 {
    font-size: 18px;
    font-weight: 600;
    margin: 0 0 4px 0;
    color: var(--text-primary);
  }
  .logs-overview .overview-desc {
    font-size: 13px;
    color: var(--text-secondary);
    margin: 0;
  }
  .logs-overview .overview-grid {
    display: grid;
    grid-template-columns: 1fr 1fr;
    grid-template-rows: auto auto;
    gap: 16px;
  }
  .logs-overview .stats-section {
    grid-column: 1 / 2;
  }
  .logs-overview .timeline-section {
    grid-column: 2 / 3;
    grid-row: 1 / 3;
  }
  .logs-overview .sessions-section {
    grid-column: 1 / 2;
  }
  @media (max-width: 900px) {
    .logs-overview .overview-grid {
      grid-template-columns: 1fr;
      grid-template-rows: auto;
    }
    .logs-overview .stats-section,
    .logs-overview .timeline-section,
    .logs-overview .sessions-section {
      grid-column: 1;
      grid-row: auto;
    }
  }
`;
document.head.appendChild(style);

export default LogsOverview;
