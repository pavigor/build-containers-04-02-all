#!/bin/bash

postgres_pid=0
java_pid=0

trap signal_handler SIGTERM SIGKILL SIGINT

function log() {
  echo "$(date +"%Y-%m-%d %H:%M:%S %Z") $1"
}

function signal_handler() {
  log "Stopping container..."
  if [ "$java_pid" -ne 0 ]; then
    log "Stopping application..."
    kill "$java_pid"
    wait "$java_pid" > /dev/null 2>&1
    log "Application was stopped"
  fi
  if [ "$postgres_pid" -ne 0 ]; then
    log "Stopping postgres..."
    kill "$postgres_pid"
    wait "$postgres_pid" > /dev/null 2>&1
  fi
  log "Done"
  exit 143
}

# Init postgres
function init_db() {
  docker-entrypoint.sh postgres &  > /dev/null 2>&1
  postgres_pid="$!"
  while ! pg_isready -d "$POSTGRES_DB"; do sleep 10s ; done
}

# Run application
function main() {
  init_db
  java -jar /app.jar &
  java_pid="$!"
}

main

tail -f /dev/null &
wait ${!}