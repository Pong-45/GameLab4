"""Compose original loopable game music and short effects using only Python's stdlib."""
import math
import random
import struct
import wave
from pathlib import Path

OUT = Path(__file__).resolve().parents[1] / "Assets/Sound/Swamp"
RATE = 22050
TAU = math.tau


def write(name, samples):
    peak = max(max(map(abs, samples)), 0.01)
    data = bytearray()
    for sample in samples:
        data.extend(struct.pack('<h', int(sample / peak * 24000)))
    with wave.open(str(OUT / (name + '.wav')), 'wb') as stream:
        stream.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
        stream.writeframes(data)


def note(buffer, start, duration, midi, volume=0.15, sound='bell'):
    freq = 440 * 2 ** ((midi - 69) / 12)
    for i in range(int(duration * RATE)):
        at = int(start * RATE) + i
        if at >= len(buffer):
            break
        t = i / RATE
        attack = min(t / 0.02, 1)
        release = min((duration - t) / 0.12, 1)
        envelope = attack * release
        if sound == 'bell':
            value = (math.sin(TAU * freq * t) + 0.3 * math.sin(TAU * freq * 2 * t)) * math.exp(-3.5 * t)
        else:
            value = math.sin(TAU * freq * t) + 0.15 * math.sin(TAU * freq * 2 * t)
        buffer[at] += value * envelope * volume


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    # Each track is exactly 16 bars; every note releases before the loop boundary.
    for track in range(1, 5):
        beat = [0.5, 0.46, 0.42, 0.44][track - 1]
        song = [0.0] * int(64 * beat * RATE)
        chords = [[45, 48, 52], [41, 45, 48], [48, 52, 55], [43, 47, 50]]
        melody = [69, 72, 76, 74, 72, 67, 64, 67, 69, 76, 79, 76, 74, 72, 67, 64]
        for bar in range(16):
            chord = chords[(bar // 2 + track - 1) % 4]
            for tone in chord:
                note(song, bar * 4 * beat, 3.6 * beat, tone, 0.055, 'pad')
            for step in range(8):
                when = (bar * 4 + step * 0.5) * beat
                pitch = chord[step % 3] + 12
                note(song, when, beat * 0.75, pitch, 0.07)
                if step % 2 == 0:
                    note(song, when, beat * 0.8, melody[(bar * 4 + step // 2 + track * 2) % 16], 0.095)
            note(song, bar * 4 * beat, beat * 1.7, chord[0] - 12, 0.10, 'pad')
        write('forest_%d' % track, song)
    random.seed(23)
    for name, duration, start, end in [('bow', 0.16, 470, 180), ('arrow_hit', 0.13, 170, 65),
                                      ('spring', 0.30, 230, 850), ('portal', 0.65, 170, 770),
                                      ('pickup', 0.25, 800, 1400), ('hurt', 0.20, 200, 85),
                                      ('checkpoint', 0.55, 440, 880), ('jump', 0.17, 290, 580)]:
        samples = []
        phase = 0.0
        for i in range(int(duration * RATE)):
            t = i / RATE
            p = t / duration
            phase += TAU * (start + (end - start) * p) / RATE
            tone = math.sin(phase) * (1 - p) ** 2
            noise = random.uniform(-1, 1) * (0.35 if name in ('bow', 'arrow_hit', 'hurt') else 0.035)
            samples.append((tone + noise * (1 - p) ** 4) * min(t / 0.006, 1))
        write(name, samples)
    for name, notes in [('win', [60, 64, 67, 72, 76, 79, 84]), ('lose', [64, 60, 57, 52])]:
        samples = [0.0] * (RATE * 4)
        for i, pitch in enumerate(notes):
            note(samples, i * 0.25, 1.7, pitch, 0.3)
            note(samples, i * 0.25, 1.7, pitch - 12, 0.12, 'pad')
        write(name, samples)
    print('Created four original music loops and ten effects in', OUT)


if __name__ == '__main__':
    main()
