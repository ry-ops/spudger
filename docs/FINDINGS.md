# Findings

A dated log of what we've learned. Newest obstacle at the bottom of each section.
None of this is re-derivable from a repo or the vendor docs — it was earned.

## The device

- Model **QN43Q60DAFXZA**, 43" QLED. Model code `24_NKL_QTV_T09`.
- **Tizen 9.0**, **armv7 / 32-bit**.
- **DUID** `uuid:<YOUR-TV-DUID>` (needed for the distributor cert).
- wifiMac `<TV-WIFI-MAC>`; IP `10.88.120.241` (DHCP — reconfirm via
  `curl -s http://<ip>:8001/api/v2/`).
- Volumio test target (the Pi): `http://10.88.120.14` (HTTP-only; no mDNS on the
  TV, and the TV auto-upgrades to HTTPS — so always use the explicit
  `http://` + IP).

## USB is a dead end

The TV's USB-A jacks are **host** ports. From a Mac you get host-to-host —
nothing enumerates. Can't read the TV over USB. (A UART tap on the mainboard
was scoped but not attempted.)

## Developer Mode + sdb (the working door)

- Enable: Apps screen → `12345` **on a real/virtual remote** (USB keyboard and
  synthetic WebSocket key injection do NOT trigger it) → Developer mode On →
  Host PC IP = Mac → **cold power-cycle** (standby tap is not enough; sdbd only
  starts on a real boot).
- Connect: `sdb connect <ip>:26101`. First shows **offline** until you **Allow**
  the popup on the TV → then `device`.
- Port probes: use a real socket/curl, NOT bash `/dev/tcp` (false "closed" here).

## Access ceiling (retail, no root)

- `intershell_support:disabled` → **no arbitrary `sdb shell`**.
- `sdbd_rootperm:disabled` → **no root**.
- `filesync` push/pull works but **only inside an app's sandbox** (system paths →
  "You cannot pull files from this path").
- **CAN:** install / launch / debug apps, sandbox file I/O, read REST device info.

## 2024 firmware locks network app-launch

WebSocket `app_list`=0, `open_browser` no-ops, REST `/api/v2/applications/<id>`
all 404. Can't launch apps/browser from the Mac via API. BUT remote **key**
control works via `samsungtvws` (port 8002 + token, Allow once). This is why the
app registers hardware media keys itself rather than being driven from the host.

## Certificates

Generic Tizen cert is **rejected** (`Invalid certificate chain …[118,-12]`). A
**Samsung** author+distributor cert bound to the DUID is required, and creating
it needs the **full GUI IDE** (Certificate Manager is an Eclipse plugin; the
CLI-only install can't do it). Active profile: `SamsungTV` at
`~/SamsungCertificate/SamsungTV/`.

## App packaging gotchas

1. **iframe-embedding Volumio is fine** — Volumio sends no `X-Frame-Options`.
   (An earlier black-screen was a missing app CSP, not Volumio.)
2. A packaged Tizen web app needs an **explicit permissive
   `<tizen:content-security-policy>`** in `config.xml` (default CSP blocks the
   external http load) plus `allow-navigation *` + `access origin *`.
3. Remote media/volume/seek keys need the `tv.inputdevice` privilege and
   `tizen.tvinputdevice.registerKey` per key (register only
   `getSupportedKeys()` entries). Volume keys ARE app-grabbable on this Q60D and
   drive Volumio, not the TV. FF/RW do ±10 s relative seek by reading
   `GET /api/v1/getState` (Volumio sends `Access-Control-Allow-Origin: *`).

## sdb-connect ROOT CAUSE (2026-11-27) — the big one

After a session gap, `sdb connect <ip>:26101` failed **every** time with
`failed to connect to remote target` — but **the TV was 100% healthy**. Proof:

- A hand-crafted raw sdb `A_CNXN` frame to port 26101 gets a valid **authorized**
  banner back: `device::QN43Q60DAFXZA::0` (protocol version `0x02000000`,
  maxdata 262044, no auth challenge). See `tools/probe.py`.
- Ports 26102/9999 correctly refuse → no network proxy/UniFi intercept.
- Mac has one IPv4 = the whitelisted dev host; model string unchanged (no silent
  firmware/protocol bump).

The fault is a **local `sdb`-server MODE bug**:

- A server auto-started as `sdb fork-server server --only-detect-tizen` (the
  default when a client *or the Tizen Studio IDE* spawns it) **fails every
  `connect`**.
- A server started as **plain `sdb nodaemon server`** **connects fine**.
- The **Tizen Studio IDE sabotages this**: while open it holds the server on
  local control port 26099 and instantly respawns a `--only-detect-tizen` server
  whenever one is killed, so a plain server loses the race. `sdb` has **no `-P`**
  to pick a different control port.

**Fix recipe (now in `tools/connect.sh`):** close the IDE → `pkill -9 -f 'sdb
fork-server'` → start a plain `sdb nodaemon server` → `sdb connect` → Allow on
TV → `device`. sdb **version is irrelevant** (4.2.36 is the newest that exists;
4.1.8 / 4.2.19 behave identically — it's the server MODE, not the version).
