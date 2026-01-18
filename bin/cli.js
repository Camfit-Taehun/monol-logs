#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

const packageJson = require('../package.json');

const args = process.argv.slice(2);
const command = args[0];

function showHelp() {
  console.log(`
monol-logs v${packageJson.version}
Claude Code plugin for session management

Usage:
  monol-logs [command]

Commands:
  --version, -v    Show version
  --help, -h       Show this help
  --status         Check installation status
  --reinstall      Reinstall the plugin

Inside Claude Code:
  /branch          Session branching with git worktree
  /sessions        List archived sessions
  /roadmap         Extract TODOs from sessions
  /summary         Generate AI summaries
  /save            Manual session save

More info: https://github.com/Camfit-Taehun/monol-logs
`);
}

function showVersion() {
  console.log(`monol-logs v${packageJson.version}`);
}

function checkStatus() {
  const os = require('os');
  const settingsPath = path.join(os.homedir(), '.claude', 'settings.json');

  if (!fs.existsSync(settingsPath)) {
    console.log('❌ Claude Code settings not found');
    return;
  }

  const settings = JSON.parse(fs.readFileSync(settingsPath, 'utf8'));
  const isEnabled = settings.enabledPlugins?.['monol-logs@monol'];
  const hasMarketplace = settings.extraKnownMarketplaces?.monol;

  console.log(`
monol-logs status:
  Marketplace registered: ${hasMarketplace ? '✅' : '❌'}
  Plugin enabled: ${isEnabled ? '✅' : '❌'}
  Package location: ${path.resolve(__dirname, '..')}
`);
}

function reinstall() {
  require('../scripts/install.js');
}

switch (command) {
  case '--version':
  case '-v':
    showVersion();
    break;
  case '--help':
  case '-h':
  case undefined:
    showHelp();
    break;
  case '--status':
    checkStatus();
    break;
  case '--reinstall':
    reinstall();
    break;
  default:
    console.log(`Unknown command: ${command}`);
    showHelp();
    process.exit(1);
}
