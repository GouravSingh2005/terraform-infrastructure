#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

APP_NAME="${app_name}"
APP_PORT="${app_port}"
APP_DIR="/opt/${app_name}"
APP_USER="ec2-user"
APP_GROUP="ec2-user"
APP_LOG_DIR="/var/log/${app_name}"
USER_DATA_LOG="/var/log/user-data.log"
CW_AGENT_CONFIG="/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json"
CW_APP_LOG_GROUP="${cloudwatch_application_log_group}"
CW_USERDATA_LOG_GROUP="${cloudwatch_userdata_log_group}"
AWS_REGION="${aws_region}"

mkdir -p "$APP_DIR" "$APP_LOG_DIR"
touch "$USER_DATA_LOG" "$APP_LOG_DIR/application.log"
chown -R "$APP_USER:$APP_GROUP" "$APP_DIR" "$APP_LOG_DIR"
chmod 0640 "$USER_DATA_LOG" "$APP_LOG_DIR/application.log"

exec > >(tee -a "$USER_DATA_LOG") 2>&1

log() {
  printf '%s [%s] %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$1" "$2"
}

retry() {
  local attempts=0
  local max_attempts=5
  local delay=5

  until "$@"; do
    attempts=$((attempts + 1))
    if [[ "$attempts" -ge "$max_attempts" ]]; then
      log ERROR "Command failed after $max_attempts attempts: $*"
      return 1
    fi
    log WARN "Command failed, retrying in $delay seconds: $*"
    sleep "$delay"
  done
}

log INFO "Starting bootstrap for $APP_NAME"

retry yum update -y
retry yum install -y curl git jq unzip amazon-cloudwatch-agent

if ! command -v node >/dev/null 2>&1; then
  log INFO "Installing Node.js 20"
  retry curl -fsSL https://rpm.nodesource.com/setup_20.x -o /tmp/nodesource_setup.sh
  bash /tmp/nodesource_setup.sh
  retry yum install -y nodejs
fi

cat > "$APP_DIR/package.json" <<'EOF'
{
  "name": "enterprise-3tier-app",
  "version": "1.0.0",
  "private": true,
  "description": "Minimal Node.js application for a production-style Terraform deployment",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  }
}
EOF

cat > "$APP_DIR/server.js" <<'EOF'
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
  fs.appendFileSync(logFile, line + '\n');
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
  const requestStartedAt = Date.now();

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

EOF

cat > /etc/systemd/system/$APP_NAME.service <<EOF
[Unit]
Description=$APP_NAME service
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=$APP_USER
Group=$APP_GROUP
WorkingDirectory=$APP_DIR
Environment=NODE_ENV=production
Environment=PORT=$APP_PORT
Environment=APP_NAME=$APP_NAME
Environment=APP_LOG_DIR=$APP_LOG_DIR
ExecStart=/usr/bin/node $APP_DIR/server.js
Restart=always
RestartSec=5
StartLimitIntervalSec=0
NoNewPrivileges=true
ProtectSystem=full
ProtectHome=true
PrivateTmp=true
ReadWritePaths=$APP_DIR $APP_LOG_DIR

[Install]
WantedBy=multi-user.target
EOF

cat > "$CW_AGENT_CONFIG" <<EOF
{
  "agent": {
    "region": "$AWS_REGION"
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "$USER_DATA_LOG",
            "log_group_name": "$CW_USERDATA_LOG_GROUP",
            "log_stream_name": "{instance_id}/user-data",
            "timestamp_format": "%Y-%m-%dT%H:%M:%SZ"
          },
          {
            "file_path": "$APP_LOG_DIR/application.log",
            "log_group_name": "$CW_APP_LOG_GROUP",
            "log_stream_name": "{instance_id}/application",
            "timestamp_format": "%Y-%m-%dT%H:%M:%SZ"
          }
        ]
      }
    }
  }
}
EOF

retry /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:"$CW_AGENT_CONFIG" -s

systemctl daemon-reload
systemctl enable --now "$APP_NAME.service"

log INFO "Bootstrap complete for $APP_NAME on port $APP_PORT"
