/**
 * Logs Timeline Component
 * 타임라인 시각화 컴포넌트
 */

import { MonolComponent } from '/design-system/component-base.js';

export class LogsTimeline extends MonolComponent {
  constructor(container, options = {}) {
    super(container, options);
    this.authorColors = {};
    this.colorPalette = [
      '#39C5CF', '#FF6B6B', '#4ECDC4', '#FFE66D',
      '#95E1D3', '#F38181', '#AA96DA', '#FCBAD3'
    ];
    this.state = {
      events: options.events || [],
      view: 'day', // day, week, month
      loading: true
    };
  }

  async init() {
    if (this.options.apiUrl) {
      await this.fetchEvents();
    } else {
      this.state.events = this.getMockEvents();
    }
    this.assignAuthorColors();
    this.state.loading = false;
    this.render();
  }

  getMockEvents() {
    return [
      { id: 1, author: 'alice', topic: 'login-feature', date: '2026-01-19', time: '14:30', duration: 120 },
      { id: 2, author: 'bob', topic: 'api-refactor', date: '2026-01-19', time: '09:15', duration: 90 },
      { id: 3, author: 'alice', topic: 'bug-fix-auth', date: '2026-01-18', time: '16:45', duration: 45 },
      { id: 4, author: 'charlie', topic: 'performance', date: '2026-01-18', time: '11:00', duration: 180 },
      { id: 5, author: 'alice', topic: 'ui-redesign', date: '2026-01-17', time: '08:30', duration: 240 },
      { id: 6, author: 'bob', topic: 'database-migration', date: '2026-01-17', time: '14:00', duration: 75 },
      { id: 7, author: 'charlie', topic: 'docs-update', date: '2026-01-16', time: '10:00', duration: 30 },
      { id: 8, author: 'alice', topic: 'testing', date: '2026-01-16', time: '15:30', duration: 60 }
    ];
  }

  async fetchEvents() {
    try {
      const response = await fetch(this.options.apiUrl);
      this.state.events = await response.json();
    } catch (error) {
      console.error('Failed to fetch timeline events:', error);
      this.state.events = this.getMockEvents();
    }
  }

  assignAuthorColors() {
    const authors = [...new Set(this.state.events.map(e => e.author))];
    authors.forEach((author, i) => {
      this.authorColors[author] = this.colorPalette[i % this.colorPalette.length];
    });
  }

  getGroupedEvents() {
    const grouped = {};
    this.state.events.forEach(event => {
      if (!grouped[event.date]) {
        grouped[event.date] = [];
      }
      grouped[event.date].push(event);
    });
    // Sort by date descending
    return Object.entries(grouped)
      .sort((a, b) => new Date(b[0]) - new Date(a[0]));
  }

  render() {
    const { loading, view } = this.state;
    const grouped = this.getGroupedEvents();
    const authors = Object.keys(this.authorColors);

    if (loading) {
      this.container.innerHTML = this.html`
        <div class="logs-timeline loading">
          <div class="loading-spinner"></div>
        </div>
      `;
      return;
    }

    this.container.innerHTML = this.html`
      <div class="logs-timeline">
        <div class="timeline-header">
          <h3>Activity Timeline</h3>
          <div class="timeline-controls">
            <div class="view-toggle">
              <button class="view-btn ${view === 'day' ? 'active' : ''}" data-view="day">Day</button>
              <button class="view-btn ${view === 'week' ? 'active' : ''}" data-view="week">Week</button>
              <button class="view-btn ${view === 'month' ? 'active' : ''}" data-view="month">Month</button>
            </div>
          </div>
        </div>
        <div class="timeline-legend">
          ${authors.map(author => `
            <div class="legend-item">
              <span class="legend-color" style="background: ${this.authorColors[author]}"></span>
              <span class="legend-name">${author}</span>
            </div>
          `).join('')}
        </div>
        <div class="timeline-content">
          ${grouped.map(([date, events]) => this.renderDateGroup(date, events)).join('')}
        </div>
      </div>
    `;

    this.bindEvents();
  }

  renderDateGroup(date, events) {
    const dayName = new Date(date).toLocaleDateString('en-US', { weekday: 'short' });
    const formattedDate = new Date(date).toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
    const isToday = date === new Date().toISOString().split('T')[0];

    return this.html`
      <div class="timeline-day ${isToday ? 'today' : ''}">
        <div class="day-header">
          <span class="day-name">${dayName}</span>
          <span class="day-date">${formattedDate}</span>
          ${isToday ? '<span class="today-badge">Today</span>' : ''}
        </div>
        <div class="day-events">
          ${events.map(e => this.renderEvent(e)).join('')}
        </div>
      </div>
    `;
  }

  renderEvent(event) {
    const color = this.authorColors[event.author];
    const durationStr = event.duration >= 60
      ? `${Math.floor(event.duration / 60)}h ${event.duration % 60}m`
      : `${event.duration}m`;

    return this.html`
      <div class="timeline-event" data-id="${event.id}" style="--author-color: ${color}">
        <div class="event-time">${event.time}</div>
        <div class="event-connector"></div>
        <div class="event-card">
          <div class="event-header">
            <span class="event-topic">${event.topic}</span>
            <span class="event-duration">${durationStr}</span>
          </div>
          <div class="event-author">@${event.author}</div>
        </div>
      </div>
    `;
  }

