#include "audioengine.h"
#include "binauralgenerator.h"
#include "colorednoisegenerator.h"

#include <QAudioDeviceInfo>
#include <QAudioFormat>
#include <QDebug>
#include <QMediaContent>
#include <QUrl>
#include <QtMath>
#include <cstring>

namespace
{
    const int AmbienceCrossfadeDuration = 8000;

    const int SleepTimerFadeOutDuration = 5000;

    const int FadeInterval = 15;
    const int VolumeUpdateInterval = 50;
}

// ============================================================================
// AUDIO ENGINE
// ============================================================================

AudioEngine::AudioEngine(QObject *parent)
    : QObject(parent),
      m_sleepTimerFadeTimer(new QTimer(this)),
      m_sleepTimerBinauralStartVolume(0.0),
      m_sleepTimerAmbienceStartVolume(0.0),
      m_sleepTimerColoredNoiseStartVolume(0.0),
      m_audioOutput(nullptr),
      m_generator(nullptr),
      m_ambiencePlayerA(new QMediaPlayer(this)),
      m_ambiencePlayerB(new QMediaPlayer(this)),
      m_coloredNoiseOutput(nullptr),
      m_coloredNoiseGenerator(nullptr),

      m_binauralFadeTimer(new QTimer(this)),
      m_ambienceFadeInTimer(new QTimer(this)),
      m_ambienceCrossfadeTimer(new QTimer(this)),

      m_binauralFadeOutTimer(new QTimer(this)),
      m_ambienceFadeOutTimer(new QTimer(this)),
      m_coloredNoiseFadeOutTimer(new QTimer(this)),

      m_ambienceVolumeTimer(new QTimer(this)),
      m_coloredNoiseVolumeTimer(new QTimer(this)),

      m_activeAmbiencePlayer(nullptr),
      m_fadingAmbiencePlayer(nullptr),

      m_beatFrequency(10.0),

      m_binauralVolume(50),
      m_ambienceVolume(50),
      m_coloredNoiseVolume(50),

      m_binauralFadeInPosition(0),
      m_ambienceFadeInPosition(0),
      m_ambienceCrossfadePosition(0),

      m_ambienceCrossfadeDuration(
          AmbienceCrossfadeDuration),

      m_binauralFadeOutStartVolume(0.0),
      m_coloredNoiseFadeOutStartVolume(0.0),

      m_ambienceFadeOutActiveVolume(0),
      m_ambienceFadeOutFadingVolume(0)
{
    m_binauralFadeTimer->setInterval(FadeInterval);
    m_ambienceFadeInTimer->setInterval(FadeInterval);
    m_ambienceCrossfadeTimer->setInterval(FadeInterval);

    m_binauralFadeOutTimer->setInterval(FadeInterval);
    m_ambienceFadeOutTimer->setInterval(FadeInterval);
    m_coloredNoiseFadeOutTimer->setInterval(FadeInterval);
    m_sleepTimerFadeTimer->setInterval(FadeInterval);

    m_ambienceVolumeTimer->setInterval(
        VolumeUpdateInterval);
    m_ambienceVolumeTimer->setSingleShot(true);

    m_coloredNoiseVolumeTimer->setInterval(
        VolumeUpdateInterval);
    m_coloredNoiseVolumeTimer->setSingleShot(true);

    connectAmbiencePlayer(m_ambiencePlayerA);
    connectAmbiencePlayer(m_ambiencePlayerB);

    connect(m_binauralFadeTimer,
            &QTimer::timeout,
            this,
            [this]()
            {
                updateBinauralFadeIn();
            });

    connect(m_ambienceFadeInTimer,
            &QTimer::timeout,
            this,
            [this]()
            {
                updateAmbienceFadeIn();
            });

    connect(m_ambienceCrossfadeTimer,
            &QTimer::timeout,
            this,
            [this]()
            {
                updateAmbienceCrossfade();
            });

    connect(m_binauralFadeOutTimer,
            &QTimer::timeout,
            this,
            [this]()
            {
                updateBinauralFadeOut();
            });

    connect(m_ambienceFadeOutTimer,
            &QTimer::timeout,
            this,
            [this]()
            {
                updateAmbienceFadeOut();
            });

    connect(m_coloredNoiseFadeOutTimer,
            &QTimer::timeout,
            this,
            [this]()
            {
                updateColoredNoiseFadeOut();
            });

    connect(m_sleepTimerFadeTimer, &QTimer::timeout, this, [this]()
    {
        const double progress =
            qMin(
                1.0,
                static_cast<double>(
                    m_sleepTimerFadeElapsed.elapsed())
                    / SleepTimerFadeOutDuration);

        const double factor = 1.0 - progress;

        if (m_audioOutput)
        {
            m_audioOutput->setVolume(
                m_sleepTimerBinauralStartVolume * factor);
        }

        if (m_activeAmbiencePlayer)
        {
            m_activeAmbiencePlayer->setVolume(
                static_cast<int>(
                    m_sleepTimerAmbienceStartVolume * factor));
        }

        if (m_fadingAmbiencePlayer)
        {
            m_fadingAmbiencePlayer->setVolume(0);
        }

        if (m_coloredNoiseOutput)
        {
            m_coloredNoiseOutput->setVolume(
                m_sleepTimerColoredNoiseStartVolume * factor);
        }

        if (progress >= 1.0)
        {
            m_sleepTimerFadeTimer->stop();

            stopBinauralImmediately();
            stopAmbienceImmediately();
            stopColoredNoiseImmediately();
        }
    });

    connect(m_ambienceVolumeTimer,
            &QTimer::timeout,
            this,
            [this]()
            {
                applyPendingAmbienceVolume();
            });

    connect(m_coloredNoiseVolumeTimer,
            &QTimer::timeout,
            this,
            [this]()
            {
                applyPendingColoredNoiseVolume();
            });

    m_ambiencePlayerA->setVolume(0);
    m_ambiencePlayerB->setVolume(0);
}


AudioEngine::~AudioEngine()
{
    stopBinauralImmediately();
    stopAmbienceImmediately();
    stopColoredNoiseImmediately();
}

// ============================================================================
// STATE
// ============================================================================

void AudioEngine::updatePlayingState()
{
    emit playingChanged();
}


// ============================================================================
// BINAURAL
// ============================================================================

void AudioEngine::fadeOutForSleepTimer()
{
    m_sleepTimerFadeTimer->stop();

    m_sleepTimerBinauralStartVolume =
        m_audioOutput
            ? m_audioOutput->volume()
            : 0.0;

    m_sleepTimerAmbienceStartVolume =
        m_activeAmbiencePlayer
            ? m_activeAmbiencePlayer->volume()
            : 0.0;

    m_sleepTimerColoredNoiseStartVolume =
        m_coloredNoiseOutput
            ? m_coloredNoiseOutput->volume()
            : 0.0;

    m_sleepTimerFadeElapsed.start();
    m_sleepTimerFadeTimer->start();
}
