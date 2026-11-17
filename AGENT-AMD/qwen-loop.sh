#!/usr/bin/env bash
set -u

ROOT="$(cd "$(dirname "$0")" && pwd)"
LOG="$ROOT/qwen-loop.log"

if ! command -v qwen >/dev/null 2>&1; then
  echo "ERRORE: comando 'qwen' non installato."
  echo "Installa: npm install -g @qwen-code/qwen-code@latest"
  exit 1
fi

if [ -z "${OPENAI_API_KEY:-}" ]; then
  echo "ERRORE: OPENAI_API_KEY non impostata."
  echo "Imposta la chiave API Qwen/DashScope nell'ambiente."
  exit 1
fi

while :; do
  LATEST=$(ls -t "$ROOT"/*.md "$ROOT"/*.txt 2>/dev/null | head -n 1)

  if [ -z "$LATEST" ]; then
    sleep 10
    continue
  fi

  {
    printf '\n## Ciclo — %s\n' "$(date '+%Y-%m-%d %H:%M:%S')"
    printf 'File passato: %s\n' "$LATEST"
  } >> "$LOG"

  qwen -p "Sei il controller del loop T27. Leggi il file $LATEST. Assegna un solo incarico read-only verificabile, oppure rispondi STOP con motivazione. Non modificare file." \
    --include-directories "$ROOT" \
    --exclude-tools shell,write,edit \
    --approval-mode yolo \
    --max-tool-calls 25 \
    --max-wall-time 10m \
    >> "$LOG" 2>&1

  sleep 15
done