  bindEvents() {
    // View toggle
    this.container.querySelectorAll('.view-btn').forEach(btn => {
      btn.addEventListener('click', () => {
        this.state.view = btn.dataset.view;
        this.render();
      });
    });

    // Event click
    this.container.querySelectorAll('.timeline-event').forEach(el => {
      el.addEventListener('click', () => {
        const id = parseInt(el.dataset.id);
        const event = this.state.events.find(e => e.id === id);
        this.emit('event-select', event);
      });
    });
  }
}

// CSS
const style = document.createElement('style');
style.textContent = `
  .logs-timeline {
    background: var(--bg-secondary);
    border: 1px solid var(--border-color);
    border-radius: var(--radius-md, 8px);
    padding: 16px;
  }
  .logs-timeline.loading {
    display: flex;
    justify-content: center;
    align-items: center;
    min-height: 300px;
  }
  .logs-timeline .loading-spinner {
    width: 24px;
    height: 24px;
    border: 2px solid var(--border-color);
    border-top-color: var(--accent-cyan);
    border-radius: 50%;
    animation: spin 1s linear infinite;
  }
  .logs-timeline .timeline-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 12px;
  }
  .logs-timeline .timeline-header h3 {
    font-size: 14px;
    font-weight: 600;
    margin: 0;
  }
  .logs-timeline .view-toggle {
    display: flex;
    gap: 4px;
    background: var(--bg-tertiary);
    padding: 2px;
    border-radius: 6px;
  }
  .logs-timeline .view-btn {
    padding: 4px 12px;
    border: none;
    background: none;
    border-radius: 4px;
    font-size: 12px;
    cursor: pointer;
    color: var(--text-secondary);
    transition: all 0.2s;
  }
  .logs-timeline .view-btn:hover {
    color: var(--text-primary);
  }
  .logs-timeline .view-btn.active {
    background: var(--accent-cyan);
    color: #000;
  }
  .logs-timeline .timeline-legend {
    display: flex;
    gap: 16px;
    padding: 8px 0;
    margin-bottom: 12px;
    border-bottom: 1px solid var(--border-color);
  }
  .logs-timeline .legend-item {
    display: flex;
    align-items: center;
    gap: 6px;
  }
  .logs-timeline .legend-color {
    width: 10px;
    height: 10px;
    border-radius: 50%;
  }
  .logs-timeline .legend-name {
    font-size: 12px;
    color: var(--text-secondary);
  }
  .logs-timeline .timeline-content {
    display: flex;
    flex-direction: column;
    gap: 16px;
    max-height: 400px;
    overflow-y: auto;
  }
  .logs-timeline .timeline-day {
    display: flex;
    flex-direction: column;
    gap: 8px;
  }
  .logs-timeline .timeline-day.today .day-header {
    color: var(--accent-cyan);
  }
  .logs-timeline .day-header {
    display: flex;
    align-items: center;
    gap: 8px;
    padding-bottom: 4px;
    border-bottom: 1px dashed var(--border-color);
  }
  .logs-timeline .day-name {
    font-weight: 600;
    font-size: 12px;
  }
  .logs-timeline .day-date {
    font-size: 12px;
    color: var(--text-secondary);
  }
  .logs-timeline .today-badge {
    font-size: 10px;
    padding: 2px 6px;
    background: var(--accent-cyan);
    color: #000;
    border-radius: 4px;
  }
  .logs-timeline .day-events {
    display: flex;
    flex-direction: column;
    gap: 6px;
    padding-left: 8px;
  }
  .logs-timeline .timeline-event {
    display: flex;
    align-items: center;
    gap: 8px;
    cursor: pointer;
  }
  .logs-timeline .event-time {
    font-size: 11px;
    color: var(--text-secondary);
    min-width: 40px;
    font-family: monospace;
  }
  .logs-timeline .event-connector {
    width: 8px;
    height: 8px;
    background: var(--author-color);
    border-radius: 50%;
    flex-shrink: 0;
  }
  .logs-timeline .event-card {
    flex: 1;
    padding: 8px 12px;
    background: var(--bg-tertiary);
    border-left: 3px solid var(--author-color);
    border-radius: 4px;
    transition: all 0.2s;
  }
  .logs-timeline .timeline-event:hover .event-card {
    background: rgba(57, 197, 207, 0.05);
  }
  .logs-timeline .event-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
  }
  .logs-timeline .event-topic {
    font-size: 12px;
    font-weight: 500;
  }
  .logs-timeline .event-duration {
    font-size: 10px;
    color: var(--text-secondary);
  }
  .logs-timeline .event-author {
    font-size: 11px;
    color: var(--author-color);
    margin-top: 2px;
  }
`;
document.head.appendChild(style);

export default LogsTimeline;
