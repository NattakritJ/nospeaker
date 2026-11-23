```text
────────────────────────  a90.com presents  ─────────────────────────

    _   __ ____      _____  ____   ______ ___     __ __  ______ ____
   / | / // __ \    / ___/ / __ \ / ____//   |   / //_/ / ____// __ \
  /  |/ // / / /    \__ \ / /_/ // __/  / /| |  / ,<   / __/  / /_/ /
 / /|  // /_/ /    ___/ // ____// /___ / ___ | / /| | / /___ / _, _/
/_/ |_/ \____/    /____//_/    /_____//_/  |_|/_/ |_|/_____//_/ |_|

─  haptic voice synthesis  ─────────────────────────────  trackpad  ─
```

**Mute your Mac. Your trackpad will still talk.**

There's no speaker in a MacBook trackpad, just a small haptic motor that taps the glass so you feel a click.
NO SPEAKER drives that motor up to 4,000 times a second, fast enough to make sound you can hear, and turns it
into a voice. It talks, sings, raps, and becomes an instrument under your finger.

One command. About a minute and a half. No speakers used.

<!-- demo video: drag an .mp4 here in GitHub's editor -->

## 01 / before you start

```text
[ mute your mac ]        it still talks; that's the point
[ put it on a table ]    on your lap it's much quieter
[ hands off the glass ]  until it asks you to touch it
```

**Space** skips a part. **q** or **Ctrl-C** goes to the end.

## 02 / run it

`[ one line ]`

```sh
curl -fsSL a90.com/nospeaker | sh
```

Downloads the latest release to `~/.local/bin/nospeaker` and starts the show. `a90.com/nospeaker` points
to [play.sh](play.sh) in this repo, so you can read what it runs first.

`[ download ]`

