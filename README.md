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

The `AudioEngine` generates binaural beats in real time, sample-by-sample, using two sine waves: a fixed 200 Hz tone on the left channel and a slightly higher frequency on the right. The frequency difference creates the perceived binaural beat. The generated stereo 16-bit PCM audio is streamed through `QAudioOutput`, with the sample rate adapted to the audio device.

Colored noise is also generated in real time using a custom `ColoredNoiseGenerator` based on `QIODevice`. It supports White, Pink, Brown, and Grey noise using dedicated DSP algorithms, with per-noise-type gain calibration for more balanced perceived loudness. The generated 16-bit PCM stream is played through `QAudioOutput`.

Ambient sounds are played from audio files using `GStreamer` for decoding. The decoded audio is processed as a `PCM` loop, allowing ambient sounds to be combined with binaural beats and colored noise. Ambient playback supports fade-in, fade-out, and crossfading.

**Audio pipeline:**

* **Binaural beats:** DSP generator → PCM → `QAudioOutput`
* **Colored noise:** DSP generator → PCM → `QAudioOutput`
* **Ambient sounds:** GStreamer decoding → `PCM` loop

## Requirements

* Sailfish OS SDK with a build target for Sailfish OS 4.6 or newer.
* GStreamer development packages installed in the SDK build target:

  * `gstreamer1.0-devel`
  * `gstreamer1.0-plugins-base-devel`

## Build

Install the required GStreamer development packages in your SDK build target before building the project. Then clone or download this repository and import it into your Sailfish OS IDE using the `harbour-binaural.pro` project file.

## Repository branches

* `master`: Release branch containing the current version of Binaural.
* `feature-*`: Branches used for testing features under development.
* `weblate-harbour-binaural-*`: Translation branch managed by Weblate.

## Contributions

Contributions to this project are very welcome. If you already know what you want to add or fix, please open a `Pull Request` with your proposal. You can also use `Discussions` to propose features or changes.

Please include an explanation of the changes or a brief changelog summary. Pull requests will be reviewed before they are merged. Please note that not all contributions may be accepted if they conflict with the project's philosophy, simplicity, or overall direction.

## Translations

Translations are managed with [Hosted Weblate](https://hosted.weblate.org/projects/harbour-binaural/). New languages can be added through `Weblate` or directly via `GitHub`. Incomplete translations may not be accepted or included in the app.

[![Translations](https://hosted.weblate.org/widgets/harbour-binaural/-/svg-badge.svg)](https://hosted.weblate.org/engage/harbour-binaural/)

## Screenshots

<img width="250" alt="grafik" src="https://github.com/user-attachments/assets/17449c02-07e1-450f-8063-c20f12c9072f" /> <img width="250" alt="grafik" src="https://github.com/user-attachments/assets/44ddcd5f-b23e-47fc-9772-c06bb5abfb66" /> <img width="250" alt="grafik" src="https://github.com/user-attachments/assets/ccfc6b48-a6bc-4cc9-9375-e954bad6c2f7" />




## Credits

* Inspired by [Metiq](https://github.com/metiq-xyz/android-app) for Android
* Audio and image asset credits: see [CREDITS.md](CREDITS.md)

## License

Licensed under the [GNU General Public License v3.0](https://www.gnu.org/licenses/gpl-3.0.html).
