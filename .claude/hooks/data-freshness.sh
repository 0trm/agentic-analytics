#!/usr/bin/env bash
# SessionStart hook: report which GA4 export data actually exists right now.
#
# The single most common source of wrong analytics answers here is assuming
# today's or yesterday's data is queryable. There is no events_intraday_* table
# and the finalized export lags ~2 days, so a session that starts without this
# line will happily write a query over a window that is partly empty.
#
# Costs nothing: `bq ls` reads table metadata, it does not scan.

PROJECT="your-gcp-project"          # <- your BigQuery project id
DATASET="analytics_XXXXXXXXX"       # <- your GA4 export dataset

command -v bq >/dev/null 2>&1 || exit 0

# `timeout` is GNU coreutils and is absent from a stock macOS, so it is optional here.
TIMEOUT=""
command -v gtimeout >/dev/null 2>&1 && TIMEOUT="gtimeout 10"
command -v timeout  >/dev/null 2>&1 && TIMEOUT="timeout 10"

LATEST=$(
  $TIMEOUT bq --project_id="$PROJECT" ls --max_results=2000 "$DATASET" 2>/dev/null |
    grep -oE 'events_[0-9]{8}' | sort | tail -1
)

[ -z "$LATEST" ] && exit 0

SHARD="${LATEST#events_}"
TODAY=$(date -u +%Y%m%d)

# Day difference, via epoch seconds. BSD date on macOS, GNU date elsewhere.
if date -j >/dev/null 2>&1; then
  S=$(date -j -f %Y%m%d "$SHARD" +%s 2>/dev/null)
  T=$(date -j -f %Y%m%d "$TODAY" +%s 2>/dev/null)
else
  S=$(date -d "$SHARD" +%s 2>/dev/null)
  T=$(date -d "$TODAY" +%s 2>/dev/null)
fi

if [ -n "${S:-}" ] && [ -n "${T:-}" ]; then
  LAG=$(( (T - S) / 86400 ))
  echo "GA4 export: newest finalized shard is ${SHARD} (D-${LAG}). No intraday table exists - anything after ${SHARD} is unqueryable."
else
  echo "GA4 export: newest finalized shard is ${SHARD}. No intraday table exists."
fi
