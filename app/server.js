'use strict';

const fs = require('fs');
const http = require('http');
const os = require('os');
const path = require('path');

const port = Number(process.env.PORT || 3000);
const appName = process.env.APP_NAME || 'enterprise-3tier-app';
const logDir = process.env.APP_LOG_DIR || '/var/log/enterprise-3tier-app';
const logFile = path.join(logDir, 'application.log');

fs.mkdirSync(logDir, { recursive: true });

function writeLog(level, message, extra = {}) {
  const entry = {
    timestamp: new Date().toISOString(),
    level,
    message,
    appName,
    hostname: os.hostname(),
    ...extra
  };

  const line = JSON.stringify(entry);
  fs.appendFileSync(logFile, `${line}\n`);
  console.log(line);
}

function sendJson(response, statusCode, payload) {
  const body = JSON.stringify(payload);
  response.writeHead(statusCode, {
    'Content-Type': 'application/json',
    'Content-Length': Buffer.byteLength(body)
  });
  response.end(body);
}

const server = http.createServer((request, response) => {
  if (request.url === '/health') {
    writeLog('INFO', 'Health check succeeded', { path: request.url, method: request.method });
    sendJson(response, 200, { status: 'ok', appName, uptimeSeconds: Math.floor(process.uptime()) });
    return;
  }

  if (request.url === '/' || request.url === '/index.html') {
    writeLog('INFO', 'Served landing page', { path: request.url, method: request.method });
    sendJson(response, 200, {
      status: 'running',
      appName,
      hostname: os.hostname(),
      timestamp: new Date().toISOString()
    });
    return;
  }

  writeLog('WARN', 'Route not found', { path: request.url, method: request.method });
  sendJson(response, 404, { error: 'not_found' });
});

server.keepAliveTimeout = 65000;
server.headersTimeout = 66000;

server.listen(port, '0.0.0.0', () => {
  writeLog('INFO', 'Application started', { port, environment: process.env.NODE_ENV || 'production' });
});

process.on('SIGTERM', () => {
  writeLog('INFO', 'Received SIGTERM, shutting down');
  server.close(() => process.exit(0));
});

process.on('SIGINT', () => {
  writeLog('INFO', 'Received SIGINT, shutting down');
  server.close(() => process.exit(0));
});
