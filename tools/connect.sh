#!/usr/bin/env bash
# connect.sh — connect sdb to a Samsung Tizen TV, reliably.
#
# Encodes the hard-won fix (see docs/FINDINGS.md): the Tizen Studio IDE respawns
# sdb in a broken `--only-detect-tizen` mode that fails every connect. We close
# the IDE, kill stray servers, start a PLAIN `sdb nodaemon server`, then connect.
#
# Usage:   TV_IP=10.88.120.241 ./tools/connect.sh
# Env:
#   TV_IP      TV address            (default 10.88.120.241)
#   TV_PORT    sdb port              (default 26101)
#   SDB        path to sdb           (default ~/tizen-studio/tools/sdb)
#   KEEP_IDE   set to 1 to NOT close Tizen Studio (then connect may fail)
set -euo pipefail

TV_IP="${TV_IP:-10.88.120.241}"
TV_PORT="${TV_PORT:-26101}"
SDB="${SDB:-$HOME/tizen-studio/tools/sdb}"
TARGET="$TV_IP:$TV_PORT"

[ -x "$SDB" ] || { echo "sdb not found/executable at $SDB" >&2; exit 1; }

echo "== Spudger connect -> $TARGET =="

if [ "${KEEP_IDE:-0}" != "1" ]; then
  if pgrep -f 'TizenStudio.app|org.eclipse|eclipse' >/dev/null 2>&1; then
    echo "-- closing Tizen Studio IDE (it respawns a broken sdb server) --"
    pkill -f 'TizenStudio.app' 2>/dev/null || true
    pkill -f 'org.eclipse'     2>/dev/null || true
    pkill -f 'eclipse'         2>/dev/null || true
    sleep 2
  fi
fi

echo "-- clearing stray sdb servers --"
pkill -9 -f 'sdb fork-server' 2>/dev/null || true
pkill -9 -f 'sdb nodaemon'    2>/dev/null || true
sleep 1

echo "-- starting PLAIN sdb server (nodaemon) --"
nohup "$SDB" nodaemon server >/tmp/spudger-sdb.log 2>&1 &
disown || true
sleep 2

echo "-- connecting --"
"$SDB" connect "$TARGET" || true
sleep 2

echo "-- devices --"
"$SDB" devices

if "$SDB" devices | grep -q "$TV_IP"; then
  state=$("$SDB" devices | awk -v ip="$TV_IP" '$0 ~ ip {print $2}')
  if [ "$state" = "device" ]; then
    echo "OK: connected ($state)."
  elif [ "$state" = "offline" ]; then
    echo "NOTE: device is OFFLINE — press ALLOW on the TV popup, then re-run or:"
    echo "      $SDB connect $TARGET"
  else
    echo "NOTE: device state = '$state'."
  fi
else
  cat <<EOF
FAILED to connect. Checklist:
  1) TV reachable?   curl -s http://$TV_IP:8001/api/v2/ | head -c 80
  2) sdbd healthy?   python3 tools/probe.py $TV_IP
  3) Dev Mode on + Host PC IP = this Mac, and did you COLD power-cycle the TV?
  4) Is Tizen Studio still open respawning the bad server? (re-run without KEEP_IDE)
EOF
  exit 1
fi
