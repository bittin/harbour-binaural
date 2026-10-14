> [!IMPORTANT]
> **GStreamer setup (only needed for the experimental DSP ambience branch) - not used in release version**

# Sailfish OS SDK Setup for experimental DSP ambience branch

This guide explains how to set up the Sailfish OS SDK to build **harbour-binaural**, including the required GStreamer development packages for ARM, aarch64, and i486 build targets.

## 1. Requirements

* Sailfish OS SDK installed on your development machine.
* Sailfish OS 4.6.0.13 build targets.
* Qt Creator included with the Sailfish OS SDK.
* GStreamer development packages installed in each build target used to compile the application.

The application uses GStreamer to decode ambient audio files. The GStreamer development packages are required at build time.

## 2. Available Build Targets

The following build targets are covered by this guide:

| Architecture       | SDK build target              |
| ------------------ | ----------------------------- |
| ARM (32-bit)       | `SailfishOS-4.6.0.13-armv7hl` |
| ARM (64-bit)       | `SailfishOS-4.6.0.13-aarch64` |
| Intel x86 (32-bit) | `SailfishOS-4.6.0.13-i486`    |

**Important:** Install the development packages separately for every target you intend to use. Installing them in one target does not install them in the others.

## 3. Open the SDK Terminal

On Windows, open an MSYS terminal and use the following path to access `sfdk`:

```bash
/c/SailfishOS/bin/sfdk
```

The commands below assume that the SDK is installed in `C:\SailfishOS`.

## 4. Install GStreamer Development Packages

The following packages are required:

* `gstreamer1.0-devel`
* `gstreamer1.0-plugins-base-devel`
* `glib2-devel`

### 4.1 ARM (32-bit)

Install the packages in the ARM build target:

```bash
/c/SailfishOS/bin/sfdk tools exec SailfishOS-4.6.0.13-armv7hl zypper install gstreamer1.0-devel gstreamer1.0-plugins-base-devel glib2-devel
```

### 4.2 ARM (64-bit)

Install the packages in the aarch64 build target:

```bash
/c/SailfishOS/bin/sfdk tools exec SailfishOS-4.6.0.13-aarch64 zypper install gstreamer1.0-devel gstreamer1.0-plugins-base-devel glib2-devel
```

### 4.3 Intel x86 (32-bit)

Install the packages in the i486 build target:

```bash
/c/SailfishOS/bin/sfdk tools exec SailfishOS-4.6.0.13-i486 zypper install gstreamer1.0-devel gstreamer1.0-plugins-base-devel glib2-devel
```

## 5. Verify the Installation

After installing the packages, verify that `pkg-config` can find GStreamer in each target.

### ARM (32-bit)

```bash
/c/SailfishOS/bin/sfdk tools exec SailfishOS-4.6.0.13-armv7hl pkg-config --modversion gstreamer-1.0
```

### ARM (64-bit)

```bash
/c/SailfishOS/bin/sfdk tools exec SailfishOS-4.6.0.13-aarch64 pkg-config --modversion gstreamer-1.0
```

### Intel x86 (32-bit)

```bash
/c/SailfishOS/bin/sfdk tools exec SailfishOS-4.6.0.13-i486 pkg-config --modversion gstreamer-1.0
```

Each command should return the installed GStreamer version.

Next, verify that the compiler flags for GStreamer and the GStreamer application library are available.

For example, for the ARM 32-bit target:

```bash
/c/SailfishOS/bin/sfdk tools exec SailfishOS-4.6.0.13-armv7hl pkg-config --cflags gstreamer-1.0 gstreamer-app-1.0
```

Repeat the command with the corresponding target name for aarch64 and i486.

## 6. Configure the Project in Qt Creator

1. Open `harbour-binaural` in Qt Creator.
2. Open the **Projects** panel.
3. Under **Build & Run**, select the build kit you want to use.
4. Confirm that the kit matches the architecture you intend to build for:

   * `SailfishOS-4.6.0.13-armv7hl`
   * `SailfishOS-4.6.0.13-aarch64`
   * `SailfishOS-4.6.0.13-i486`

**Important:** The active Qt Creator kit determines which SDK build target is used. Installing GStreamer in one target does not make it available in another.

## 7. Run qmake and Build the Project

After installing the required development packages:

1. Open the project in Qt Creator.
2. Select **Build → Run qmake**.
3. Wait for qmake to finish.
4. Select **Build → Rebuild Project**.

Run qmake again after installing the packages or switching to a different build target so that the project configuration is regenerated for the selected kit.

## 8. GStreamer Integration

The project uses different audio pipelines for its sound sources:

* **Binaural beats:** Generated in real time using a DSP generator and played through `QAudioOutput`.
* **Colored noise:** Generated in real time using a DSP generator and played through `QAudioOutput`.
* **Ambient sounds:** Decoded using GStreamer and processed through a PCM loop.

The project uses `pkg-config` in its qmake configuration to locate GStreamer:

```qmake
CONFIG += link_pkgconfig
PKGCONFIG += gstreamer-1.0 gstreamer-app-1.0 glib-2.0

```
