# Binaural <img width="50" title="Page Home" src="https://github.com/molan-git/harbour-binaural/blob/main/icons/172x172/harbour-binaural.png">

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/G7W527ZZR9)

## About

Binaural is a sound app for [Sailfish OS](https://sailfishos.org) designed for relaxation, focus, sleep, and meditation. Create your own listening experience with binaural beats, colored noise, and ambient sounds. Mix different sounds together, adjust their volume levels, and find the combination that works best for you.

## Features

- Binaural beats with selectable frequency bands
- Colored noise: white, pink, brown, and grey
- Ambient sounds
- [WIP] Custom sound playback
- Mix sound sources simultaneously
- Sleep timer

## Download

Download the latest release from:

* [OpenRepos.net](https://openrepos.net/content/molan/binaural)
* [GitHub Releases](https://github.com/molan-git/harbour-binaural/releases)

## Translations

Translations are managed with [Hosted Weblate](https://hosted.weblate.org/projects/harbour-binaural/harbour-binaural/). New languages can be added through `Weblate` or directly via `GitHub`. Incomplete translations may not be accepted or included in the app.

<a href="https://hosted.weblate.org/engage/harbour-binaural/"><img src="https://hosted.weblate.org/widget/harbour-binaural/harbour-binaural/svg-badge.svg" alt="Übersetzungsstatus"></a>

## Audio Engine

The `AudioEngine` coordinates three types of audio sources: binaural beats, colored noise, and ambient sounds. Each source type has its own playback implementation, allowing different types of sound to be combined.

### PCM Audio Channels

The `PcmChannel` component provides a reusable playback pipeline for generated PCM audio. It manages `QAudioOutput` and the associated generator's lifecycle. It also handles volume control, pause/resume, fade-out, and resource cleanup.

The channel requests signed 16-bit, little-endian PCM at 48 kHz in stereo. If the output device does not support the requested format, it checks for a compatible alternative while retaining the required sample size, sample type, and byte order. The selected format is passed to the generator so it can configure its output accordingly.

### Binaural Beats

`BinauralGenerator` generates stereo audio containing two sine waves: a fixed 200 Hz tone in the left channel and a slightly higher frequency in the right channel. The frequency difference creates the perceived binaural beat.

The generated audio is played through a dedicated `PcmChannel`.

### Colored Noise

`ColoredNoiseGenerator` generates white, pink, brown, and grey noise in real time using dedicated digital signal processing (DSP) algorithms. Per-type gain calibration helps balance perceived loudness.

The generated audio is played through its own `PcmChannel`. Changing the noise type during playback updates the generator without restarting the audio stream.

### Ambient Sounds

Ambient audio files are played using `QMediaPlayer`. The ambience implementation supports looping, fade-in, fade-out, and crossfading between loop iterations.

The `AmbienceChannel` component provides an independent playback channel for an ambient sound. This allows multiple ambient sounds to play concurrently rather than forcing all ambient playback through a single player. Up to three ambient sounds can be selected and mixed at the same time.

### Source Files

| File                           | Responsibility                                                                                                     |
| ------------------------------ | ------------------------------------------------------------------------------------------------------------       |
| `audioengine.cpp`              | Initializes the audio engine and provides shared functionality.                                                    |
| `audioengine_binaural.cpp`     | Manages binaural beat generation and playback.                                                                     |
| `audioengine_colorednoise.cpp` | Manages colored noise generation and playback.                                                                     |
| `audioengine_ambience.cpp`     | Coordinates ambient sound playback and active ambience channels.                                                   |
| `pcmchannel.cpp`               | Manages PCM playback through `QAudioOutput`, including volume, pause/resume, fade-out, and resource cleanup.       |
| `pcmchannel.h`                 | Declares the `PcmChannel` class and its playback interface.                                                        |
| `ambiencechannel.cpp`          | Implements an individual ambient playback channel, allowing up to three ambient sounds to play simultaneously.     |
| `binauralgenerator.cpp`        | Generates binaural tones using sine waves.                                                                         |
| `colorednoisegenerator.cpp`    | Implements DSP algorithms for white, pink, brown, and grey noise.                                                  |

### Audio Pipeline

* **Binaural beats:** `BinauralGenerator` → `PcmChannel` → `QAudioOutput`
* **Colored noise:** `ColoredNoiseGenerator` → `PcmChannel` → `QAudioOutput`
* **Ambient sounds:** Audio files → `AmbienceChannel` → `QMediaPlayer`

## Requirements

* Sailfish OS SDK with a build target for Sailfish OS 4.6.0.12 or newer.

## Build

Clone or download this repository and import it into your Sailfish OS IDE using the `harbour-binaural.pro` project file.

## Repository branches

* `master`: Release branch containing the current version of Binaural.
* `feature-*`: Branches used for testing features under development.
* `weblate-harbour-binaural-*`: Translation branch managed by Weblate.

## Contributions

Contributions to this project are very welcome!
Before implementing a new feature, please discuss your proposal with the main developer. All contributions must respect the project's existing Sailfish OS build target and compatibility requirements. 

When submitting a `Pull Request`, please include a clear explanation of the changes. All `Pull Requests` will be reviewed before being merged. Please note that not all contributions may be accepted, particularly if they conflict with the project's philosophy, simplicity, compatibility requirements, or overall direction.

## Screenshots

<img width="250" alt="grafik" src="https://github.com/user-attachments/assets/17449c02-07e1-450f-8063-c20f12c9072f" /> <img width="250" alt="grafik" src="https://github.com/user-attachments/assets/44ddcd5f-b23e-47fc-9772-c06bb5abfb66" /> <img width="250" alt="grafik" src="https://github.com/user-attachments/assets/ccfc6b48-a6bc-4cc9-9375-e954bad6c2f7" />

## Credits
See [CREDITS.md](CREDITS.md)

## License

Licensed under the [GNU General Public License v3.0](https://www.gnu.org/licenses/gpl-3.0.html).
