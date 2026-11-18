#!/usr/bin/env python3
"""CyberNeon sound theme: short, quiet synthetic sounds generated from scratch (no samples, standard library only).

usage: make_sounds.py OUT_DIR       writes OUT_DIR/index.theme and OUT_DIR/stereo/*.wav (freedesktop sound theme)

Original sounds. FAN MADE - inspired by Cyberpunk 2077 by CD PROJEKT RED (trademarks of CD PROJEKT S.A.).
"""
import math, pathlib, random, struct, sys, wave

RATE = 44100
random.seed(2077)


def silence(seconds):
    return [0.0] * int(seconds * RATE)


def sweep(seconds, f0, f1, level=1.0, attack=0.006, release=0.04, shape=0.0):
    """Sine sweep from f0 to f1 Hz with a soft envelope; shape > 0 adds odd harmonics for a digital edge."""
    n = int(seconds * RATE)
    out, phase = [], 0.0
    for i in range(n):
        t = i / RATE
        phase += 2 * math.pi * (f0 + (f1 - f0) * i / max(1, n - 1)) / RATE
        v = math.sin(phase) + shape * math.sin(3 * phase) / 3 + shape * math.sin(5 * phase) / 5
        env = min(1.0, t / attack) * min(1.0, (seconds - t) / release)
        out.append(v * env * level / (1 + shape * 0.5))
    return out


def ticks(seconds, every, level, f=2600):
    """Short high clicks at a shrinking interval, like data locking on."""
    out = silence(seconds)
    pos, gap = 0.0, every
    while pos < seconds - 0.01:
        for i, v in enumerate(sweep(0.009, f, f * 0.7, level, 0.001, 0.006)):
            j = int(pos * RATE) + i
            if j < len(out):
                out[j] += v
        pos += gap
        gap = max(0.018, gap * 0.86)
    return out


def mix(*tracks):
    out = [0.0] * max(len(t) for t in tracks)
    for t in tracks:
        for i, v in enumerate(t):
            out[i] += v
    return out


def seq(*tracks):
    return [v for t in tracks for v in t]


def write(path, mono, peak):
    """Normalises to `peak` (well below full scale: these are background cues) with a small stereo offset."""
    top = max(1e-9, max(abs(v) for v in mono))
    delay = int(0.004 * RATE)
    left = mono + [0.0] * delay
    right = [0.0] * delay + mono
    frames = bytearray()
    for a, b in zip(left, right):
        frames += struct.pack("<hh", int(a / top * peak * 32767), int((a * 0.35 + b * 0.65) / top * peak * 32767))
    with wave.open(str(path), "wb") as w:
        w.setnchannels(2); w.setsampwidth(2); w.setframerate(RATE); w.writeframes(bytes(frames))


call = seq(sweep(0.11, 170, 250, 1, release=0.05, shape=0.3), silence(0.07), sweep(0.15, 190, 300, 1, release=0.08, shape=0.3))
warning = seq(sweep(0.13, 240, 170, 1, shape=0.8), silence(0.05), sweep(0.13, 240, 170, 1, shape=0.8), silence(0.05),
              sweep(0.2, 240, 130, 1, release=0.1, shape=0.8))
error = seq(sweep(0.09, 150, 110, 1, shape=1.0), silence(0.04), sweep(0.24, 150, 80, 1, release=0.12, shape=1.0))
info = sweep(0.12, 300, 420, 1, release=0.07, shape=0.2)
tick = sweep(0.035, 1500, 1100, 1, attack=0.001, release=0.02, shape=0.4)
added = seq(sweep(0.06, 320, 420, 1), sweep(0.1, 480, 620, 1, release=0.06))
removed = seq(sweep(0.06, 480, 380, 1), sweep(0.1, 320, 220, 1, release=0.06))
jack_in = mix(sweep(1.15, 55, 220, 0.8, attack=0.25, release=0.3, shape=0.25),
              sweep(1.15, 110, 880, 0.22, attack=0.5, release=0.2),
              ticks(0.95, 0.15, 0.22),
              silence(1.5))
jack_in = [v for v in jack_in]
for i, v in enumerate(sweep(0.3, 660, 990, 0.35, release=0.2)):      # the link locks in
    jack_in[int(1.1 * RATE) + i] += v

SOUNDS = {
    "message-new-instant": (call, 0.20),          # the "incoming call" chirp for notifications
    "dialog-information": (info, 0.16),
    "dialog-warning": (warning, 0.20),            # also played when the HUD enters alert mode
    "dialog-error": (error, 0.24),
    "audio-volume-change": (tick, 0.14),
    "device-added": (added, 0.16),
    "device-removed": (removed, 0.16),
    "desktop-login": (jack_in, 0.26),             # jack-in, at the start of the session
    "service-login": (jack_in, 0.26),
}


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    out = pathlib.Path(sys.argv[1])
    (out / "stereo").mkdir(parents=True, exist_ok=True)
    (out / "index.theme").write_text(
        "[Sound Theme]\nName=CyberNeon\nComment=Fan-made synthetic cues, inspired by Cyberpunk 2077 by CD PROJEKT RED\n"
        "Inherits=freedesktop\nDirectories=stereo\n\n[stereo]\nOutputProfile=stereo\n")
    for name, (mono, peak) in SOUNDS.items():
        write(out / "stereo" / f"{name}.wav", mono, peak)
    print(f"{len(SOUNDS)} sounds in {out}")


if __name__ == "__main__":
    main()
