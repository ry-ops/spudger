# Samsung TV sideload — runbook

Target: **Samsung QN43Q60DAFXZA**, Tizen 9. Local development only.

## Known-good facts
- TV IP: `10.88.120.241` (DHCP — reconfirm via `curl -s http://<ip>:8001/api/v2/`).
- Mac (host PC) IP: `10.88.120.97`.
- **DUID** (needed for the distributor cert): `uuid:<YOUR-TV-DUID>`.
- Toolchain: `~/tizen-studio/tools/sdb`, `~/tizen-studio/tools/ide/bin/tizen`.
- App source: `VolumioTV/` here. Pre-built package: `Volumio.wgt` here.
  - It loads `http://volumio.local/` then falls back to `http://10.88.120.14/` (the IP+HTTP combo that actually works — the TV has no mDNS and auto-upgrades to HTTPS, which Volumio refuses).

## Current blocker
Generic Tizen cert is **rejected** by the TV:
`install failed[118,-12]: Invalid certificate chain with certificate in signature.`
A **Samsung** author+distributor certificate bound to the DUID is required. The CLI-only
Tizen Studio install has no extension catalog ("No extension server exists"), so the
**Samsung Certificate Extension** must be added first.

## Final mile

### 1. Reconnect to the TV
```bash
SDB=~/tizen-studio/tools/sdb
$SDB connect 10.88.120.241:26101      # Allow the popup on the TV -> state goes offline -> device
$SDB devices                          # expect: 10.88.120.241:26101  device  QN43Q60DAFXZA
```
If 26101 refuses: Dev Mode may have reset — re-enable (Apps -> 12345 -> On -> Host PC IP 10.88.120.97 -> **cold power-cycle**).

### 2. Install the full Tizen Studio GUI IDE (REQUIRED for the cert)
The Certificate Manager is an Eclipse IDE plugin — the CLI-only install CANNOT create a
Samsung cert (verified: cert-add-on is just a plugin jar needing the IDE's Eclipse base).
- Installer: `~/Downloads/web-ide_Tizen_SDK_10.0_macos-64.dmg` (~699 MB).
- Double-click the dmg -> run the GUI installer -> install to `~/tizen-studio` (merges with the
  existing CLI install). Brings the IDE + working Package Manager + Certificate Manager.
- The Samsung Certificate Extension server is ALREADY registered (`package-manager-cli extra --list`
  shows index 1 -> tizen-certificate-extension_2.0.75). If not active after install:
  Package Manager -> Extension SDK -> install "Samsung Certificate Extension".

### 3. Create the Samsung certificate (interactive — YOU do this)
Open **Certificate Manager** (comes with the extension):
1. Create a **Samsung** certificate profile.
2. **Author certificate** -> sign in with your Samsung account (OAuth, likely 2FA).
3. **Distributor certificate** -> add DUID `uuid:<YOUR-TV-DUID>`.
4. It creates/activates a security profile — note its **name** (e.g. `SamsungTV`).

### 4. Re-sign and install
```bash
TZ=~/tizen-studio/tools/ide/bin/tizen
SDB=~/tizen-studio/tools/sdb
APP=~/Projects/samsung-tv-hack/VolumioTV
$TZ package -t wgt -s <SamsungProfileName> -- "$APP"     # re-sign with the Samsung profile
$SDB -s 10.88.120.241:26101 install "$APP/Volumio.wgt"
```
Success looks like `app_id[...] install completed`. Then the **Volumio** app appears on the TV's
Apps row — open it and it loads the Volumio UI.

## Notes
- Access ceiling: no `sdb shell` (intershell disabled), no root. Can install/launch/debug + sandbox file I/O only.
- Keep everything local. Do not commit certs/keystores/secrets.
