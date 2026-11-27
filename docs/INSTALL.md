# Install everything Spudger needs

This is the complete setup to go from a bare Mac to sideloading a signed app on
a Samsung Tizen TV. It reflects what actually worked (hard-won — see
[`FINDINGS.md`](FINDINGS.md)); it is not the Samsung happy-path docs.

Platform used: Apple Silicon macOS. Linux/Windows differ mainly in the Tizen
Studio installer and paths.

---

## 0a. Your device values (private)

Device-identifying values are **never committed**. Create your private copies:

```bash
cp device.example.env device.local.env            # DUID, Wi-Fi MAC, LAN IPs, cert profile
cp VolumioTV/config.example.js VolumioTV/config.js # the app's Volumio URL
```

Edit both with your own values (read DUID/MAC/IP from
`curl -s http://<TV_IP>:8001/api/v2/`). Both files are gitignored; `config.js`
is still bundled into the `.wgt` so the app works. The `tools/` scripts source
`device.local.env` automatically.

## 0. Prerequisites

| Need | Why | Install |
| --- | --- | --- |
| **Node.js 22+** | Required by `tizen-agent-skills` runners (future backbone). User default is Node 24. | `brew install node` or nvm |
| **Git** | Clone tooling. | `brew install git` / Xcode CLT |
| **A Samsung account** | Required to issue the distributor certificate bound to the TV's DUID. | https://account.samsung.com |
| **~15 GB free** | Tizen Studio + TV extension + (optional) SDK installed by the skills. | — |

---

## 1. Tizen Studio toolchain (REQUIRED)

> ⚠️ The **CLI-only** `web-cli` package **cannot create a Samsung certificate** —
> Certificate Manager is an Eclipse IDE plugin. You must install the **full GUI
> IDE** at least once. This cost us a whole detour; don't skip it.

1. Download the GUI installer (`web-ide_Tizen_SDK_10.0_macos-64.dmg`, ~699 MB)
   from `http://download.tizen.org/sdk/Installer/tizen-sdk_10.0/`.
2. Run it; install to `~/tizen-studio` (merges with any existing CLI install).
3. This brings the IDE, a working Package Manager, **Certificate Manager**, and:
   - `~/tizen-studio/tools/sdb` — Samsung Debug Bridge (CLI), v4.2.36.
   - `~/tizen-studio/tools/ide/bin/tizen` — the `tizen` packaging CLI.
4. Install the **Samsung Certificate Extension** if not already active:
   Package Manager → Extension SDK → "Samsung Certificate Extension"
   (repo already registered: `tizen-certificate-extension_2.0.75`).
5. Install the **TV extension / Samsung TV platform** (for TV targets): Package
   Manager → Extension SDK.

Verify:

```bash
~/tizen-studio/tools/sdb version                 # Smart Development Bridge 4.2.36
~/tizen-studio/tools/ide/bin/tizen version
```

---

## 2. Samsung certificate (interactive — you do this in the GUI)

A generic Tizen cert is **rejected** by retail TVs
(`Invalid certificate chain`). You need a Samsung author + distributor cert
bound to the TV's **DUID**.

In **Certificate Manager**:

1. Create a **Samsung** certificate profile (we named ours `SamsungTV`).
2. **Author certificate** → sign in with your Samsung account (OAuth, likely 2FA).
3. **Distributor certificate** → add the TV's DUID (find it via
   `curl -s http://<TV_IP>:8001/api/v2/` → `duid`).
4. It activates a security profile — note its **name**; `tools/sideload.sh`
   passes it to `tizen package -s <profile>`.

Material lands in `~/SamsungCertificate/<profile>/{author,distributor}.p12`.
**Never commit these** (see `.gitignore`).

---

## 3. Put the TV in Developer Mode

See [`RUNBOOK.md`](../RUNBOOK.md) for the full dance. Short version:

1. TV **Apps** screen → type **`12345`** on a *real/virtual remote* (a USB
   keyboard or synthetic key injection will NOT trigger it).
2. Developer mode **On**; **Host PC IP** = this Mac's IP.
3. **Cold power-cycle** the TV (unplug ~15–20 s). sdbd only arms on a real boot.

---

## 4. Connect (use the script — it encodes the hard-won fix)

```bash
TV_IP=192.0.2.10 ./tools/connect.sh
```

> Why a script: the Tizen Studio **IDE respawns `sdb` in a broken
> `--only-detect-tizen` mode** that fails every `connect`. The fix is to close
> the IDE and run a plain `sdb nodaemon server`. `connect.sh` does this for you.
> Full diagnosis in [`FINDINGS.md`](FINDINGS.md).

Expect `sdb devices` to show `… device  QN43Q60DAFXZA`. If it shows `offline`,
press **Allow** on the TV popup.

---

## 5. Sideload

```bash
TV_IP=192.0.2.10 CERT_PROFILE=SamsungTV APP=VolumioTV ./tools/sideload.sh
```

This packages → signs → installs → launches. Success ends with
`Tizen application is successfully launched.`

---

## Forward-looking: Samsung `tizen-agent-skills` (optional backbone)

Samsung's official, Apache-2.0 agent tooling (30 skills / 36 commands) can drive
SDK install, build, device management, **cert signing**, and sideload for you —
with **Claude Code as a first-class host**. We are evaluating it as a maintained
replacement for the scripts in `tools/`.

Repo: https://github.com/Samsung/tizen-agent-skills

**Before installing, know:** the Claude Code setup **merges three PreToolUse
guard hooks into `~/.claude/settings.json`** and drops skills in `~/.claude`.
Its guard hooks also want `config.xml` generated from *its* templates and `sdb`
routed through *its* runner. We must confirm its templates preserve our custom
CSP + `tv.inputdevice` keys, and point it at the existing `~/tizen-studio`,
**before** letting it touch `~/.claude`. Trial it in isolation first.

Install (when we decide to): clone and run the Claude Code setup —

```bash
git clone https://github.com/Samsung/tizen-agent-skills.git
cd tizen-agent-skills/tizen-sdk-skills
bash claude/setup/setup.sh          # merges hooks into ~/.claude/settings.json
# then restart the Claude Code session
```

Standalone CLI (no AI assistant, JSON output — good for CI):

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Samsung/tizen-agent-skills/main/tizen-sdk-skills/common/setup/setup-tizen-sdk.sh)
tizen-sdk --doctor
```
