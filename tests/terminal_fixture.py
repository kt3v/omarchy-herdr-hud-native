"""Harmless raw terminal fixture: records input, emits logs and redraws a TUI."""

import argparse
import json
import os
import select
import sys
import termios
import time
import tty


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("events")
    parser.add_argument("--seconds", type=float, default=180)
    args = parser.parse_args()
    original = termios.tcgetattr(sys.stdin)
    alternate = False
    pending = bytearray()
    counter = 0
    previous_size = None
    deadline = time.monotonic() + args.seconds
    with open(args.events, "a", buffering=1) as events:
        def record(event):
            events.write(json.dumps(event) + "\n")

        try:
            tty.setraw(sys.stdin)
            record({"type": "ready", "pid": os.getpid()})
            for counter in range(1, 121):
                sys.stdout.write(f"LOG{counter:06d} | fixture history; no actions\r\n")
            sys.stdout.flush()
            while time.monotonic() < deadline:
                size = os.get_terminal_size(sys.stdout.fileno())
                if size != previous_size:
                    record({"type": "size", "cols": size.columns, "rows": size.lines})
                    previous_size = size
                counter += 1
                if alternate:
                    sys.stdout.write("\x1b[H\x1b[2J\x1b[32mSAFE TUI\x1b[0m\r\n"
                                     f"Redraw: {counter} | {size.columns}x{size.lines}\r\n"
                                     "1/2/3 or yes/no then Enter: record only, no actions.\r\n"
                                     "Type normal then Enter to return to logs.\r\n")
                else:
                    sys.stdout.write(f"LOG{counter:06d} | 1/2/3, yes/no: record only | alt: TUI | quit: exit\r\n")
                sys.stdout.flush()
                readable, _, _ = select.select([sys.stdin], [], [], 0.12)
                if not readable:
                    continue
                data = os.read(sys.stdin.fileno(), 4096)
                if not data:
                    break
                record({"type": "input", "hex": data.hex()})
                pending.extend(data)
                while b"\r" in pending:
                    command, _, remaining = pending.partition(b"\r")
                    pending = bytearray(remaining)
                    text = command.decode("utf-8", errors="replace")
                    record({"type": "command", "text": text})
                    if text == "quit":
                        return
                    if text == "alt":
                        alternate = True
                        sys.stdout.write("\x1b[?1049h")
                    elif text == "normal":
                        alternate = False
                        sys.stdout.write("\x1b[?1049l")
                    else:
                        sys.stdout.write(f"\r\nRECORDED {text!r}; NO ACTION EXECUTED\r\n")
                if len(pending) > 4096:
                    pending.clear()
        finally:
            if alternate:
                sys.stdout.write("\x1b[?1049l")
            sys.stdout.write("\r\nFIXTURE_EXIT\r\n")
            sys.stdout.flush()
            termios.tcsetattr(sys.stdin, termios.TCSANOW, original)
            record({"type": "exit"})


if __name__ == "__main__":
    main()
