#!/bin/sh
# macOS-only: checks decoding, FFT peak detection, bass octave-shifting and silence.
# No Force Touch trackpad is required because --analyze does not open the motor.
set -eu
cd "$(dirname "$0")/.."
[ -x ./nospeaker ] || { echo "Build ./nospeaker first with ./build.sh" >&2; exit 2; }
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT HUP INT TERM
python3 - "$work" <<'PY'
import math, os, struct, sys, wave
base = sys.argv[1]
rate = 44100
for name, freq in [('a440.wav', 440), ('bass80.wav', 80), ('silence.wav', 0)]:
    with wave.open(os.path.join(base, name), 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(rate)
        values = (int(12000 * math.sin(2 * math.pi * freq * i / rate))
                  if freq else 0 for i in range(rate // 2))
        w.writeframes(b''.join(struct.pack('<h', v) for v in values))
PY

for entry in 'a440.wav:430:450' 'bass80.wav:150:170'; do
    name=${entry%%:*}
    range=${entry#*:}
    lo=${range%%:*}
    hi=${range#*:}
    result=$(./nospeaker --analyze "$work/$name")
    printf '%s\n' "$result"
    hz=$(printf '%s\n' "$result" | awk '/First dominant frequency:/ {print $(NF-1)}')
    awk -v hz="$hz" -v lo="$lo" -v hi="$hi" 'BEGIN { if (!(hz >= lo && hz <= hi)) exit 1 }' || {
        echo "Unexpected dominant pitch for $name: ${hz:-missing} Hz" >&2
        exit 1
    }
done

# A real compressed decoder path is essential: PCM-only smoke tests will
# not exercise AAC's packet padding and estimated frame counts.
if ! command -v afconvert >/dev/null 2>&1; then
    echo "afconvert is required on macOS to test AAC and ALAC decoding" >&2
    exit 1
fi
afconvert -f m4af -d aac "$work/a440.wav" "$work/a440-aac.m4a"
afconvert -f m4af -d alac "$work/a440.wav" "$work/a440-alac.m4a"
for name in a440-aac.m4a a440-alac.m4a; do
    result=$(./nospeaker --analyze "$work/$name")
    printf '%s\n' "$result"
    hz=$(printf '%s\n' "$result" | awk '/First dominant frequency:/ {print $(NF-1)}')
    awk -v hz="$hz" 'BEGIN { if (!(hz >= 425 && hz <= 455)) exit 1 }' || {
        echo "Compressed audio decode or pitch check failed for $name: ${hz:-missing} Hz" >&2
        exit 1
    }
done

result=$(./nospeaker --analyze "$work/silence.wav")
printf '%s\n' "$result"
printf '%s\n' "$result" | grep -q 'No audible spectral peaks detected' || {
    echo "Silent file generated spectral peaks" >&2
    exit 1
}
echo 'Music analysis smoke tests passed.'
