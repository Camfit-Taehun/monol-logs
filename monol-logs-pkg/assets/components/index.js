/**
 * Logs Components Index
 */

export { LogsStatsCard } from './stats-card.js';
export { LogsSessionList } from './session-list.js';
export { LogsTimeline } from './timeline.js';
export { LogsOverview } from './overview.js';

import { ComponentRegistry } from '/design-system/component-base.js';
import { LogsStatsCard } from './stats-card.js';
import { LogsSessionList } from './session-list.js';
import { LogsTimeline } from './timeline.js';
import { LogsOverview } from './overview.js';

ComponentRegistry.register('logs-stats-card', LogsStatsCard);
ComponentRegistry.register('logs-session-list', LogsSessionList);
ComponentRegistry.register('logs-timeline', LogsTimeline);
ComponentRegistry.register('logs-overview', LogsOverview);
