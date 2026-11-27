#!/usr/bin/env bash
# sideload.sh — package, sign, install, and launch a Tizen web app on the TV.
#
# Assumes sdb is already connected (run tools/connect.sh first) and a Samsung
# certificate profile exists (see docs/INSTALL.md).
#
# Usage:  TV_IP=192.0.2.10 CERT_PROFILE=SamsungTV APP=VolumioTV ./tools/sideload.sh
# Env:
#   APP           app dir under repo root            (default VolumioTV)
#   CERT_PROFILE  Samsung security profile name      (default SamsungTV)
#   TV_IP/TV_PORT target                             (from device.local.env; TV_PORT default 26101)
#   TIZEN         path to tizen CLI                  (default ~/tizen-studio/tools/ide/bin/tizen)
#   SDB           path to sdb                        (default ~/tizen-studio/tools/sdb)
#   APP_ID        Tizen app id to launch             (default Volumio123.VolumioTV)
#   WGT           output package name                (default Volumio.wgt)
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
# Load private device config if present (gitignored; see device.example.env).
# shellcheck disable=SC1091
[ -f "$REPO/device.local.env" ] && . "$REPO/device.local.env"

APP="${APP:-VolumioTV}"
CERT_PROFILE="${CERT_PROFILE:-SamsungTV}"
TV_IP="${TV_IP:-}"
TV_PORT="${TV_PORT:-26101}"
[ -n "$TV_IP" ] || { echo "TV_IP not set. Fill device.local.env or pass TV_IP=…" >&2; exit 2; }
TIZEN="${TIZEN:-$HOME/tizen-studio/tools/ide/bin/tizen}"
SDB="${SDB:-$HOME/tizen-studio/tools/sdb}"
APP_ID="${APP_ID:-Volumio123.VolumioTV}"
WGT="${WGT:-Volumio.wgt}"
TARGET="$TV_IP:$TV_PORT"
APP_DIR="$REPO/$APP"

[ -d "$APP_DIR" ] || { echo "app dir not found: $APP_DIR" >&2; exit 1; }
[ -x "$TIZEN" ]   || { echo "tizen CLI not found at $TIZEN" >&2; exit 1; }

echo "== Spudger sideload: $APP -> $TARGET (profile $CERT_PROFILE) =="

if ! "$SDB" devices | grep -q "$TV_IP"; then
  echo "TV not connected. Run: TV_IP=$TV_IP ./tools/connect.sh" >&2
  exit 1
fi

echo "-- package + sign --"
"$TIZEN" package -t wgt -s "$CERT_PROFILE" -- "$APP_DIR"

echo "-- install --"
"$TIZEN" install -n "$WGT" -- "$APP_DIR" -s "$TARGET"

echo "-- launch --"
"$TIZEN" run -p "$APP_ID" -s "$TARGET"

echo "Done. If it launched, '$APP' is live on the TV."
