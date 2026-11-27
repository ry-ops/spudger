# Roadmap

Measured against [ADR-0001](adr/0001-sanctioned-techniques-not-piracy.md): own
hardware, sanctioned tools, no piracy/DRM-circumvention.

## Done

- ✅ Dev Mode + `sdb` access (incl. the `--only-detect-tizen` server fix).
- ✅ Samsung certificate signing (`SamsungTV` profile).
- ✅ **VolumioTV** sideloaded and live: full-screen Volumio UI + remote
  play/pause, next/prev, volume (±/mute), seek (±10 s).

## Now

1. **Scaffold complete** — this repo (`ry-ops/spudger`): README, INSTALL,
   FINDINGS, ADR-0001, and `tools/` scripts encoding the proven recipes.
2. ✅ **Adopted `tizen-agent-skills`** (Samsung, Apache-2.0) — installed **v1.11.0**
   for Claude Code (30 skills + 27 agents in `~/.claude`, 3 PreToolUse guard hooks
   merged into `~/.claude/settings.json`, prior hooks preserved, backups kept).
   Cloned at `~/Projects/tizen-agent-skills`. Loads fully after a session restart.
   Our `tools/` scripts stay as the no-dependency fallback and the documented
   record of the hard-won recipes. **Still to confirm:** point the plugin at the
   existing `~/tizen-studio` (via `~/.tizen.sdk.path.config` / `tizen-sdk-init`)
   and verify its packaging preserves our custom CSP + `tv.inputdevice` keys
   before routing real sideloads through it.

## Next

3. **VolumioTV polish** — whatever the owner wants on-screen (kept intentionally
   simple after the album-art experiment was reverted).
4. **Harden `connect.sh` / `sideload.sh`** — detect DHCP IP changes, auto-handle
   the Allow popup wait, idempotent re-sign.

## Later (owner-choice, clearly non-default)

5. **Boot-into-app / home-screen app** — make the TV boot straight into Volumio.
   Requires persistence beyond a normal sideload.
6. **Root research** — *non-sanctioned track* (would rely on an SVE-class `sdb`
   vuln, not a Samsung tool). Firewalled per ADR-0001: own device only,
   ownership/education only, never piracy/DRM, risks (brick/warranty/volatility)
   stated plainly. Candidates noted: SVE-2025-50109-based tooling, `tizenlite`
   (reported working on Q60D). **Not started.**
7. **Debloat** — only meaningful with persistence/root; same ADR-0001 limits.

## Explicit non-goals

Per ADR-0001: no piracy, no DRM/content-protection circumvention, no attacking
hardware/accounts the operator doesn't own, no redistributing Samsung IP.