Grab `nospeaker.zip` from the [latest release](https://github.com/os6/nospeaker/releases/latest),
unzip it and run `./nospeaker` in Terminal. Signed with a Developer ID and notarized by Apple.

`[ from source ]`

Needs Xcode or the Command Line Tools (`xcode-select --install`). Builds one program for Apple Silicon
and Intel Macs.

```sh
git clone https://github.com/os6/nospeaker
cd nospeaker
./build.sh
./nospeaker
```

## 03 / play with it

```text
./nospeaker "hello there"            say anything
./nospeaker --voice Daniel "hello"   in another macOS voice
./nospeaker --sweep                  a rising tone, 100 Hz to 4 kHz
./nospeaker --play "song.wav"        experimental music via trackpad
./nospeaker --analyze "song.wav"     inspect spectral peaks (no motor needed)

--dark                               white on black
--plain                              no visuals, plain text
```

## 04 / needs

A Force Touch trackpad (built into MacBooks from 2015 on, or a Magic Trackpad 2 or newer), and macOS 12 or
later on Apple Silicon, or macOS 13 or later on Intel. Without a Force Touch trackpad, it says so and exits.

```text
tested on

MacBook Pro (Mac17,10)   M5 Max   macOS 27.2.1   everything works
```

Not tested yet: Intel Macs, a Magic Trackpad, and older versions of macOS. MultitouchSupport is private, so
older systems may lack the functions it uses, and loudness differs between trackpads. If you try it on another
Mac, open an issue with your model, your macOS version and how it sounded.

## 05 / how it works

```text
say ──▶ formants ──▶ two tones ──▶ motor ──▶ glass
        per 10 ms    F1 + F2       haptics   sound
```

**Why you can hear it.** The trackpad has no speaker, but the motor moves the glass. Driven back and forth
hundreds or thousands of times a second, the glass vibrates fast enough to make sound you can hear. It's quiet
because the motor is built for short taps, not for sound.

**The motor.** `MultitouchSupport` is the private framework macOS uses for the trackpad. Its function
`MTActuationCreateFromDictionary` takes a description of a vibration, a list of sine tones with a frequency,
a strength and a length each, and `MTActuationActuate` plays it on the motor. Apple's public haptics API only
offers three fixed taps.

**The range.** Measured with the MacBook's own microphone, every semitone from 98 Hz to 3,951 Hz: how loud it
is over a quiet room, and how much of the sound is the note itself.

```text
│                                      ###
│                          #+#     +++#####        #
│                         +#+#+   .+++#####       .#
│              .       ++++#+#+   .+++#####    # #.# #
│   ++        +. . #..+++++#+#++++.+++#####+ #####.###          .#
│   +++#.     +...+#..+++++#+#++++.+++#####+ #####.####+        .#
│  ++++#...   +...+#..+++++#+#++++.+++#####+.#####.####+        .#
│ .++++#...++++...+#..+++++#+#++++.+++#####+.#####.####+  +#    .#
│..++++#...++++...+#..+++++#+#++++.+++#####+.#####.####+#.+#  .#.#
│..++++#...++++...+#..+++++#+#++++.+++#####+.#####.####+#.+#+..#.#
└─────────────────────────────────────────────────────────────────
      131         262         523         1047        2093    3951
   public notes stop at 600 Hz ─┘

across: every semitone, in Hz · up: loudness, +16 to +34 dB
# clean note   + fair   . mostly buzz
```

It's loud from about 100 Hz to 4 kHz, with a few dead spots where the glass resonates. Its loudest, cleanest
notes are around 1 kHz, which covers the most important part of a voice.

**The voice.** macOS's own voice speaks the line into memory. Every 10 ms, linear prediction finds the voice's
two strongest resonances (formants), its loudness and its pitch. The motor plays those two resonances as tones,
restarted on every beat of the pitch, so they buzz like a voice instead of whistling. Hiss sounds (s, f, t)
become quick bursts of high tones. Two resonances beat three: in a blind test they were clearer, and louder,
because the motor's strength is split fewer ways.

It sounds robotic, and it's much easier to follow when you can read along, which is why the show types every
line as it speaks.

**The code.** One Swift file, [nospeaker.swift](nospeaker.swift), with no dependencies.

## 06 / caveats

- **Is it safe?** It never drives the motor past its normal maximum strength. Going past it is possible and
  louder, but the driver starts to stall, so nospeaker doesn't.
- MultitouchSupport is private and undocumented, so a macOS update could break this.

The MultitouchSupport function names were learned from the open-source Tactile project. Everything else was
measured on a MacBook.

## 07 / experimental: play audio through the trackpad

The new `--play` mode takes a normal audio file, decodes it with AVFoundation, runs a windowed
FFT via Accelerate/vDSP, and chooses the 1–6 strongest **separated spectral peaks** for each
20 ms playback frame. Frequencies below 100 Hz are shifted up by octaves, frequencies
above 3,950 Hz are dropped, and the frame energy controls loudness. It then synthesizes
those tones with the **same haptic motor** used by the original demo.

```sh
./build.sh
./nospeaker --play "music.wav"
./nospeaker --play "music.mp3" --tones 3 --level 0.30
./nospeaker --play "music.m4a" --tones 6 --level 0.45
```

`--tones` accepts 1–6 simultaneous tones (default 4), and `--level` accepts 0.05–0.60
(default 0.40). Stop playback immediately with **Ctrl-C**. Supported input formats
depend on macOS decoders (WAV, MP3, M4A/AAC, AIFF are typical). Stereo is mixed to mono.

**Inspect without using the motor** (also works on a Mac without a Force Touch trackpad):

```sh
./nospeaker --analyze "music.wav"
./nospeaker --analyze "music.wav" --tones 6
sh tests/music-smoke.sh  # after ./build.sh, requires Python 3
```

**Know the limitations.** This is *spectral resynthesis*, not real speaker/PCM playback:
the motor only plays a few sine tones per frame, and the glass has a narrow, uneven
frequency response. Expect faint, buzzy, very lo-fi audio; vocals, drums and complex
mixes will be particularly distorted. The trackpad is *not* designed as a continuous
speaker. The 0.60 level cap reduces the drive relative to the API's normal maximum,
but continuous-use safety and wear have **not been validated**. Start with short,
quiet clips, keep the Mac on a stable surface, and don't leave playback unattended.
The private MultitouchSupport API may break with macOS updates.

```text
──────────────────────  thanks for listening  ───────────────────────
```

Made by [Cody Collier](https://x.com/codycollier) · [a90.com](https://a90.com) · [MIT license](LICENSE)
