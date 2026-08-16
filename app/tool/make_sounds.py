#!/usr/bin/env python3
"""Procedural loops for the burn effects that have no natural recording.

    python3 tool/make_sounds.py            # writes assets/audio/water.wav, static.wav

Why synthesise: no licensing, no attribution screen, deterministic output,
and each loop is tuned to the effect it sits under. Why 12 s: audioplayers'
iOS loop is not gapless (seek + resume round trip), so a clip has to be
long enough that a whole hold fits inside one pass — see burn_sound.dart.

Seamless looping: synthesise N + FADE samples, overlap-add the tail onto
the head with an equal-power crossfade, truncate to N. The join then has
no discontinuity even if the loop *does* restart cleanly.

Stdlib only (wave, struct, math, random) so it runs anywhere.
"""
from __future__ import annotations

import math
import random
import struct
import wave
from pathlib import Path

RATE = 44100
SECONDS = 12.0
FADE = 0.6  # crossfade length for the seamless join
OUT = Path(__file__).resolve().parent.parent / "assets" / "audio"


def _one_pole_lowpass(samples: list[float], cutoff_hz: float) -> list[float]:
    rc = 1.0 / (2 * math.pi * cutoff_hz)
    dt = 1.0 / RATE
    a = dt / (rc + dt)
    out = []
    y = 0.0
    for x in samples:
        y += a * (x - y)
        out.append(y)
    return out


def _one_pole_highpass(samples: list[float], cutoff_hz: float) -> list[float]:
    rc = 1.0 / (2 * math.pi * cutoff_hz)
    dt = 1.0 / RATE
    a = rc / (rc + dt)
    out = []
    y = 0.0
    prev = 0.0
    for x in samples:
        y = a * (y + x - prev)
        prev = x
        out.append(y)
    return out


def _seamless(samples: list[float], n: int, fade: int) -> list[float]:
    """Overlap-add the extra `fade` tail onto the head; return exactly n."""
    assert len(samples) >= n + fade
    out = samples[:n]
    for i in range(fade):
        t = i / fade
        # equal-power
        a = math.cos(t * math.pi / 2)
        b = math.sin(t * math.pi / 2)
        out[i] = out[i] * b + samples[n + i] * a
    return out


def _normalise(samples: list[float], peak: float = 0.85) -> list[float]:
    m = max(abs(s) for s in samples) or 1.0
    k = peak / m
    return [s * k for s in samples]


def _write(path: Path, samples: list[float]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(
            b"".join(struct.pack("<h", int(max(-1.0, min(1.0, s)) * 32767)) for s in samples)
        )
    print(f"wrote {path} ({len(samples) / RATE:.1f}s)")


def water() -> list[float]:
    """Underwater: a low filtered rumble, a slow swell, and bubble blips.

    Under a dissolving page the sound should feel submerged — nothing
    sharp, nothing rhythmic. Two layers of lowpassed noise breathing at
    different rates give the body; occasional short rising sine chirps,
    heavily lowpassed, are the bubbles.
    """
    rnd = random.Random(7)
    n = int(RATE * SECONDS)
    fade = int(RATE * FADE)
    total = n + fade

    noise = [rnd.uniform(-1, 1) for _ in range(total)]
    body = _one_pole_lowpass(noise, 220.0)
    body = _one_pole_lowpass(body, 180.0)
    body = _one_pole_highpass(body, 35.0)
    swirl = _one_pole_lowpass(noise, 900.0)
    swirl = _one_pole_highpass(swirl, 300.0)

    out = []
    for i in range(total):
        t = i / RATE
        breathe = 0.65 + 0.35 * math.sin(2 * math.pi * t / 4.7)
        breathe2 = 0.7 + 0.3 * math.sin(2 * math.pi * t / 7.3 + 1.1)
        out.append(body[i] * 3.2 * breathe + swirl[i] * 0.55 * breathe2)

    # Bubbles: ~2 per second, each a 40–90 ms chirp rising ~200 Hz.
    bubbles = [0.0] * total
    t = 0.15
    while t < SECONDS + FADE:
        dur = rnd.uniform(0.04, 0.09)
        f0 = rnd.uniform(380.0, 900.0)
        amp = rnd.uniform(0.10, 0.28)
        start = int(t * RATE)
        length = int(dur * RATE)
        for k in range(length):
            u = k / length
            env = math.sin(math.pi * u) ** 1.6
            f = f0 * (1.0 + 0.55 * u)
            idx = start + k
            if idx < total:
                bubbles[idx] += amp * env * math.sin(2 * math.pi * f * (k / RATE))
        t += rnd.uniform(0.25, 0.8)
    bubbles = _one_pole_lowpass(bubbles, 1400.0)

    mixed = [out[i] + bubbles[i] for i in range(total)]
    return _normalise(_seamless(mixed, n, fade))


def static() -> list[float]:
    """A dying screen: hiss, mains hum, and dropouts with clicks.

    White noise shaped into a hiss, a quiet 50 Hz hum with a 100 Hz
    partial (the transformer), and every so often a dropout — the hiss
    cuts for 30–120 ms with a click on the way in and out. Dropouts are
    what make it read as a signal failing rather than a waterfall.
    """
    rnd = random.Random(11)
    n = int(RATE * SECONDS)
    fade = int(RATE * FADE)
    total = n + fade

    noise = [rnd.uniform(-1, 1) for _ in range(total)]
    hiss = _one_pole_highpass(noise, 1800.0)
    hiss = _one_pole_lowpass(hiss, 9000.0)

    # Dropout mask.
    gate = [1.0] * total
    clicks = [0.0] * total
    t = 0.4
    while t < SECONDS + FADE:
        dur = rnd.uniform(0.03, 0.12)
        s = int(t * RATE)
        e = min(total, int((t + dur) * RATE))
        for k in range(s, e):
            gate[k] = 0.08
        for edge in (s, e - 1):
            if 0 <= edge < total:
                for k in range(0, 60):
                    idx = edge + k
                    if idx < total:
                        clicks[idx] += (0.9 if k == 0 else 0.0) * rnd.uniform(0.4, 0.8) - 0.0
                        clicks[idx] += rnd.uniform(-1, 1) * 0.35 * (1 - k / 60)
        t += rnd.uniform(0.35, 1.4)
    clicks = _one_pole_lowpass(clicks, 6000.0)

    out = []
    for i in range(total):
        tt = i / RATE
        hum = 0.09 * math.sin(2 * math.pi * 50.0 * tt) + 0.045 * math.sin(2 * math.pi * 100.0 * tt)
        wobble = 0.85 + 0.15 * math.sin(2 * math.pi * tt / 3.1)
        out.append(hiss[i] * 0.9 * gate[i] * wobble + hum + clicks[i] * 0.5)

    return _normalise(_seamless(out, n, fade))


if __name__ == "__main__":
    _write(OUT / "water.wav", water())
    _write(OUT / "static.wav", static())
