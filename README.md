# Binaural <img width="50" title="Page Home" src="https://github.com/molan-git/harbour-binaural/blob/main/icons/172x172/harbour-binaural.png">

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/G7W527ZZR9)

## About

Binaural is a sound app for [Sailfish OS](https://sailfishos.org) designed for relaxation, focus, sleep, and meditation. Create your own listening experience with binaural beats, colored noise, and ambient sounds. Mix different sounds together, adjust their volume levels, and find the combination that works best for you.

## Features

- Binaural beats with selectable frequency bands
- Colored noise: white, pink, brown, and grey
- Ambient sounds
- Mix binaural beats, noise, and ambient sounds
- Sleep timer

## Download

The latest release is available on [OpenRepos.net](https://openrepos.net/content/molan/binaural)

## Audio Engine

The `AudioEngine` manages three audio sources: binaural beats, colored noise, and ambient sounds.

* **Binaural beats:** `BinauralGenerator` generates two sine waves: a fixed 200 Hz tone in the left channel and a slightly higher frequency in the right channel. Their frequency difference creates the perceived binaural beat. The resulting stereo 16-bit PCM audio is streamed through `QAudioOutput`, with the sample rate adapted to the audio device.
* **Colored noise:** `ColoredNoiseGenerator` generates White, Pink, Brown, and Grey noise in real time using dedicated DSP algorithms. Per-type gain calibration helps balance perceived loudness. The resulting 16-bit PCM audio is streamed through `QAudioOutput`.
* **Ambient sounds:** Audio files are played using `QMediaPlayer`. The `AudioEngine` manages seamless looping, fade-in, fade-out, and crossfading between loop iterations.

### Source Files

| File                           | Responsibility                                                    |
| ------------------------------ | ----------------------------------------------------------------- |
| `audioengine.cpp`              | Initializes the audio engine and provides shared functionality.   |
| `audioengine_binaural.cpp`     | Manages binaural beat generation and playback.                    |
| `audioengine_colorednoise.cpp` | Manages colored noise generation and playback.                    |
| `audioengine_ambience.cpp`     | Manages ambient sound playback, looping, fading, and crossfading. |
| `binauralgenerator.cpp`        | Generates binaural tones using sine waves.                        |
| `colorednoisegenerator.cpp`    | Implements DSP algorithms for White, Pink, Brown, and Grey noise. |

### Audio Pipeline

* **Binaural beats:** `BinauralGenerator` → PCM stream → `QAudioOutput`
* **Colored noise:** `ColoredNoiseGenerator` → PCM stream → `QAudioOutput`
* **Ambient sounds:** Audio files → `QMediaPlayer` → looping and crossfading

## Requirements

* Sailfish OS SDK with a build target for Sailfish OS 4.6 or newer.

## Build

Clone or download this repository and import it into your Sailfish OS IDE using the `harbour-binaural.pro` project file.

## Repository branches

* `master`: Release branch containing the current version of Binaural.
* `feature-*`: Branches used for testing features under development.
* `weblate-harbour-binaural-*`: Translation branch managed by Weblate.

## Contributions

Contributions to this project are very welcome. If you already know what you want to add or fix, please open a `Pull Request` with your proposal. You can also use `Discussions` to propose features or changes.

Please include an explanation of the changes or a brief changelog summary. Pull requests will be reviewed before they are merged. Please note that not all contributions may be accepted if they conflict with the project's philosophy, simplicity, or overall direction.

## Translations

Translations are managed with [Hosted Weblate](https://hosted.weblate.org/projects/harbour-binaural/harbour-binaural/). New languages can be added through `Weblate` or directly via `GitHub`. Incomplete translations may not be accepted or included in the app.

<a href="https://hosted.weblate.org/engage/harbour-binaural/"><img src="https://hosted.weblate.org/widget/harbour-binaural/harbour-binaural/svg-badge.svg" alt="Übersetzungsstatus"></a>

## Screenshots

<img width="250" alt="grafik" src="https://github.com/user-attachments/assets/17449c02-07e1-450f-8063-c20f12c9072f" /> <img width="250" alt="grafik" src="https://github.com/user-attachments/assets/44ddcd5f-b23e-47fc-9772-c06bb5abfb66" /> <img width="250" alt="grafik" src="https://github.com/user-attachments/assets/ccfc6b48-a6bc-4cc9-9375-e954bad6c2f7" />




## Credits

* Inspired by [Metiq](https://github.com/metiq-xyz/android-app) for Android
* Audio and image asset credits: see [CREDITS.md](CREDITS.md)

## License

Licensed under the [GNU General Public License v3.0](https://www.gnu.org/licenses/gpl-3.0.html).
