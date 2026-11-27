#!/usr/bin/env python3
"""probe.py — is the TV's sdbd actually healthy?

Sends a raw sdb/adb A_CNXN handshake to the TV's debug port and prints the
device banner it replies with. This is how we proved (docs/FINDINGS.md) that the
TV was fine and the local sdb CLI was the problem.

A healthy, authorized TV replies with a banner like:
    device::QN43Q60DAFXZA::0

Usage:  python3 tools/probe.py [TV_IP] [PORT]
        (defaults: 192.0.2.10  26101)
"""
import socket
import struct
import sys

A_CNXN = 0x4E584E43  # "CNXN"


def probe_cnxn(ip: str, port: int, timeout: float = 4.0):
    s = socket.socket()
    s.settimeout(timeout)
    try:
        s.connect((ip, port))
    except Exception as e:
        return None, f"TCP connect failed: {e}"
    payload = b"host::\x00"
    hdr = struct.pack(
        "<6I",
        A_CNXN,
        0x01000000,            # our version
        256 * 1024,            # maxdata
        len(payload),
        sum(payload) & 0xFFFFFFFF,
        A_CNXN ^ 0xFFFFFFFF,   # magic
    )
    try:
        s.sendall(hdr + payload)
        data = s.recv(512)
    except Exception as e:
        return None, f"no reply: {e}"
    finally:
        s.close()
    if len(data) < 24:
        return None, f"short reply ({len(data)} bytes): {data!r}"
    cmd, a0, a1, dl, _dc, _mg = struct.unpack("<6I", data[:24])
    body = data[24:24 + dl]
    cmd_name = struct.pack("<I", cmd).decode("latin1")
    return {
        "cmd": cmd_name,
        "version": hex(a0),
        "maxdata": a1,
        "banner": body.rstrip(b"\x00").decode("latin1", "replace"),
    }, None


def tcp_open(ip: str, port: int, timeout: float = 2.0) -> bool:
    s = socket.socket()
    s.settimeout(timeout)
    try:
        s.connect((ip, port))
        return True
    except Exception:
        return False
    finally:
        s.close()


def main():
    ip = sys.argv[1] if len(sys.argv) > 1 else "192.0.2.10"
    port = int(sys.argv[2]) if len(sys.argv) > 2 else 26101
    print(f"Probing {ip}:{port} ...")

    info, err = probe_cnxn(ip, port)
    if err:
        print(f"  sdbd handshake: FAILED — {err}")
    else:
        print("  sdbd handshake: OK")
        print(f"    reply cmd : {info['cmd']}")
        print(f"    version   : {info['version']}")
        print(f"    maxdata   : {info['maxdata']}")
        print(f"    banner    : {info['banner']}")
        state = info["banner"].split("::")[-1] if "::" in info["banner"] else "?"
        if info["cmd"] == "CNXN":
            print("  => sdbd is HEALTHY and speaking the protocol.")
            if info["banner"].startswith("device::"):
                print("     TV is AUTHORIZED (state 'device'); if `sdb` still can't")
                print("     connect, the fault is the local sdb client — see")
                print("     docs/FINDINGS.md and run tools/connect.sh.")

    # Sanity: a couple of ports that should be refused (rules out a proxy intercept).
    for p in (26102, 9999):
        print(f"  control port {p}: {'OPEN (unexpected!)' if tcp_open(ip, p) else 'refused (expected)'}")


if __name__ == "__main__":
    main()
