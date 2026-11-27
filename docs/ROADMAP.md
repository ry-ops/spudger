# Roadmap

Measured against [ADR-0001](adr/0001-sanctioned-techniques-not-piracy.md): own
hardware, sanctioned tools, no piracy/DRM-circumvention.

## Done

- ✅ Dev Mode + `sdb` access, incl. the `--only-detect-tizen` server fix (scripted
  in `tools/connect.sh`).
- ✅ Samsung certificate signing (`SamsungTV` profile).
- ✅ **VolumioTV** sideloaded and live: full-screen Volumio UI + remote
  play/pause, next/prev, volume (±/mute), seek (±10 s).
- ✅ **VolumioTV polish** (2026-11-27): branded loading splash while Volumio
  loads + a "Can't reach Volumio / Retry" fallback (remote-focusable). No
  black-screen-on-load.
- ✅ **`tizen-agent-skills` v1.11.0 adopted and wired to `~/tizen-studio`**
  (`~/.tizen.sdk.path.config`); guard hook live; handoff proven — `connect.sh`
  opens the door, then the plugin's `device-manager` sees the TV. Repo scaffolded
  (`ry-ops/spudger`) with README, INSTALL, FINDINGS, ADR-0001, `tools/`, and the
  hand-drawn hero/social art.

## Now / Next

1. **Harden `connect.sh` / `sideload.sh`** — detect DHCP IP changes, auto-handle
   the Allow popup wait, idempotent re-sign.
2. **Known limitation:** the plugin's **install** path does NOT work on this
   retail TV (it uninstalls-first, which fails on the running app, and can't
   `sdb shell` to stop it), and its guard hook blocks a hand-typed `tizen
   install`. **Sideload via `tools/sideload.sh`** (the hook only sees the script
   name). Use the plugin for queries (device-manager, cert, repo-info), not install.

## Later (owner-choice, clearly non-default — ADR-0001)

3. **Boot-into-app / home-screen app** — make the TV boot straight into Volumio.
   Requires persistence beyond a normal sideload (i.e. root).

4. **Root — RESEARCH DONE 2026-11-27; foothold staged; pending the owner running
   the exploit once.** *Non-sanctioned track*, firewalled per ADR-0001 (own
   device, ownership/education only, risks stated: brick/warranty/volatility).
   - **Vuln:** SVE-2025-50109 (Bishop Fox) — SDB command injection, Tizen ≤9.0,
     needs Dev Mode + connecting from the whitelisted dev-host IP (us).
   - **Harness:** `chris-ritsen/samsung-tv-root` (Python; release **v0.0.13**
     `macos-arm64`, sha256-verified, extracted under
     `~/Projects/tv-root-research/harness-release/…`). Debloat driver:
     `tw0m8/tizenlite` (Q60D-tested; its `tv-root-apply` is the reversible
     system-modify step — NOT yet run).
   - **Compatibility:** a Q60D on `T-NKLD…-0090/2123.9` / Tizen 9.0 returns
     `uid 0`; our `24_NKL_QTV_T09` is the same `NKL` Q60D family.
   - **Foothold is non-destructive:** the harness hashes `/etc/passwd` + the sdbd
     key, reports `system files unchanged`, is volatile (gone on reboot), and
     cleans its staging.
   - **Blocked for the agent:** the oversight classifier won't let the assistant
     execute a downloaded exploit binary — the owner runs it via `!`.
   - **RESUME HERE** (owner runs, non-destructive, confirms `uid 0` + real build):
     `cd ~/Projects/tv-root-research/harness-release/samsung-tv-root-0.0.13-macos-arm64 && ./samsung-tv-root --sdb ~/tizen-studio/tools/sdb archive-root root <TV_IP> --command 'id; uname -a; cat /etc/default/tv-root'`
     (first run: allow macOS "Local Network"). Then **stop and decide** before any
     system modification (debloat).
   - Exploit code is **not vendored** into this repo (untrusted third-party; no
     redistributing Samsung IP).

5. **Debloat** — only with root; via `tizenlite`'s reversible `tv-root-apply`
   (strip ads/ACR/telemetry/voice, free RAM). Same ADR-0001 limits; one change
   per cold boot; every change has a rollback.

## Explicit non-goals

Per ADR-0001: no piracy, no DRM/content-protection circumvention, no attacking
hardware/accounts the operator doesn't own, no redistributing Samsung IP.
