#!/usr/bin/env python3
"""Tiny unix-socket client for the dictation server.

  client.py --ping        -> exit 0 if server is up, exit 3 otherwise
  client.py <path-to-wav> -> prints transcribed/translated text to stdout
"""
import os
import socket
import sys

RUNDIR = os.path.join(os.environ.get("XDG_RUNTIME_DIR", "/tmp"), "dictate")
SOCK = os.path.join(RUNDIR, "sock")


def main():
    arg = sys.argv[1] if len(sys.argv) > 1 else ""
    task = sys.argv[2] if len(sys.argv) > 2 else ""
    if arg == "--ping":
        msg = "PING"
    elif task:
        msg = f"{task}\t{arg}"   # "<task>\t<path>"
    else:
        msg = arg

    s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    s.settimeout(120)
    try:
        s.connect(SOCK)
    except OSError:
        sys.exit(3)

    s.sendall(msg.encode())
    s.shutdown(socket.SHUT_WR)

    buf = b""
    while True:
        chunk = s.recv(65536)
        if not chunk:
            break
        buf += chunk

    if msg == "PING":
        sys.exit(0 if buf == b"PONG" else 3)

    sys.stdout.write(buf.decode())


if __name__ == "__main__":
    main()
