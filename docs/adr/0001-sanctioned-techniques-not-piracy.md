# ADR-0001: Sanctioned techniques only — not piracy, not jailbreaking the unwilling

- **Status:** Accepted
- **Date:** 2026-11-27
- **Deciders:** project owner (ry-ops)

## Context

"Spudger" is, by name and by nature, a prying tool. A project that pries into a
consumer TV invites an obvious question: *is this piracy? Is this jailbreaking?*
We want the answer written down, up front, so every future decision in this
repo is measured against it — and so anyone who finds this work knows exactly
what we stand for.

The important fact that shapes everything: **Samsung gave us the tools.** This
TV is not a locked black box we had to crack with a hostile exploit. Samsung
ships and *documents* a developer surface for this exact kind of work:

- **Developer Mode** — a documented toggle in the TV's own Apps UI.
- **`sdb`** (Samsung Debug Bridge) — Samsung's own on-device daemon and host CLI.
- **Tizen Studio** — Samsung's official SDK and tooling.
- **Samsung certificates** — author + distributor certs Samsung issues to a
  developer's own account, bound to the device's own DUID.
- **`tizen-agent-skills`** — Samsung's own, Apache-2.0, open-source agent tooling
  for driving all of the above.

These are not holes. They are doors Samsung built and handed us the keys to.

## Decision

**Spudger operates only within the vendor-sanctioned developer surface, on
hardware the operator owns, to help owners make their own device their own.**

We will **abuse, use, and reuse** those sanctioned techniques — "abuse" in the
sense of creative, unintended-but-legitimate use of officially provided tools —
to build a better experience for people who want to customize the TV they paid
for. Specifically, we commit to the following.

### We DO

1. Work only on **hardware the operator legally owns.**
2. Use **Samsung's own developer tools** (Developer Mode, `sdb`, Tizen Studio,
   Samsung-issued certs, `tizen-agent-skills`) as the primary path.
3. **Sideload the owner's own software** — apps we wrote, or open-source apps —
   to improve the device's usefulness (e.g. a Volumio music front-end).
4. **Document our findings openly** so other owners can reproduce the work and
   make their own device their own.
5. Keep all signing material, accounts, and credentials **private and local**
   (see `.gitignore`); never redistribute them.

### We DON'T

1. **No piracy.** We do not copy, distribute, or help anyone obtain software,
   media, or content they are not entitled to.
2. **No DRM / content-protection circumvention.** We do not defeat Widevine,
   HDCP, PlayReady, or any content-protection scheme, and we do not build tools
   whose purpose is to.
3. **No breaking into devices the operator doesn't own**, and nothing designed
   to attack someone else's hardware, account, or network.
4. **No credential, account, or identity theft**, and no bypassing of
   authentication that protects other people.
5. **No redistribution of Samsung's proprietary IP** (firmware images, SDK
   binaries, certificates). We link to Samsung's own distribution instead.

## On root and non-sanctioned paths

The sanctioned surface above does **not** include root. Rooting this model
would rely on a security vulnerability (e.g. an SVE-class `sdb` issue), which is
*not* a tool Samsung handed us. We treat root research as a clearly-labeled,
**owner-choice, educational** track, held to the same hard limits as everything
else in this ADR:

- It may only ever target **the operator's own device.**
- Its purpose is **ownership and understanding** (debloat, boot-into-app on your
  own TV), **never** piracy or DRM circumvention.
- Any such work is **marked distinctly** in the repo as non-sanctioned, with its
  risks (bricking, warranty, volatility) stated plainly, and is never the
  default path.

If a technique can only be used to pirate, to break content protection, or to
attack hardware the operator doesn't own, **it does not belong in Spudger.**

## Consequences

- Every new capability is checked against the DO / DON'T lists above before it
  lands. A feature that fails the test is rejected regardless of how clever it is.
- Because we stay on the vendor-sanctioned surface, the work is reproducible by
  any owner with a Samsung account and their own TV — which is the whole point.
- The one asterisk is the root track, which is firewalled off as owner-choice,
  non-sanctioned, and non-default, and is still bound by the no-piracy /
  no-DRM-circumvention / own-hardware-only limits.
- This ADR is the reference the project's ethos points back to; changing the
  stance requires a superseding ADR, not a quiet edit.
