// monol-logs - Claude Code plugin for session management
// This file is the main entry point for programmatic use

const path = require('path');
const packageJson = require('./package.json');

module.exports = {
  name: packageJson.name,
  version: packageJson.version,
  description: packageJson.description,

  // Plugin directory paths
  paths: {
    root: __dirname,
    marketplace: path.join(__dirname, 'marketplace.json'),
    plugin: path.join(__dirname, 'monol-logs-pkg'),
    skills: path.join(__dirname, 'monol-logs-pkg', 'skills'),
    hooks: path.join(__dirname, 'monol-logs-pkg', 'hooks'),
    lib: path.join(__dirname, 'monol-logs-pkg', 'lib'),
  }
};
