#include "audioengine.h"
#include "binauralgenerator.h"

#include <QAudioDeviceInfo>
#include <QAudioFormat>
#include <QMap>
#include <QtMath>

// ============================================================================
// BINAURAL CONSTANTS
// ============================================================================

namespace
{
    const int BinauralFadeInDuration = 0;
    const int BinauralFadeOutDuration = 0;

    const int FadeInterval = 15;

    double frequencyForBand(const QString &band)
    {
        static const QMap<QString, double> bands = {
            { QStringLiteral("Delta"),          2.0 },
            { QStringLiteral("Delta/Theta"),    4.0 },
            { QStringLiteral("Theta"),          6.0 },
            { QStringLiteral("Alpha"),         10.0 },
            { QStringLiteral("Beta"),          20.0 },
            { QStringLiteral("Gamma"),         40.0 }
        };

        return bands.value(band, -1.0);
    }
}

// ============================================================================
// STATE
// ============================================================================

bool AudioEngine::isBinauralPlaying() const
{
    return m_audioOutput &&
           m_audioOutput->state() == QAudio::ActiveState;
}

bool AudioEngine::isBinauralPaused() const
{
    return m_audioOutput &&
           m_audioOutput->state() == QAudio::SuspendedState;
}

// ============================================================================
// RESUME
// ============================================================================

void AudioEngine::resumeBinaural()
{
    if (isBinauralPaused())
        m_audioOutput->resume();
}

// ============================================================================
// FREQUENCY
// ============================================================================

void AudioEngine::setFrequencyBand(const QString &band)
{
    const double frequency = frequencyForBand(band);
    if (frequency < 0.0)
        return;

    m_beatFrequency = frequency;

    if (m_generator)
        m_generator->setBeatFrequency(m_beatFrequency);
}

// ============================================================================
// VOLUME
// ============================================================================

void AudioEngine::setBinauralVolume(int volume)
{
    m_binauralVolume =
        qBound(0, volume, 100);

    if (m_audioOutput &&
        !m_binauralFadeTimer->isActive() &&
        !m_binauralFadeOutTimer->isActive())
    {
        m_audioOutput->setVolume(
            m_binauralVolume / 100.0);
    }
}

// ============================================================================
// BINAURAL AUDIO
// ============================================================================

void AudioEngine::start()
{
    if (m_audioOutput)
    {
        /*
         * Starting while a fade-out is running cancels
         * the fade-out and restores the requested volume.
         */
        if (m_binauralFadeOutTimer->isActive())
        {
            m_binauralFadeOutTimer->stop();

            m_audioOutput->setVolume(
                m_binauralVolume / 100.0);
        }

        return;
    }

    QAudioFormat format;
    QAudioDeviceInfo device;

    if (!resolvePcmFormat(format, device,
                          QStringLiteral("binaural")))
        return;

    m_generator =
        new BinauralGenerator(this);

    m_generator->setBeatFrequency(
        m_beatFrequency);

    m_generator->setSampleRate(
        format.sampleRate());

    m_generator->start();

    m_audioOutput =
        new QAudioOutput(device, format, this);

    m_audioOutput->setVolume(
        m_binauralVolume / 100.0);

    connect(
        m_audioOutput,
        &QAudioOutput::stateChanged,
        this,
        [this](QAudio::State)
        {
            updatePlayingState();
        });

    m_audioOutput->start(m_generator);
    updatePlayingState();
}

void AudioEngine::pauseBinaural()
{
    if (!m_audioOutput ||
        m_audioOutput->state() != QAudio::ActiveState)
        return;

    m_binauralFadeTimer->stop();
    m_binauralFadeOutTimer->stop();

    m_audioOutput->suspend();

    updatePlayingState();
}

void AudioEngine::stop()
{
    if (!m_audioOutput ||
        m_binauralFadeOutTimer->isActive())
    {
        return;
    }

    m_binauralFadeTimer->stop();
    m_binauralFadeOutStartVolume =
        m_audioOutput->volume();

    m_binauralFadeOutElapsed.start();

    m_binauralFadeOutTimer->start();
}

void AudioEngine::updateBinauralFadeIn()
{
    if (!m_audioOutput)
    {
        m_binauralFadeTimer->stop();
        return;
    }

    m_binauralFadeInPosition +=
        FadeInterval;

    const double progress =
        BinauralFadeInDuration > 0
            ? qMin(
                  1.0,
                  static_cast<double>(
                      m_binauralFadeInPosition)
                      / BinauralFadeInDuration)
            : 1.0;

    m_audioOutput->setVolume(
        (m_binauralVolume / 100.0)
        * progress);

    if (progress >= 1.0)
    {
        m_audioOutput->setVolume(
            m_binauralVolume / 100.0);

        m_binauralFadeTimer->stop();
        m_binauralFadeInPosition = 0;
    }
}

void AudioEngine::updateBinauralFadeOut()
{
    if (!m_audioOutput)
    {
        m_binauralFadeOutTimer->stop();
        return;
    }

    const double progress =
        BinauralFadeOutDuration > 0
            ? qMin(
                  1.0,
                  static_cast<double>(
                      m_binauralFadeOutElapsed.elapsed())
                      / BinauralFadeOutDuration)
            : 1.0;

    m_audioOutput->setVolume(
        m_binauralFadeOutStartVolume
        * (1.0 - progress));

    if (progress >= 1.0)
        stopBinauralImmediately();
}

void AudioEngine::stopBinauralImmediately()
{
    m_binauralFadeTimer->stop();
    m_binauralFadeOutTimer->stop();

    if (m_audioOutput)
    {
        m_audioOutput->stop();

        delete m_audioOutput;
        m_audioOutput = nullptr;
    }

    if (m_generator)
    {
        m_generator->stop();
        delete m_generator;
        m_generator = nullptr;
    }

    m_binauralFadeInPosition = 0;
    m_binauralFadeOutStartVolume = 0.0;

    updatePlayingState();
}
