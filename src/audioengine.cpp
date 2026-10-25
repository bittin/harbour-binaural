#include "audioengine.h"

#include <QtMath>
#include <QTimer>

namespace
{
    const int SleepTimerFadeOutDuration = 5000;
    const int FadeInterval = 15;
    const int VolumeUpdateInterval = 50;
}

AudioEngine::AudioEngine(QObject *parent)
    : QObject(parent),
      m_sleepTimerFadeTimer(new QTimer(this)),
      m_sleepTimerBinauralStartVolume(0.0),
      m_sleepTimerColoredNoiseStartVolume(0.0),
      m_binauralChannel(nullptr),
      m_noiseChannel(nullptr),
      m_binauralGenerator(nullptr),
      m_noiseGenerator(nullptr),
      m_coloredNoiseVolumeTimer(new QTimer(this)),
      m_beatFrequency(10.0),
      m_binauralVolume(50),
      m_ambienceVolume(50),
      m_coloredNoiseVolume(50)
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

    m_sleepTimerFadeTimer->setInterval(FadeInterval);

    m_coloredNoiseVolumeTimer->setInterval(VolumeUpdateInterval);
    m_coloredNoiseVolumeTimer->setSingleShot(true);

    m_binauralChannel =
        new PcmChannel(QStringLiteral("binaural"),
                       m_binauralVolume / 100.0,
                       this);

    m_noiseChannel =
        new PcmChannel(QStringLiteral("colored noise"),
                       static_cast<qreal>(
                           coloredNoiseTargetVolume()) / 100.0,
                       this);

    connect(m_binauralChannel,
            &PcmChannel::stateChanged,
            this,
            &AudioEngine::updatePlayingState);

    connect(m_noiseChannel,
            &PcmChannel::stateChanged,
            this,
            &AudioEngine::updatePlayingState);

    connect(m_binauralChannel,
            &PcmChannel::stopped,
            this,
            [this]()
            {
                m_binauralGenerator = nullptr;
            });

    connect(m_noiseChannel,
            &PcmChannel::stopped,
            this,
            [this]()
            {
                m_noiseGenerator = nullptr;
                m_currentColoredNoise.clear();
                m_coloredNoiseVolumeTimer->stop();
            });

    connect(m_coloredNoiseVolumeTimer,
            &QTimer::timeout,
            this,
            [this]()
            {
                applyPendingColoredNoiseVolume();
            });

    connect(m_sleepTimerFadeTimer,
            &QTimer::timeout,
            this,
            [this]()
            {
                const double progress = qMin(
                    1.0,
                    static_cast<double>(
                        m_sleepTimerFadeElapsed.elapsed())
                        / SleepTimerFadeOutDuration);

                const double factor = 1.0 - progress;

                m_binauralChannel->setVolume(
                    m_sleepTimerBinauralStartVolume * factor);

                for (int i = 0; i < MaxAmbienceChannels; ++i) {
                    if (m_ambienceChannels[i]) {
                        m_ambienceChannels[i]->applySleepVolume(
                            m_sleepTimerAmbienceStartVolumes[i],
                            factor);
                    }
                }

                m_noiseChannel->setVolume(
                    m_sleepTimerColoredNoiseStartVolume * factor);

                if (progress >= 1.0) {
                    m_sleepTimerFadeTimer->stop();

                    m_binauralChannel->stopImmediately();
                    stopAmbiencesImmediately();
                    m_noiseChannel->stopImmediately();

                    updatePlayingState();
                }
            });
}

AudioEngine::~AudioEngine()
{
    m_sleepTimerFadeTimer->stop();

    m_binauralChannel->stopImmediately();
    stopAmbiencesImmediately();
    m_noiseChannel->stopImmediately();
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
        m_binauralChannel->volume();

    m_sleepTimerColoredNoiseStartVolume =
        m_noiseChannel->volume();

    for (int i = 0; i < MaxAmbienceChannels; ++i) {
        m_sleepTimerAmbienceStartVolumes[i] =
            m_ambienceChannels[i]
                ? m_ambienceChannels[i]->currentVolume()
                : 0;
    }

    m_sleepTimerFadeElapsed.start();
    m_sleepTimerFadeTimer->start();
}
