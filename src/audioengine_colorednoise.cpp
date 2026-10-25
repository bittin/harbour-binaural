#include "audioengine.h"
#include "colorednoisegenerator.h"

#include <QAudioDeviceInfo>
#include <QAudioFormat>

#include <QtMath>

namespace
{
    const int ColoredNoiseFadeOutDuration = 200;
}


// ============================================================================
// STATE
// ============================================================================

bool AudioEngine::isColoredNoisePlaying() const
{
    return m_coloredNoiseOutput &&
           m_coloredNoiseOutput->state()
               == QAudio::ActiveState;
}

bool AudioEngine::isColoredNoisePaused() const
{
    return m_coloredNoiseOutput &&
           m_coloredNoiseOutput->state()
               == QAudio::SuspendedState;
}


// ============================================================================
// RESUME
// ============================================================================

void AudioEngine::resumeColoredNoise()
{
    if (isColoredNoisePaused())
        m_coloredNoiseOutput->resume();
}


// ============================================================================
// VOLUME
// ============================================================================

void AudioEngine::setColoredNoiseVolume(int volume)
{
    m_coloredNoiseVolume =
        qBound(0, volume, 100);

    m_coloredNoiseVolumeTimer->start();
}

int AudioEngine::coloredNoiseTargetVolume() const
{
    return qRound(
        // MASTER VOLUME Adjuster Colored Noise
        m_coloredNoiseVolume * 0.4);
}

void AudioEngine::applyPendingColoredNoiseVolume()
{
    if (m_coloredNoiseOutput &&
        !m_coloredNoiseFadeOutTimer->isActive())
    {
        m_coloredNoiseOutput->setVolume(
            static_cast<qreal>(
                coloredNoiseTargetVolume()) / 100.0);
    }
}


// ============================================================================
// COLORED NOISE AUDIO
// ============================================================================

void AudioEngine::setColoredNoise(
    const QString &noise)
{
    ColoredNoiseGenerator::NoiseType type;

    if (noise == "White")
    {
        type = ColoredNoiseGenerator::WhiteNoise;
    }
    else if (noise == "Pink")
    {
        type = ColoredNoiseGenerator::PinkNoise;
    }
    else if (noise == "Brown")
    {
        type = ColoredNoiseGenerator::BrownNoise;
    }
    else if (noise == "Grey")
    {
        type = ColoredNoiseGenerator::GreyNoise;
    }
    else
    {
        return;
    }

    /*
     * If noise is already running, only change the
     * algorithm. The audio stream itself remains alive.
     */
    if (m_coloredNoiseGenerator &&
        m_coloredNoiseOutput)
    {
        m_coloredNoiseFadeOutTimer->stop();

        m_coloredNoiseGenerator->setNoiseType(type);

        m_coloredNoiseOutput->setVolume(
            static_cast<qreal>(
                coloredNoiseTargetVolume()) / 100.0);

        m_currentColoredNoise = noise;
        updatePlayingState();
        return;
    }

    QAudioFormat format;
    QAudioDeviceInfo device;

    if (!resolvePcmFormat(format, device,
                          QStringLiteral("colored noise")))
        return;

    m_coloredNoiseGenerator =
        new ColoredNoiseGenerator(this);

    m_coloredNoiseGenerator->setSampleRate(
        format.sampleRate());

    m_coloredNoiseGenerator->setChannelCount(
        format.channelCount());

    m_coloredNoiseGenerator->setNoiseType(type);

    m_coloredNoiseGenerator->start();

    m_coloredNoiseOutput =
        new QAudioOutput(device, format, this);

    m_coloredNoiseOutput->setVolume(
        static_cast<qreal>(
            coloredNoiseTargetVolume()) / 100.0);

    connect(
        m_coloredNoiseOutput,
        &QAudioOutput::stateChanged,
        this,
        [this](QAudio::State)
        {
            updatePlayingState();
        });

    m_currentColoredNoise = noise;

    m_coloredNoiseOutput->start(
        m_coloredNoiseGenerator);

    updatePlayingState();
}


void AudioEngine::pauseColoredNoise()
{
    if (!m_coloredNoiseOutput ||
        m_coloredNoiseOutput->state()
            != QAudio::ActiveState)
        return;

    m_coloredNoiseFadeOutTimer->stop();

    m_coloredNoiseOutput->suspend();

    updatePlayingState();
}


void AudioEngine::stopColoredNoise()
{
    if (!m_coloredNoiseOutput)
    {
        stopColoredNoiseImmediately();
        return;
    }

    if (m_coloredNoiseFadeOutTimer->isActive())
        return;

    m_coloredNoiseFadeOutStartVolume =
        m_coloredNoiseOutput->volume();

    m_coloredNoiseFadeOutElapsed.start();

    m_coloredNoiseFadeOutTimer->start();
}


void AudioEngine::updateColoredNoiseFadeOut()
{
    if (!m_coloredNoiseOutput)
    {
        m_coloredNoiseFadeOutTimer->stop();
        return;
    }

    const double progress =
        ColoredNoiseFadeOutDuration > 0
            ? qMin(
                  1.0,
                  static_cast<double>(
                      m_coloredNoiseFadeOutElapsed.elapsed())
                      / ColoredNoiseFadeOutDuration)
            : 1.0;

    m_coloredNoiseOutput->setVolume(
        m_coloredNoiseFadeOutStartVolume
        * (1.0 - progress));

    if (progress >= 1.0)
        stopColoredNoiseImmediately();
}


void AudioEngine::stopColoredNoiseImmediately()
{
    m_coloredNoiseFadeOutTimer->stop();
    m_coloredNoiseVolumeTimer->stop();

    if (m_coloredNoiseOutput)
    {
        m_coloredNoiseOutput->stop();

        delete m_coloredNoiseOutput;
        m_coloredNoiseOutput = nullptr;
    }

    if (m_coloredNoiseGenerator)
    {
        m_coloredNoiseGenerator->stop();

        delete m_coloredNoiseGenerator;
        m_coloredNoiseGenerator = nullptr;
    }

    m_currentColoredNoise.clear();
    m_coloredNoiseFadeOutStartVolume = 0.0;

    updatePlayingState();
}
