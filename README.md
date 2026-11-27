# Spudger

> A spudger is the nylon pry tool every teardown uses to pop open a sealed
> device without cracking the case. This project does the software equivalent
> for a **Samsung Tizen TV**: it pries the set open — through Samsung's own
> sanctioned developer tools — so the owner can make it *theirs*.

Part of the **ry-ops** line-up (`ry-ops/spudger`) — tactile, craft-tool names.

## What this is

Tooling, findings, and runbooks for sideloading your own apps onto a Samsung
QLED TV (and, down the road, exploring deeper ownership of hardware you own).
The first payload is **VolumioTV** — a full-screen Volumio music front-end with
TV-remote media controls — running on a `QN43Q60DAFXZA` (Tizen 9).

Everything here uses tools Samsung *ships and documents*: Developer Mode, `sdb`
(Samsung Debug Bridge), Tizen Studio, Samsung-issued certificates bound to the
device's DUID, and Samsung's own [`tizen-agent-skills`](https://github.com/Samsung/tizen-agent-skills).

**On ethics:** we do not condone piracy, DRM circumvention, or breaking into
devices you don't own. See [`docs/adr/0001-sanctioned-techniques-not-piracy.md`](docs/adr/0001-sanctioned-techniques-not-piracy.md).

## Layout

```
spudger/
├── README.md
├── RUNBOOK.md              # operational quick-reference (the final-mile sideload)
├── app/                    # (reserved) future app sources
├── VolumioTV/              # the live app: index.html, config.xml, icon.png, signed .wgt
├── tools/
│   ├── connect.sh          # cold-boot → plain sdb server → connect (the hard-won recipe)
│   ├── sideload.sh         # package → sign → install → launch
│   └── probe.py            # diagnose: is the TV's sdbd actually healthy?
└── docs/
    ├── INSTALL.md          # install everything this project needs
    ├── FINDINGS.md         # device facts, the access ceiling, the sdb root cause
    ├── ROADMAP.md          # where this is going
    └── adr/                # architecture / policy decision records
        └── 0001-sanctioned-techniques-not-piracy.md
```

## Quick start

1. Install the toolchain — see [`docs/INSTALL.md`](docs/INSTALL.md).
2. Put the TV in Developer Mode and connect — see [`RUNBOOK.md`](RUNBOOK.md)
   and run [`tools/connect.sh`](tools/connect.sh).
3. Sideload the app — [`tools/sideload.sh`](tools/sideload.sh).

## Status

- ✅ Dev Mode + `sdb` access working
- ✅ Samsung certificate signing working
- ✅ VolumioTV sideloaded and live (full-screen UI + remote media/volume/seek keys)
- 🔎 Evaluating Samsung's `tizen-agent-skills` as a maintained backbone
- ⏭️ Root / boot-into-app research (owner-choice; see ADR-0001)
