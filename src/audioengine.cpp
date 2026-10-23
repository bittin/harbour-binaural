#include "audioengine.h"

#include <QtMath>
#include <QTimer>

namespace
{
    const int SleepTimerFadeOutDuration = 10000;
    const int FadeInterval = 15;
    const int VolumeUpdateInterval = 50;
}

AudioEngine::AudioEngine(QObject *parent)
    : QObject(parent),
      m_sleepTimerFadeTimer(new QTimer(this)),
      m_sleepTimerBinauralStartVolume(0.0),
      m_sleepTimerColoredNoiseStartVolume(0.0),
      m_audioOutput(nullptr),
      m_generator(nullptr),
      m_coloredNoiseOutput(nullptr),
      m_coloredNoiseGenerator(nullptr),
      m_binauralFadeTimer(new QTimer(this)),
      m_binauralFadeOutTimer(new QTimer(this)),
      m_coloredNoiseFadeOutTimer(new QTimer(this)),
      m_coloredNoiseVolumeTimer(new QTimer(this)),
      m_beatFrequency(10.0),
      m_binauralVolume(50),
      m_ambienceVolume(50),
      m_coloredNoiseVolume(50),
      m_binauralFadeInPosition(0),
      m_binauralFadeOutStartVolume(0.0),
      m_coloredNoiseFadeOutStartVolume(0.0)
{
    for (int i = 0; i < MaxAmbienceChannels; ++i) {
        m_ambienceChannels[i] = new AmbienceChannel(this);
        m_sleepTimerAmbienceStartVolumes[i] = 0;

        m_ambienceChannels[i]->setVolume(m_ambienceVolume);

        connect(m_ambienceChannels[i],
                &AmbienceChannel::stateChanged,
                this,
                &AudioEngine::updateAmbienceState);

        connect(m_ambienceChannels[i],
                &AmbienceChannel::finished,
                this,
                &AudioEngine::updatePlayingState);
    }

    m_binauralFadeTimer->setInterval(FadeInterval);
    m_binauralFadeOutTimer->setInterval(FadeInterval);
    m_coloredNoiseFadeOutTimer->setInterval(FadeInterval);

    m_sleepTimerFadeTimer->setInterval(FadeInterval);

    m_coloredNoiseVolumeTimer->setInterval(VolumeUpdateInterval);
    m_coloredNoiseVolumeTimer->setSingleShot(true);

    connect(m_binauralFadeTimer,
            &QTimer::timeout,
            this,
            [this]() {
                updateBinauralFadeIn();
            });

    connect(m_binauralFadeOutTimer,
            &QTimer::timeout,
            this,
            [this]() {
                updateBinauralFadeOut();
            });

    connect(m_coloredNoiseFadeOutTimer,
            &QTimer::timeout,
            this,
            [this]() {
                updateColoredNoiseFadeOut();
            });

    connect(m_coloredNoiseVolumeTimer,
            &QTimer::timeout,
            this,
            [this]() {
                applyPendingColoredNoiseVolume();
            });

    connect(m_sleepTimerFadeTimer,
            &QTimer::timeout,
            this,
            [this]() {
                const double progress = qMin(
                    1.0,
                    static_cast<double>(
                        m_sleepTimerFadeElapsed.elapsed())
                        / SleepTimerFadeOutDuration);

                const double factor = 1.0 - progress;

                if (m_audioOutput) {
                    m_audioOutput->setVolume(
                        m_sleepTimerBinauralStartVolume * factor);
                }

                for (int i = 0; i < MaxAmbienceChannels; ++i) {
                    if (m_ambienceChannels[i]) {
                        m_ambienceChannels[i]->applySleepVolume(
                            m_sleepTimerAmbienceStartVolumes[i],
                            factor);
                    }
                }

                if (m_coloredNoiseOutput) {
                    m_coloredNoiseOutput->setVolume(
                        m_sleepTimerColoredNoiseStartVolume * factor);
                }

                if (progress >= 1.0) {
                    m_sleepTimerFadeTimer->stop();

                    stopBinauralImmediately();
                    stopAmbiencesImmediately();
                    stopColoredNoiseImmediately();

                    updatePlayingState();
                }
            });
}

AudioEngine::~AudioEngine()
{
    m_sleepTimerFadeTimer->stop();

    stopBinauralImmediately();
    stopAmbiencesImmediately();
    stopColoredNoiseImmediately();
}

void AudioEngine::updatePlayingState()
{
    emit playingChanged();
}

void AudioEngine::updateAmbienceState()
{
    updatePlayingState();
}

void AudioEngine::fadeOutForSleepTimer()
{
    m_sleepTimerFadeTimer->stop();

    m_sleepTimerBinauralStartVolume =
        m_audioOutput ? m_audioOutput->volume() : 0.0;

    m_sleepTimerColoredNoiseStartVolume =
        m_coloredNoiseOutput
            ? m_coloredNoiseOutput->volume()
            : 0.0;

    for (int i = 0; i < MaxAmbienceChannels; ++i) {
        m_sleepTimerAmbienceStartVolumes[i] =
            m_ambienceChannels[i]
                ? m_ambienceChannels[i]->currentVolume()
                : 0;
    }

    m_sleepTimerFadeElapsed.start();
    m_sleepTimerFadeTimer->start();
}
