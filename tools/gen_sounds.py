#!/usr/bin/env python3
"""Generate ArrowQuest's sound effects and the ambient loop.

Everything is synthesised here so the project ships no third-party audio — the
sounds are original, tiny (a few kB each) and licence-free.

Outputs (relative to the Flutter project root):
  assets/sounds/tap.wav       button press
  assets/sounds/escape.wav    a successful escape
  assets/sounds/blocked.wav   a refused move
  assets/sounds/win.wav       level cleared
  assets/sounds/music.wav     short ambient loop (Settings -> Music)
"""
import math
import os
import wave

import numpy as np

RATE = 22050
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "sounds")


def env(n, attack=0.005, decay=1.0, power=2.0):
    """Simple attack/decay envelope, values in 0..1."""
    t = np.linspace(0, 1, n, endpoint=False)
    a = np.clip(t / max(attack, 1e-6), 0, 1)
    d = np.exp(-power * t / max(decay, 1e-6))
    return a * d


def sine(freq, n, phase=0.0):
    t = np.arange(n) / RATE
    return np.sin(2 * math.pi * freq * t + phase)


def sweep(f0, f1, n):
    """Linear frequency sweep."""
    t = np.arange(n) / RATE
    k = (f1 - f0) / (n / RATE)
    phase = 2 * math.pi * (f0 * t + 0.5 * k * t * t)
    return np.sin(phase)


def noise(n, seed=7):
    rng = np.random.default_rng(seed)
    return rng.uniform(-1, 1, n)


def write(name, samples, gain=0.6):
    samples = np.asarray(samples, dtype=np.float64)
    peak = np.max(np.abs(samples)) or 1.0
    samples = samples / peak * gain
    # short fade in/out so nothing clicks
    fade = min(220, len(samples) // 8) or 1
    samples[:fade] *= np.linspace(0, 1, fade)
    samples[-fade:] *= np.linspace(1, 0, fade)
    data = (samples * 32767).astype("<i2")
    path = os.path.join(OUT, name)
    with wave.open(path, "wb") as fh:
        fh.setnchannels(1)
        fh.setsampwidth(2)
        fh.setframerate(RATE)
        fh.writeframes(data.tobytes())
    print(f"wrote {path}  {len(samples) / RATE:.3f}s  {os.path.getsize(path)} bytes")


def tap():
    n = int(RATE * 0.05)
    body = sine(1180, n) * env(n, attack=0.002, decay=0.35, power=5)
    click = noise(n, 3) * env(n, attack=0.001, decay=0.06, power=9) * 0.25
    return body + click


def escape():
    n = int(RATE * 0.20)
    whoosh = sweep(420, 1500, n) * env(n, attack=0.01, decay=0.9, power=3.2)
    pop = sine(1760, n) * env(n, attack=0.001, decay=0.12, power=8) * 0.35
    return whoosh * 0.8 + pop


def blocked():
    n = int(RATE * 0.16)
    thud = sine(150, n) * env(n, attack=0.002, decay=0.5, power=4)
    buzz = np.sign(sine(96, n)) * env(n, attack=0.002, decay=0.3, power=6) * 0.22
    grit = noise(n, 11) * env(n, attack=0.001, decay=0.1, power=7) * 0.16
    return thud + buzz + grit


def win():
    notes = [523.25, 659.25, 783.99, 1046.5]  # C5 E5 G5 C6
    parts = []
    for i, f in enumerate(notes):
        n = int(RATE * (0.34 if i == len(notes) - 1 else 0.16))
        tone = sine(f, n) * env(n, attack=0.006, decay=0.9, power=3.4)
        tone += sine(f * 2, n) * env(n, attack=0.006, decay=0.5, power=5) * 0.22
        parts.append(tone)
        if i < len(notes) - 1:
            parts.append(np.zeros(int(RATE * 0.045)))
    return np.concatenate(parts)


def music():
    """A soft, slow ambient pad that loops cleanly."""
    seconds = 12.0
    n = int(RATE * seconds)
    t = np.arange(n) / RATE
    # A minor-ish pad: A2, C4, E4, A4 with gentle detune.
    freqs = [110.0, 261.63, 329.63, 440.0, 220.0]
    out = np.zeros(n)
    for i, f in enumerate(freqs):
        detune = 1.0 + (0.0016 * (1 if i % 2 else -1))
        amp = 0.16 / (1 + i * 0.35)
        slow = 0.55 + 0.45 * np.sin(2 * math.pi * (0.06 + 0.013 * i) * t + i)
        out += amp * slow * np.sin(2 * math.pi * f * detune * t)
    # breathing filter-ish tremolo
    out *= 0.75 + 0.25 * np.sin(2 * math.pi * 0.035 * t)
    # cross-fade the ends so the loop is seamless
    fade = int(RATE * 1.5)
    ramp = np.linspace(0, 1, fade)
    out[:fade] = out[:fade] * ramp + out[-fade:] * (1 - ramp)
    out = out[:-fade]
    return out


def main():
    os.makedirs(OUT, exist_ok=True)
    write("tap.wav", tap(), gain=0.45)
    write("escape.wav", escape(), gain=0.60)
    write("blocked.wav", blocked(), gain=0.55)
    write("win.wav", win(), gain=0.55)
    write("music.wav", music(), gain=0.30)


if __name__ == "__main__":
    main()
